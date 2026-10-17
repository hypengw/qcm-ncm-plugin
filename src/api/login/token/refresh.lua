local M = {auth_request = true, no_error_check = true}
M.__index = M
function M.new(token) return setmetatable({token = token}, M) end
function M:path() return '/login/token/refresh' end
function M:operation() return 'POST' end
function M:crypto() return 'eapi' end
function M:query() return {} end
function M:body() return {refreshToken = self.token} end
function M:parse_response(response) return response:json() end
return M
