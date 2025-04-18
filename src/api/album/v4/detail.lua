local M = {}
M.__index = M

local crypto = require("crypto")

function M.new(id)
    local self = setmetatable({}, M)
    self.id = id
    -- (injectedDebuggable || isDebug) && !enablePacketEncryption
    self.e_r = true
    return self
end

function M:path()
    return "/album/v4/detail"
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
        cache_key = crypto.cacheKey({
            id = self.id,
            e_r = self.e_r,
        }),
    }
end

function M:parse_response(response)
    return response:json()
end

return M