local QrcodeUnikey = {}
QrcodeUnikey.__index = QrcodeUnikey

function QrcodeUnikey.new()
    local self = setmetatable({}, QrcodeUnikey)
    return self
end

function QrcodeUnikey:path()
    return "/login/qrcode/unikey"
end

function QrcodeUnikey:operation()
    return "POST"
end

function QrcodeUnikey:crypto()
    return "weapi"
end

function QrcodeUnikey:query()
    return {}
end

function QrcodeUnikey:body()
    return {
        type = "1"
    }
end

function QrcodeUnikey:parse_response(response)
    local data = response:json()
    return {
        code = data.code,
        unikey = data.unikey,
        qrurl = string.format("https://music.163.com/login?codekey=%s", data.unikey)
    }
end

return QrcodeUnikey