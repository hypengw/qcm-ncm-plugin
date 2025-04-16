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