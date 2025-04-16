-- Miscellaneous implementations of Netease's security algorithms
local bit = require("bit")
local json = require("cjson")
local md5 = require("md5")
-- local socket = require("socket")
-- local urllib = require("socket.url")

local BASE62 = 'PJArHa0dpwhvMNYqKnTbitWfEmosQ9527ZBx46IXUgOzD81VuSFyckLRljG3eC'
local BASE64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- Constants
local WEAPI_WATCHMAN_PAD = 5
local WEAPI_WATCHMAN_SBOX = 'LPc4uQNptC2A6y.R90DOBIroS+qnx/eb3FM8fW1UZG7VmwvksgjhaTKzlXdiYEHJ'
local WEAPI_WATCHMAN_KEY = {31, 125, -12, 60, 32, 48}
local WEAPI_WATCHMAN_SALT_1 = 'dAWsBhCqtOaNLLJ25hBzWbqWXwiK99Wd'
local WEAPI_WATCHMAN_SALT_2 = 'WoeTpXnDDPhiAvsJUUIY3RdAo2PKaVwi'
local WEAPI_WATCHMAN_DID = 'Eyj1ZVEWep5ERQEFFVMuN0xNxLvKykXT'

-- Add abroad encryption constants
local WEAPI_ABROAD_SBOX = {82, 9, 106, -43, 48, 54, -91, 56, -65, 64, -93, -98, -127, -13, -41, -5, 124, -29, 57, -126, -101, 47, -1, -121, 52, -114, 67, 68, -60, -34, -23, -53, 84, 123, -108, 50, -90, -62, 35, 61, -18, 76, -107, 11, 66, -6, -61, 78, 8, 46, -95, 102, 40, -39, 36, -78, 118, 91, -94, 73, 109, -117, -47, 37, 114, -8, -10, 100, -122, 104, -104, 22, -44, -92, 92, -52, 93, 101, -74, -110, 108, 112, 72, 80, -3, -19, -71, -38, 94, 21, 70, 87, -89, -115, -99, -124, -112, -40, -85, 0, -116, -68, -45, 10, -9, -28, 88, 5, -72, -77, 69, 6, -48, 44, 30, -113, -54, 63, 15, 2, -63, -81, -67, 3, 1, 19, -118, 107, 58, -111, 17, 65, 79, 103, -36, -22, -105, -14, -49, -50, -16, -76, -26, 115, -106, -84, 116, 34, -25, -83, 53, -123, -30, -7, 55, -24, 28, 117, -33, 110, 71, -15, 26, 113, 29, 41, -59, -119, 111, -73, 98, 14, -86, 24, -66, 27, -4, 86, 62, 75, -58, -46, 121, 32, -102, -37, -64, -2, 120, -51, 90, -12, 31, -35, -88, 51, -120, 7, -57, 49, -79, 18, 16, 89, 39, -128, -20, 95, 96, 81, 127, -87, 25, -75, 74, 13, 45, -27, 122, -97, -109, -55, -100, -17, -96, -32, 59, 77, -82, 42, -11, -80, -56, -21, -69, 60, -125, 83, -103, 97, 23, 43, 4, 126, -70, 119, -42, 38, -31, 105, 20, 99, 85, 33, 12, 125}
local WEAPI_ABROAD_KEY = 'fuck~#$%^&*(458'
local WEAPI_ABROAD_IV = {} -- Will be filled on initialization

-- Initialize WEAPI_ABROAD_IV
do
    local keyBytes = {string.byte(WEAPI_ABROAD_KEY, 1, #WEAPI_ABROAD_KEY)}
    for i = 1, 64 do
        WEAPI_ABROAD_IV[i] = keyBytes[(i-1) % #keyBytes + 1]
    end
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

local function HexDigest(data)
    local result = {}
    for i = 1, #data do
        table.insert(result, string.format("%02x", data:byte(i)))
    end
    return table.concat(result)
end

local function HexCompose(hexstr)
    local result = {}
    for i = 1, #hexstr, 2 do
        table.insert(result, string.char(tonumber(hexstr:sub(i, i+1), 16)))
    end
    return table.concat(result)
end

local function HashDigest(text)
    return md5.sum(text)
end

local function HashHexDigest(text)
    return HexDigest(HashDigest(text))
end

-- JavaScript bit operation mimics
local function jint(v)
    return bit.tobit(v)
end

local function jls(v, bs)
    return bit.lshift(v, bit.band(bs, 0x1F))
end

local function jrs(v, bs)
    return bit.rshift(v, bit.band(bs, 0x1F))
end

local function jmask(v)
    return bit.band(v, 0xFFFFFFFF)
end

local function jxor(v1, v2)
    return jint(bit.bxor(jmask(v1), jmask(v2)))
end

-- String conversion functions
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
    local high = bit.rshift(bit.band(e, 0xF0), 4) + 1
    local low = bit.band(e, 0x0F) + 1
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
    result[1] = cast_to_signed(bit.rshift(b, 24) % 256)
    result[2] = cast_to_signed(bit.rshift(b, 16) % 256)
    result[3] = cast_to_signed(bit.rshift(b, 8) % 256)
    result[4] = cast_to_signed(b % 256)
    return result
end

-- Watchman security functions
local function wm_xor_cipher_La(e)
    local d = WEAPI_WATCHMAN_KEY
    e = string_to_charcodes(e)
    local g = {}
    for q = 1, #e do
        local val = cast_to_signed(jxor(e[q], d[(q-1) % #d + 1]))
        table.insert(g, cast_to_signed(-val))
    end
    return HexDigest(string.char(table.unpack(g)))
end

local function wm_pbox_ga(e, c, d, r, g)
    for h = 1, g do
        d[r + h] = e[c + h]
    end
end

local function wm_sbox_Qb(e, c, d, r, g)
    g = tostring(g or WEAPI_WATCHMAN_PAD)
    r = r or WEAPI_WATCHMAN_SBOX
    local h, m = 0, {}
    
    if d == 1 then
        d = e[c]
        h = 0
        table.insert(m, r[bit.rshift(d, 2) % 64 + 1])
        table.insert(m, r[bit.bor(bit.lshift(d, 4) % 48, bit.rshift(h, 4) % 15) + 1])
        table.insert(m, g)
        table.insert(m, g)
    elseif d == 2 then
        d = e[c]
        h = e[c + 1]
        local e = 0
        table.insert(m, r[bit.rshift(d, 2) % 64 + 1])
        table.insert(m, r[bit.bor(bit.lshift(d, 4) % 48, bit.rshift(h, 4) % 15) + 1])
        table.insert(m, r[bit.bor(bit.lshift(h, 2) % 60, bit.rshift(e, 6) % 3) + 1])
        table.insert(m, g)
    elseif d == 3 then
        d = e[c]
        h = e[c + 1]
        e = e[c + 2]
        table.insert(m, r[bit.rshift(d, 2) % 64 + 1])
        table.insert(m, r[bit.bor(bit.lshift(d, 4) % 48, bit.rshift(h, 4) % 15) + 1])
        table.insert(m, r[bit.bor(bit.lshift(h, 2) % 60, bit.rshift(e, 6) % 3) + 1])
        table.insert(m, r[e % 64 + 1])
    end
    return table.concat(m)
end

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

local function wm_generate_OTP_b()
    local e = math.floor(socket.gettime() * 1000)
    local c = math.floor(e / 4294967296)
    local d = e % 4294967296
    local e = cast_to_multi_signed(c)
    local d = cast_to_multi_signed(d)
    local c = {}
    for i = 1, 8 do c[i] = 0 end
    
    wm_pbox_ga(e, 0, c, 0, 4)
    wm_pbox_ga(d, 0, c, 4, 4)
    local d = {}
    for i = 1, 8 do d[i] = 0 end
    local e = {}
    for i = 1, 16 do e[i] = 0 end
    
    for g = 0, 15 do
        if g % 2 == 0 then
            local f = math.floor(g / 2) + 1
            e[g + 1] = bit.bor(
                e[g + 1],
                bit.rshift(bit.band(d[f], 16), 4),
                bit.rshift(bit.band(d[f], 32), 3),
                bit.rshift(bit.band(d[f], 64), 2),
                bit.rshift(bit.band(d[f], 128), 1),
                bit.rshift(bit.band(c[f], 16), 3),
                bit.rshift(bit.band(c[f], 32), 2),
                bit.rshift(bit.band(c[f], 64), 1),
                bit.band(c[f], 128)
            )
        else
            local f = math.floor(g / 2) + 1
            e[g + 1] = bit.bor(
                e[g + 1],
                bit.lshift(bit.band(d[f], 1), 0),
                bit.lshift(bit.band(d[f], 2), 1),
                bit.lshift(bit.band(d[f], 4), 2),
                bit.lshift(bit.band(d[f], 8), 3),
                bit.lshift(bit.band(c[f], 1), 1),
                bit.lshift(bit.band(c[f], 2), 2),
                bit.lshift(bit.band(c[f], 4), 3),
                bit.lshift(bit.band(c[f], 8), 4)
            )
        end
        e[g + 1] = cast_to_signed(e[g + 1])
    end
    
    c = HexDigest(string.char(table.unpack(e)))
    c = HashHexDigest(c .. WEAPI_WATCHMAN_SALT_1)
    c = HexCompose(string.sub(c, 1, 16))
    c = wm_apply_sbox_Sb(string_to_charcodes(c .. string.char(table.unpack(e))), BASE64)
    return c
end

local function wm_generate_config_chiper_bc(c, f, g)
    f = f or 1
    g = g or WEAPI_WATCHMAN_DID
    local t = f .. g .. c .. WEAPI_WATCHMAN_SALT_2
    local hash = HashDigest(t)
    local config = {
        r = f,
        d = g,
        b = c,
        t = "placeholder" -- Actual implementation would compute this
    }
    return wm_xor_cipher_La(json.encode(config))
end

-- Abroad decryption functions
local function c_signed_xor(v1, v2)
    return jxor(cast_to_signed(v1), cast_to_signed(v2))
end

local function c_apply_sbox(src, map)
    local result = {}
    for _, i in ipairs(src) do
        local idx = bit.bor(bit.lshift(bit.rshift(i, 4) % 15, 4), bit.band(i, 15)) + 1
        table.insert(result, map[idx])
    end
    return result
end

local function c_decrypt_abroad_message(hexstring)
    local source = {}
    for i = 1, #hexstring, 2 do
        local byte = tonumber(hexstring:sub(i, i+1), 16)
        table.insert(source, byte)
    end
    
    local result = {}
    for i = 1, #source, 64 do
        local box = {}
        for j = 1, 64 do
            if source[i+j-1] then
                box[j] = source[i+j-1]
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

-- Export functions
return {
    generate_config_chiper = wm_generate_config_chiper_bc,
    generate_OTP = wm_generate_OTP_b,
    RandomString = RandomString,
    HashDigest = HashDigest,
    HashHexDigest = HashHexDigest,
    HexDigest = HexDigest,
    HexCompose = HexCompose,
    decrypt_abroad = c_decrypt_abroad_message
}