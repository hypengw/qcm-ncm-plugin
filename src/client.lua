local json = require("json")
local crypto = require("crypto")
local get_http_client = qcm.get_http_client;

local BASE_URL = "https://music.163.com"

local function formatCookie(table)
    local cookie = ''
    for k, v in pairs(table) do
        if cookie ~= "" then cookie = cookie .. "; " end
        cookie = cookie .. k .. "=" .. v
    end
    return cookie
end

local Client = {}
Client.__index = Client

function Client.new(device_id)
    local self = setmetatable({}, Client)

    -- Generate random player_id
    local player_id = ""
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
        resolution = "1920x1080",
        appver = "2.10.13",
        os = "pc",
        versioncode = "202675",
        osver = "8.1.0",
        brand = "hw",
        model = "",
        channel = ""
    }

    self.web_params_cookie = formatCookie(self.web_params)
    self.device_params_cookie = formatCookie(self.device_params)

    return self
end

function Client:perform(api, timeout)
    local base_url = self:get_base()
    local url = self:format_url(base_url, api)
    local headers = {
        ["Referer"] = "https://music.163.com",
        ["User-Agent"] =
        "Mozilla/5.0 (X11; Linux x86_64; rv:137.0) Gecko/20100101 Firefox/137.0"
    }

    if api:crypto() == "weapi" then
        headers["Cookie"] = self.web_params_cookie
    elseif api:crypto() == "eapi" then
        headers["Cookie"] = self.device_params_cookie
    end

    local response
    local http = get_http_client()
    if api:operation() == "GET" then
        response = http:get(url):headers(headers):query(api:query()):timeout(timeout):send();
    else
        local body = self:prepare_body(api)
        response = http:post(url):headers(headers):query(api:query()):timeout(timeout):form(body):send();
    end

    return api:parse_response(response)
end

function Client:get_base()
    return BASE_URL
end

function Client:prepare_body(api)
    local body = api:body();
    if not body then return "" end

    local params = type(body) == "string" and body or json.encode(body)
    return self:encrypt(api:path(), params, api:crypto())
end

function Client:format_url(base_url, api)
    local prefix = ""
    if api:crypto() == "weapi" then
        prefix = "/weapi"
    elseif api:crypto() == "eapi" then
        prefix = "/eapi"
    end
    return base_url .. prefix .. api:path()
end

function Client:encrypt(path, data, crypto_type)
    if crypto_type == "weapi" then
        return crypto.weapi(data)
    elseif crypto_type == "eapi" then
        return crypto.eapi(path, data)
    end
    return data
end

return Client
