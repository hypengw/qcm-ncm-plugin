-- Miscellaneous implementations of Netease's security algorithms
local json = require("cjson")
local md5 = require("md5")
local socket = require("socket")
-- local urllib = require("socket.url")
-- checkToken: "9ca17ae2e6ffcda170e2e6eeccd180f68ff894e86188b88eb2c85e928f8fb0d26f819f9aa9f568f3a6ff9ad82af0feaec3b92a9baeaa94ce5c96b997acb45f979a8bb2c15fa68cafb4c45a8f878fd7f33ff7f1ee9e"

local BASE62 = 'PJArHa0dpwhvMNYqKnTbitWfEmosQ9527ZBx46IXUgOzD81VuSFyckLRljG3eC'
local BASE64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- Constants
local WEAPI_WATCHMAN_PAD = 5
local WEAPI_WATCHMAN_SBOX = 'LPc4uQNptC2A6y.R90DOBIroS+qnx/eb3FM8fW1UZG7VmwvksgjhaTKzlXdiYEHJ'
local WEAPI_WATCHMAN_KEY = { 31, 125, -12, 60, 32, 48 }
local WEAPI_WATCHMAN_SALT_1 = 'dAWsBhCqtOaNLLJ25hBzWbqWXwiK99Wd'
local WEAPI_WATCHMAN_SALT_2 = 'WoeTpXnDDPhiAvsJUUIY3RdAo2PKaVwi'
local WEAPI_WATCHMAN_DID = 'Eyj1ZVEWep5ERQEFFVMuN0xNxLvKykXT'

-- Add abroad encryption constants
local WEAPI_ABROAD_SBOX = { 82, 9, 106, -43, 48, 54, -91, 56, -65, 64, -93, -98, -127, -13, -41, -5, 124, -29, 57, -126, -101, 47, -1, -121, 52, -114, 67, 68, -60, -34, -23, -53, 84, 123, -108, 50, -90, -62, 35, 61, -18, 76, -107, 11, 66, -6, -61, 78, 8, 46, -95, 102, 40, -39, 36, -78, 118, 91, -94, 73, 109, -117, -47, 37, 114, -8, -10, 100, -122, 104, -104, 22, -44, -92, 92, -52, 93, 101, -74, -110, 108, 112, 72, 80, -3, -19, -71, -38, 94, 21, 70, 87, -89, -115, -99, -124, -112, -40, -85, 0, -116, -68, -45, 10, -9, -28, 88, 5, -72, -77, 69, 6, -48, 44, 30, -113, -54, 63, 15, 2, -63, -81, -67, 3, 1, 19, -118, 107, 58, -111, 17, 65, 79, 103, -36, -22, -105, -14, -49, -50, -16, -76, -26, 115, -106, -84, 116, 34, -25, -83, 53, -123, -30, -7, 55, -24, 28, 117, -33, 110, 71, -15, 26, 113, 29, 41, -59, -119, 111, -73, 98, 14, -86, 24, -66, 27, -4, 86, 62, 75, -58, -46, 121, 32, -102, -37, -64, -2, 120, -51, 90, -12, 31, -35, -88, 51, -120, 7, -57, 49, -79, 18, 16, 89, 39, -128, -20, 95, 96, 81, 127, -87, 25, -75, 74, 13, 45, -27, 122, -97, -109, -55, -100, -17, -96, -32, 59, 77, -82, 42, -11, -80, -56, -21, -69, 60, -125, 83, -103, 97, 23, 43, 4, 126, -70, 119, -42, 38, -31, 105, 20, 99, 85, 33, 12, 125 }
local WEAPI_ABROAD_KEY = 'fuck~#$%^&*(458'
local WEAPI_ABROAD_IV = {} -- Will be filled on initialization

-- Initialize WEAPI_ABROAD_IV
do
    local keyBytes = { string.byte(WEAPI_ABROAD_KEY, 1, #WEAPI_ABROAD_KEY) }
    for i = 1, 64 do
        WEAPI_ABROAD_IV[i] = keyBytes[(i - 1) % #keyBytes + 1]
    end
end

-- String conversion functions
---@param e string | table<integer>
---@return table<integer>
local function string_to_charcodes(e)
    if type(e) == "string" then
        local result = {}
        for i = 1, #e do
            table.insert(result, e:byte(i))
        end
        return result
    end
    return e
end

local function char_to_hex(e)
    local c = "0123456789abcdef"
    local high = ((e & 0xF0) >> 4) + 1
    local low = (e & 0x0F) + 1
    return c:sub(high, high) .. c:sub(low, low)
end

local function cast_to_signed(e)
    if e < -128 then
        return cast_to_signed(e + 256)
    elseif e >= -128 and e <= 127 then
        return e
    else
        return cast_to_signed(e - 256)
    end
end

local function cast_to_multi_signed(b)
    local result = {}
    result[1] = cast_to_signed((b >> 24) % 256)
    result[2] = cast_to_signed((b >> 16) % 256)
    result[3] = cast_to_signed((b >> 8) % 256)
    result[4] = cast_to_signed(b % 256)
    return result
end

-- Helper functions
local function RandomString(len, chars)
    chars = chars or BASE62
    local result = {}
    for i = 1, len do
        local rand = math.random(1, #chars)
        table.insert(result, chars:sub(rand, rand))
    end
    return table.concat(result)
end

---@param data table<integer> | string
---@return string
local function ints_to_hex(data)
    local result = {}
    local get = function(i)
        return data[i]
    end
    if type(data) == "string" then
        get = function(i)
            return string.byte(data, i)
        end
    end

    for i = 1, #data do
        table.insert(result, char_to_hex(get(i)))
    end
    return table.concat(result)
end

---@param hexstr string
---@return table<integer>
local function hex_to_ints_hb(hexstr)
    local result = {}
    for i = 1, #hexstr, 2 do
        table.insert(result, cast_to_signed(tonumber(hexstr:sub(i, i + 1), 16)))
    end
    return result
end

---@param text string
---@return string
local function wm_hash(text)
    return md5.sum(text)
end

local function wm_hexhash(text)
    return ints_to_hex(wm_hash(text))
end

-- Watchman security functions
local function wm_xor_cipher_La(e)
    local d = WEAPI_WATCHMAN_KEY
    e = string_to_charcodes(e)
    local g = {}
    for q = 1, #e do
        local l1 = e[q]
        local l2 = (d[(q - 1) % #d + 1]);
        local val = cast_to_signed((l1 ~ l2))
        table.insert(g, cast_to_signed(-val))
    end
    return ints_to_hex(g)
end

local function wm_pbox_ga(e, c, d, r, g)
    for h = 1, g do
        d[r + h] = e[c + h]
    end
end

---@param e table<integer>
---@param c integer
---@param d integer
---@param r string
---@param g integer | string
local function wm_sbox_Qb(e, c, d, r, g)
    g = tostring(g or WEAPI_WATCHMAN_PAD)
    r = r or WEAPI_WATCHMAN_SBOX
    local h = 0
    local m = {}

    if d == 1 then
        d = e[c]
        h = 0
        table.insert(m, string.byte(r, (d >> 2) % 64 + 1))
        table.insert(m, string.byte(r, ((d << 4) % 48 | (h >> 4) % 15) + 1))
        table.insert(m, g)
        table.insert(m, g)
    elseif d == 2 then
        d = e[c]
        h = e[c + 1]
        local e = 0
        table.insert(m, string.byte(r, (d >> 2) % 64 + 1))
        table.insert(m, string.byte(r, ((d << 4) % 48 | (h >> 4) % 15) + 1))
        table.insert(m, string.byte(r, ((h << 2) % 60 | (e >> 6) % 3) + 1))
        table.insert(m, g)
    elseif d == 3 then
        d = e[c]
        h = e[c + 1]
        e = e[c + 2]
        table.insert(m, string.byte(r, (d >> 2) % 64 + 1))
        table.insert(m, string.byte(r, ((d << 4) % 48 | (h >> 4) % 15) + 1))
        table.insert(m, string.byte(r, ((h << 2) % 60 | (e >> 6) % 3) + 1))
        table.insert(m, string.byte(r, e % 64 + 1))
    end
    return string.char(table.unpack(m))
end

---@param e table<integer>
---@param c string
---@param d? integer
local function wm_apply_sbox_Sb(e, c, d)
    c = c or {}
    d = d or WEAPI_WATCHMAN_PAD
    local r = 3
    local h = 1
    local g = {}

    while h <= #e do
        if h + r <= #e then
            table.insert(g, wm_sbox_Qb(e, h, r, c, d))
            h = h + r
        else
            table.insert(g, wm_sbox_Qb(e, h, #e - h + 1, c, d))
            break
        end
    end
    return table.concat(g)
end

---@param a string | table<integer>
---@return string
local function wm_map_string_Tb(a)
    a = string_to_charcodes(a)
    return wm_apply_sbox_Sb(a, BASE64, string.byte('='))
end

local function wm_generate_OTP_b()
    local e = math.floor(socket.gettime() * 1000)
    local c = math.floor(e / 4294967296)
    local d = e % 4294967296
    local e = cast_to_multi_signed(c)
    local d = cast_to_multi_signed(d)
    ---@type table<integer>
    local c = {}
    for i = 1, 8 do c[i] = 0 end

    wm_pbox_ga(e, 0, c, 0, 4)
    wm_pbox_ga(d, 0, c, 4, 4)
    ---@type table<integer>
    local d = {}
    for i = 1, 8 do d[i] = 0 end

    ---@type table<integer>
    local e = {}
    for i = 1, 16 do e[i] = 0 end
    for g = 0, 15 do
        if g % 2 == 0 then
            local f = math.floor(g / 2) + 1
            e[g + 1] = (
                ((d[f] & 16) >> 4) |
                ((d[f] & 32) >> 3) |
                ((d[f] & 64) >> 2) |
                ((d[f] & 128) >> 1) |
                ((c[f] & 16) >> 3) |
                ((c[f] & 32) >> 2) |
                ((c[f] & 64) >> 1) |
                (c[f] & 128)
            )
        else
            local f = math.floor(g / 2) + 1
            e[g + 1] = (
                ((d[f] & 1) << 0) |
                ((d[f] & 2) << 1) |
                ((d[f] & 4) << 2) |
                ((d[f] & 8) << 3) |
                ((c[f] & 1) << 1) |
                ((c[f] & 2) << 2) |
                ((c[f] & 4) << 3) |
                ((c[f] & 8) << 4)
            )
        end
        e[g + 1] = cast_to_signed(e[g + 1])
    end
    local c_str = ints_to_hex(e)
    c_str = wm_hexhash(c_str .. WEAPI_WATCHMAN_SALT_1)
    c = hex_to_ints_hb(string.sub(c_str, 1, 16))
    table.move(e, 1, #e, #c + 1, c)
    return wm_map_string_Tb(c)
end

--[[
​b: "TpG3L9ZskXdEERUVUVeTaHBVlHngFuLJ"
d: "+Rt6Q8sekDhBQEVRQAOSeCAVHvl1z1yU"
r: 1
t: "K1zLQUbIYmyQZb8tG566pA=="
]]

local function wm_generate_config_chiper_bc(c, f, g)
    f = f or 1
    g = g or WEAPI_WATCHMAN_DID
    local t = f .. g .. c .. WEAPI_WATCHMAN_SALT_2
    t = wm_hash(t)
    print("t:" .. t)
    local config = {
        r = f,
        d = g,
        b = c,
        t = wm_map_string_Tb(t)
    }
    return wm_xor_cipher_La(json.encode(config))
end

-- Abroad decryption functions
local function c_signed_xor(v1, v2)
    return cast_to_signed(v1) ~ cast_to_signed(v2)
end

local function c_apply_sbox(src, map)
    local result = {}
    for _, i in ipairs(src) do
        local idx = (((i >> 4) % 15) << 4) | (i & 15) + 1
        table.insert(result, map[idx])
    end
    return result
end

local function c_decrypt_abroad_message(hexstring)
    local source = {}
    for i = 1, #hexstring, 2 do
        local byte = tonumber(hexstring:sub(i, i + 1), 16)
        table.insert(source, byte)
    end

    local result = {}
    for i = 1, #source, 64 do
        local box = {}
        for j = 1, 64 do
            if source[i + j - 1] then
                box[j] = source[i + j - 1]
            end
        end

        local boxB = c_apply_sbox(c_apply_sbox(box, WEAPI_ABROAD_SBOX), WEAPI_ABROAD_SBOX)
        local boxC = {}
        local boxD = {}
        local boxE = {}

        for j = 1, #box do
            boxC[j] = c_signed_xor(boxB[j], WEAPI_ABROAD_IV[j])
            boxD[j] = cast_to_signed(boxC[j] + cast_to_signed(-WEAPI_ABROAD_IV[j]))
            boxE[j] = c_signed_xor(boxD[j], WEAPI_ABROAD_IV[j])
        end

        for j = 1, #box do
            WEAPI_ABROAD_IV[j] = box[j]
        end

        for j = 1, #boxE do
            table.insert(result, boxE[j])
        end
    end

    -- Remove last 4 bytes (length info)
    for i = 1, 4 do table.remove(result) end

    -- Convert to URL-encoded hex string and decode
    local hex = table.concat(result, function(b) return '%' .. char_to_hex(b) end)
    return (urllib.unescape(hex):gsub('\0+$', ''))
end

local function xor_encode(input)
    local d = WEAPI_WATCHMAN_KEY
    local e = string_to_charcodes(input)
    local g = {}
    for i = 1, #e do
        local xored = e[i] ~ d[(i - 1) % #d + 1]
        local signed = cast_to_signed(xored)
        g[i] = cast_to_signed(-signed)
    end
    return ints_to_hex(g)
end


local function test()
    local otp = wm_generate_OTP_b();
    print('otp: ' .. otp)
    print(wm_generate_config_chiper_bc(otp))
end

-- Export functions
return {
    generate_config_chiper = wm_generate_config_chiper_bc,
    generate_OTP = wm_generate_OTP_b,
    xor_encode = xor_encode,
    decrypt_abroad = c_decrypt_abroad_message
}
