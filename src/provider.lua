local provider = {}
local Client = require('client')
local json = require('json')
local crypto = require('crypto')

local qcm = require('qcm.mod')
local inner = qcm.inner
local ssl = qcm.crypto
local get_http_client = qcm.get_http_client
local session = require('session').new()
local client = Client.new(inner:device_id(), session)
local load_error
local ItemType = qcm.enum.ItemType
local SyncState = qcm.enum.SyncState
local DAILY_MIX_NATIVE_ID = "recommend/daily"
local roaming = require('roaming')
local Radio = require('radio')
local CategoryRadio = require('category_radio')

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
    if load_error then error(load_error, 0) end
    local saved = {user_id = status.user_id, nickname = status.nickname, avatar_url = status.avatar_url, session = session.state}
    return json.encode(saved)
end

function provider.load(data)
    load_error = 'invalid saved NCM authentication'
    local s = data == '' and {} or json.decode(data)
    assert(type(s) == 'table', load_error)
    assert(s.user_id == nil or math.type(s.user_id) == 'integer', load_error)
    assert(s.nickname == nil or type(s.nickname) == 'string', load_error)
    assert(s.avatar_url == nil or type(s.avatar_url) == 'string', load_error)
    session:load(s.session, s.user_id ~= nil and s.user_id ~= -1)
    status.user_id = s.user_id or -1
    status.nickname = s.nickname or ''
    status.avatar_url = s.avatar_url or ''
    load_error = nil
end

function provider.resource_scope()
    if load_error then error(load_error, 0) end
    return session:scope()
end

function provider.check()
    if load_error then error(load_error, 0) end
    client:perform(require('api.nuser.account').new(), 30)
end

function provider.qr()
    session:begin()
    load_error = nil
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
        session:begin()
        load_error = nil
        local Api = require('api.login')
        local pw = ssl.hex.encode_low(ssl.digest("md5", m.pw))
        api = Api.new(m.email or m.username, pw)
    elseif m.type == "Qr" then
        local Api = require('api.login.qrcode.client.login')
        api = Api.new(m.key)
    else
        error("Unsupported auth method")
    end
    local res = client:perform(api, 30)
    if res.code == 200 or res.code == 803 then
        local api         = require('api.nuser.account').new()
        api.auth_request = true
        local rsp         = client:perform(api, 30) --[[@as NuserAccountRsp]]
        session:authenticated()
        status.user_id    = rsp.profile.userId
        status.nickname   = rsp.profile.nickname
        status.avatar_url = rsp.profile.avatarUrl

        session:save()
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
    local sync = require("sync").new(client, status.user_id, inner.id)
    sync:sync_sub_songs(ctx, library_id, user_id, artist_collect)
    sync:sync_sub_albums(ctx, library_id, artist_collect)
    sync:sync_artists(ctx, artist_collect, library_id)
    sync:sync_daily_mix(ctx, library_id, DAILY_MIX_NATIVE_ID)
    sync:sync_mixes(ctx, library_id)
    local radios = {
        { native_id = "roaming/fm", name = "私人漫游", description = "沿着目前喜好继续聆听" },
        { native_id = "roaming/similar", name = "相似歌曲", description = "从喜欢的歌曲发现相似推荐" },
    }
    for _, entry in ipairs(CategoryRadio.entries()) do radios[#radios + 1] = entry end
    ctx:sync_radio_queues(radios)
end

function provider.sync_item(ctx, item)
    local sync = require("sync").new(client, status.user_id, inner.id)
    if item.type == 'Mix' then
        if item.native_id == DAILY_MIX_NATIVE_ID then
            sync:sync_daily_mix(ctx, item.library_id, item.native_id)
        else
            sync:sync_mix(ctx, item)
        end
    end
end

function provider.queue_configuration(ctx, native_id)
    return roaming.configuration(native_id)
end

function provider.queue_definition(ctx, native_id)
    return Radio.definition(native_id)
end

function provider.open_queue(ctx, native_id, request)
    return Radio.new(client, status.user_id, inner.id):open(ctx, native_id, request)
end

function provider.next_queue(ctx, native_id, request)
    return Radio.new(client, status.user_id, inner.id):next(ctx, native_id, request)
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

function provider.prepare_image(item_id, pic_id, pic_type)
    if pic_id == nil then
        return nil
    end
    local client = get_http_client()
    local url = string.format("https://p1.music.126.net/%s/%s.jpg?param=400x400", crypto.encrypt_id(pic_id), pic_id)
    return client:get(url):stream {headers_timeout_ms=30000}
end

function provider.prepare_audio(item_id)
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
    return client:get(url):stream {headers_timeout_ms=30000}
end

function provider.image(item_id, pic_id, pic_type)
    local request = provider.prepare_image(item_id, pic_id, pic_type)
    if request then return request:send() end
end

function provider.audio(item_id, headers)
    local request = provider.prepare_audio(item_id)
    if request then return request:headers(headers or {}):send() end
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
