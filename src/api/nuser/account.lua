local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/nuser/account/get"
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

---@class MProfile
---@field userId integer
---@field userType number
---@field nickname string
---@field avatarUrl string
---@field backgroundUrl string
---@field createTime number
---@field accountType number
---@field authority number
---@field gender number
---@field accountStatus number
---@field description string?
---@field detailDescription string?
---@field defaultAvatar boolean
---@field vipType number

---@class NuserAccountRsp
---@field code number
---@field profile MProfile?

---@return NuserAccountRsp
function M:parse_response(response)
    return response:json()
end

return M
