local M = {}
M.__index = M

---@class ArtistSublistResponse
---@field hasMore boolean Whether there are more items
---@field count number Total number of items
---@field code number Response code
---@field data ArtistSublistItem[] Array of artist items

---@class ArtistSublistItem
---@field alias string[] Artist aliases
---@field mvSize number Number of music videos
---@field picUrl string URL of artist picture
---@field name string Artist name
---@field albumSize number Number of albums
---@field info string Additional information
---@field id number Artist ID
---@field picId number Picture ID
---@field img1v1Url string URL

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
    return "/artist/sublist"
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

function M:parse_response(response)
    return response:json()
end

return M