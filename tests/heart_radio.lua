package.path = 'src/?.lua;' .. package.path

local null = {}
local function copy(value)
    if type(value) ~= 'table' or value == null then return value end
    local out = {}
    for key, child in pairs(value) do out[key] = copy(child) end
    return out
end
local states, sequence = {}, 0
local function size(value)
    if type(value) == 'string' then return #value end
    if type(value) ~= 'table' then return 8 end
    local count = 2
    for key, child in pairs(value) do count = count + size(key) + size(child) + 4 end
    return count
end
local json = {
    encode = function(value)
        sequence = sequence + 1
        local encoded = 'state-' .. sequence .. string.rep(' ', size(value))
        states[encoded] = copy(value)
        return encoded
    end,
    decode = function(value) return copy(assert(states[value], 'invalid JSON')) end,
}
package.preload.json = function() return json end
package.preload.crypto = function() return {} end
package.preload['qcm.mod'] = function()
    return {null = null, inner = {id = 7, device_id = function() return 'test' end,
        new_session_id = function() return 'scope' end}, crypto = {}, enum = {ItemType = {}, SyncState = {}}}
end

local requests, responses, pages, playlist, recommendations, details, failure = {}, {}, {}, {}, {}, {}, nil
local Client = {}
function Client.new() return Client end
function Client:perform(api, timeout)
    assert(timeout == 30 and api:operation() == 'POST' and api:crypto() == 'weapi' and api.retry_after_auth)
    local path, body = api:path(), copy(api:body())
    requests[#requests + 1] = {path = path, body = body, ids = copy(api.ids)}
    if failure then error(failure, 0) end
    local data
    if path == '/user/playlist' then
        assert(body.uid == '42' and body.limit == 100 and body.includeVideo == false)
        data = assert(pages[body.offset], 'unexpected playlist page')
    elseif path == '/v6/playlist/detail' then
        assert(body.id == tostring(playlist.id) and (body.n == 50 or body.n == 10000))
        data = {code = 200, playlist = playlist}
    elseif path == '/playmode/intelligence/list' then
        data = {code = 200, data = recommendations}
    elseif path == '/v3/song/detail' then
        data = {code = 200, songs = details}
    else
        error('unexpected API ' .. path)
    end
    local response = {reads = 0}
    function response:json() self.reads = self.reads + 1; assert(self.reads == 1); return copy(data) end
    responses[#responses + 1] = response
    return api:parse_response(response)
end
package.preload.client = function() return Client end

local database = {ids = {}, next_id = 1000, songs = {}, albums = {}, images = {}, writes = 0}
local ctx = {}
function ctx:libraries() return {{library_id = 9}} end
function ctx:allocate_items(items)
    local ids = {}
    for _, item in ipairs(items) do
        assert(item.library_id == 9)
        local key = item.type .. '/' .. item.native_id
        if not database.ids[key] then database.next_id = database.next_id + 1; database.ids[key] = database.next_id end
        ids[#ids + 1] = database.ids[key]
    end
    return ids
end
function ctx:sync_songs(songs)
    database.writes = database.writes + 1
    for _, song in ipairs(songs) do database.songs[song.item.native_id] = copy(song) end
end
function ctx:sync_albums(albums)
    for _, album in ipairs(albums) do database.albums[album.item.native_id] = copy(album) end
end
function ctx:sync_images(images)
    for _, image in ipairs(images) do database.images[image.item_id] = copy(image) end
end
function ctx:sync_dynamics(items, options)
    assert(#options.include == 1 and options.include[1] == 'update_at')
    for _, item in ipairs(items) do assert(item.favorite_at == nil) end
end
local function song(id)
    return {id = id, name = 'song ' .. id, dt = 180000, no = 1,
        al = {id = 100, name = 'album', picId_str = '9007199254740993'}}
end
local function reset()
    requests, responses, failure = {}, {}, nil
    pages = {[0] = {code = 200, playlist = {
        {id = 8, name = '我喜欢的音乐', specialType = 0, userId = 42},
        {id = 9, specialType = 5, creator = {userId = 43}},
        {id = 10, specialType = 5, creator = {userId = 42}},
    }, more = false}}
    playlist = {id = 10, trackIds = {{id = 11}, {id = 12}, {id = 13}}, tracks = {song(12), song(11)}}
    recommendations = {
        {id = 13, songInfo = song(13), recommended = false, alg = 'familiar'},
        {id = 21, songInfo = song(21), recommended = true, alg = 'new'},
        {id = 12, songInfo = null, recommended = false},
        {id = 22, recommended = true}, {id = 21, songInfo = song(21), recommended = true},
        {id = 23, recommended = true}, {id = 11, songInfo = song(11), recommended = false},
    }
    details = {song(999), song(22)}
end
reset()
local provider = require('provider')
provider.load(json.encode({user_id = 42}))
local Heart = require('heart_radio')
local random = math.random
math.random = function() return 1 end
local definition = provider.queue_definition(ctx, 'heart/liked')
assert(definition.can_restart and definition.restart_label == '重新推荐' and #definition.configuration == 0)
assert(#requests == 0)
local function open(request)
    request = request or {}
    request.configuration = request.configuration or {}
    request.reason = request.reason or 'Initial'
    return provider.open_queue(ctx, 'heart/liked', request)
end
local first = open()
local expected = {'11', '13', '21', '12', '22'}
assert(#first.songs == #expected and first.exhausted and next(first.configuration) == nil)
assert(first.presentation.description == Heart.entry().description and first.presentation.source_item_id == nil)
for index, id in ipairs(expected) do
    local item = first.songs[index]
    assert(item.item.native_id == id and item.name == 'song ' .. id and item.duration == 180000)
    assert(item.album_id == database.albums['100'].id)
    assert(database.images[item.album_id].native_id == '9007199254740993')
end
assert(database.songs['999'] == nil and database.songs['23'] == nil)
local state = json.decode(first.state)
assert(state.kind == 'heart' and state.version == 1 and state.user_id == '42')
assert(state.playlist_id == '10' and state.seed_id == '11' and #state.recommendations == 5)
assert(not state.recommendations[2].recommended and state.recommendations[2].alg == 'familiar')
assert(state.recommendations[3].recommended and state.recommendations[3].alg == 'new')
assert(state.recommendations[3].song == nil and state.recommendations[3].songInfo == nil)
assert(#requests == 4 and requests[3].path == '/playmode/intelligence/list')
local body = requests[3].body
assert(body.playlistId == '10' and body.songId == '11' and body.startMusicId == '11')
assert(body.type == 'fromPlayAll' and body.count == '3' and body.mode == nil and body.limit == nil)
assert(#requests[4].ids == 2 and requests[4].ids[1] == '22' and requests[4].ids[2] == '23')
local next_batch = provider.next_queue(ctx, 'heart/liked', {state = first.state, current_native_ids = {'22'}})
assert(#requests == 4 and #next_batch.songs == 0 and next_batch.exhausted and next_batch.state == first.state)

local restarted = open({reason = 'Restart', previous_state = first.state})
assert(json.decode(restarted.state).seed_id == '12')
assert(json.decode(first.state).seed_id == '11' and #json.decode(first.state).recommendations == 5)
local count = #requests
for _, request in ipairs{{configuration = {mode = 'DEFAULT'}}, {input = {item_type = 'Song', native_id = '11'}},
    {previous_state = 'corrupt'}, {previous_state = json.encode({version = 1, kind = 'similar'})}} do
    assert(not pcall(open, request))
end
assert(not pcall(provider.next_queue, ctx, 'roaming/fm', {state = first.state}))
assert(not pcall(provider.next_queue, ctx, 'roaming/similar', {state = first.state}))
assert(not pcall(provider.next_queue, ctx, 'category/rap', {state = first.state}))
for _, mutate in ipairs{
    function(s) s.user_id = '43' end, function(s) s.playlist_id = '0' end,
    function(s) s.recommendations[2] = s.recommendations[1] end,
    function(s) s.recommendations[2].recommended = 'true' end,
    function(s) s.recommendations[2].alg = {} end,
    function(s) s.recommendations[1] = false end,
} do
    local corrupted = json.decode(first.state)
    mutate(corrupted)
    assert(not pcall(open, {previous_state = json.encode(corrupted)}))
end
assert(#requests == count)

reset()
local writes = database.writes
recommendations = {}
assert(not pcall(open, {reason = 'Restart', previous_state = first.state}))
assert(database.writes == writes and #json.decode(first.state).recommendations == 5)
failure = 'network unavailable'
local ok, err = pcall(open, {reason = 'Restart', previous_state = first.state})
assert(not ok and tostring(err):match('心动模式') and tostring(err):match('network unavailable'))
assert(database.writes == writes)
reset()
recommendations = {{id = 23}}
details = {}
assert(not pcall(open))
assert(database.writes == writes)
reset()
recommendations = {{id = 11, recommended = false}}
assert(#open().songs == 1)
reset()
playlist.tracks, details = {}, {}
assert(not pcall(open))
assert(#requests == 5 and requests[3].path == '/v3/song/detail')
reset()
playlist.trackIds, playlist.tracks = {}, {}
ok, err = pcall(open)
assert(not ok and tostring(err):match('还没有喜欢的歌曲'))
reset()
pages = {[0] = {code = 200, playlist = {{id = 9, specialType = 5, userId = 43}}, more = false}}
ok, err = pcall(open)
assert(not ok and tostring(err):match('未找到当前账号'))
reset()
local liked = pages[0].playlist[3]
pages = {[0] = {code = 200, playlist = {{id = 8}}, more = true},
    [1] = {code = 200, playlist = {liked}, more = false}}
assert(#open().songs == 5 and requests[2].body.offset == 1)
reset()
for offset = 0, 19 do pages[offset] = {code = 200, playlist = {{id = 8}}, more = true} end
ok, err = pcall(open)
assert(not ok and tostring(err):match('分页上限') and #requests == 20)

reset()
playlist.trackIds, playlist.tracks, recommendations = {}, {}, {}
for id = 11, 110 do
    playlist.trackIds[#playlist.trackIds + 1] = {id = id}
    recommendations[#recommendations + 1] = {id = id, songInfo = song(id), recommended = id > 60}
end
playlist.tracks = {song(11)}
local bounded = open()
assert(#bounded.songs == 50 and #json.decode(bounded.state).recommendations == 50)
assert(#requests == 3 and requests[3].body.count == '50')
reset()
writes = database.writes
recommendations[2].alg = string.rep('x', 65536)
assert(not pcall(open) and database.writes == writes)
reset()
local large = '9007199254740993'
playlist.id, pages[0].playlist[3].id = large, large
playlist.trackIds, playlist.tracks = {{id = large}}, {song(large)}
recommendations = {{id = large, songInfo = song(large)}}
local precise = open()
assert(precise.songs[1].item.native_id == large and requests[3].body.playlistId == large)
assert(requests[3].body.songId == large and requests[3].body.startMusicId == large)

local Intelligence = require('api.playmode.intelligence.list')
local source = {playlist_id = large, song_id = large, start_music_id = large, type = 'fromPlayOne', count = 1}
local api = Intelligence.new(source)
source.song_id = '1'
assert(api:body().songId == large and api:body().type == 'fromPlayOne')
local function parse(data) return api:parse_response({json = function() return data end}) end
assert(parse({code = 301}).code == 301)
local record = parse({code = 200, data = {{id = large, songInfo = null, alg = null, recommended = null}}}).recommendations[1]
assert(record.native_id == large and record.song == nil and record.alg == nil and not record.recommended)
for _, data in ipairs{{bad = true}, {false}, {{id = 0}}, {{id = 1.5}}, {{id = 'x'}},
    {{id = 1, songInfo = song(2)}}, {{id = 1, alg = {}}}, {{id = 1, recommended = 1}}} do
    assert(not pcall(parse, {code = 200, data = data}))
end
assert(not pcall(parse, {code = 200}))
local UserPlaylists = require('api.user.playlist').new(42)
for _, data in ipairs{{code = 200}, {code = 200, playlist = {}, more = true},
    {code = 200, playlist = {}, more = 'true'}, {code = 200, playlist = {
        {id = 1, specialType = 5, userId = 42}, {id = 2, specialType = 5, userId = 42}}}} do
    assert(not pcall(UserPlaylists.parse_response, UserPlaylists, {json = function() return data end}))
end
local PlaylistDetail = require('api.v6.playlist.detail')
assert(PlaylistDetail.new(10):body().n == 10000)
assert(not pcall(PlaylistDetail.new, 10, 0))
local detail = PlaylistDetail.new(10)
assert(not pcall(detail.parse_response, detail, {json = function() return {code = 200, playlist = {id = 11}} end}))
assert(not pcall(detail.parse_response, detail, {json = function() return {code = 200, playlist = {
    id = 10, trackIds = {}, tracks = {song(11), song(11)}}} end}))
reset()
playlist.name, playlist.trackCount = 'liked', 3
details = {song(999), song(13)}
local synced_mix_ids
function ctx:sync_remote_mixes() end
function ctx:sync_remote_mix_song_ids(_, ids) synced_mix_ids = ids end
require('sync').new(Client, 42, 7):sync_mix(ctx, {library_id = 9, native_id = '10'})
assert(#requests == 2 and requests[1].body.n == 10000)
assert(#requests[2].ids == 1 and requests[2].ids[1] == '13')
assert(#synced_mix_ids == 3)
for index, id in ipairs{'11', '12', '13'} do assert(synced_mix_ids[index] == database.songs[id].id) end
count = #requests
ctx.libraries = function() return {} end
assert(not pcall(open) and #requests == count)
provider.load(json.encode({user_id = -1}))
assert(not pcall(open) and #requests == count)
math.random = random
for _, response in ipairs(responses) do assert(response.reads == 1) end
print('heart radio request, finite mixing, ordered sync, restart, bounds, identity and failure tests passed')
