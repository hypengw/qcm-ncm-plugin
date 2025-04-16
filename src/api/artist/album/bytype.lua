local M = {}
M.__index = M

function M.new(id, index, limit, sort)
    local self = setmetatable({}, M)
    self.artist_id = id
    self.index = index or 0
    self.limit = limit or 25
    self.sort = sort or 'score'
    return self
end

function M:path()
    return "/album/sublist"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {
        artist_id = self.artist_id,
        index = self.index,
        limit = self.limit,
        sort = self.sort,
    }
end

function M:body()
    return {}
end

function M:parse_response(response)
    return response:json()
end

return M
