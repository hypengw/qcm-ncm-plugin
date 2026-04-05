local M = {}
M.__index = M

local json = require('json')

function M.new(song_id, current_song_id, limit)
    local self = setmetatable({}, M)
    self.song_id = song_id
    self.current_song_id = current_song_id or song_id
    self.limit = limit or 3
    return self
end

function M:path()
    return "/v1/playmode/song/playlist"
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
        songId = tostring(self.song_id),
        targetSongId = tostring(self.current_song_id),
        limit = tostring(self.limit)
    }
end

function M:parse_response(response)
    return response:json()
end

return M
