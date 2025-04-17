---@class AndroidVersionResponse
---@field cdn string[] CDN URL list
---@field postSongListen boolean Whether to post song listen event
---@field allowTencentLogin boolean Allow Tencent login
---@field officalAccountIds number[] Official account IDs
---@field baoyueMsg string VIP subscription message
---@field fingerPrintUpgraded boolean Fingerprint upgrade status
---@field privateCloudCdn string[] Private cloud CDN URLs
---@field qqSpecificBlockedTip string QQ specific blocked message
---@field weixinSpecificBlockedTip string WeChat specific blocked message
---@field version string App version
---@field needToNofifyToDownload boolean Download notification flag
---@field customerServicePhone string Customer service phone number
---@field neteaseDomain string[] Netease domain list
---@field updateContent string Update content description
---@field unicomRingAvailable string Unicom ring availability
---@field canHackWXAndroid boolean WeChat Android hack capability
---@field unicomAvailable boolean Unicom service availability
---@field ignoreAudioFocusChange table<string, number> Audio focus change ignore list
---@field canHackQQAndroid boolean QQ Android hack capability
---@field scanBlackList string[] Scan blacklist
---@field sportsFMIconSpin boolean Sports FM icon spin state
---@field privateCloudMusicShareAllowed boolean Private cloud music share permission
---@field canAppendUrlAndroid boolean Android URL append capability
---@field code number Response code
---@field mustScanList string[] Must scan list
---@field id3Limit number ID3 limit
---@field forceUpdate boolean Force update flag

local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/android/version"
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

---@return AndroidVersionResponse
function M:parse_response(response)
    return response:json()
end

return M
