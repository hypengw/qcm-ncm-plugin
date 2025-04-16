local M = {}
M.__index = M

function M.new(id)
    local self = setmetatable({}, M)
    self.id = id
    return self
end

function M:path()
    return "/v1/user/detail/" .. self.id
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

---@class VillageInfo
---@field imageUrl string Village image URL
---@field targetUrl string Target URL for the village
---@field title string Village title

---@class UserPoint
---@field userId number User ID
---@field balance number Point balance
---@field updateTime number Last update timestamp
---@field version number Point version
---@field status number Point status

---@class UserProfile
---@field userId number User ID
---@field nickname string User nickname
---@field avatarUrl string Avatar URL
---@field backgroundUrl string Profile background URL
---@field signature string User signature
---@field followeds number Number of followers
---@field follows number Number of following
---@field eventCount number Number of events
---@field playlistCount number Number of playlists

---@class UserBinding
---@field bindingTime number Binding timestamp
---@field expired boolean Whether binding is expired
---@field expiresIn number Time until expiration
---@field id number Binding ID
---@field refreshTime number Last refresh timestamp
---@field tokenJsonStr string Token JSON string
---@field type number Binding type
---@field url string Binding URL
---@field userId number User ID

---@class UserDetailResponse
---@field level number User level
---@field profileVillageInfo VillageInfo Village info details
---@field recallUser boolean Whether user is recalled
---@field mobileSign boolean Mobile sign status
---@field userPoint UserPoint User point information
---@field createDays number Days since account creation
---@field createTime number Account creation timestamp
---@field profile UserProfile User profile details
---@field peopleCanSeeMyPlayRecord boolean Play record visibility
---@field newUser boolean New user status
---@field bindings UserBinding[] Account bindings array
---@field pcSign boolean PC sign status
---@field listenSongs number Number of songs listened
---@field adValid boolean Ad validity status
---@field code number Response code

---Parse the response from server
---@return UserDetailResponse
function M:parse_response(response)
    return response:json()
end

return M
