local M = {}
M.__index = M

function M.new(cat, limit)
    local self = setmetatable({}, M)
    self.cat = cat or "10001"
    self.limit = limit or 100
    return self
end

function M:path()
    return "/playlist/category/list"
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
        cat = self.cat,
        limit = self.limit,
    }
end

function M:parse_response(response)
    return response:json()
end

return M
