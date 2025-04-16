local M = {}
M.__index = M

function M.new(id, offset, limit, sort)
    local self = setmetatable({}, M)
    self.id = id
    self.offset = offset or 0
    self.limit = limit or 25
    self.sort = sort or 'score'
    return self
end

function M:path()
    return "/artist/albums/" .. self.id
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {
        offset = self.offset,
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
