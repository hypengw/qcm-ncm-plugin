local M = {}
M.__index = M

---@param id string
---@param sub boolean
---@return table
function M.new(id, sub)
    local self = setmetatable({}, M)
    self.id = id
    self.sub = sub or true
    return self
end

function M:path()
    if self.sub then
        return "/artist/sub"
    else
        return "/artist/unsub"
    end
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
        artistId = self.id,
        artistIds = { self.id, }
    }
end

function M:parse_response(response)
    return response:json()
end

return M
