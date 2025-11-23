local M = {}
M.__index = M

function M.new(album_id)
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/v1/discovery/recommend/resource"
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

function M:parse_response(response)
    local data = response:json()
    return data
end

return M


--[[
struct RecommendResourceItem {
    PlaylistId  id;
    i64         type;
    std::string name;
    std::string copywriter;
    std::string picUrl;
    i64         playcount;
    Time        createTime;
    //      "creator": null,
    i64 trackCount;
};

struct RecommendResource {
    std::vector<RecommendResourceItem> recommend;
    i64                                       code;
};
]]
