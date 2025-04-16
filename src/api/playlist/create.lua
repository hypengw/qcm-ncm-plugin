local M = {}
M.__index = M

function M.new(name, privacy, type)
    local self = setmetatable({}, M)
    self.name = name
    self.privacy = privacy or 0  -- 0: public, 10: private
    self.type = type or "NORMAL"
    return self
end

function M:path()
    return "/playlist/create"
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
        name = self.name,
        privacy = self.privacy,
        type = self.type
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M