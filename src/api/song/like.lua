local M = {}
M.__index = M

function M.new()
    local self = setmetatable({}, M)
    return self
end

function M:path()
    return "/song/like"
end

function M:operation()
    return "POST"
end

function M:crypto()
    return "weapi"
end

function M:query()
    return {
    }
end

function M:body()
    return {
        like = true,
        trackId = 1,
        userid = 1,
        userActionMap = {}, -- opt
        sceneParams = {},   -- opt
        checkToken = ''
    }
end

function M:parse_response(response)
    local data = response:json()
    return data
end

return M
