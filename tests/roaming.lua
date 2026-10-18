package.path = 'src/?.lua;' .. package.path

local performed, synced, values = {}, {}, {}
local liked = {201, 202}
local unavailable, empty, network_error = {}, {}, false
local radio_songs = {{id = 101, name = 'recommended'}, {id = 102}, {id = 103}}
local function copy(value)
    if type(value) ~= 'table' then return value end
    local out = {}
    for key, item in pairs(value) do out[key] = copy(item) end
    return out
end
local json = {
    encode = function(value)
        values[#values + 1] = copy(value)
        return 'test-state-' .. #values
    end,
    decode = function(value)
        return copy(values[tonumber(value:match('^test%-state%-(%d+)$'))])
    end,
}
package.preload.json = function() return json end
package.preload.crypto = function() return {} end
package.preload['qcm.mod'] = function()
    return {
        inner = {id = 7, device_id = function() return 'test' end,
            new_session_id = function() return 'test-session' end},
        crypto = {}, enum = {ItemType = {}, SyncState = {}},
    }
end
package.preload.client = function()
    return {new = function()
        return {perform = function(_, api, timeout)
            assert(timeout == 30)
            performed[#performed + 1] = api
            if network_error then error('network unavailable') end
            if api:path() == '/song/like/get' then
                assert(api:body().uid == 42)
                return {code = 200, ids = liked}
            elseif api:path() == '/v3/song/detail' then
                local id = api.ids[1]
                return {code = 200, songs = unavailable[id] and {} or {{id = tonumber(id), name = 'song ' .. id}}}
            end
            assert(api:path() == '/v1/radio/get')
            return {code = 200, data = empty[api:body().sourceIds] and {} or radio_songs}
        end}
    end}
end
package.preload.sync = function()
    return {new = function(_, _, provider_id)
        assert(provider_id == 7)
        return {sync_songs = function(_, ctx, library_id, songs)
            assert(library_id == 9 and ctx ~= nil)
            synced[#synced + 1] = songs
            local out = {}
            for _, song in ipairs(songs) do out[#out + 1] = {id = song.id + 1000, name = song.name} end
            return out
        end}
    end}
end

local provider = dofile('src/provider.lua')
local ctx = {libraries = function() return {{library_id = 9}} end}
provider.load(json.encode({user_id = 42}))
local fields = provider.queue_definition(ctx, 'roaming/fm').configuration
assert(#fields == 1 and fields[1].key == 'mode' and fields[1].value == 'DEFAULT')
assert(#fields[1].options == 3 and fields[1].options[1].name == '默认模式')
assert(fields[1].options[2].name == '熟悉模式' and fields[1].options[3].name == '探索模式')
local similar = provider.queue_definition(ctx, 'roaming/similar')
assert(#similar.configuration == 0 and similar.can_restart and similar.restart_label == '换一首推荐')
assert(provider.queue_definition(ctx, 'roaming/fm').restart_label == '重新推荐')
assert(#performed == 0)
local function open(id, options)
    options = options or {}
    options.configuration = options.configuration or {}
    options.reason = options.reason or 'Initial'
    return provider.open_queue(ctx, id, options)
end
for _, mode in ipairs{'DEFAULT', 'FAMILIAR', 'EXPLORE'} do
    local result = open('roaming/fm', {configuration = {mode = mode}})
    assert(#result.songs == 3 and result.configuration.mode == mode)
    assert(next(result.presentation) == nil)
    local body = performed[#performed]:body()
    assert(body.mode == mode and body.subMode == '' and body.limit == 3)
    assert(body.sourceIds == nil and body.unplaySongIds == nil)
    provider.next_queue(ctx, 'roaming/fm', {state = result.state, current_native_ids = {'999'}})
    assert(performed[#performed]:body().mode == mode)
end
local count = #performed
assert(not pcall(open, 'roaming/fm', {configuration = {mode = 'UNKNOWN'}}))
assert(not pcall(open, 'roaming/fm', {configuration = {unknown = 'DEFAULT'}}))
assert(not pcall(open, 'roaming/similar', {configuration = {mode = 'EXPLORE'}}))
assert(not pcall(open, 'roaming/similar', {configuration = {unknown = 'value'}}))
assert(not pcall(open, 'roaming/201', {configuration = {mode = 'DEFAULT'}}))
assert(not pcall(open, 'unknown'))
assert(#performed == count)

local random = math.random
math.random = function() return 1 end
local roaming = require('roaming')
local mode = roaming.mode
roaming.mode = function() error('similar radio must not parse private roaming modes') end
local first = open('roaming/similar')
assert(next(first.configuration) == nil)
local state = json.decode(first.state)
assert(state.source_id == '201' and state.source_name == 'song 201')
assert(first.presentation.source_item_id == 1201 and first.presentation.description == '根据「song 201」推荐')
assert(first.songs[1].id == 1101 and first.songs[1].id ~= first.presentation.source_item_id)
assert(performed[#performed - 2]:path() == '/song/like/get')
assert(performed[#performed - 1]:path() == '/v3/song/detail')
local function similar_request(id)
    local api = performed[#performed]
    assert(api:path() == '/v1/radio/get' and api:operation() == 'POST' and api:crypto() == 'weapi')
    local body = api:body()
    assert(body.mode == 'SIMILAR' and body.sourceType == 'song' and body.sourceIds == id and body.limit == 3)
    assert(body.unplaySonIds == nil and body.unplaySongIds == nil and body.subMode == nil)
end
similar_request('201')
count = #performed
for _ = 1, 3 do
    local next = provider.next_queue(ctx, 'roaming/similar', {state = first.state, current_native_ids = {}})
    assert(json.decode(next.state).source_id == '201')
    similar_request('201')
end
assert(#performed == count + 3)
local second = open('roaming/similar', {reason = 'Restart', previous_state = first.state})
assert(json.decode(second.state).source_id == '202')
count = #performed
open('roaming/similar', {reason = 'Reconfigure', previous_state = second.state})
assert(#performed == count + 1)
similar_request('202')

count = #performed
open('roaming/similar', {input = {native_id = '9007199254740993', item_type = 'Song'}})
similar_request('9007199254740993')
assert(#performed == count + 2)
open('roaming/201')
similar_request('201')
assert(not pcall(open, 'roaming/similar', {input = {native_id = '201', item_type = 'Artist'}}))
assert(not pcall(provider.next_queue, ctx, 'roaming/similar', {state = 'corrupt'}))
assert(not pcall(provider.next_queue, ctx, 'roaming/fm', {state = first.state}))
assert(not pcall(provider.next_queue, ctx, 'roaming/similar', {state = json.encode({version = 2, kind = 'similar'})}))
assert(not pcall(open, 'roaming/similar', {previous_state = json.encode({version = 1, kind = 'fm', mode = 'DEFAULT'})}))

liked = {}
local ok, err = pcall(open, 'roaming/similar')
assert(not ok and err:match('还没有喜欢的歌曲'))
liked = {201}
assert(json.decode(open('roaming/similar', {reason = 'Restart', previous_state = first.state}).state).source_id == '201')
liked = {201, 202}
unavailable['201'] = true
assert(json.decode(open('roaming/similar').state).source_id == '202')
unavailable = {}
empty['201'] = true
assert(json.decode(open('roaming/similar').state).source_id == '202')
empty['202'] = true
count = #performed
assert(not pcall(open, 'roaming/similar'))
assert(#performed == count + 5)
empty = {}
network_error = true
assert(not pcall(open, 'roaming/similar'))
assert(json.decode(first.state).source_id == '201')
roaming.mode = mode
math.random = random
print('radio lifecycle tests passed')
