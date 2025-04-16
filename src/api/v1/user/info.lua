local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/v1/user/info"
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

---@class MTicketConfig
---@field content string
---@field picId string
---@field picUrl string

---@class MUserInfoRsp
---@field code number
---@field level number
---@field userPoint UserPoint
---@field mobileSign boolean
---@field pcSign boolean
---@field viptype number
---@field expiretime number
---@field backupExpireTime number
---@field ticketConfig MTicketConfig

---@return MUserInfoRsp
function M:parse_response(response)
    return response:json()
end

return M
