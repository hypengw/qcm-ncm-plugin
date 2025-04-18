local M = {}
M.__index = M

---@class SongPlayerUrl
---@field ids table<number> Song IDs
---@field level string Standard|Higher|Exhigh|Lossless|Hires
---@field encodeType string Encoding type (default: 'flac')

---@class SongPlayerUrlResponse
---@field data SongPlayerUrlData[] Array of song URL data
---@field code number Response code

---@class SongPlayerUrlData
---@field fee number Fee type
---@field closedPeak number Closed peak value
---@field canExtend boolean Whether can be extended
---@field expi number Expiration time
---@field peak number Peak value
---@field flag number Flag value
---@field gain number Gain value
---@field freeTimeTrialPrivilege FreeTimeTrialPrivilege Trial privilege info
---@field payed number Payment status
---@field freeTrialPrivilege FreeTrialPrivilege Trial privilege info
---@field url string Music file URL
---@field size number File size in bytes
---@field md5 string File MD5 hash
---@field encodeType string Encoding type
---@field rightSource number Right source
---@field br number Bit rate
---@field urlSource number URL source
---@field type string File type
---@field time number Duration in milliseconds
---@field closedGain number Closed gain value
---@field sr number Sample rate
---@field musicId string Music ID
---@field level string Quality level
---@field id number Song ID
---@field code number Status code

---@class FreeTimeTrialPrivilege
---@field remainTime number Remaining trial time
---@field resConsumable boolean Resource consumable flag
---@field userConsumable boolean User consumable flag
---@field type number Privilege type

---@class FreeTrialPrivilege
---@field userConsumable boolean User consumable flag
---@field resConsumable boolean Resource consumable flag

---@param ids number | string | table<number | string>
function M.new(ids)
    local self = setmetatable({}, M)
    if ids == nil then
        error("ids is nil")
    end
    if type(ids) ~= 'table' then
        ids = { ids }
    end
    self.ids = ids
    return self
end

function M:base()
    return 'https://interface.music.163.com'
end

function M:path()
    return "/song/enhance/player/url/v1"
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
    local b = {
        ids = string.format("[%s]", table.concat(self.ids, ",")),
        level = self.level or 'exhigh',
        encodeType = self.encodeType or 'flac',
    }
    return b
end

function M:parse_response(response)
    return response:json()
end

return M


--[[
  "data": [
    {
      "fee": 1,
      "closedPeak": 0.0,
      "canExtend": false,
      "expi": 1200,
      "peak": 1.0,
      "flag": 260,
      "gain": -9.7721,
      "freeTimeTrialPrivilege": {
        "remainTime": 0,
        "resConsumable": false,
        "userConsumable": false,
        "type": 0
      },
      "payed": 1,
      "freeTrialPrivilege": {
        "userConsumable": false,
        "resConsumable": false
      },
      "url": "http://m7.music.126.net/20250419035316/3b1a3657a3f011bd0b0c86a291e044dd/ymusic/1638/7b53/26f6/4ef90b8e364ab982009a97b18d0e2535.mp3",
      "size": 8740722,
      "md5": "4ef90b8e364ab982009a97b18d0e2535",
      "encodeType": "mp3",
      "rightSource": 0,
      "br": 320000,
      "urlSource": 0,
      "type": "mp3",
      "time": 218000,
      "closedGain": 0.0,
      "sr": 44100,
      "musicId": "65128247",
      "level": "exhigh",
      "id": 28639179,
      "code": 200
    }
  ],
  "code": 200
} 
]]