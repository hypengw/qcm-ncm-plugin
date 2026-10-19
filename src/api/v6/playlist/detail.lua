local util = require('util')
local qcm = require('qcm.mod')
local SongDetail = require('api.v3.song.detail')
local M = {retry_after_auth = true}
M.__index = M

function M.new(id, limit)
    local self = setmetatable({}, M)
    self.id = id
    self.limit = limit or 10000
    assert(math.type(self.limit) == 'integer' and self.limit > 0 and self.limit <= 10000, 'invalid playlist detail limit')
    return self
end

function M:path()
    return "/v6/playlist/detail"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {}
end

function M:body()
    return {
        id = self.id,
        t = 0,
        n = self.limit,
        s = 5,
        -- shareUserId=%d
        -- sharedInvitationId=%s
    }
end

function M:parse_response(response)
    local data = response:json()
    if data.code == 200 then
        local playlist = data.playlist
        assert(type(playlist) == 'table' and util.positive_id(playlist.id) == util.positive_id(self.id), 'invalid playlist detail')
        data.track_ids = nil
        if playlist.trackIds ~= nil and playlist.trackIds ~= qcm.null then
            data.track_ids = {}
            for _, track in ipairs(util.array(playlist.trackIds)) do
                assert(type(track) == 'table', 'invalid playlist track')
                data.track_ids[#data.track_ids + 1] = util.positive_id(track.id)
            end
        end
        data.songs_by_id = SongDetail.index(playlist.tracks ~= qcm.null and playlist.tracks or {})
    end
    return data
end

return M
