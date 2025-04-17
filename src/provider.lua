local provider = {}
local Client = require('client')
local json = require('json')

local inner = qcm.inner
local ssl = qcm.crypto
local client = Client.new(inner:device_id())

local status = {
    user_id = -1,
    nickname = '',
    avatar_url = ''
}

function provider.save()
    return json.encode(status)
end

function provider.load(data)
    local s = json.decode(data)
    status.user_id = s.user_id
    status.nickname = s.nickname
    status.avatar_url = s.avatar_url
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
    if res.code == 200 or res.code == 803 then
        local api         = require('api.v1.user.detail').new()
        local rsp         = client:perform(api, 30) --[[@as UserDetailResponse]]
        status.user_id    = rsp.profile.userId
        status.nickname   = rsp.profile.nickname
        status.avatar_url = rsp.profile.avatarUrl

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

function provider.sync(ctx)
    --local api = require('api.album_sublist').new()
    --qcm.debug(client:perform(api, 30))
    local api = require('api.v1.user.info').new()
    local rsp = client:perform(api, 30) --[[@as MUserInfoRsp]]

    ctx:sync_library({ {
        library_id = -1,
        name = "",
        provider_id = inner.id,
        native_id = tostring(rsp.userPoint.userId),
    }, {
        library_id = -1,
        name = "netease external",
        provider_id = inner.id,
        native_id = "external",
    } })

    local api = require('api.user.setting').new()
    local rsp = client:perform(api, 30)
    qcm.debug(rsp)

    local api = require('api.cdns').new()
    local rsp = client:perform(api, 30)
    qcm.debug(rsp)

    local api = require('api.middle.device-info.web').new()
    local rsp = client:perform(api, 30)
    qcm.debug(rsp)
end

function provider.image(item_id, image_type)
end

function provider.audio(item_id)
end

return provider
