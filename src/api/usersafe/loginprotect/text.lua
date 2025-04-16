local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/usersafe/loginprotect/text/get"
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

--[[
{
  "code": 200,
  "data": "登录保护",
  "message": "SUCCESS"
}
]]

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
