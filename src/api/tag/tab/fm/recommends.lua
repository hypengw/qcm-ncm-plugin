local util = require('util')
local qcm = require('qcm.mod')
local M = {retry_after_auth = true}
M.__index = M

function M.new(source)
    assert(type(source.tab_tag_id) == 'string' and type(source.rule_id) == 'string'
        and math.type(source.rule_type) == 'integer', 'invalid category radio source')
    assert((source.tab_tag_id ~= '') ~= (source.rule_id ~= ''), 'ambiguous category radio source')
    return setmetatable({source = source}, M)
end

function M:path() return '/tag/tab/fm/recommends' end
function M:operation() return 'POST' end
function M:crypto() return 'weapi' end
function M:query() return {} end

function M:body()
    return {tabTagId = self.source.tab_tag_id, ruleId = self.source.rule_id,
        ruleType = self.source.rule_type, limit = 5}
end

function M:parse_response(response)
    local result = response:json()
    if result.code == 200 then
        local recommendations = {}
        for _, item in ipairs(util.array(result.data)) do
            assert(type(item) == 'table', 'invalid category recommendation')
            local alg = item.alg
            if alg == qcm.null then alg = nil end
            assert(alg == nil or type(alg) == 'string', 'invalid recommendation algorithm')
            recommendations[#recommendations + 1] = {native_id = util.positive_id(item.id), alg = alg}
        end
        result.recommendations = recommendations
    end
    return result
end

return M
