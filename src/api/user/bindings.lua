local M = {}
M.__index = M

---@class Binding
---@field refreshTime number
---@field tokenJsonStr string JSON string containing user info
---@field userId number
---@field bindingTime number
---@field expired boolean
---@field url string
---@field id number
---@field type number 0 for email, 1 for phone
---@field expiresIn number

---@class BindingsResponse
---@field bindings Binding[]
---@field code number

function M.new(id)
    local self = setmetatable({}, M)
    self.id = id
    return self
end

function M:path()
    return "/user/bindings/" .. self.id
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
    return {}
end

---@return BindingsResponse
function M:parse_response(response)
    return response:json()
end

return M
