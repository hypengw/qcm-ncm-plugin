local M = {}
M.__index = M

function M.new(id, name)
    local self = setmetatable({}, M)
    self.name = name
    self.id = id
    return self
end

function M:path()
    return "/playlist/update/name"
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
        id = self.id,
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
