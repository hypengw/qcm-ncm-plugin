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
---@field parse_response fun(Api, any): any

local function formatCookie(table)
    local cookie = ''
    for k, v in pairs(table) do
        if cookie ~= '' then cookie = cookie .. '; ' end
        cookie = cookie .. k .. '=' .. v
    end
    return cookie
end

local Client = {}
Client.__index = Client

function Client.new(device_id)
    local self = setmetatable({}, Client)

    -- Generate random player_id
    local player_id = ''
    for i = 1, 8 do
        player_id = player_id .. tostring(math.random(0, 9))
    end

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

---@param api Api
---@param timeout integer | nil
function Client:perform(api, timeout)
    local response = self:_req_build(api, timeout):send()
    local rsp = api:parse_response(response)
    if not api.no_error_check then
        error.check(rsp)
    end
    return rsp
end

---@param next fun(): Api
---@param timeout integer | nil
function Client:perform_queue(next, timeout)
    local batch = get_http_client():new_batch()
    local results = {}
    while true do
        local rsp = batch:wait_one()
        if rsp == nil then
            local ok = true
            for i = 1, 5 do
                local api = next()
                if not api then
                    ok = false
                    break
                end
                local builder = self:_req_build(api, timeout)
                batch:add(builder)
            end
            if not ok then
                break
            end
        else
            rsp = json.decode(rsp)
            -- error.check(rsp)
            if rsp.code ~= 200 then
                print('warn: ' .. rsp.code .. ' ' .. rsp.message)
            else
                table.insert(results, rsp)
            end
        end
    end
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
