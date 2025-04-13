local json = require("json")
local crypto = require("crypto")

local BASE_URL = "https://music.163.com"

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
    self.crypto = crypto.new()
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
    
    return self
end

function Client:perform(api, timeout)
    local base_url = self:get_base()
    local url = self:format_url(base_url, api.path)
    local body = self:prepare_body(api)
    local headers = {
        ["Referer"] = "https://music.163.com",
        ["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.2 Safari/605.1.15"
    }
    
    -- Add cookie headers based on crypto type
    if api.crypto_type == "weapi" then
        local cookie = ""
        for k, v in pairs(self.web_params) do
            if cookie ~= "" then cookie = cookie .. "; " end
            cookie = cookie .. k .. "=" .. v
        end
        headers["Cookie"] = cookie
    elseif api.crypto_type == "eapi" then
        local cookie = ""
        for k, v in pairs(self.device_params) do
            if cookie ~= "" then cookie = cookie .. "; " end
            cookie = cookie .. k .. "=" .. v
        end
        headers["Cookie"] = cookie
    end
    
    local response
    if api.operation == "GET" then
        response = http:get(url, {
            headers = headers,
            query = api.query,
            timeout = timeout
        })
    else
        response = http:post(url, {
            headers = headers,
            body = body,
            query = api.query,
            timeout = timeout
        })
    end
    
    return api.parse_response(response, api.input)
end

function Client:get_base()
    return BASE_URL
end

function Client:prepare_body(api)
    if not api.body then return "" end
    
    local params = type(api.body) == "string" and api.body or json.encode(api.body)
    return self:encrypt(api.path, params, api.crypto_type)
end

function Client:format_url(base_url, path)
    local prefix = ""
    if api.crypto_type == "weapi" then
        prefix = "/weapi"
    elseif api.crypto_type == "eapi" then
        prefix = "/eapi"
    end
    return base_url .. prefix .. path
end

function Client:encrypt(path, data, crypto_type)
    if crypto_type == "weapi" then
        return self.crypto:weapi(data)
    elseif crypto_type == "eapi" then
        return self.crypto:eapi(path, data)
    end
    return data
end

return Client