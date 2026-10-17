local json = require('json')
local crypto = require('crypto')
local error = require('error')
local qcm = require('qcm.mod')
local get_http_client = qcm.get_http_client;

local BASE_URL = 'https://music.163.com'

---@class Api
---@field no_error_check? boolean
---@field base? fun(): string
---@field operation fun(): string
---@field crypto fun(): string
---@field query fun(): table
---@field body fun(): table
---@field path fun(): string
---@field parse_response fun(Api, any): any

local function formatCookie(table)
    local cookie = ''
    for k, v in pairs(table) do
        if cookie ~= '' then cookie = cookie .. '; ' end
        cookie = cookie .. k .. '=' .. v
    end
    return cookie
end

---@class Client
---@field device_id string Device ID for authentication
---@field web_params table Web request parameters
---@field device_params table Device-specific parameters
---@field web_params_cookie string Formatted web parameters as cookie string
---@field device_params_cookie string Formatted device parameters as cookie string
local Client = {}
Client.__index = Client

function Client.new(device_id, session)
    local self = setmetatable({}, Client)

    -- Generate random player_id
    local player_id = ''
    for i = 1, 8 do
        player_id = player_id .. tostring(math.random(0, 9))
    end

    self.session = session
    self.device_id = device_id
    self.web_params = {
        playerid = player_id,
        sDeviceId = device_id
    }
    self.device_params = {
        deviceId = device_id,
        resolution = '1920x1080',
        appver = '2.10.13',
        os = 'pc',
        versioncode = '202675',
        osver = '8.1.0',
        brand = 'hw',
        model = '',
        channel = ''
    }

    self.web_params_cookie = formatCookie(self.web_params)
    self.device_params_cookie = formatCookie(self.device_params)

    return self
end

---@param api Api
function Client:_req_build(api, timeout)
    local base_url = api.base and api:base() or self:get_base()
    local url = self:format_url(base_url, api)
    local headers = {
        ['Referer'] = 'https://music.163.com',
        ['User-Agent'] =
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.2 Safari/605.1.15'
    }

    if api:crypto() == 'weapi' then
        headers['Cookie'] = self.web_params_cookie;
    elseif api:crypto() == 'eapi' then
        headers['Cookie'] = self.device_params_cookie
    end

    local builder
    local http = get_http_client()
    if api:operation() == 'GET' then
        builder = http:get(url):headers(headers):query(api:query()):timeout(timeout);
    else
        local body = self:prepare_body(api)
        builder = http:post(url):headers(headers):query(api:query()):timeout(timeout):form(body);
    end
    return builder
end

function Client:_response(api, response, generation)
    local ok, result = pcall(function()
        if self.session then
            self.session:accept(response, generation)
            self.session:save()
        end
        local value = api:parse_response(response)
        if self.session then self.session:check(generation) end
        return value
    end)
    response:close()
    if not ok then _G.error(result, 0) end
    return result
end

function Client:_send(api, timeout)
    local generation = self.session and self.session.generation
    local response = self:_req_build(api, timeout):send()
    return self:_response(api, response, generation)
end

function Client:perform(api, timeout)
    if self.session and not api.auth_request then self.session:ensure(self) end
    local rsp = self:_send(api, timeout)
    if self.session and not api.auth_request and self.session.invalid(rsp.code) then
        self.session:recover(self, api:path())
        if api.retry_after_auth then rsp = self:_send(api, timeout) end
    end
    if not api.no_error_check then error.check(rsp) end
    return rsp
end

function Client:perform_queue(next, timeout)
    if self.session then self.session:ensure(self) end
    local batch = get_http_client():new_batch {results = 'response', limit = 12}
    local results, pending, sequence, count, ended = {}, {}, 0, 0, false
    local ok, failure = pcall(function()
        while true do
            while not ended and count < 12 do
                local api = next()
                if not api then ended = true; batch:seal(); break end
                sequence = sequence + 1
                local key = tostring(sequence)
                local generation = self.session and self.session.generation
                batch:add(key, self:_req_build(api, timeout):build())
                pending[key], count = {api = api, generation = generation}, count + 1
            end
            local completed = batch:wait_one()
            if not completed then break end
            local entry = assert(pending[completed.key], 'unknown batch key')
            pending[completed.key], count = nil, count - 1
            if completed.error then _G.error(completed.error, 0) end
            local rsp = self:_response(entry.api, completed.response, entry.generation)
            if self.session and self.session.invalid(rsp.code) then
                self.session:recover(self, entry.api:path())
                if entry.api.retry_after_auth then rsp = self:_send(entry.api, timeout) end
            end
            if not entry.api.no_error_check then error.check(rsp) end
            results[#results + 1] = rsp
        end
    end)
    batch:close()
    if not ok then _G.error(failure, 0) end
    return results
end

function Client:get_base()
    return BASE_URL
end

function Client:prepare_body(api)
    local body = api:body();
    if not body then return '' end

    local params = type(body) == 'string' and body or json.encode(body)
    return self:encrypt(api:path(), params, api:crypto())
end

function Client:format_url(base_url, api)
    local prefix = ''
    if api:crypto() == 'weapi' then
        prefix = '/weapi'
    elseif api:crypto() == 'eapi' then
        prefix = '/eapi'
    end
    return base_url .. prefix .. api:path()
end

function Client:encrypt(path, data, crypto_type)
    if crypto_type == 'weapi' then
        return crypto.weapi(data)
    elseif crypto_type == 'eapi' then
        return crypto.eapi('/api' .. path, data)
    end
    return data
end

return Client
