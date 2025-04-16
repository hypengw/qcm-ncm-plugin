local M = {}
M.__index = M

function M.new(album_id)
    local self = setmetatable({}, M)
    self.album_id = album_id
    return self
end

function M:path()
    return "/v1/album/" .. self.album_id
end

function M:operation()
    return "GET"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {
    }
end

function M:body()
    return {
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
