local M = {}
M.__index = M

---@class SongPlayerUrl
---@field ids table<number> Song IDs
---@field level string Standard|Higher|Exhigh|Lossless|Hires
---@field encodeType string Encoding type (default: 'flac')

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/song/enhance/player/url/v1"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "eapi"
end

function M:query()
    return {}
end

function M:body()
    return {
        ids = string.format("[%s]", table.concat(self.ids or {}, ",")),
        level = self.level or 'exhigh',
        encodeType = self.encodeType or 'flac',
    }
end

function M:parse_response(response)
    return response:json()
end

return M
