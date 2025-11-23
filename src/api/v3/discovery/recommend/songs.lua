local M = {}
M.__index = M

function M.new(ids)
    local self = setmetatable({}, M)
    self.ispush = false
    return self
end

function M:path()
    return "/v3/discovery/recommend/songs"
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
        ispush = self.ispush
    }
end

function M:parse_response(response)
    return response:json()
end

return M
