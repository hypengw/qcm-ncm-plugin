local provider = {}
local Client = require('client')
local json = require('json')
local crypto = require('crypto')

local inner = qcm.inner
local ssl = qcm.crypto
local get_http_client = qcm.get_http_client;
local client = Client.new(inner:device_id())

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

---@param library_id integer
local function sync_albums(ctx, library_id)
    local api = require('api.album.sublist').new()


    local songs = {}
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

        local images = {}
        local rsps = client:perform_queue(next, 30) --[[@as table<AlbumDetailRsp>]]
        for _, rsp in ipairs(rsps) do
            local a = rsp.album
            for i = 1, #rsp.songs do
                rsp.songs[i].track_number = i
            end
            table.move(rsp.songs, 1, #rsp.songs, #songs + 1, songs)
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
            table.insert(images, {
                id         = -1,
                item_id    = -1,
                library_id = library_id,
                native_id  = a.picId_str or (a.picId and tostring(a.picId) or (a.pic and tostring(a.pic) or a.pic)),
                image_type = 'Primary',
                item_type  = 'Album',
            })
        end
        local ids = ctx:sync_albums(items)
        ctx:commit_album(#items)

        for i = 1, #images do
            images[i].item_id = ids[i]
        end
        ctx:sync_images(table.filter(images, function(v)
            return v.native_id ~= nil
        end))


        if not rsp.hasMore or api.offset > 1e6 then
            break
        end
        api.offset = api.offset + api.limit
    end

    local models = {}
    for _, value in ipairs(songs) do
        local song = value --[[@as Song]]
        local item = {
            id = -1,
            library_id = library_id,
            name = song.name,
            native_id = tostring(song.id),
            album_id = nil,
            track_number = song.track_number,
            disc_number = 1,
            publish_time = format_time(song.publishTime),
            popularity = song.pop or 0,
            duration = song.dt * 1000,
        }
        table.insert(models, item)
    end
    ctx:sync_songs(models)
    models = {}
    for _, song in ipairs(songs) do
        table.insert(models, { tostring(song.id), tostring(song.al.id) })
    end
    ctx:sync_song_album_ids(library_id, models)
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
    sync_albums(ctx, library_id)
end

function provider.image(item_id, pic_id, pic_type)
    if pic_id == nil then
        return nil
    end
    local client = get_http_client()
    local url = string.format("https://p1.music.126.net/%s/%s.jpg", crypto.encrypt_id(pic_id), pic_id)
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
    local client = get_http_client()
    if headers == nil then
        headers = {}
    end
    return client:get(url):headers(headers):send()
end

return provider
