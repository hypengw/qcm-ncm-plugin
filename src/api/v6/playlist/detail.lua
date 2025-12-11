local M = {}
M.__index = M

function M.new(id)
    local self = setmetatable({}, M)
    self.id = id
    return self
end

function M:path()
    return "/v6/playlist/detail"
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
        id = self.id,
        n = 1000000,
        s = 10,
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
