local util = require('util')
local qcm = require('qcm.mod')
local M = {retry_after_auth = true}
M.__index = M

function M.new(source)
    assert(source.type == 'fromPlayAll' or source.type == 'fromPlayOne', 'invalid heart play type')
    assert(math.type(source.count) == 'integer' and source.count > 0, 'invalid heart song count')
    return setmetatable({source = {
        playlist_id = util.positive_id(source.playlist_id), song_id = util.positive_id(source.song_id),
        start_music_id = util.positive_id(source.start_music_id), type = source.type, count = source.count,
    }}, M)
end

function M:path() return '/playmode/intelligence/list' end
function M:operation() return 'POST' end
function M:crypto() return 'weapi' end
function M:query() return {} end

function M:body()
    local source = self.source
    return {playlistId = source.playlist_id, songId = source.song_id, type = source.type,
        startMusicId = source.start_music_id, count = tostring(source.count)}
end

function M:parse_response(response)
    local result = response:json()
    if result.code == 200 then
        local records = {}
        for _, item in ipairs(util.array(result.data)) do
            assert(type(item) == 'table', 'invalid heart recommendation')
            local id = util.positive_id(item.id)
            local song, alg, recommended = item.songInfo, item.alg, item.recommended
            if song == qcm.null then song = nil end
            if alg == qcm.null then alg = nil end
            if recommended == nil or recommended == qcm.null then recommended = false end
            assert(song == nil or (type(song) == 'table' and util.positive_id(song.id) == id), 'invalid heart song detail')
            assert(alg == nil or type(alg) == 'string', 'invalid heart recommendation algorithm')
            assert(type(recommended) == 'boolean', 'invalid heart recommendation flag')
            records[#records + 1] = {native_id = id, song = song, alg = alg, recommended = recommended}
        end
        result.recommendations = records
    end
    return result
end

return M
