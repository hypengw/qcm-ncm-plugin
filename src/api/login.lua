local M = {auth_request = true}
M.__index = M

function M.new(username, password_md5)
    local self = setmetatable({}, M)
    self.username = username
    self.password_md5 = password_md5
    self.no_error_check = true
    return self
end

function M:path()
    return "/login"
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
        username = self.username,
        password = self.password_md5,
        rememberLogin = "true"
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
