local M = {}
M.__index = M

---@param op integer 0 -> add, 1 -> del
---@param trackIds [integer]
function M.new(id, op, trackIds)
    local self = setmetatable({}, M)
    self.op = op
    self.pid = id
    self.trackIds = trackIds
    self.imme = true
    return self
end

function M:path()
    return "/playlist/manipulate/tracks"
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
        name = self.name,
        privacy = self.privacy,
        type = self.type
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M