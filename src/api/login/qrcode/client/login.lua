local QrcodeLogin = {}
QrcodeLogin.__index = QrcodeLogin

function QrcodeLogin.new(key)
    local self = setmetatable({}, QrcodeLogin)
    self.key = key
    self.no_error_check = true
    return self
end

function QrcodeLogin:path()
    return "/login/qrcode/client/login"
end

function QrcodeLogin:operation()
    return "POST"
end

function QrcodeLogin:crypto()
    return "weapi"
end

function QrcodeLogin:query()
    return {}
end

function QrcodeLogin:body()
    return {
        type = "1",
        key = self.key
    }
end

---@class QrcodeLoginRsp
---@field code number
---@field message string
---@field nickname string
---@field avatarUrl string

---@return QrcodeLoginRsp
function QrcodeLogin:parse_response(response)
    local data = response:json()
    return data
end

return QrcodeLogin
