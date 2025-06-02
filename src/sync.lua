local util = require('util')

local M = {}
M.__index = M


local function format_time(timestamp)
    if timestamp == nil then
        timestamp = 0
    end
    return os.date("!%Y-%m-%dT%H:%M:%S.000000000+00:00", math.floor(timestamp / 1000))
end

---@param library_id integer
local function collect_library_artists(ctx, library_id)
    local api = require('api.artist.sublist').new()
    local artist_id_map = {}
    api.limit = 100
    while true do
        local rsp = client:perform(api, 30) --[[@as ArtistSublistResponse]]

        for _, value in ipairs(rsp.data) do
            local item = value --[[@as ArtistSublistItem]]
            artist_id_map[item.id] = {
                in_library = true,
                album_ids = {}
            }
        end

        if not rsp.hasMore or api.offset > 1e6 then
            break
        end
        api.offset = api.offset + api.limit
    end
    return artist_id_map
end



---@class ArtistCollect
---@field album_ids integer[]
---@field song_ids integer[]
---@field id integer

---@return ArtistCollect
local function check_artists_collect(t, native_id)
    local ar = t[native_id]
    if ar == nil then
        t[native_id] = {
            album_ids = {},
            song_ids = {},
            id = nil,
        }
        ar = t[native_id]
    end
    return ar
end

---@param library_id integer
function M.sync_albums(client, ctx, library_id, artists_collect)
    local detail_api_t = require('api.v3.album.detail')
    local api = require('api.album.sublist').new()
    local songs = {}
    local album_id_map = {}
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

            ctx:commit_album(1)
            local api = detail_api_t.new(item.id)
            return api
        end

        local images = {}
        local dynamics = {}
        local rsps = client:perform_queue(next, 30) --[[@as table<AlbumDetailRsp>]]
        for _, rsp in ipairs(rsps) do
            local a = rsp.album --[[@as Album]]

            table.move(rsp.songs, 1, #rsp.songs, #songs + 1, songs)
            ctx:commit_song(#rsp.songs)
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
            table.insert(dynamics, {
                id         = -1,
                item_id    = -1,
                library_id = library_id,
                native_id  = a.picId_str or (a.picId and tostring(a.picId) or (a.pic and tostring(a.pic) or a.pic)),
                image_type = 'Primary',
                item_type  = 'Album',
            })
        end
        local ids = ctx:sync_albums(items)

        for i = 1, #ids do
            local album = rsps[i].album --[[@as Album]]
            album_id_map[album.id] = ids[i]
            images[i].item_id = ids[i]
            for _, v in ipairs(album.artists) do
                local artist = v --[[@as ArtistSublistItem]]
                if artist.id ~= 0 and artist.id ~= nil then
                    local ar = check_artists_collect(artists_collect, artist.id)
                    table.insert(ar.album_ids, ids[i])
                end
            end
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
            album_id = album_id_map[song.al.id],
            track_number = song.no,
            disc_number = 1,
            publish_time = format_time(song.publishTime),
            popularity = song.pop or 0,
            duration = song.dt * 1000,
        }
        table.insert(models, item)
    end
    local ids = ctx:sync_songs(models)
    models = {}
    for _, song in ipairs(songs) do
        table.insert(models, { tostring(song.id), tostring(song.al.id) })
    end
    for i = 1, #ids do
        local song = songs[i] --[[@as Song]]
        for _, v in ipairs(song.ar) do
            local artist = v --[[@as AlbumDetailArtist]]
            if artist.id ~= nil and artist.id > 0 then
                local ar = check_artists_collect(artists_collect, artist.id)
                table.insert(ar.song_ids, ids[i])
            end
        end
    end

    ctx:sync_song_album_ids(library_id, models)
end



function M.sync_artists(client, ctx, artist_collect, library_id)
    local artist_api_t = require('api.artist.head.info.get')

    local k, v = nil, nil
    local next_ = function()
        k, v = next(artist_collect, k)
        if k == nil then
            return nil
        end

        ctx:commit_artist(1)
        local api = artist_api_t.new(k)
        return api
    end

    local images = {}
    local models = {}
    local rsps = client:perform_queue(next_, 30) --[[@as table<ArtistHeadResponse>]]
    for _, v in ipairs(rsps) do
        local item = v.data.artist --[[@as ArtistHeadInfo]]
        table.insert(models, {
            id          = -1,
            library_id  = library_id,
            name        = item.name,
            native_id   = tostring(item.id),
            description = item.briefDesc or '',
            _native_id  = item.id
        })
        table.insert(images, {
            id         = -1,
            item_id    = -1,
            library_id = library_id,
            native_id  = item.avatar ~= nil and util.extract_image_id(item.avatar) or nil,
            image_type = 'Primary',
            item_type  = 'Artist',
        })
    end
    local ids = ctx:sync_artists(models)
    for i = 1, #ids do
        images[i].item_id = ids[i]
        artist_collect[models[i]._native_id].id = ids[i]
    end
    ctx:sync_images(images)

    local models = {}
    local song_models = {}
    for _, v in pairs(artist_collect) do
        if v.id ~= nil then
            for _, album_id in ipairs(v.album_ids) do
                table.insert(models, {
                    id = -1,
                    album_id = album_id,
                    artist_id = v.id,
                })
            end
            for _, song_id in ipairs(v.song_ids) do
                table.insert(song_models, {
                    id = -1,
                    song_id = song_id,
                    artist_id = v.id,
                })
            end
        end
    end
    ctx:sync_album_artist_ids(models)
    ctx:sync_song_artist_ids(song_models)
end

return M
