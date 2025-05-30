local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    return self
end

--[[
ydDeviceToken: "NT9Wq/rxZ4JBEgRRBVPDOSASJ7TwF2pV"
ydDeviceType: "WebOnline"
]]
function M:path()
    return "/middle/device-info/web/get"
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

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
