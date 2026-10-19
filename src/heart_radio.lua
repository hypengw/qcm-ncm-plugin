local json = require('json')
local util = require('util')
local UserPlaylists = require('api.user.playlist')
local PlaylistDetail = require('api.v6.playlist.detail')
local SongDetail = require('api.v3.song.detail')
local Intelligence = require('api.playmode.intelligence.list')
local M = {}
M.__index = M

local NATIVE_ID = 'heart/liked'
local MAX_SONGS = 50
local DESCRIPTION = '从喜欢的音乐出发，混合熟悉歌曲与新推荐'

function M.resolve(native_id) return native_id == NATIVE_ID end

function M.entry()
    return {native_id = NATIVE_ID, name = '心动模式', description = DESCRIPTION}
end

function M.definition()
    return {configuration = {}, can_restart = true, restart_label = '重新推荐'}
end

function M.new(client, user_id, provider_id)
    return setmetatable({client = client, user_id = user_id, provider_id = provider_id}, M)
end

function M:restore(value)
    local state = json.decode(value)
    assert(type(state) == 'table' and state.version == 1 and state.kind == 'heart'
        and state.user_id == tostring(self.user_id), 'invalid heart radio state')
    for _, key in ipairs{'playlist_id', 'seed_id'} do
        assert(type(state[key]) == 'string' and util.positive_id(state[key]) == state[key], 'invalid heart source state')
    end
    local records = util.array(state.recommendations)
    assert(#records > 0 and #records <= MAX_SONGS and type(records[1]) == 'table'
        and records[1].native_id == state.seed_id, 'invalid heart recommendation state')
    local seen = {}
    for _, record in ipairs(records) do
        assert(type(record) == 'table' and type(record.native_id) == 'string'
            and util.positive_id(record.native_id) == record.native_id
            and type(record.recommended) == 'boolean' and (record.alg == nil or type(record.alg) == 'string')
            and not seen[record.native_id], 'invalid heart recommendation state')
        seen[record.native_id] = true
    end
    return state
end

function M:liked_playlist()
    local offset = 0
    for _ = 1, 20 do
        local response = self.client:perform(UserPlaylists.new(self.user_id, offset, 100, false), 30)
        if response.liked_playlist then return response.liked_playlist.native_id end
        if not response.has_more then error('未找到当前账号的喜欢歌单', 0) end
        offset = response.next_offset
    end
    error('喜欢歌单查询超过分页上限', 0)
end

function M:generate(ctx, previous, reason)
    local libraries = ctx:libraries()
    local library_id = assert(libraries[1] and libraries[1].library_id, 'missing heart radio library')
    local playlist_id = self:liked_playlist()
    local detail = self.client:perform(PlaylistDetail.new(playlist_id, MAX_SONGS), 30)
    local candidates, seen = {}, {}
    for _, id in ipairs(util.array(detail.track_ids)) do
        if not seen[id] then candidates[#candidates + 1], seen[id] = id, true end
        if #candidates == MAX_SONGS then break end
    end
    assert(#candidates > 0, '还没有喜欢的歌曲，无法开始心动模式')
    local start_music_id, count = candidates[1], #candidates
    if previous and reason == 'Restart' and #candidates > 1 then
        for index, id in ipairs(candidates) do
            if id == previous.seed_id then table.remove(candidates, index); break end
        end
    end
    local seed, seed_id
    for _ = 1, math.min(3, #candidates) do
        seed_id = table.remove(candidates, math.random(#candidates))
        seed = detail.songs_by_id[seed_id]
        if not seed then
            local response = self.client:perform(SongDetail.new({seed_id}), 30)
            seed = response.songs_by_id[seed_id]
        end
        if seed then break end
    end
    assert(seed, '喜欢的歌曲暂时无法作为心动模式起点')
    local response = self.client:perform(Intelligence.new({playlist_id = playlist_id,
        song_id = seed_id, start_music_id = start_music_id, type = 'fromPlayAll', count = count}), 30)
    assert(#response.recommendations > 0, '心动模式暂时没有推荐结果')
    local pending, missing, returned_seed = {}, {}, false
    seen = {[seed_id] = true}
    for _, record in ipairs(response.recommendations) do
        if record.native_id == seed_id then returned_seed = true end
        if not seen[record.native_id] then
            seen[record.native_id] = true
            pending[#pending + 1] = record
            if not record.song and not detail.songs_by_id[record.native_id] then
                missing[#missing + 1] = record.native_id
            end
            if #pending == MAX_SONGS - 1 then break end
        end
    end
    local fetched = {}
    if #missing > 0 then
        fetched = self.client:perform(SongDetail.new(missing), 30).songs_by_id
    end
    local ordered = {seed}
    local records = {{native_id = seed_id, recommended = false}}
    for _, record in ipairs(pending) do
        local song = record.song or detail.songs_by_id[record.native_id] or fetched[record.native_id]
        if song then
            ordered[#ordered + 1] = song
            records[#records + 1] = {native_id = record.native_id, alg = record.alg, recommended = record.recommended}
        end
    end
    assert(#ordered > 1 or returned_seed, '心动模式推荐歌曲暂时不可用')
    local state = json.encode({version = 1, kind = 'heart', user_id = tostring(self.user_id),
        playlist_id = playlist_id, seed_id = seed_id, recommendations = records})
    assert(#state <= 64 * 1024, 'heart radio state exceeds size limit')
    local sync = require('sync').new(self.client, self.user_id, self.provider_id)
    return {songs = sync:sync_songs(ctx, library_id, ordered), state = state, configuration = {},
        presentation = {description = DESCRIPTION}, exhausted = true}
end

function M:open(ctx, request)
    assert(next(request.configuration or {}) == nil, 'heart radio does not accept configuration')
    assert(request.input == nil, 'heart radio does not accept a song input')
    assert(math.type(self.user_id) == 'integer' and self.user_id > 0, 'heart radio requires an account')
    local previous = request.previous_state and self:restore(request.previous_state)
    local ok, result = pcall(self.generate, self, ctx, previous, request.reason)
    if not ok then
        if type(result) == 'string' then error('心动模式：' .. result, 0) end
        error(result, 0)
    end
    return result
end

function M:next(_, request)
    self:restore(request.state)
    return {songs = {}, state = request.state, configuration = {},
        presentation = {description = DESCRIPTION}, exhausted = true}
end

return M
