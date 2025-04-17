local M = {}
M.__index = M

function M.new(ids)
    local self = setmetatable({}, M)
    self.ids = ids
    return self
end

function M:path()
    return "/v3/song/detail"
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
    local t = {}
    for _, id in ipairs(self.ids) do
        table.insert(t, { id = id, v = '0' })
    end
    return t
end

function M:parse_response(response)
    return response:json()
end

return M
