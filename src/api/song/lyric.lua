local M = {}
M.__index = M

---@class SongLyricRequest
---@field id string Song ID
---@field tv string TV version (default: '-1')
---@field lv string Lyric version (default: '-1')
---@field rv string Roma version (default: '-1')
---@field kv string Karaoke version (default: '-1')

---@class SongLyricItem
---@field version number
---@field lyric string

---@class SongLyricResponse
---@field code number
---@field lrc SongLyricItem?
---@field klyric SongLyricItem?
---@field tlyric SongLyricItem?
---@field romalrc SongLyricItem?

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/song/lyric"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {
        _nmclfl = "1"
    }
end

function M:body()
    return {
        id = self.id,
        tv = "-1",
        lv = "-1",
        rv = "-1",
        kv = "-1"
    }
end

---@return SongLyricResponse
function M:parse_response(response)
    return response:json()
end

return M