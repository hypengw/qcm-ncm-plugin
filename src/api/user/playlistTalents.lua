local M = {}
M.__index = M

function M.new(tag_name, offset, limit)
    local self = setmetatable({}, M)
    self.tag_name = tag_name or ""
    self.offset = offset or 0
    self.limit = limit or 30
    return self
end

function M:path()
    return "/user/playlistTalents"
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
        tagName = self.tag_name,
        offset = self.offset,
        limit = self.limit,
    }
end

function M:parse_response(response)
    return response:json()
end

return M
