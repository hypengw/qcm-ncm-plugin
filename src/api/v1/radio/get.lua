local M = {retry_after_auth = true}
M.__index = M

function M.new(options)
    local self = setmetatable({}, M)
    options = options or {}
    self.mode = options.mode or 'DEFAULT'
    self.source_id = options.source_id
    assert(self.mode ~= 'SIMILAR' or (type(self.source_id) == 'string' and self.source_id:match('^%d+$')), 'similar radio requires a source')
    return self
end

function M:path()
    return "/v1/radio/get"
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
    local body = {mode = self.mode, limit = 3}
    if self.mode == 'SIMILAR' then
        body.sourceType = 'song'
        body.sourceIds = self.source_id
    else
        body.subMode = ''
    end
    return body
end

function M:parse_response(response)
    return response:json()
end

return M

--[[
{
  "data": [
    {
      "reason": "你可能喜欢的轻音乐歌曲",
      "disc": "01",
      "status": 0,
      "mMusic": {
        "bitrate": 192000,
        "volumeDelta": -7718.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 397146,
        "id": 8642646071,
        "size": 9533275
      },
      "lMusic": {
        "bitrate": 128000,
        "volumeDelta": -5919.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 397146,
        "id": 8642646073,
        "size": 6355531
      },
      "score": 85,
      "commentThreadId": "R_SO_4_2106665750",
      "hearTime": 0,
      "dayPlays": 0,
      "ringtone": "",
      "copyright": 1,
      "copyFrom": "",
      "alg": "alg-music-rec-unite-userFm-vec-muti_interest_embedding_mm_mae1-default",
      "alias": [],
      "copyrightId": 7003,
      "playedNum": 0,
      "artists": [
        {
          "musicSize": 0,
          "img1v1Id": 0,
          "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "albumSize": 0,
          "picId": 0,
          "briefDesc": "",
          "trans": "",
          "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "alias": [],
          "id": 13773,
          "name": "小瀬村晶"
        }
      ],
      "fee": 8,
      "rtype": 0,
      "privilege": {
        "dl": 999000,
        "downloadMaxBrLevel": "lossless",
        "cp": 1,
        "maxbr": 999000,
        "pl": 999000,
        "dlLevel": "lossless",
        "flLevel": "exhigh",
        "sp": 7,
        "st": 0,
        "realPayed": 0,
        "plLevel": "lossless",
        "downloadMaxbr": 999000,
        "chargeInfoList": [
          {
            "rate": 128000,
            "chargeType": 0
          },
          {
            "rate": 192000,
            "chargeType": 0
          },
          {
            "rate": 320000,
            "chargeType": 0
          },
          {
            "rate": 999000,
            "chargeType": 1
          }
        ],
        "fee": 8,
        "payed": 1,
        "cs": false,
        "id": 2106665750,
        "code": 0,
        "flag": 4,
        "playMaxBrLevel": "lossless",
        "toast": false,
        "subp": 1,
        "rightSource": 0,
        "preSell": false,
        "playMaxbr": 999000,
        "maxBrLevel": "lossless",
        "paidBigBang": false,
        "freeTrialPrivilege": {
          "resConsumable": false,
          "userConsumable": false
        },
        "fl": 320000
      },
      "id": 2106665750,
      "starredNum": 0,
      "popularity": 85.0,
      "rtUrls": [],
      "duration": 397146,
      "mvid": 22777224,
      "starred": false,
      "bMusic": {
        "bitrate": 128000,
        "volumeDelta": -5919.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 397146,
        "id": 8642646073,
        "size": 6355531
      },
      "position": 0,
      "no": 7,
      "name": "lanrete",
      "album": {
        "description": "",
        "pic": 109951169145777432,
        "artist": {
          "musicSize": 0,
          "img1v1Id": 0,
          "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "albumSize": 0,
          "picId": 0,
          "briefDesc": "",
          "trans": "",
          "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "alias": [],
          "id": 0,
          "name": ""
        },
        "artists": [
          {
            "musicSize": 0,
            "img1v1Id": 0,
            "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
            "albumSize": 0,
            "picId": 0,
            "briefDesc": "",
            "trans": "",
            "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
            "alias": [],
            "id": 13773,
            "name": "小瀬村晶"
          }
        ],
        "blurPicUrl": "http://p2.music.126.net/09yAoiNjjYtjKZG9IuDBZA==/109951169145777432.jpg",
        "commentThreadId": "R_AL_3_180690286",
        "id": 180690286,
        "type": "专辑",
        "picUrl": "http://p2.music.126.net/09yAoiNjjYtjKZG9IuDBZA==/109951169145777432.jpg",
        "size": 10,
        "subType": "录音室版",
        "status": 1,
        "companyId": 0,
        "picId_str": "109951169145777432",
        "picId": 109951169145777432,
        "tags": "",
        "publishTime": 1701964800000,
        "songs": [],
        "name": "The Two Of Us",
        "company": "Universal Music LLC",
        "alias": [],
        "copyrightId": 7003,
        "briefDesc": ""
      },
      "hMusic": {
        "bitrate": 320000,
        "volumeDelta": -10342.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 397146,
        "id": 8642646072,
        "size": 15888762
      },
      "ftype": 0
    },
    {
      "disc": "01",
      "status": 0,
      "mMusic": {
        "bitrate": 192000,
        "volumeDelta": -62566.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 211772,
        "id": 6496401555,
        "size": 5083890
      },
      "lMusic": {
        "bitrate": 128000,
        "volumeDelta": -61228.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 211772,
        "id": 6496401557,
        "size": 3389275
      },
      "score": 40,
      "commentThreadId": "R_SO_4_1819673042",
      "hearTime": 0,
      "dayPlays": 0,
      "ringtone": "",
      "copyright": 0,
      "copyFrom": "",
      "alg": "alg-music-rec-unite-userFm-vec-muti_interest_embedding_mm_mae1-default",
      "alias": [],
      "copyrightId": 0,
      "playedNum": 0,
      "artists": [
        {
          "musicSize": 0,
          "img1v1Id": 0,
          "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "albumSize": 0,
          "picId": 0,
          "briefDesc": "",
          "trans": "",
          "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "alias": [],
          "id": 12604795,
          "name": "lunari.io"
        }
      ],
      "fee": 0,
      "rtype": 0,
      "privilege": {
        "dl": 999000,
        "downloadMaxBrLevel": "lossless",
        "cp": 1,
        "maxbr": 999000,
        "pl": 999000,
        "dlLevel": "lossless",
        "flLevel": "exhigh",
        "sp": 7,
        "st": 0,
        "realPayed": 0,
        "plLevel": "lossless",
        "downloadMaxbr": 999000,
        "chargeInfoList": [
          {
            "rate": 128000,
            "chargeType": 0
          },
          {
            "rate": 192000,
            "chargeType": 0
          },
          {
            "rate": 320000,
            "chargeType": 0
          },
          {
            "rate": 999000,
            "chargeType": 1
          }
        ],
        "fee": 0,
        "payed": 0,
        "cs": false,
        "id": 1819673042,
        "code": 0,
        "flag": 1,
        "playMaxBrLevel": "lossless",
        "toast": false,
        "subp": 1,
        "rightSource": 0,
        "preSell": false,
        "playMaxbr": 999000,
        "maxBrLevel": "lossless",
        "paidBigBang": false,
        "freeTrialPrivilege": {
          "resConsumable": false,
          "userConsumable": false
        },
        "fl": 320000
      },
      "id": 1819673042,
      "starredNum": 0,
      "popularity": 40.0,
      "rtUrls": [],
      "duration": 211772,
      "mvid": 0,
      "starred": false,
      "bMusic": {
        "bitrate": 128000,
        "volumeDelta": -61228.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 211772,
        "id": 6496401557,
        "size": 3389275
      },
      "position": 0,
      "no": 1,
      "name": "[warmsnow]",
      "album": {
        "description": "",
        "pic": 109951165718783088,
        "artist": {
          "musicSize": 0,
          "img1v1Id": 0,
          "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "albumSize": 0,
          "picId": 0,
          "briefDesc": "",
          "trans": "",
          "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "alias": [],
          "id": 0,
          "name": ""
        },
        "artists": [
          {
            "musicSize": 0,
            "img1v1Id": 0,
            "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
            "albumSize": 0,
            "picId": 0,
            "briefDesc": "",
            "trans": "",
            "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
            "alias": [],
            "id": 12604795,
            "name": "lunari.io"
          }
        ],
        "blurPicUrl": "http://p2.music.126.net/62IJt8q1LhPjlUQMnqeDrQ==/109951165718783088.jpg",
        "commentThreadId": "R_AL_3_122839678",
        "id": 122839678,
        "picUrl": "http://p2.music.126.net/62IJt8q1LhPjlUQMnqeDrQ==/109951165718783088.jpg",
        "type": "专辑",
        "publishTime": 1613033003529,
        "subType": "现场版",
        "companyId": 0,
        "status": 0,
        "picId": 109951165718783088,
        "tags": "",
        "size": 1,
        "songs": [],
        "picId_str": "109951165718783088",
        "name": "[warmsnow]",
        "alias": [],
        "copyrightId": 0,
        "briefDesc": ""
      },
      "hMusic": {
        "bitrate": 320000,
        "volumeDelta": -64901.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 211772,
        "id": 6496401553,
        "size": 8473121
      },
      "ftype": 0
    },
    {
      "disc": "01",
      "status": 0,
      "mMusic": {
        "bitrate": 192000,
        "volumeDelta": -3608.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 153810,
        "id": 7898296170,
        "size": 3693340
      },
      "lMusic": {
        "bitrate": 128000,
        "volumeDelta": -1840.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 153810,
        "id": 7898296172,
        "size": 2462241
      },
      "score": 95,
      "commentThreadId": "R_SO_4_2023313598",
      "hearTime": 0,
      "dayPlays": 0,
      "ringtone": "",
      "copyright": 1,
      "copyFrom": "",
      "alg": "alg-music-rec-unite-userFm-vec-muti_interest_embedding_mm_mae2-default",
      "alias": [],
      "copyrightId": 1416618,
      "playedNum": 0,
      "artists": [
        {
          "musicSize": 0,
          "img1v1Id": 0,
          "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "albumSize": 0,
          "picId": 0,
          "briefDesc": "",
          "trans": "",
          "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "alias": [],
          "id": 51862646,
          "name": "精彩威Sir"
        }
      ],
      "fee": 1,
      "rtype": 0,
      "privilege": {
        "dl": 999000,
        "downloadMaxBrLevel": "lossless",
        "cp": 1,
        "maxbr": 999000,
        "pl": 999000,
        "dlLevel": "lossless",
        "flLevel": "none",
        "sp": 7,
        "st": 0,
        "realPayed": 0,
        "plLevel": "lossless",
        "downloadMaxbr": 999000,
        "chargeInfoList": [
          {
            "rate": 128000,
            "chargeType": 1
          },
          {
            "rate": 192000,
            "chargeType": 1
          },
          {
            "rate": 320000,
            "chargeType": 1
          },
          {
            "rate": 999000,
            "chargeType": 1
          }
        ],
        "fee": 1,
        "payed": 1,
        "cs": false,
        "id": 2023313598,
        "code": 0,
        "flag": 4,
        "playMaxBrLevel": "lossless",
        "toast": false,
        "subp": 1,
        "rightSource": 0,
        "preSell": false,
        "playMaxbr": 999000,
        "maxBrLevel": "lossless",
        "paidBigBang": false,
        "freeTrialPrivilege": {
          "resConsumable": false,
          "userConsumable": false
        },
        "fl": 0
      },
      "id": 2023313598,
      "starredNum": 0,
      "popularity": 95.0,
      "rtUrls": [],
      "duration": 153810,
      "mvid": 0,
      "starred": false,
      "bMusic": {
        "bitrate": 128000,
        "volumeDelta": -1840.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 153810,
        "id": 7898296172,
        "size": 2462241
      },
      "position": 0,
      "no": 3,
      "name": "相遇即永恒",
      "album": {
        "description": "",
        "pic": 109951168317217919,
        "artist": {
          "musicSize": 0,
          "img1v1Id": 0,
          "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "albumSize": 0,
          "picId": 0,
          "briefDesc": "",
          "trans": "",
          "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
          "alias": [],
          "id": 0,
          "name": ""
        },
        "artists": [
          {
            "musicSize": 0,
            "img1v1Id": 0,
            "img1v1Url": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
            "albumSize": 0,
            "picId": 0,
            "briefDesc": "",
            "trans": "",
            "picUrl": "http://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg",
            "alias": [],
            "id": 51862646,
            "name": "精彩威Sir"
          }
        ],
        "blurPicUrl": "http://p2.music.126.net/lGe71ZJ4qLOfqP05u4hciA==/109951168317217919.jpg",
        "commentThreadId": "R_AL_3_160292126",
        "id": 160292126,
        "type": "EP",
        "picUrl": "http://p2.music.126.net/lGe71ZJ4qLOfqP05u4hciA==/109951168317217919.jpg",
        "size": 5,
        "subType": "录音室版",
        "status": 1,
        "companyId": 0,
        "picId_str": "109951168317217919",
        "picId": 109951168317217919,
        "tags": "",
        "publishTime": 1677081600000,
        "songs": [],
        "name": "相遇即永恒",
        "company": "独立发行",
        "alias": [],
        "copyrightId": 1416618,
        "briefDesc": ""
      },
      "hMusic": {
        "bitrate": 320000,
        "volumeDelta": -6249.0,
        "dfsId": 0,
        "sr": 44100,
        "extension": "mp3",
        "playTime": 153810,
        "id": 7898296165,
        "size": 6155538
      },
      "ftype": 0
    }
  ],
  "popAdjust": false,
  "extTransMap": {},
  "code": 200
}
--]]
