local M = {}
M.__index = M

function M.new(ids)
    local self = setmetatable({}, M)
    self.ids = ids
    return self
end

function M:path()
    return "/playlist/remove"
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
        ids = string.format("[%s]", table.concat(self.ids, ","))
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M