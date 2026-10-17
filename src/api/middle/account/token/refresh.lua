local M = {auth_request = true, no_error_check = true}
M.__index = M
function M.new(path) return setmetatable({path_value = path}, M) end
function M:path() return '/middle/account/token/refresh' end
function M:operation() return 'POST' end
function M:crypto() return 'eapi' end
function M:query() return {} end
function M:body() return {fromAPI = self.path_value} end
function M:parse_response(response) return response:json() end
return M
