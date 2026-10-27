local M = {}
M.__index = M

function M.new(path, body, read)
    return setmetatable({endpoint = path, params = body, retry_after_auth = read == true}, M)
end
function M:path() return self.endpoint end
function M:operation() return 'POST' end
function M:crypto() return 'weapi' end
function M:query() return {} end
function M:body() return self.params end
function M:parse_response(response) return response:json() end

return M
