local M = {}
M.__index = M

function M.new(id, limit, offset, work_type, order)
    local self = setmetatable({}, M)
    -- id=%d&limit=%d&offset=%d&private_cloud=true&work_type=%d&order=%s
    self.id = id
    self.limit = limit
    self.offset = offset
    self.private_cloud = true
    self.work_type = work_type == nil and 1 or work_type
    -- order = "hot" or "time"
    self.order = order == nil and "hot" or order
    return self
end

function M:path()
    return "/v1/artist/songs"
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
        limit = self.limit,
        offset = self.offset,
        private_cloud = self.private_cloud,
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
