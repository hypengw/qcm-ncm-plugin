---@class AlbumDetailRsp
---@field songs Song[] Array of songs in the album
---@field info AlbumInfo Album information
---@field code number Response code
---@field preSellSongIds number[] Array of pre-sell song IDs
---@field album Album Album details

---@class Song
---@field track_number integer | nil
---@field resourceState boolean Resource state
---@field mark number Song mark
---@field al Album Album information
---@field ar AlbumDetailArtist[] Array of artists
---@field mv number MV ID
---@field name string Song name
---@field id number Song ID
---@field dt number Duration in milliseconds
---@field sq SongQuality? Super quality information
---@field h SongQuality? High quality information
---@field m SongQuality? Medium quality information
---@field l SongQuality? Low quality information
---@field hr SongQuality? Hi-Res quality information

---@class SongQuality
---@field fid number File ID
---@field size number File size
---@field vd number Volume adjustment
---@field sr number Sample rate
---@field br number Bit rate

---@class AlbumDetailArtist
---@field alias string[] Artist aliases
---@field name string Artist name
---@field id number Artist ID
---@field tns string[] Translated names

---@class AlbumInfo
---@field threadId string Thread ID
---@field resourceType number Resource type
---@field shareCount number Share count
---@field commentCount number Comment count
---@field likedCount number Like count

---@class Album
---@field name string Album name
---@field id number Album ID
---@field type string Album type
---@field picUrl string Album cover URL
---@field company string Record company
---@field publishTime number Publish timestamp
---@field description string Album description
---@field size number Number of tracks

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
    return "/album/v3/detail"
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
    local key = crypto.cacheKey({
        id = self.id,
        e_r = self.e_r,
    });
    return {
        id = self.id,
        cache_key = key,
    }
end

---@return AlbumDetailRsp
function M:parse_response(response)
    return response:json()
end

return M



--[[
{
    "songs": [
        {
            "resourceState": true,
            "mark": 17716748288,
            "a": null,
            "al": {
                "name": "我肯定在几百年前就说过爱你",
                "id": 79515295,
                "pic": 109951164111703663,
                "tns": [
                    "Somewhere in time, I love you"
                ],
                "pic_str": "109951164111703663",
                "picUrl": "https://p1.music.126.net/5JLQMl8xASllDubCWb9WHw==/109951164111703663.jpg"
            },
            "alia": [],
            "additionalTitle": null,
            "rtype": 0,
            "ar": [
                {
                    "alias": [],
                    "name": "告五人",
                    "id": 12676697,
                    "tns": []
                }
            ],
            "mv": 0,
            "fee": 1,
            "t": 0,
            "m": {
                "fid": 0,
                "size": 7011117,
                "vd": -82373.0,
                "sr": 48000,
                "br": 192001
            },
            "cd": "01",
            "mainTitle": null,
            "ftype": 0,
            "h": {
                "fid": 0,
                "size": 11685165,
                "vd": -84953.0,
                "sr": 48000,
                "br": 320001
            },
            "no": 1,
            "sq": {
                "fid": 0,
                "size": 38690912,
                "vd": -85022.0,
                "sr": 48000,
                "br": 1059753
            },
            "version": 25,
            "name": "爱人错过",
            "id": 1368754688,
            "rtUrls": [],
            "tns": [
                "Somewhere in time"
            ],
            "noCopyrightRcmd": null,
            "st": 0,
            "copyright": 0,
            "awardTags": null,
            "originSongSimpleData": null,
            "songJumpInfo": null,
            "single": 0,
            "s_id": 0,
            "rurl": null,
            "v": 58,
            "rtUrl": null,
            "dt": 292074,
            "l": {
                "fid": 0,
                "size": 4674093,
                "vd": -80779.0,
                "sr": 48000,
                "br": 128001
            },
            "pst": 0,
            "djId": 0,
            "crbt": null,
            "hr": {
                "fid": 0,
                "size": 66762450,
                "vd": -84978.0,
                "sr": 48000,
                "br": 1828639
            },
            "entertainmentTags": null,
            "cp": 22036,
            "displayTags": null,
            "tagPicList": null,
            "mst": 9,
            "publishTime": 0,
            "originCoverType": 1,
            "rt": "",
            "pop": 100.0,
            "cf": ""
        },
        {
            "resourceState": true,
            "mark": 17716748288,
            "a": null,
            "al": {
                "name": "我肯定在几百年前就说过爱你",
                "id": 79515295,
                "pic": 109951164111703663,
                "tns": [
                    "Somewhere in time, I love you"
                ],
                "pic_str": "109951164111703663",
                "picUrl": "https://p1.music.126.net/5JLQMl8xASllDubCWb9WHw==/109951164111703663.jpg"
            },
            "alia": [],
            "additionalTitle": null,
            "rtype": 0,
            "ar": [
                {
                    "alias": [],
                    "name": "告五人",
                    "id": 12676697,
                    "tns": []
                }
            ],
            "mv": 10874102,
            "fee": 1,
            "t": 0,
            "m": {
                "fid": 0,
                "size": 6105069,
                "vd": -72268.0,
                "sr": 48000,
                "br": 192000
            },
            "cd": "01",
            "mainTitle": null,
            "ftype": 0,
            "h": {
                "fid": 0,
                "size": 10175085,
                "vd": -74871.0,
                "sr": 48000,
                "br": 320000
            },
            "no": 2,
            "sq": {
                "fid": 0,
                "size": 27844595,
                "vd": -74940.0,
                "sr": 48000,
                "br": 875941
            },
            "version": 33,
            "name": "法兰西多士",
            "id": 1368753797,
            "rtUrls": [],
            "tns": [
                "Pain toast"
            ],
            "noCopyrightRcmd": null,
            "st": 0,
            "copyright": 0,
            "awardTags": null,
            "originSongSimpleData": null,
            "songJumpInfo": null,
            "single": 0,
            "s_id": 0,
            "rurl": null,
            "v": 66,
            "rtUrl": null,
            "dt": 254305,
            "l": {
                "fid": 0,
                "size": 4070061,
                "vd": -70595.0,
                "sr": 48000,
                "br": 128000
            },
            "pst": 0,
            "djId": 0,
            "crbt": null,
            "hr": {
                "fid": 0,
                "size": 52151070,
                "vd": -74876.0,
                "sr": 48000,
                "br": 1640579
            },
            "entertainmentTags": null,
            "cp": 22036,
            "displayTags": null,
            "tagPicList": null,
            "mst": 9,
            "publishTime": 0,
            "originCoverType": 1,
            "rt": "",
            "pop": 100.0,
            "cf": ""
        },
        {
            "resourceState": true,
            "mark": 17716748288,
            "a": null,
            "al": {
                "name": "我肯定在几百年前就说过爱你",
                "id": 79515295,
                "pic": 109951164111703663,
                "tns": [
                    "Somewhere in time, I love you"
                ],
                "pic_str": "109951164111703663",
                "picUrl": "https://p1.music.126.net/5JLQMl8xASllDubCWb9WHw==/109951164111703663.jpg"
            },
            "alia": [],
            "additionalTitle": null,
            "rtype": 0,
            "ar": [
                {
                    "alias": [],
                    "name": "告五人",
                    "id": 12676697,
                    "tns": []
                }
            ],
            "mv": 0,
            "fee": 1,
            "t": 0,
            "m": {
                "fid": 0,
                "size": 6940929,
                "vd": -67159.0,
                "sr": 48000,
                "br": 192001
            },
            "cd": "01",
            "mainTitle": null,
            "ftype": 0,
            "h": {
                "fid": 0,
                "size": 11568129,
                "vd": -69712.0,
                "sr": 48000,
                "br": 320001
            },
            "no": 3,
            "sq": {
                "fid": 0,
                "size": 34865185,
                "vd": -69461.0,
                "sr": 48000,
                "br": 964669
            },
            "version": 19,
            "name": "跳海",
            "id": 1368754689,
            "rtUrls": [],
            "tns": [
                "Farewell in the sea"
            ],
            "noCopyrightRcmd": null,
            "st": 0,
            "copyright": 0,
            "awardTags": null,
            "originSongSimpleData": null,
            "songJumpInfo": null,
            "single": 0,
            "s_id": 0,
            "rurl": null,
            "v": 52,
            "rtUrl": null,
            "dt": 289136,
            "l": {
                "fid": 0,
                "size": 4627329,
                "vd": -65643.0,
                "sr": 48000,
                "br": 128001
            },
            "pst": 0,
            "djId": 0,
            "crbt": null,
            "hr": {
                "fid": 0,
                "size": 62542739,
                "vd": -69702.0,
                "sr": 48000,
                "br": 1730468
            },
            "entertainmentTags": null,
            "cp": 22036,
            "displayTags": null,
            "tagPicList": null,
            "mst": 9,
            "publishTime": 0,
            "originCoverType": 1,
            "rt": "",
            "pop": 95.0,
            "cf": ""
        }
    ],
    "info": {
        "threadId": "R_AL_3_79515295",
        "resourceType": 3,
        "shareCount": 12929,
        "commentCount": 1678,
        "likedCount": 0
    },
    "code": 200,
    "preSellSongIds": [],
    "album": {
        "songs": [],
        "name": "我肯定在几百年前就说过爱你",
        "id": 79515295,
        "alias": [],
        "status": 1,
        "briefDesc": "",
        "type": "专辑",
        "pic": 109951164111703663,
        "artists": [
            {
                "img1v1Url": "https://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
                "albumSize": 0,
                "id": 12676697,
                "alias": [],
                "briefDesc": "",
                "trans": "",
                "name": "告五人",
                "img1v1Id": 0,
                "musicSize": 0,
                "picId": 0,
                "topicPerson": 0,
                "picUrl": "https://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg"
            }
        ],
        "onSale": false,
        "transName": "Somewhere in time, I love you",
        "picId_str": "109951164111703663",
        "locked": false,
        "companyId": 0,
        "mark": 0,
        "artist": {
            "img1v1Url": "https://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
            "albumSize": 28,
            "id": 12676697,
            "alias": [
                "Accusefive"
            ],
            "briefDesc": "",
            "name": "告五人",
            "trans": "",
            "musicSize": 104,
            "img1v1Id": 0,
            "picId_str": "109951168306629780",
            "picId": 109951168306629780,
            "topicPerson": 0,
            "picUrl": "https://p2.music.126.net/Xyoa72EqbaHGHiSfL5D_qA==/109951168306629780.jpg"
        },
        "publishTime": 1560441600000,
        "description": "若你遇见了爱， 如人们口中的， 我想知道， 那是什么样子。 — 告五人 《我肯定在几百年前就说过爱你》 告五人首张专辑《我肯定在几百年前就说过爱你》探讨爱的本质，描写关于爱的不同切面，从生活经验里，写下关于爱的蛛丝马迹。什么是爱呢？其实我们也无法真正回答爱是什么，仍常在爱里迷失，但也在边迷路边寻找答案的过程，沿途找到散落在各地的自己。 -- 集结多年创作、生活的累积与观察，告五人终于完成第一张专辑。与制作人陈君豪共同制作，加入复古声响及编曲，曲风多元涵盖70年代风格舞曲、Synth Pop、嬉皮摇滚、硬地摇滚、民谣。密集录音制作，相信本质即为潮流，追寻本质、跟随直觉，调和出首张专辑《我肯定在几百年前就说过爱你》。",
        "company": "音之邦",
        "picUrl": "https://p2.music.126.net/5JLQMl8xASllDubCWb9WHw==/109951164111703663.jpg",
        "tags": "",
        "picId": 109951164111703663,
        "transNames": [
            "Somewhere in time, I love you"
        ],
        "commentThreadId": "R_AL_3_79515295",
        "copyrightId": 22036,
        "dolbyMark": 0,
        "size": 11,
        "subType": "录音室版",
        "blurPicUrl": "https://p2.music.126.net/5JLQMl8xASllDubCWb9WHw==/109951164111703663.jpg",
        "gapless": 0
    }
}
]]
