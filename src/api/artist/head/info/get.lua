
local M = {}
M.__index = M

---@class ArtistHeadInfo
---@field name string Artist name
---@field albumSize integer Number of albums
---@field id integer Artist ID
---@field alias string[] Alias names
---@field briefDesc string Artist description
---@field transNames string[] Translated names
---@field mvSize integer Number of music videos
---@field cover string Cover image URL
---@field identities string[] Artist identities
---@field musicSize integer Number of music tracks
---@field avatar string Avatar image URL

---@class ExpertIdentity
---@field expertIdentiyCount integer Count of expert identity
---@field expertIdentiyId integer Expert identity ID
---@field expertIdentiyName string Expert identity name

---@class ArtistHeadData
---@field videoCount integer Number of videos
---@field preferShow integer Prefer show value
---@field showPriMsg boolean Show private message flag
---@field artist ArtistHeadInfo Artist information
---@field secondaryExpertIdentiy ExpertIdentity[] Secondary expert identities


---@class ArtistHeadResponse
---@field data ArtistHeadData
---@field code integer
---@field message string

---@param id integer
function M.new(id)
    local self = setmetatable({}, M)
    self.id = id
    return self
end

function M:path()
    return "/artist/head/info/get"
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
        id = self.id
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
