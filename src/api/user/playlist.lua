local util = require('util')
local qcm = require('qcm.mod')
local M = {retry_after_auth = true}
M.__index = M

function M.new(uid, offset, limit, includeVideo)
    local self = setmetatable({}, M)
    self.uid = uid
    self.offset = offset or 0
    self.limit = limit or 25
    self.includeVideo = includeVideo
    if self.includeVideo == nil then
        self.includeVideo = true
    end
    return self
end

function M:path()
    return "/user/playlist"
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
        uid = tostring(self.uid),
        offset = self.offset,
        limit = self.limit,
        includeVideo = self.includeVideo
    }
end

function M:parse_response(response)
    local data = response:json()
    if data.code == 200 then
        data.liked_playlist = nil
        assert(data.more == nil or type(data.more) == 'boolean', 'invalid user playlist pagination')
        data.has_more = data.more == true
        for _, playlist in ipairs(util.array(data.playlist)) do
            assert(type(playlist) == 'table', 'invalid user playlist')
            if playlist.specialType == 5 then
                local owner = playlist.userId
                if owner == nil or owner == qcm.null then
                    owner = type(playlist.creator) == 'table' and playlist.creator.userId or nil
                end
                if owner ~= nil and owner ~= qcm.null and util.positive_id(owner) == util.positive_id(self.uid) then
                    assert(data.liked_playlist == nil, 'duplicate liked playlist')
                    data.liked_playlist = {native_id = util.positive_id(playlist.id)}
                end
            end
        end
        data.next_offset = self.offset + #data.playlist
        assert(not data.has_more or data.next_offset > self.offset, 'empty user playlist page')
    end
    return data
end

return M
--[[
more
playlist
]]

--[[
subscribers	[]
subscribed	false
creator	{…}
artists	null
tracks	null
updateFrequency	null
backgroundCoverId	0
backgroundCoverUrl	null
titleImage	0
titleImageUrl	null
englishTitle	null
opRecommend	false
recommendInfo	null
subscribedCount	4
cloudTrackCount	1
userId	32953014
totalDuration	0
coverImgId	109951167805071570
privacy	0
trackUpdateTime	1678022963095
trackCount	1032
updateTime	1678018138230
commentThreadId	"A_PL_0_24381616"
coverImgUrl	"https://p1.music.126.net/a1rL4eeEnJO0F-B26zxVMw==/109951167805071571.jpg"
specialType	5
anonimous	false
createTime	1407747901072
highQuality	false
newImported	false
trackNumberUpdateTime	1678018138230
playCount	18151
adType	0
description	"描述"
tags
0	"学习"
ordered	true
status	0
name	"binaryify喜欢的音乐"
id	24381616
coverImgId_str	"109951167805071571"
sharedUsers	null
shareStatus	null
copied	false
]]--
