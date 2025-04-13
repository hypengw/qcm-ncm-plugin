local Login = {}
Login.__index = Login

function Login.new(username, password_md5)
    local self = setmetatable({}, Login)
    self.username = username
    self.password_md5 = password_md5
    return self
end

function Login:path()
    return "/login"
end

function Login:operation()
    return "POST"
end

function Login:crypto()
    return "weapi"
end

function Login:query()
    return {}
end

function Login:body()
    return {
        username = self.username,
        password = self.password_md5,
        rememberLogin = "true"
    }
end

function Login:parse_response(response)
    local status = response:status()
    local data = response:text()
    return {
        code = status,
        text = data
    }
end

return Login