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

local function format_time(timestamp)
    if timestamp == nil then
        timestamp = 0
    end
    return os.date("!%Y-%m-%dT%H:%M:%S.000000000+00:00", math.floor(timestamp / 1000))
end

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
    local Api = require('api.login.qrcode.unikey')
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
        local Api = require('api.login.qrcode.client.login')
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
    local api = require('api.nuser.account').new()
    local rsp = client:perform(api, 30) --[[@as NuserAccountRsp]]

    local ids = ctx:sync_libraries({ {
        library_id = -1,
        name = rsp.profile.nickname,
        provider_id = inner.id,
        native_id = tostring(rsp.profile.userId),
    }, {
        library_id = -1,
        name = "netease external",
        provider_id = inner.id,
        native_id = "external",
    } })

    if (#ids ~= 2) then
        error("library sync failed")
    end

    local library_id = ids[1]

    local api = require('api.album.sublist').new()
    while true do
        local rsp = client:perform(api, 30) --[[@as AlbumSublistRsp]]

        local len = #rsp.data and rsp.data or 0
        if len == 0 then
            break
        end


        local items = {}
        local next = function()
            local item = table.remove(rsp.data, 1)
            if item == nil then
                return nil
            end

            local api = require('api.album.v3.detail').new(item.id)
            return api
        end
        local rsps = client:perform_queue(next, 30) --[[@as table<AlbumDetailRsp>]]
        for _, rsp in ipairs(rsps) do
            local a = rsp.album
            table.insert(items, {
                id           = -1,
                native_id    = tostring(a.id),
                library_id   = library_id,
                name         = a.name or '',
                publish_time = format_time(a.publishTime),
                track_count  = a.size,
                description  = a.description or '',
                company      = a.company or ''
            })
        end
        ctx:sync_albums(items)

        if not rsp.hasMore or api.offset > 1e6 then
            break
        end
        api.offset = api.offset + api.limit
    end
end

function provider.image(item_id, image_type)
end

function provider.audio(item_id)
end

return provider
