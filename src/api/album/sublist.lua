local M = {}
M.__index = M

function M.new(offset, limit, total)
    local self = setmetatable({}, M)
    ---@type number
    self.offset = offset or 0
    ---@type number
    self.limit = limit or 25
    ---@type boolean
    self.total = total == nil and true or total
    return self
end

function M:path()
    return "/album/sublist"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {}
end

function M:body()
    return {
        offset = self.offset,
        limit = self.limit,
        total = self.total
    }
end

---@class AlbumSublistArtist
---@field id number
---@field name string
---@field picUrl string
---@field alias string[]

---@class AlbumSublistItem
---@field subTime number
---@field alias string[]
---@field artists AlbumSublistArtist[]
---@field picUrl string
---@field name string
---@field id number
---@field size number
---@field transNames string[]

---@class AlbumSublistRsp
---@field code number
---@field count number
---@field hasMore boolean
---@field data AlbumSublistItem[]

---@return AlbumSublistRsp
function M:parse_response(response)
    return response:json()
end

return M
