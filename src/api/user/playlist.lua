local M = {}
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