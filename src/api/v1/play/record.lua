local M = {}
M.__index = M

function M.new(id, type)
    local self = setmetatable({}, M)
    self.id = id
    self.type = type
    return self
end

function M:path()
    return "/v1/play/record"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {
        uid = self.id,
        type = self.type,
    }
end

function M:body()
    return {}
end

function M:parse_response(response)
    return response:json()
end

return M
