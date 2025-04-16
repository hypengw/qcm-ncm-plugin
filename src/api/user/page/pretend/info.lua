local M = {}
M.__index = M

---@class UserBackgroundInfo
---@field userId string
---@field validType string
---@field backgroundValue string
---@field vip boolean
---@field initedTypeList table
---@field showEntrance boolean
---@field curHeads table

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/user/pretend/page/info"
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

---@return UserBackgroundInfo
function M:parse_response(response)
    return response:json()
end

return M
