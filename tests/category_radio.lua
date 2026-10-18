package.path = 'src/?.lua;' .. package.path

local function copy(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end
local states = {}
local json = {
    encode = function(value)
        states[#states + 1] = copy(value)
        return 'state-' .. #states
    end,
    decode = function(value) return copy(assert(states[tonumber(value:match('^state%-(%d+)$'))])) end,
}
package.preload.json = function() return json end
package.preload.crypto = function() return {} end
package.preload['qcm.mod'] = function()
    return {inner = {id = 7, device_id = function() return 'test' end,
        new_session_id = function() return 'scope' end}, crypto = {},
        enum = {ItemType = {}, SyncState = {}}}
end

local requests, recommendations, details, failure, responses = {}, {}, {}, nil, {}
local Client = {}
function Client.new() return Client end
function Client:perform(api, timeout)
    assert(timeout == 30)
    requests[#requests + 1] = {path = api:path(), body = copy(api:body())}
    if failure then error(failure) end
    local body
    if api:path() == '/tag/tab/fm/recommends' then
        assert(api:operation() == 'POST' and api:crypto() == 'weapi')
        body = {code = 200, data = copy(recommendations)}
    elseif api:path() == '/v3/song/detail' then
        body = {code = 200, songs = copy(details)}
    else
        error('unexpected request ' .. api:path())
    end
    local response = {reads = 0}
    function response:json() self.reads = self.reads + 1; assert(self.reads == 1); return body end
    responses[#responses + 1] = response
    return api:parse_response(response)
end
package.preload.client = function() return Client end

local Sync = require('sync')
local database = {ids = {}, next_id = 1000, songs = {}, albums = {}, images = {}, favorites = {}}
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
    for _, song in ipairs(songs) do database.songs[song.item.native_id] = copy(song) end
end
function ctx:sync_albums(albums)
    for _, album in ipairs(albums) do database.albums[album.item.native_id] = copy(album) end
end
function ctx:sync_images(images)
    for _, image in ipairs(images) do database.images[image.item_id] = copy(image) end
end
function ctx:sync_dynamics(dynamics, options)
    assert(#options.include == 1 and options.include[1] == 'update_at')
    for _, item in ipairs(dynamics) do assert(item.favorite_at == nil) end
end

local function song(id, duration)
    return {id = id, name = 'song ' .. id, dt = duration or 180000, no = 1,
        al = {id = id + 100, name = 'album ' .. id, picId_str = tostring(id + 200)}}
end
local provider = dofile('src/provider.lua')
local Category = require('category_radio')
local expected = {'rap', 'electronic', 'sleep', 'chinese', 'occident', 'korea', 'classical'}
local entries = Category.entries()
assert(#entries == 7)
for i, tag in ipairs(expected) do
    assert(entries[i].native_id == 'category/' .. tag and entries[i].name:match('漫游$'))
    local definition = provider.queue_definition(ctx, entries[i].native_id)
    assert(#definition.configuration == 0 and definition.can_restart and definition.restart_label == '重新推荐')
end
entries[1].native_id = 'changed'
assert(Category.entries()[1].native_id == 'category/rap')
assert(#requests == 0)

local function open(id, request)
    request = request or {}
    request.configuration = request.configuration or {}
    request.reason = request.reason or 'Initial'
    return provider.open_queue(ctx, id, request)
end
local first = {}
for i, tag in ipairs(expected) do
    local base = i * 10
    recommendations = {{id = base + 1, alg = 'first'}, {id = base + 2}, {id = base + 1, alg = 'duplicate'},
        {id = base + 3}, {id = base + 4}, {id = base + 5}, {id = base + 6}}
    details = {song(base + 6), song(base + 2), song(base + 1), song(base + 4), song(base + 5), song(999)}
    local start = #requests
    local result = open('category/' .. tag)
    first[tag] = result
    local body = requests[start + 1].body
    assert(body.tabTagId == tag and body.ruleId == '' and body.ruleType == 1 and body.limit == 5)
    assert(body.mode == nil and body.sourceIds == nil and body.offset == nil and body.unplaySongIds == nil)
    assert(#requests == start + 2 and #result.songs == 5 and not result.exhausted)
    local order = {base + 1, base + 2, base + 4, base + 5, base + 6}
    for index, id in ipairs(order) do
        local item = result.songs[index]
        assert(item.item.native_id == tostring(id) and item.name == 'song ' .. id)
        assert(item.duration == 180000)
        assert(item.album_id == database.albums[tostring(id + 100)].id)
        assert(database.images[item.album_id].native_id == tostring(id + 200))
    end
    assert(next(result.configuration) == nil and result.presentation.source_item_id == nil)
    assert(result.presentation.description == Category.resolve('category/' .. tag).description)
    local state = json.decode(result.state)
    assert(state.kind == 'category' and state.native_id == 'category/' .. tag)
    assert(#state.recommendations == 5 and state.recommendations[1].alg == 'first')
    assert(database.songs['999'] == nil)
end

recommendations = {{id = 11}, {id = 12}, {id = 19, alg = 'new'}, {id = 19}}
details = {song(19)}
local result = provider.next_queue(ctx, 'category/rap', {state = first.rap.state, current_native_ids = {'12', '11'}})
assert(#result.songs == 1 and result.songs[1].item.native_id == '19')
local state = json.decode(result.state)
assert(#state.recommendations == 3 and state.recommendations[1].alg == 'first')
assert(state.recommendations[3].native_id == '19' and state.recommendations[3].alg == 'new')
assert(#json.decode(first.rap.state).recommendations == 5)
recommendations = {{id = 19}}
local count = #requests
local empty = provider.next_queue(ctx, 'category/rap', {state = result.state, current_native_ids = {'19'}})
assert(#requests == count + 1 and #empty.songs == 0 and not empty.exhausted)
assert(#json.decode(empty.state).recommendations == 1)
recommendations, details = {{id = 20}}, {}
empty = provider.next_queue(ctx, 'category/rap', {state = result.state, current_native_ids = {}})
assert(#empty.songs == 0 and not empty.exhausted)
recommendations = {}
assert(not pcall(open, 'category/rap', {reason = 'Restart', previous_state = first.rap.state}))
assert(#json.decode(first.rap.state).recommendations == 5)

count = #requests
for _, request in ipairs{{input = {item_type = 'Song', native_id = '11'}},
    {configuration = {mode = 'DEFAULT'}}, {configuration = {category = 'rap'}},
    {previous_state = first.electronic.state}, {previous_state = 'corrupt'}} do
    assert(not pcall(open, 'category/rap', request))
end
assert(not pcall(provider.next_queue, ctx, 'category/electronic', {state = first.rap.state}))
assert(not pcall(provider.next_queue, ctx, 'roaming/fm', {state = first.rap.state}))
assert(not pcall(open, 'category/unknown'))
assert(not pcall(provider.queue_definition, ctx, 'category/unknown'))
local corrupted = json.decode(first.rap.state)
corrupted.source.tab_tag_id = 'electronic'
assert(not pcall(provider.next_queue, ctx, 'category/rap', {state = json.encode(corrupted)}))
corrupted = json.decode(first.rap.state)
corrupted.recommendations[2] = corrupted.recommendations[1]
assert(not pcall(provider.next_queue, ctx, 'category/rap', {state = json.encode(corrupted)}))
assert(#requests == count)

local Recommends = require('api.tag.tab.fm.recommends')
local api = Recommends.new({tab_tag_id = '', rule_id = 'rule', rule_type = 1})
assert(api:body().tabTagId == '' and api:body().ruleId == 'rule')
assert(not pcall(Recommends.new, {tab_tag_id = 'rap', rule_id = 'rule', rule_type = 1}))
local function parse(value) return api:parse_response({json = function() return value end}) end
assert(parse({code = 200, data = {{id = '9007199254740993'}}}).recommendations[1].native_id == '9007199254740993')
for _, data in ipairs{{bad = {}}, {{id = 0}}, {{id = 1.5}}, {{id = 'x'}}, {{id = 1, alg = {}}}, {false}} do
    assert(not pcall(parse, {code = 200, data = data}))
end
assert(not pcall(parse, {code = 200}))
assert(parse({code = 301}).code == 301)
local Detail = require('api.v3.song.detail').new({})
assert(not pcall(Detail.parse_response, Detail, {json = function() return {code = 200, songs = {song(1), song(1)}} end}))
assert(Detail:parse_response({json = function() return {code = 301} end}).code == 301)

recommendations, details, failure = {{id = 21}}, {song(21)}, 'network unavailable'
local ok, err = pcall(open, 'category/rap', {reason = 'Restart', previous_state = first.rap.state})
assert(not ok and tostring(err):match('说唱漫游') and tostring(err):match('network unavailable'))
assert(#json.decode(first.rap.state).recommendations == 5)
failure = nil
local restarted = open('category/rap', {reason = 'Restart', previous_state = first.rap.state})
assert(#json.decode(restarted.state).recommendations == 1)
assert(json.decode(restarted.state).source.tab_tag_id == 'rap')
local legacy = song(888)
legacy.album, legacy.al, legacy.duration, legacy.dt = legacy.al, nil, 235000, nil
local legacy_song = Sync.new(Client, 42, 7):sync_songs(ctx, 9, {legacy})[1]
assert(legacy_song.duration == 235000)
for _, response in ipairs(responses) do assert(response.reads == 1) end
print('category radio request, ordered detail sync, state isolation, retry, and bounded metadata tests passed')
