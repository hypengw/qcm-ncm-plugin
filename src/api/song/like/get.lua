local M = {}
M.__index = M

function M.new(id)
    local self = setmetatable({}, M)
    self.uid = id
    return self
end

function M:path()
    return "/song/like/get"
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
        uid = self.uid
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
