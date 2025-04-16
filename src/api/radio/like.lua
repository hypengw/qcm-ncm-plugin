local M = {}
M.__index = M

function M.new(track_id, like, alg, time)
    local self = setmetatable({}, M)
    self.track_id = track_id
    self.like = like
    self.alg = alg or "itembased"
    self.time = time or 3
    return self
end

function M:path()
    return "/radio/like"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "eapi"
end

function M:query()
    return {}
end

function M:body()
    return {
        trackId = self.track_id,
        like = self.like,
        alg = self.alg,
        time = self.time
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M