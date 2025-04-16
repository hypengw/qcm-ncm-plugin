local M = {}
M.__index = M

-- 会员挂件

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/pendant/user/get"
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
    return {}
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
