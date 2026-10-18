local json = require('json')
local roaming = require('roaming')
local RadioGet = require('api.v1.radio.get')
local M = {}
M.__index = M

function M.new(client, user_id, provider_id)
    return setmetatable({client = client, user_id = user_id, provider_id = provider_id}, M)
end

local function kind(native_id)
    if native_id == 'roaming/fm' then return 'fm' end
    assert(native_id == 'roaming/similar' or native_id:match('^roaming/%d+$'), 'unsupported radio')
    return 'similar'
end

local function restore(value, expected)
    local state = json.decode(value)
    assert(type(state) == 'table' and state.version == 1 and state.kind == expected, 'invalid radio state')
    if expected == 'fm' then
        roaming.mode('roaming/fm', {mode = state.mode})
        assert(type(state.mode) == 'string', 'invalid radio mode state')
    else
        assert(type(state.source_id) == 'string' and state.source_id:match('^%d+$')
            and type(state.source_name) == 'string' and math.type(state.source_item_id) == 'integer'
            and state.source_item_id > 0, 'invalid radio source state')
    end
    return state
end

function M.definition(native_id)
    local radio_kind = kind(native_id)
    return {configuration = radio_kind == 'fm' and roaming.configuration(native_id) or {}, can_restart = true,
        restart_label = radio_kind == 'similar' and '换一首推荐' or '重新推荐'}
end

function M:context(ctx)
    local libraries = ctx:libraries()
    local library_id = libraries[1] and libraries[1].library_id or -1
    return require('sync').new(self.client, self.user_id, self.provider_id), library_id
end

function M:fetch(ctx, sync, library_id, state)
    local options = {mode = state.mode or 'SIMILAR'}
    if state.kind == 'similar' then options.source_id = state.source_id end
    local response = self.client:perform(RadioGet.new(options), 30)
    assert(response.code == 200 and type(response.data) == 'table', 'radio request failed: ' .. tostring(response.code))
    local songs = sync:sync_songs(ctx, library_id, response.data)
    local presentation = {}
    local configuration = {}
    if state.kind == 'similar' then
        presentation = {description = '根据「' .. state.source_name .. '」推荐', source_item_id = state.source_item_id}
    else
        configuration.mode = state.mode
    end
    return {songs = songs, state = json.encode(state), configuration = configuration,
        presentation = presentation, exhausted = false}
end

function M:source(ctx, sync, library_id, source_id)
    local api = require('api.v3.song.detail').new({source_id})
    local response = self.client:perform(api, 30)
    assert(response.code == 200 and type(response.songs) == 'table', 'source request failed: ' .. tostring(response.code))
    local song = response.songs[1]
    if not song or tostring(song.id) ~= source_id then return nil end
    local songs = sync:sync_songs(ctx, library_id, {song})
    if not songs[1] then return nil end
    return {version = 1, kind = 'similar', source_id = source_id, source_name = song.name,
        source_item_id = songs[1].id}
end

function M:open(ctx, native_id, request)
    local radio_kind = kind(native_id)
    local mode
    if radio_kind == 'fm' then
        mode = roaming.mode(native_id, request.configuration)
    else
        assert(next(request.configuration or {}) == nil, 'similar radio does not accept configuration')
    end
    local previous = request.previous_state and restore(request.previous_state, radio_kind)
    local sync, library_id = self:context(ctx)
    if radio_kind == 'fm' then
        assert(request.input == nil, 'private roaming does not accept an input')
        local result = self:fetch(ctx, sync, library_id, {version = 1, kind = 'fm', mode = mode})
        assert(#result.songs > 0, '私人漫游暂时没有可播放歌曲')
        return result
    end
    if previous and request.reason == 'Reconfigure' and not request.input then
        local result = self:fetch(ctx, sync, library_id, previous)
        assert(#result.songs > 0, '相似推荐暂时没有可播放歌曲')
        return result
    end
    local source_id = native_id:match('^roaming/(%d+)$')
    if request.input then
        assert(request.input.item_type == 'Song', 'similar radio requires a song input')
        source_id = request.input.native_id
        assert(type(source_id) == 'string' and source_id:match('^%d+$'), 'invalid song input')
    end
    local candidates = {}
    if source_id then
        candidates[1] = source_id
    else
        assert(self.user_id and self.user_id > 0, 'similar radio requires an account')
        local response = self.client:perform(require('api.song.like.get').new(self.user_id), 30)
        assert(response.code == 200 and type(response.ids) == 'table', 'liked songs request failed: ' .. tostring(response.code))
        local seen = {}
        for _, id in ipairs(response.ids) do
            local value = tostring(id)
            assert(value:match('^%d+$'), 'invalid liked song ID')
            if not seen[value] then
                candidates[#candidates + 1] = value
                seen[value] = true
            end
        end
        assert(#candidates > 0, '还没有喜欢的歌曲，无法开始相似推荐')
        if previous and request.reason == 'Restart' and #candidates > 1 then
            for i, id in ipairs(candidates) do
                if id == previous.source_id then table.remove(candidates, i); break end
            end
        end
    end
    for _ = 1, math.min(3, #candidates) do
        local index = source_id and 1 or math.random(#candidates)
        local selected = table.remove(candidates, index)
        local state = self:source(ctx, sync, library_id, selected)
        if state then
            local result = self:fetch(ctx, sync, library_id, state)
            if #result.songs > 0 then return result end
        end
    end
    error('喜欢的歌曲暂时无法生成相似推荐')
end

function M:next(ctx, native_id, request)
    local state = restore(request.state, kind(native_id))
    local sync, library_id = self:context(ctx)
    local result = self:fetch(ctx, sync, library_id, state)
    assert(#result.songs > 0, 'radio temporarily returned no songs')
    return result
end

return M
