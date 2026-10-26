package.path = 'src/?.lua;' .. package.path

local bodies, requests, batches, responses, transport_id, other_code, radio_songs, song_details
local radio_responses
local function copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = copy(item) end
    return out
end
local function dispatch(path, body)
    if radio_responses[path] then return copy(radio_responses[path]) end
    if path == '/nuser/account/get' then return {code = 200, profile = {userId = 42, nickname = 'test'}} end
    if path == '/song/like/get' then return {code = other_code or 200, ids = {}} end
    if path == '/v3/song/detail' then return {code = 200, songs = copy(song_details)} end
    if path == '/v1/radio/get' then return {code = 200, data = copy(radio_songs)} end
    if path == '/album/sublist' then
        return {code = 200, data = {{id = 10, name = 'album', subTime = 1}}, hasMore = false}
    end
    if path == '/album/v3/detail' then
        return {code = 200, album = {id = 10, name = 'album', size = 1,
            artists = {{id = 11}, {id = 12}}, picId = 99},
            songs = {{id = 100, name = 'song', dt = 1000, no = 1, cd = '1',
                al = {id = 10}, ar = {{id = 11}, {id = 12}}}}}
    end
    if path == '/artist/head/info/get' then
        if body.id == transport_id then error('network unavailable') end
        return copy(assert(bodies[body.id], 'unexpected artist'))
    end
    if path == '/middle/account/token/refresh' then return {code = 200, data = {action = 2}} end
    if path == '/v3/discovery/recommend/songs' then return {code = 200, data = {dailySongs = {}}} end
    if path == '/personalized/playlist' then return {code = 200, result = {}} end
    if path == '/user/playlist' then return {code = 200, playlist = {}} end
    error('unexpected request ' .. path)
end
local function builder(url)
    local request = {url = url}
    for _, name in ipairs{'headers', 'query', 'timeout', 'form'} do
        request[name] = function(self, value) self[name .. '_value'] = value; return self end
    end
    function request:build() return self end
    function request:send()
        requests[#requests + 1] = self
        local path = self.url:gsub('^https://music%.163%.com', ''):gsub('^/weapi', ''):gsub('^/eapi', '')
        local body = dispatch(path, self.form_value)
        local response = {closed = false, reads = 0}
        function response:json() self.reads = self.reads + 1; assert(self.reads == 1); return body end
        function response:url() return url end
        function response:header_values(name) assert(name == 'x-refresh-token'); return {} end
        function response:close() self.closed = true end
        responses[#responses + 1] = response
        return response
    end
    return request
end
local http = {}
function http:get(url) return builder(url) end
function http:post(url) return builder(url) end
function http:new_batch()
    local batch = {pending = {}}
    function batch:add(key, request) self.pending[#self.pending + 1] = {key = key, response = request:send()} end
    function batch:seal() end
    function batch:wait_one() return table.remove(self.pending) end
    function batch:close()
        self.closed = true
        for _, value in ipairs(self.pending) do value.response:close() end
    end
    batches[#batches + 1] = batch
    return batch
end
package.preload['qcm.mod'] = function()
    return {
        inner = {id = 7, device_id = function() return 'test' end,
            new_session_id = function() return 'scope' end, save_session = function() return 'saved' end,
            session_task = function(_, _, callback) return callback() end},
        error = function(value) error(value, 0) end,
        debug = function() end,
        errors = {inspect = function(value) return type(value) == 'table' and value or nil end},
        time = {now = function() return 1000000 end}, crypto = {},
        enum = {ItemType = {}, SyncState = {NotAuth = 1}}, get_http_client = function() return http end,
    }
end
package.preload.json = function()
    return {encode = function(value) return copy(value) end,
        decode = function(value) return type(value) == 'table' and copy(value) or {user_id = 42} end}
end
package.preload.crypto = function()
    return {weapi = function(value) return value end, eapi = function(_, value) return value end,
        cache_key = function() return 'cache' end}
end

local function reset()
    bodies = {[11] = {code = 404, message = '无相关艺人'},
        [12] = {code = 200, data = {artist = {id = 12, name = 'available', avatar = 'https://image.invalid/12.jpg'}}}}
    requests, batches, responses, transport_id, other_code = {}, {}, {}, nil, nil
    radio_songs, song_details, radio_responses = {}, {}, {}
end
local function context()
    local ctx = {saved = {}, calls = {}, ids = {}, next_id = 1000}
    function ctx:libraries() return {{library_id = 9}} end
    function ctx:sync_libraries(libraries) assert(libraries[1].native_id == '42'); return {9} end
    function ctx:allocate_items(items)
        local ids = {}
        for _, item in ipairs(items) do
            assert(item.library_id == 9)
            local key = item.type .. '/' .. item.native_id
            if not self.ids[key] then self.next_id = self.next_id + 1; self.ids[key] = self.next_id end
            ids[#ids + 1] = self.ids[key]
        end
        return ids
    end
    for _, name in ipairs{'sync_albums', 'sync_songs', 'sync_artists', 'sync_images', 'sync_dynamics',
        'sync_album_artist_ids', 'sync_song_artist_ids', 'sync_remote_mixes', 'sync_radio_queues'} do
        ctx[name] = function(self, value)
            self.saved[name] = copy(value)
            self.calls[name] = self.calls[name] or {}
            table.insert(self.calls[name], copy(value))
        end
    end
    function ctx:sync_remote_mix_song_ids() end
    function ctx:commit_artist() end
    function ctx:commit_album() end
    function ctx:commit_song() end
    return ctx
end
local function sync()
    local provider = dofile('src/provider.lua')
    provider.load('account')
    local ctx = context()
    local ok, err = pcall(provider.sync, ctx)
    for _, batch in ipairs(batches) do assert(batch.closed, 'batch was not closed') end
    for _, response in ipairs(responses) do assert(response.closed, 'response was not closed') end
    return ctx, ok, err
end
local passed = 0
local function test(name, run)
    reset(); run(); passed = passed + 1; print('ok ' .. name)
end
test('missing artist does not stop later sync or misalign relations', function()
    local ctx, ok, err = sync(); assert(ok, err)
    assert(#ctx.saved.sync_artists == 1 and ctx.saved.sync_artists[1].name == 'available')
    local id = ctx.ids['Artist/12']
    assert(id and not ctx.ids['Artist/11'])
    local image_count = 0
    for _, images in ipairs(ctx.calls.sync_images) do
        for _, image in ipairs(images) do
            if image.native_id == '12' then
                assert(image.item_id == id)
                image_count = image_count + 1
            end
        end
    end
    assert(image_count == 1)
    assert(#ctx.saved.sync_album_artist_ids == 1 and ctx.saved.sync_album_artist_ids[1].artist_id == id)
    assert(#ctx.saved.sync_song_artist_ids == 1 and ctx.saved.sync_song_artist_ids[1].artist_id == id)
    local queues = ctx.saved.sync_radio_queues
    assert(#queues == 10 and queues[1].native_id == 'roaming/fm' and queues[2].native_id == 'roaming/similar'
        and queues[3].native_id == 'heart/liked')
end)
test('all artists missing still reaches radio sync', function()
    bodies[12] = {code = 404}
    local ctx, ok, err = sync(); assert(ok, err)
    assert(#ctx.saved.sync_artists == 0 and #ctx.saved.sync_album_artist_ids == 0 and #ctx.saved.sync_song_artist_ids == 0)
    assert(#ctx.saved.sync_radio_queues == 10)
end)
test('artist business failure remains fatal', function()
    bodies[11] = {code = 500, message = 'server failed'}
    local ctx, ok, err = sync(); assert(not ok and tostring(err):match('500'))
    assert(ctx.saved.sync_radio_queues == nil)
end)
test('artist transport failure remains fatal', function()
    transport_id = 11
    local ctx, ok, err = sync(); assert(not ok and tostring(err):match('network unavailable'))
    assert(ctx.saved.sync_radio_queues == nil)
end)
test('authentication failure remains fatal', function()
    bodies[11] = {code = 301}
    local ctx, ok, err = sync(); assert(not ok and type(err) == 'table' and err.code == 'not_auth')
    assert(ctx.saved.sync_radio_queues == nil)
end)
test('malformed successful artist response remains fatal', function()
    bodies[11] = {code = 200, data = {}}
    local ctx, ok, err = sync(); assert(not ok and tostring(err):match('invalid artist head response'))
    assert(ctx.saved.sync_radio_queues == nil)
end)
test('single artist request shares the missing outcome', function()
    local client = require('client').new('test')
    local result = client:perform(require('api.artist.head.info.get').new(11), 30)
    assert(result.code == 404 and result.artist == nil and responses[1].reads == 1 and responses[1].closed)
end)
test('unrelated APIs still reject 404 in single and batch requests', function()
    other_code = 404
    local client = require('client').new('test')
    local api = require('api.song.like.get').new(42)
    assert(not pcall(client.perform, client, api, 30))
    local next_api = api
    assert(not pcall(client.perform_queue, client, function()
        local value = next_api; next_api = nil; return value
    end, 30))
    assert(batches[1].closed)
end)
local function song(id, artists, legacy)
    local value = {id = id, name = 'song ' .. id, dt = 180000, no = 1,
        al = {id = 10, name = 'album', picId = 99}, ar = artists}
    if legacy then
        value.album, value.al = value.al, nil
        value.artists, value.ar = value.ar, nil
        value.duration, value.dt = value.dt, nil
    end
    return value
end
local function artist_requests()
    local counts = {}
    for _, request in ipairs(requests) do
        if request.url:match('/artist/head/info/get$') then
            local id = request.form_value.id
            counts[id] = (counts[id] or 0) + 1
        end
    end
    return counts
end
test('dynamic songs sync artists once per batch and retain every song relation', function()
    bodies[11] = {code = 200, data = {artist = {id = 11, name = 'first', briefDesc = 'description'}}}
    local ctx = context()
    local operator = require('sync').new(require('client').new('test'), 42, 7)
    local input = {song(101, {{id = 11}, {id = 12}, {id = 11}, {id = 0}, {}}),
        song(102, {{id = '12'}, {id = 11}}, true), song(103), song(101, {{id = 11}})}
    local songs = operator:sync_songs(ctx, 9, input)
    assert(#songs == 4 and songs[1].item.native_id == '101' and songs[2].duration == 180000)
    assert(songs[4].id == songs[1].id)
    assert(#ctx.saved.sync_artists == 2 and not ctx.ids['Artist/0'])
    local counts = artist_requests()
    assert(counts[11] == 1 and counts[12] == 1)
    local expected = {}
    for _, song_id in ipairs{101, 102} do
        for _, artist_id in ipairs{11, 12} do
            expected[ctx.ids['Song/' .. song_id] .. '/' .. ctx.ids['Artist/' .. artist_id]] = true
        end
    end
    assert(#ctx.saved.sync_song_artist_ids == 4)
    for _, relation in ipairs(ctx.saved.sync_song_artist_ids) do
        local key = relation.song_id .. '/' .. relation.artist_id
        assert(expected[key], 'duplicate or incorrect song artist relation')
        expected[key] = nil
    end
    assert(next(expected) == nil and #ctx.saved.sync_album_artist_ids == 0)
    for _, artist in ipairs(ctx.saved.sync_artists) do
        if artist.item.native_id == '11' then assert(artist.description == 'description') end
    end
    local repeated = operator:sync_songs(ctx, 9, input)
    for index, value in ipairs(repeated) do assert(value.id == songs[index].id) end
    assert(#ctx.saved.sync_song_artist_ids == 4)
end)
test('dynamic songs without valid artists do not request artist details', function()
    local ctx = context()
    local operator = require('sync').new(require('client').new('test'), 42, 7)
    local songs = operator:sync_songs(ctx, 9, {song(101, {{id = 0}, {id = -1}, {id = 1.5}, {}}), song(102)})
    assert(#songs == 2 and #requests == 0 and #batches == 0)
    assert(ctx.saved.sync_artists == nil and ctx.saved.sync_song_artist_ids == nil)
end)
test('dynamic artist IDs retain integer precision', function()
    local id = 9007199254740993
    bodies[id] = {code = 200, data = {artist = {id = id, name = 'large ID'}}}
    local ctx = context()
    local operator = require('sync').new(require('client').new('test'), 42, 7)
    local songs = operator:sync_songs(ctx, 9, {song(101, {{id = id}, {id = tostring(id)}})})
    assert(artist_requests()[id] == 1 and ctx.ids['Artist/9007199254740993'])
    assert(#ctx.saved.sync_song_artist_ids == 1)
    assert(ctx.saved.sync_song_artist_ids[1].song_id == songs[1].id)
    assert(ctx.saved.sync_song_artist_ids[1].artist_id == ctx.ids['Artist/9007199254740993'])
end)
test('missing dynamic artist does not misalign song relations', function()
    local ctx = context()
    local operator = require('sync').new(require('client').new('test'), 42, 7)
    local songs = operator:sync_songs(ctx, 9, {song(101, {{id = 11}}), song(102, {{id = 12}}, true)})
    assert(#songs == 2 and not ctx.ids['Artist/11'] and ctx.ids['Artist/12'])
    assert(#ctx.saved.sync_song_artist_ids == 1)
    local relation = ctx.saved.sync_song_artist_ids[1]
    assert(relation.song_id == songs[2].id and relation.artist_id == ctx.ids['Artist/12'])
    for _, batch in ipairs(batches) do assert(batch.closed) end
    for _, response in ipairs(responses) do assert(response.closed and response.reads == 1) end
end)
test('private roaming and similar radio persist artists before returning songs', function()
    local provider = dofile('src/provider.lua')
    provider.load('account')
    local ctx = context()
    radio_songs = {song(101, {{id = 12}}, true)}
    local first = provider.open_queue(ctx, 'roaming/fm', {configuration = {}, reason = 'Initial'})
    assert(#first.songs == 1 and ctx.ids['Artist/12'])
    assert(ctx.saved.sync_song_artist_ids[1].song_id == first.songs[1].id)
    bodies[11] = {code = 200, data = {artist = {id = 11, name = 'next artist'}}}
    radio_songs = {song(102, {{id = 11}})}
    local following = provider.next_queue(ctx, 'roaming/fm', {state = first.state, current_native_ids = {'101'}})
    assert(#following.songs == 1 and ctx.ids['Artist/11'])
    assert(ctx.saved.sync_song_artist_ids[1].artist_id == ctx.ids['Artist/11'])
    assert(ctx.saved.sync_song_artist_ids[1].song_id == following.songs[1].id)
    song_details = {song(201, {{id = 12}})}
    radio_songs = {song(103, {{id = 12}}, true)}
    local similar = provider.open_queue(ctx, 'roaming/similar', {configuration = {}, reason = 'Initial',
        input = {item_type = 'Song', native_id = '201'}})
    assert(similar.presentation.source_item_id == ctx.ids['Song/201'])
    assert(ctx.saved.sync_song_artist_ids[1].song_id == similar.songs[1].id)
    assert(ctx.saved.sync_song_artist_ids[1].artist_id == ctx.ids['Artist/12'])
    assert(#ctx.calls.sync_artists == 4 and #ctx.saved.sync_album_artist_ids == 0)
    for _, batch in ipairs(batches) do assert(batch.closed) end
    for _, response in ipairs(responses) do assert(response.closed and response.reads == 1) end
end)
test('category radio persists artists on open and next batches', function()
    local provider = dofile('src/provider.lua')
    provider.load('account')
    local ctx = context()
    radio_responses['/tag/tab/fm/recommends'] = {code = 200, data = {{id = 101}, {id = 102}}}
    song_details = {song(102, {{id = 12}}), song(101, {{id = 12}})}
    local first = provider.open_queue(ctx, 'category/rap', {configuration = {}, reason = 'Initial'})
    assert(#first.songs == 2 and first.songs[1].item.native_id == '101')
    assert(artist_requests()[12] == 1 and #ctx.saved.sync_song_artist_ids == 2)
    for _, relation in ipairs(ctx.saved.sync_song_artist_ids) do
        assert(relation.artist_id == ctx.ids['Artist/12'])
    end
    bodies[11] = {code = 200, data = {artist = {id = 11, name = 'next artist'}}}
    radio_responses['/tag/tab/fm/recommends'].data = {{id = 103}}
    song_details = {song(103, {{id = 11}})}
    local following = provider.next_queue(ctx, 'category/rap', {state = first.state,
        current_native_ids = {'101', '102'}})
    assert(#following.songs == 1 and following.songs[1].item.native_id == '103')
    assert(ctx.saved.sync_song_artist_ids[1].artist_id == ctx.ids['Artist/11'])
    assert(ctx.saved.sync_song_artist_ids[1].song_id == following.songs[1].id)
end)
test('heart radio persists seed and recommended song artists', function()
    local provider = dofile('src/provider.lua')
    provider.load('account')
    local ctx = context()
    radio_responses['/user/playlist'] = {code = 200, playlist = {{id = 10, specialType = 5, userId = 42}}, more = false}
    radio_responses['/v6/playlist/detail'] = {code = 200, playlist = {id = 10,
        trackIds = {{id = 201}}, tracks = {song(201, {{id = 12}})}}}
    radio_responses['/playmode/intelligence/list'] = {code = 200,
        data = {{id = 101, songInfo = song(101, {{id = 12}}), recommended = true}}}
    local result = provider.open_queue(ctx, 'heart/liked', {configuration = {}, reason = 'Initial'})
    assert(#result.songs == 2 and result.exhausted and artist_requests()[12] == 1)
    assert(result.songs[1].item.native_id == '201' and result.songs[2].item.native_id == '101')
    assert(#ctx.saved.sync_song_artist_ids == 2)
    for _, relation in ipairs(ctx.saved.sync_song_artist_ids) do
        assert(relation.artist_id == ctx.ids['Artist/12'])
    end
    assert(#ctx.saved.sync_album_artist_ids == 0)
end)
print(passed .. ' artist sync tests passed')
