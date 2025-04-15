local provider = {}
local Client = require('client')

local inner = qcm.inner
local ssl = qcm.crypto
local client = Client.new(inner:device_id())

function provider.save()
    return ""
end

function provider.load(data)
end

function provider.check()
end

function provider.qr()
    local Api = require('api.qrcode_unikey')
    local api = Api.new()
    local res = client:perform(api, 30)
    return {
        key = res.unikey,
        url = res.qrurl
    }
end

function provider.login(auth_info)
    local m = auth_info.method
    local api

    print("---------------------")
    if m.type == "Email" then
        local Api = require('api.login')
        local pw = ssl.digest("md5", m.pw)
        api = Api.new(m.username, pw)
    elseif m.type == "Qr" then
        local Api = require('api.qrcode_login')
        api = Api.new(m.key)
    else
        error("Unsupported auth method")
    end
    local res = client:perform(api, 30)
    print(res.code, res.message)
    if res.code == 200 or res.code == 803 then
        return {
            type = "Ok",
        }
    elseif res.code == 800 then
        return {
            type = "QrExpired",
        }
    elseif res.code == 801 then
        return {
            type = "QrWaitScan",
        }
    elseif res.code == 802 then
        return {
            type = "QrWaitComform",
            message = {
                message = res.message,
                name = res.nickname,
                avatar_url = res.avatarUrl
            }
        }
    else
        if res.message == nil then
            res.message = ""
        end

        return {
            type = "Failed",
            message = {
                message = res.message
            }
        }
    end
end

function provider.sync()
end

function provider.image(item_id, image_type)
end

function provider.audio(item_id)
end

return provider
