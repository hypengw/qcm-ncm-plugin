local M = {}

local qcm = require("qcm.mod")
local ssl = qcm.crypto;

local AES_IV = '0102030405060708'
local AES_KEY = '0CoJUm6Qyw8W8jud'
local RSA_PUB_KEY = [[-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDgtQn2JZ34ZC28NWYpAUd98iZ37BUrX/aKzmFbt7clFSs6sXqHauqKWqdtLkF2KexO40H1YTX8z2lSgBBOAxLsvaklV8k4cBFK9snQXE9/DDaFt6Rr7iVZMldczhC0JNgTz+SHXT6CBHuX3e9SdB1Ua44oncaTWz7OBGLbCiK45wIDAQAB
-----END PUBLIC KEY-----]]
local BASE62 = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
local EAPI_KEY = 'e82ckenh8dichen8'

local RSA = ssl.create_rsa(RSA_PUB_KEY)

function M.weapi(data)
    -- Generate random 16-byte string from BASE62
    local sec_key = ''
    for i = 1, 16 do
        local idx = math.random(1, 62)
        sec_key = sec_key .. string.sub(BASE62, idx, idx)
    end

    -- First encryption
    local first_enc = ssl.encrypt('aes-128-cbc', AES_KEY, AES_IV, data)
    local encoded = ssl.encode(first_enc)

    -- Second encryption
    local second_enc = ssl.encrypt('aes-128-cbc', sec_key, AES_IV, encoded)
    local params = ssl.encode(second_enc)

    -- Prepare sec_key for RSA encryption
    local sec_key_padding = sec_key .. string.rep('\0', 128 - #sec_key)
    local sec_key_rev = string.reverse(sec_key_padding)

    local enc_sec_key = ssl.hex.encode_low(RSA:encrypt(sec_key_rev))

    return {
        params = params,
        encSecKey = enc_sec_key
    }
end

function M.eapi(url, data)
    local message = 'nobody' .. url .. 'use' .. data .. 'md5forencrypt'
    local hash = ssl.hex.encode_low(ssl.digest('md5', message))

    local params = string.format('%s-36cd479b6b5-%s-36cd479b6b5-%s',
        url, data, hash)

    local encrypted = ssl.encrypt('aes-128-ecb', EAPI_KEY, AES_IV, params)
    local encoded = ssl.hex.encode_up(encrypted)

    return {
        params = encoded,
    }
end

--- order by key and concat like 'key1=value1&key2=value2'
local function buildQuery(params)
    local keys = {}
    for k in pairs(params) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        return utf8.codepoint(a) < utf8.codepoint(b)
    end)

    local parts = {}
    for _, k in ipairs(keys) do
        table.insert(parts, string.format('%s=%s', k, tostring(params[k])))
    end
    return table.concat(parts, '&')
end

function M.cache_key(params)
    local text = buildQuery(params)
    local key = ')(13daqP@ssw0rd~'
    return ssl.encode_block(ssl.encrypt('aes-128-ecb', key, '', text))
end

function M.encrypt_id(id)
    local magic = '3go8&$8*3*3h0k(2)2'

    if type(id) == 'number' then
        id = tostring(id)
    end

    local out = {}
    for i = 1, #id do
        local id_b = string.byte(id:sub(i, i))
        local magic_b = string.byte(magic, (i - 1) % #magic + 1)
        local xor_char = string.char(id_b ~ magic_b)
        table.insert(out, xor_char)
    end

    local joined = table.concat(out)

    local encoded = ssl.encode_block(ssl.digest('md5', joined))
    encoded = encoded:gsub("/", "_"):gsub("+", "-")
    return encoded
end

assert('5bLXRrbJWcwCFwNRHdA7MrRspVsq5SeyqPe/cDJQWIY=' == M.cache_key({
    id = 53320,
    e_r = true
}))

assert(M.encrypt_id(53320) == '-j--V46lIcBXqg1xAFvXBQ==')
assert(M.encrypt_id('109951164111703663') == '5JLQMl8xASllDubCWb9WHw==')

return M
