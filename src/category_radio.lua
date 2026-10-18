local json = require('json')
local util = require('util')
local Recommends = require('api.tag.tab.fm.recommends')
local SongDetail = require('api.v3.song.detail')
local M = {}
M.__index = M

local categories = {
    {tag = 'rap', name = '说唱'},
    {tag = 'electronic', name = '电音'},
    {tag = 'sleep', name = '助眠'},
    {tag = 'chinese', name = '国风'},
    {tag = 'occident', name = '欧美'},
    {tag = 'korea', name = '韩流'},
    {tag = 'classical', name = '古典'},
}
local sources = {}
for _, category in ipairs(categories) do
    category.native_id = 'category/' .. category.tag
    category.description = '按' .. category.name .. '分类持续推荐'
    sources[category.native_id] = category
end

function M.resolve(native_id) return sources[native_id] end

function M.entries()
    local entries = {}
    for _, category in ipairs(categories) do
        entries[#entries + 1] = {native_id = category.native_id, name = category.name .. '漫游',
            description = category.description}
    end
    return entries
end

function M.definition()
    return {configuration = {}, can_restart = true, restart_label = '重新推荐'}
end

function M.new(client, user_id, provider_id, category)
    return setmetatable({client = client, user_id = user_id, provider_id = provider_id,
        category = category}, M)
end

function M:restore(value)
    local state = json.decode(value)
    assert(type(state) == 'table' and state.version == 1 and state.kind == 'category'
        and state.native_id == self.category.native_id, 'invalid category radio state')
    local source = state.source
    assert(type(source) == 'table' and source.tab_tag_id == self.category.tag
        and source.rule_id == '' and source.rule_type == 1, 'invalid category radio source state')
    local seen = {}
    for _, record in ipairs(util.array(state.recommendations)) do
        assert(type(record) == 'table' and type(record.native_id) == 'string'
            and util.positive_id(record.native_id) == record.native_id
            and (record.alg == nil or type(record.alg) == 'string')
            and not seen[record.native_id], 'invalid category recommendation state')
        seen[record.native_id] = true
    end
    return state
end

function M:fetch(ctx, state, current_native_ids)
    local current, records, seen = {}, {}, {}
    for _, id in ipairs(util.array(current_native_ids)) do current[util.positive_id(id)] = true end
    for _, record in ipairs(state.recommendations) do
        if current[record.native_id] then records[#records + 1] = record end
    end
    local response = self.client:perform(Recommends.new(state.source), 30)
    local pending, ids = {}, {}
    for _, record in ipairs(response.recommendations) do
        local id = record.native_id
        if not current[id] and not seen[id] then
            seen[id] = true
            ids[#ids + 1], pending[#pending + 1] = id, record
        end
    end
    local songs = {}
    if #ids > 0 then
        local detail = self.client:perform(SongDetail.new(ids), 30)
        local ordered = {}
        for _, record in ipairs(pending) do
            local song = detail.songs_by_id[record.native_id]
            if song then
                ordered[#ordered + 1] = song
                records[#records + 1] = record
            end
        end
        if #ordered > 0 then
            local libraries = ctx:libraries()
            local library_id = assert(libraries[1] and libraries[1].library_id, 'missing radio library')
            local sync = require('sync').new(self.client, self.user_id, self.provider_id)
            songs = sync:sync_songs(ctx, library_id, ordered)
        end
    end
    local next_state = {version = 1, kind = 'category', native_id = state.native_id,
        source = state.source, recommendations = records}
    return {songs = songs, state = json.encode(next_state), configuration = {},
        presentation = {description = self.category.description}, exhausted = false}
end

function M:run(ctx, state, current_native_ids)
    local ok, result = pcall(self.fetch, self, ctx, state, current_native_ids)
    if not ok then
        if type(result) == 'string' then error(self.category.name .. '漫游：' .. result, 0) end
        error(result, 0)
    end
    return result
end

function M:open(ctx, request)
    assert(next(request.configuration or {}) == nil, 'category radio does not accept configuration')
    assert(request.input == nil, 'category radio does not accept a song input')
    if request.previous_state then self:restore(request.previous_state) end
    local state = {version = 1, kind = 'category', native_id = self.category.native_id,
        source = {tab_tag_id = self.category.tag, rule_id = '', rule_type = 1}, recommendations = {}}
    local result = self:run(ctx, state, {})
    assert(#result.songs > 0, self.category.name .. '漫游暂时没有可播放歌曲')
    return result
end

function M:next(ctx, request)
    return self:run(ctx, self:restore(request.state), request.current_native_ids or {})
end

return M
