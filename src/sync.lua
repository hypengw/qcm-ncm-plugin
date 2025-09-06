local util = require('util')
local qcm = require('qcm.mod')
local fun = require('third.fun')

---@class SyncOperator
---@field client Client
---@field album_id_map table<integer, integer>
---@field song_id_map table<integer, integer>
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


---@param song any
---@param library_id integer
---@param album_id? integer
local function song_model_from_detail(song, library_id, album_id)
    ---@type QcmSongModel
    local item = {
        item = {
            id = -1,
            library_id = library_id,
            native_id = tostring(song.id),
            type = 'Song',
        },
        id = -1,
        name = song.name,
        album_id = album_id or -1,
        _album_native_id = tostring(song.al.id),
        track_number = song.no,
        disc_number = 1,
        publish_time = song.publishTime,
        popularity = song.pop or 0,
        duration = song.dt * 1000,
    }
    return item
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

local function get_pic_id(a)
    return a.picId_str or (a.picId and tostring(a.picId) or (a.pic and tostring(a.pic) or a.pic))
end

---@param dst table
---@param src table
local function table_merge(dst, src)
    for k, v in pairs(src) do
        dst[k] = v
    end
    return dst
end

local function album_type_convert(type_str)
    -- 专辑 精选集 Single EP 未知
    if type_str == '专辑' then
        return 'Album'
    elseif type_str == '精选集' then
        return 'Compilation';
    elseif type_str == 'Single' then
        return 'Single';
    elseif type_str == 'EP' then
        return 'EP';
        -- elseif type_str == '原声' then
        --     return 'Soundtrack';
        -- elseif type_str == '现场' then
        --     return 'Live';
    else
        return 'Unknown';
    end
end

---@param client Client
function M.new(client)
    local self = setmetatable({}, M)
    self.client = client
    self.album_id_map = {}
    self.song_id_map = {}
    return self
end

---@param ctx QcmSyncContext
---@param library_id integer
---@param user_id integer
---@param artists_collect table<integer, ArtistCollect>
function M:sync_sub_songs(ctx, library_id, user_id, artists_collect)
    local api = require('api.song.like.get').new(user_id)
    local rsp = self.client:perform(api, 30) --[[@as GetSongLikeRsp]]
    local api = require('api.v3.song.detail').new(rsp.ids)
    local rsp = self.client:perform(api, 30)
    local albums = {}
    local songs = {}
    local images = {}

    for _, el in ipairs(rsp.songs) do
        local a = el.al
        albums[a.id] = {
            item = {
                id = -1,
                native_id = tostring(a.id),
                library_id = library_id,
                type = 'Album'
            },
            dynamic = {
                id = -1,
                favorite_at = nil,
                is_external = true
            } --[[@as QcmDynamicModel]],
            id = -1,
            name = a.name,
            disc_count = 1,
            track_count = 0,
        }
        table.insert(images, {
            id         = -1,
            item_id    = -1,
            native_id  = get_pic_id(a),
            image_type = 'Primary',
            _native_id = tostring(a.id),
        } --[[@as QcmImageModel]])

        local song = song_model_from_detail(el, library_id)
        song['dynamic'] = {
            id = -1,
            favorite_at = 0,
            is_external = false
        } --[[@as QcmDynamicModel]]

        table.insert(songs, song)
        ctx:commit_song(1)
        ctx:commit_album(1)
    end

    do
        local album_list = {}
        local item_list = {}
        local dynamic_list = {}
        for _, v in pairs(albums) do
            table.insert(item_list, v.item)
            table.insert(album_list, v)
            table.insert(dynamic_list, v.dynamic)
        end
        local ids = ctx:allocate_items(item_list)
        for i, id in ipairs(ids) do
            album_list[i].id = id
            dynamic_list[i].id = id
            local native_id = item_list[i].native_id
            self.album_id_map[native_id] = id
        end
        ctx:sync_albums(album_list)
        ctx:sync_dynamics(dynamic_list)
    end

    for i, el in ipairs(images) do
        local album_id = self.album_id_map[el._native_id]
        el.item_id = album_id
        songs[i].album_id = album_id
    end

    ctx:sync_images(images)

    do
        local items = {}
        local dynamics = {}
        for _, v in ipairs(songs) do
            table.insert(items, v.item)
            table.insert(dynamics, v.dynamic)
        end
        local ids = ctx:allocate_items(items)
        for i, id in ipairs(ids) do
            songs[i].id = id
            dynamics[i].id = id
        end
        ctx:sync_songs(songs)
        ctx:sync_dynamics(dynamics)
    end
end

---@param ctx QcmSyncContext
---@param library_id integer
---@param artists_collect table<integer, ArtistCollect>
---@param override table|nil
function M:sync_album_from_ids(ctx, library_id, ids, artists_collect, override)
    local detail_api_t = require('api.v3.album.detail')
    local albums = {}
    local next = function()
        local id = table.remove(ids, 1)
        if id == nil then
            return nil
        end

        ctx:commit_album(1)
        local api = detail_api_t.new(id)
        return api
    end


    ---@type QcmImageModel[]
    local images = {}
    ---@type QcmDynamicModel[]
    local dynamics = {}

    local songs = {}

    local rsps = self.client:perform_queue(next, 30) --[[@as table<AlbumDetailRsp>]]
    for _, rsp in ipairs(rsps) do
        local a = rsp.album --[[@as Album]]

        local disc_count = 1;
        local duration = 0;
        for i = 1, #rsp.songs do
            local s = rsp.songs[i];
            local song_cd = tonumber(s.cd)
            disc_count = math.max(disc_count, song_cd ~= nil and song_cd or 1)
            duration = duration + (s.dt or 0)
            table.insert(songs, s)
        end
        ctx:commit_song(#rsp.songs)
        local album = {
            item         = {
                id         = -1,
                library_id = library_id,
                type       = 'Album',
                native_id  = tostring(a.id),
            },
            id           = -1,
            name         = a.name or '',
            publish_time = a.publishTime,
            disc_count   = disc_count,
            track_count  = a.size,
            description  = a.description or '',
            company      = a.company or '',
            duration     = duration,
            type         = album_type_convert(a.type),
        } --[[@as QcmAlbumModel]]
        local over = (override or {})[a.id]
        if over ~= nil then
            album = table_merge(album, over)
        end
        table.insert(albums, album)
        table.insert(images, {
            id         = -1,
            item_id    = -1,
            native_id  = get_pic_id(a),
            image_type = 'Primary',
        } --[[@as QcmImageModel]])
        table.insert(dynamics, {
            id          = -1,
            favorite_at = 0,
            is_external = false,
        } --[[@as QcmDynamicModel]])
    end
    local ids = ctx:allocate_items(fun.iter(albums):map(function(v) return v.item end):totable())

    for i, id in ipairs(ids) do
        albums[i].id = id
        dynamics[i].id = id
        images[i].item_id = id
        self.album_id_map[albums[i].item.native_id] = id
        local album = rsps[i].album --[[@as Album]]
        for _, v in ipairs(album.artists) do
            local artist = v --[[@as ArtistSublistItem]]
            if artist.id ~= 0 and artist.id ~= nil then
                local ar = check_artists_collect(artists_collect, artist.id)
                table.insert(ar.album_ids, ids[i])
            end
        end
    end
    ctx:sync_albums(albums)
    ctx:sync_images(table.filter(images, function(v)
        return v.native_id ~= nil
    end))
    ctx:sync_dynamics(dynamics)

    return songs
end

---@param ctx QcmSyncContext
---@param library_id integer
---@param artists_collect table<integer, ArtistCollect>
function M:sync_sub_albums(ctx, library_id, artists_collect)
    local api = require('api.album.sublist').new()

    local dynamics = {}
    local songs = {}

    while true do
        local rsp = self.client:perform(api, 30) --[[@as AlbumSublistRsp]]

        local ids = {}

        local len = #rsp.data and rsp.data or 0
        if len == 0 then
            break
        end
        local override = {}

        for _, el in ipairs(rsp.data) do
            table.insert(ids, el.id)
            override[el.id] = {
                added_at = el.subTime
            }
        end

        local albums_songs = self:sync_album_from_ids(ctx, library_id, ids, artists_collect, override)
        table.move(albums_songs, 1, #albums_songs, #songs + 1, songs)

        for _, el in ipairs(rsp.data) do
            local native_id = tostring(el.id)
            local id = self.album_id_map[native_id]
            if id == nil then
                error("not found album: " .. native_id .. ' name: ' .. el.name)
            end
            table.insert(dynamics, {
                id = id,
                favorite_at = el.subTime,
                is_external = false
            } --[[@as QcmDynamicModel]])
        end

        if not rsp.hasMore or api.offset > 1e6 then
            break
        end
        api.offset = api.offset + api.limit
    end


    local song_dynamic_idx = #dynamics
    ---@type QcmDynamicModel[]
    local song_models = {}
    for _, value in ipairs(songs) do
        local song = value --[[@as Song]]
        local album_id = self.album_id_map[tostring(song.al.id)]
        if album_id == nil then
            print("not found album for song: " .. song.name)
        end
        ---@type QcmSongModel
        local item = {
            id = -1,
            item = {
                id = -1,
                library_id = library_id,
                type = 'Song',
                native_id = tostring(song.id),
            },
            name = song.name,
            album_id = album_id,
            track_number = song.no,
            disc_number = tonumber(song.cd) or 1,
            publish_time = song.publishTime,
            popularity = song.pop or 0,
            duration = song.dt * 1000,
        }
        table.insert(song_models, item)
        table.insert(dynamics, {
            id = -1,
            favorite_at = nil,
            is_external = false
        } --[[@as QcmDynamicModel]])
    end
    local ids = ctx:allocate_items(fun.iter(song_models):map(function(v) return v.item end):totable())
    for i, id in ipairs(ids) do
        song_models[i].id = id
        dynamics[i + song_dynamic_idx].id = id
    end
    ctx:sync_songs(song_models)
    ctx:sync_dynamics(dynamics, { exclude = { "favorite_at", } })

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
end

---@param ctx QcmSyncContext
---@param artist_collect ArtistCollect[]
---@param library_id integer
function M:sync_artists(ctx, artist_collect, library_id)
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

    ---@type QcmImageModel[]
    local images = {}
    local models = {}
    local rsps = self.client:perform_queue(next_, 30) --[[@as table<ArtistHeadResponse>]]
    for _, v in ipairs(rsps) do
        local item = v.data.artist --[[@as ArtistHeadInfo]]
        table.insert(models, {
            id          = -1,
            item        = {
                id         = -1,
                library_id = library_id,
                native_id  = tostring(item.id),
                type       = 'Artist'
            },
            name        = item.name,
            description = item.briefDesc or '',
            _native_id  = item.id
        } --[[@as QcmArtistModel]])
        table.insert(images, {
            id         = -1,
            item_id    = -1,
            native_id  = item.avatar ~= nil and util.extract_image_id(item.avatar) or nil,
            image_type = 'Primary',
        } --[[@as QcmImageModel]])
    end
    local ids = ctx:allocate_items(fun.iter(models):map(function(v) return v.item end):totable())
    for i, id in ipairs(ids) do
        models[i].id = id
        images[i].item_id = id
        artist_collect[models[i]._native_id].id = id
    end
    ctx:sync_artists(models)
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
