local M = {}
M.__index = M

function M.new(id)
    local self = setmetatable({}, M)
    self.id = id
    return self
end

function M:path()
    return "/album/detail/dynamic"
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
        id = self.id
    }
end

function M:parse_response(response)
    return response:json()
end

return M