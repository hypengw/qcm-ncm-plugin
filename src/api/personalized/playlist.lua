local M = {}
M.__index = M

function M.new(limit, offset)
    local self = setmetatable({}, M)
    self.limit = limit or 30
    self.offset = offset or 0
    return self
end

function M:path()
    return "/personalized/playlist"
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
        limit = self.limit,
        total = true,
        n = 1000,
        offset = self.offset,
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M

--[[
{
  "result": [
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1690978111718,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/XyoVPk4TPfZpRxDfBFqXZw==/109951163944520221.jpg",
      "trackCount": 111,
      "type": 0,
      "name": "试着做个善良的人",
      "copywriter": "",
      "playCount": 25237776.0,
      "id": 2547050034,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1763515625648,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/DTA1vQiLtNxZZe7dDWI6Qg==/109951164187665128.jpg",
      "trackCount": 384,
      "type": 0,
      "name": "节奏控 | 那些超带感的英文歌",
      "copywriter": "",
      "playCount": 59089276.0,
      "id": 2345048322,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1749113975722,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/vZ5ef3WzRneTTydXSzPauQ==/109951165994871935.jpg",
      "trackCount": 307,
      "type": 0,
      "name": "别急，甜甜的恋爱马上就轮到你了",
      "copywriter": "",
      "playCount": 78171624.0,
      "id": 2430524968,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1762325756917,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/82AGwjWrmcz0Lr1VbYJsWA==/109951170001861865.jpg",
      "trackCount": 108,
      "type": 0,
      "name": "你最爱的歌 我反复听",
      "copywriter": "",
      "playCount": 24705004.0,
      "id": 6943933489,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1661946539352,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/OQfrX2yq1QjvOWOTK3b_4g==/18936888765371604.jpg",
      "trackCount": 100,
      "type": 0,
      "name": "【节奏控】一听就上瘾的惊艳女声",
      "copywriter": "",
      "playCount": 25511260.0,
      "id": 768047050,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1738758187442,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/Xd6h-xOoPj2yTUuQXOhyCQ==/18612532836990988.jpg",
      "trackCount": 100,
      "type": 0,
      "name": "粤语男声：我爱你依旧如初不曾改变",
      "copywriter": "",
      "playCount": 29808046.0,
      "id": 893153237,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1760669773762,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/hjj85ZazuFZbxE-Ul2meKw==/3273246127527246.jpg",
      "trackCount": 195,
      "type": 0,
      "name": "【节奏控】超带感的爆款歌（经典篇）",
      "copywriter": "",
      "playCount": 174270928.0,
      "id": 312734124,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1763568000000,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/IkPN-xNgvvtmFiciUiRe6g==/109951172317334191.jpg",
      "trackCount": 50,
      "type": 0,
      "name": "一周日语上新 | 人气组合YOASOBI再度唤醒心底悸动！",
      "copywriter": "",
      "playCount": 98402656.0,
      "id": 2819914042,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1762502787314,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/em_fXgUJDApoV_3_8HYkNg==/109951164362973668.jpg",
      "trackCount": 103,
      "type": 0,
      "name": "成长篇 | 认识到自己的平凡，并且接受",
      "copywriter": "",
      "playCount": 33665420.0,
      "id": 2983726621,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1678525624408,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/3RANMlMM-udSsHyInyVbrQ==/528865105234307.jpg",
      "trackCount": 60,
      "type": 0,
      "name": "[声线] 空 灵 女 声",
      "copywriter": "",
      "playCount": 26268524.0,
      "id": 123243715,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1694470650502,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/SBuPJUfGgt626uP0TGDuww==/18675205000177588.jpg",
      "trackCount": 231,
      "type": 0,
      "name": "【欧美翻唱】叫醒耳朵系列",
      "copywriter": "",
      "playCount": 26024348.0,
      "id": 118321798,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1456740067839,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/2SZVbfU_sXfK6KTvztFoqQ==/1376588559900158.jpg",
      "trackCount": 100,
      "type": 0,
      "name": "电音王国 | 荷兰",
      "copywriter": "",
      "playCount": 25211546.0,
      "id": 308905952,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1761960682184,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/QHD2Uy2y9ktndbK1UKgdgg==/18611433325258133.jpg",
      "trackCount": 238,
      "type": 0,
      "name": "『粤语』好听到爆的粤语歌单.",
      "copywriter": "",
      "playCount": 207227856.0,
      "id": 632021463,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1749636465078,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/vuPDRsBSPjjRUG2D_CGngw==/109951162933606208.jpg",
      "trackCount": 100,
      "type": 0,
      "name": "『一百首』经典华语怀旧老歌",
      "copywriter": "",
      "playCount": 55452076.0,
      "id": 737535139,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1763740800000,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/P7nOBW_mZhv3gsCFKhA0Og==/109951172322560712.jpg",
      "trackCount": 30,
      "type": 0,
      "name": "[一周原创发现] 8bite带你漫游水星",
      "copywriter": "",
      "playCount": 61117100.0,
      "id": 2821115454,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1746497572863,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/Fg_8XLbz9uwJvHVLXhz5Cg==/109951163349262839.jpg",
      "trackCount": 304,
      "type": 0,
      "name": "[纯音乐]错落一身宁静，深海浮沉摘星",
      "copywriter": "",
      "playCount": 25031428.0,
      "id": 2195404116,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1586721214781,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/JZguHNVDUvmo0rjhQVYjiA==/3405187517388215.jpg",
      "trackCount": 45,
      "type": 0,
      "name": "【妖气弥漫】那些妖异的古风歌曲",
      "copywriter": "",
      "playCount": 25047844.0,
      "id": 318112231,
      "highQuality": true
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1690945575312,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/2rux5LnJey75tm9Md-9D-Q==/2890616070443534.jpg",
      "trackCount": 212,
      "type": 0,
      "name": "『90后』小时候【所谓非主流】的经典神曲",
      "copywriter": "",
      "playCount": 30254760.0,
      "id": 69860949,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1737026267435,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/AWcDI5wc9fkS2bZt6wIm-Q==/109951163212638897.jpg",
      "trackCount": 45,
      "type": 0,
      "name": "愿还会有人，做个傻子陪你浪费一生",
      "copywriter": "",
      "playCount": 28308548.0,
      "id": 2042205655,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1491989871334,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/tgkN397ohC6XpqRRHzndLw==/2925800441997173.jpg",
      "trackCount": 387,
      "type": 0,
      "name": "【国人纯音赏】聆听国人华章",
      "copywriter": "",
      "playCount": 25448848.0,
      "id": 379025025,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1763704104879,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/ICv1ZqD39lvvS0CdhHl1EA==/109951163320645123.jpg",
      "trackCount": 537,
      "type": 0,
      "name": "Space Club/蹦迪必备",
      "copywriter": "",
      "playCount": 98696400.0,
      "id": 946216567,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1760159432407,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/b3wneqObn_0ZFajnFqwbXw==/109951171880769088.jpg",
      "trackCount": 172,
      "type": 0,
      "name": "前奏一响起 我瞬间释怀了",
      "copywriter": "",
      "playCount": 34065648.0,
      "id": 6917327039,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1672737898470,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/uFWcdYyjcqvM5JFZ5nsPGw==/1365593453032084.jpg",
      "trackCount": 54,
      "type": 0,
      "name": "不让你通宵循环的电音不是好电音",
      "copywriter": "",
      "playCount": 39656988.0,
      "id": 128871831,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1737351465798,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/TacJxbYVjD0vc7Nrn5FzUQ==/109951163557993210.jpg",
      "trackCount": 562,
      "type": 0,
      "name": "「看书学习」在安静的位置看热闹的世界",
      "copywriter": "",
      "playCount": 29032976.0,
      "id": 2426530028,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1762337041110,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/hoGRbppqaUIYkKpQGPwilw==/109951168031132211.jpg",
      "trackCount": 110,
      "type": 0,
      "name": "予你情诗百首，余生你是我的所有",
      "copywriter": "",
      "playCount": 67231240.0,
      "id": 2230318386,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1544284547496,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/aao5Ku06P5PrMafCfT3MjQ==/18648816720698170.jpg",
      "trackCount": 72,
      "type": 0,
      "name": "「日语民谣」月色中的浅吟低唱",
      "copywriter": "",
      "playCount": 24645102.0,
      "id": 806728741,
      "highQuality": true
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1744691222213,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/PsONIoIzCJ-9gPCAeq9ahw==/19115009649498152.jpg",
      "trackCount": 212,
      "type": 0,
      "name": "粤语传世经典，怀旧是人的本能",
      "copywriter": "",
      "playCount": 147044496.0,
      "id": 2237551001,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1742169668406,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/ptx2Jf4PZl3oNLxv4NiADg==/109951164018765577.jpg",
      "trackCount": 169,
      "type": 0,
      "name": "欧美万评优质女声•萦绕耳畔忆于心间",
      "copywriter": "",
      "playCount": 40688380.0,
      "id": 2748492595,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1763103213606,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/ZvJP5ZEI4EWdKoh3EUIbdg==/1365593450023866.jpg",
      "trackCount": 182,
      "type": 0,
      "name": "【电子】入耳收藏的经典旋律",
      "copywriter": "",
      "playCount": 44860436.0,
      "id": 123216450,
      "highQuality": false
    },
    {
      "canDislike": true,
      "trackNumberUpdateTime": 1515554115534,
      "alg": "alg_high_quality",
      "picUrl": "https://p1.music.126.net/Izq2rrMzKPNaxmgg0O0KNA==/19155691579189685.jpg",
      "trackCount": 63,
      "type": 0,
      "name": "不得了！这些英文歌的热评信息量好大……",
      "copywriter": "",
      "playCount": 33637116.0,
      "id": 645384312,
      "highQuality": true
    }
  ],
  "code": 200,
  "category": 0,
  "hasTaste": false
}
]]
