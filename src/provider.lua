local provider = {}
local Client = require('client')
local json = require('json')
local crypto = require('crypto')

local qcm = require('qcm.mod')
local inner = qcm.inner
local ssl = qcm.crypto
local get_http_client = qcm.get_http_client
local client = Client.new(inner:device_id())
local ItemType = qcm.enum.ItemType
local SyncState = qcm.enum.SyncState

local status = {
    user_id = -1,
    nickname = '',
    avatar_url = ''
}

table.filter = function(t, filterIter)
    local out = {}

    for k, v in pairs(t) do
        if filterIter(v, k, t) then out[k] = v end
    end

    return out
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
        local api         = require('api.nuser.account').new()
        local rsp         = client:perform(api, 30) --[[@as NuserAccountRsp]]
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

---@param ctx QcmSyncContext
function provider.sync(ctx)
    local api = require('api.nuser.account').new()
    local rsp = client:perform(api, 30) --[[@as NuserAccountRsp]]

    if rsp.profile == nil then
        return SyncState.NotAuth
    end

    local user_id = rsp.profile.userId;

    local ids = ctx:sync_libraries({ {
        library_id = -1,
        name = rsp.profile.nickname,
        provider_id = inner.id,
        native_id = tostring(user_id),
    }, })

    if (#ids ~= 1) then
        return SyncState.NotAuth
    end

    local library_id = ids[1]
    local artist_collect = {}
    local sync = require("sync").new(client)
    --sync:sync_sub_songs(ctx, library_id, user_id, artist_collect)
    sync:sync_sub_albums(ctx, library_id, artist_collect)
    sync:sync_artists(ctx, artist_collect, library_id)
end

---@param ctx any
---@param item_id string
---@param item_type integer
---@param value boolean
function provider.favorite(ctx, item_id, item_type, value)
    if (item_type == ItemType.Album) then
        local api = require("api.album.sub").new(item_id, value)
        local rsp = client:perform(api, 30)
        return true
    elseif (item_type == ItemType.Song) then
        local api = require("api.radio.like").new(item_id, value)
        local rsp = client:perform(api, 30)
        return true
    elseif (item_type == ItemType.Artist) then
        local api = require("api.artist.sub").new(item_id, value)
        local rsp = client:perform(api, 30)
        return true
    end
    return false
end

function provider.image(item_id, pic_id, pic_type)
    if pic_id == nil then
        return nil
    end
    local client = get_http_client()
    local url = string.format("https://p1.music.126.net/%s/%s.jpg?param=400x400", crypto.encrypt_id(pic_id), pic_id)
    local rsp = client:get(url):send()
    return rsp
end

function provider.audio(item_id, headers)
    local api = require('api.song.enhance.player.url.v1').new(item_id)
    local rsp = client:perform(api, 30) --[[@as SongPlayerUrlResponse]]

    if rsp.data == nil or #rsp.data == 0 then
        return nil
    end
    local url = rsp.data[1].url
    if url == nil then
        return nil
    end
    local client = get_http_client()
    if headers == nil then
        headers = {}
    end
    return client:get(url):headers(headers):send()
end

function provider.subtitle(item_id)
    local api = require('api.song.lyric').new(item_id)
    local rsp = client:perform(api, 30) --[[@as SongLyricResponse]]

    if rsp.lrc == nil or rsp.lrc.lyric == nil then
        return nil
    end
    return rsp.lrc.lyric
end

return provider
