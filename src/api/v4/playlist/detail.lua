local M = {}
M.__index = M

function M.new(id)
    local self = setmetatable({}, M)
    self.id = id
    return self
end

function M:path()
    return "/playlist/v4/detail"
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
        id = self.id,
        t = 0,
        n = 10000,
        s = 5,
        -- shareUserId=%d
        -- sharedInvitationId=%s
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
