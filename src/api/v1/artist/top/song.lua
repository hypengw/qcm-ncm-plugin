local M = {}
M.__index = M

function M.new(id, top, work_type, order)
    local self = setmetatable({}, M)
    self.id = id
    self.top = top
    self.work_type = work_type
    self.order = order
    return self
end

function M:path()
    return "/v1/artist/top/song"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {
        id = self.id,
        top = self.top,
        work_type = self.work_type,
        order = self.order,
    }
end

function M:body()
    return {}
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
