local M = {}

local WATCHMAN_KEY = { 31, 125, -12, 60, 32, 48 }
local WATCHMAN_SALT_1 = 'dAWsBhCqtOaNLLJ25hBzWbqWXwiK99Wd'
local WATCHMAN_SALT_2 = 'WoeTpXnDDPhiAvsJUUIY3RdAo2PKaVwi'
local WATCHMAN_DID = 'Eyj1ZVEWep5ERQEFFVMuN0xNxLvKykXT'

local ABROAD_SBOX = { 82, 9, 106, -43, 48, 54, -91, 56, -65, 64, -93, -98, -127, -13, -41, -5, 124, -29, 57, -126, -101, 47, -1, -121, 52, -114, 67, 68, -60, -34, -23, -53, 84, 123, -108, 50, -90, -62, 35, 61, -18, 76, -107, 11, 66, -6, -61, 78, 8, 46, -95, 102, 40, -39, 36, -78, 118, 91, -94, 73, 109, -117, -47, 37, 114, -8, -10, 100, -122, 104, -104, 22, -44, -92, 92, -52, 93, 101, -74, -110, 108, 112, 72, 80, -3, -19, -71, -38, 94, 21, 70, 87, -89, -115, -99, -124, -112, -40, -85, 0, -116, -68, -45, 10, -9, -28, 88, 5, -72, -77, 69, 6, -48, 44, 30, -113, -54, 63, 15, 2, -63, -81, -67, 3, 1, 19, -118, 107, 58, -111, 17, 65, 79, 103, -36, -22, -105, -14, -49, -50, -16, -76, -26, 115, -106, -84, 116, 34, -25, -83, 53, -123, -30, -7, 55, -24, 28, 117, -33, 110, 71, -15, 26, 113, 29, 41, -59, -119, 111, -73, 98, 14, -86, 24, -66, 27, -4, 86, 62, 75, -58, -46, 121, 32, -102, -37, -64, -2, 120, -51, 90, -12, 31, -35, -88, 51, -120, 7, -57, 49, -79, 18, 16, 89, 39, -128, -20, 95, 96, 81, 127, -87, 25, -75, 74, 13, 45, -27, 122, -97, -109, -55, -100, -17, -96, -32, 59, 77, -82, 42, -11, -80, -56, -21, -69, 60, -125, 83, -103, 97, 23, 43, 4, 126, -70, 119, -42, 38, -31, 105, 20, 99, 85, 33, 12, 125 }
local ABROAD_KEY = 'fuck~#$%^&*(458'
local ABROAD_IV = {
    0x66, 0x75, 0x63, 0x6b, 0x7e, 0x23, 0x24, 0x25, 0x5e, 0x26, 0x2a, 0x28, 0x34, 0x35, 0x38, 0x0a,
    0x66, 0x75, 0x63, 0x6b, 0x7e, 0x23, 0x24, 0x25, 0x5e, 0x26, 0x2a, 0x28, 0x34, 0x35, 0x38, 0x0a,
    0x66, 0x75, 0x63, 0x6b, 0x7e, 0x23, 0x24, 0x25, 0x5e, 0x26, 0x2a, 0x28, 0x34, 0x35, 0x38, 0x0a,
    0x66, 0x75, 0x63, 0x6b, 0x7e, 0x23, 0x24, 0x25, 0x5e, 0x26, 0x2a, 0x28, 0x34, 0x35, 0x38, 0x0a,
}

-- region Watchman.js security
local function wm_hash(e)
    return e
end
local function wm_hexhash(e)
    return e
end
local function wm_encode(e)
    -- encodeURIComponent() in watchman.js. not necessary though.
    return e
end
local function wm_unescape(e)
    -- since there's nothing escaped anyway...
    return e
end

-- common
local function string_to_charcodes(e)
    if type(e) == 'string' then
        local encoded = wm_encode(e)
        local t = {}
        for i = 1, #encoded do
            t[#t + 1] = encoded:byte(i)
        end
        return t
    else
        return e
    end
end

local function char_to_hex(e)
    local c = '0123456789abcdef'
    local high = e >> 4 & 0xF
    local low = e & 0xF
    return string.sub(c, high + 1, high + 1) .. string.sub(c, low + 1, low + 1)
end

local function to_hex_string(t)
    local out = {}
    for _, v in ipairs(t) do
        v = v & 0xFF
        table.insert(out, char_to_hex(v))
    end
    return table.concat(out)
end

local function cast_to_signed(e)
    if e < -128 then
        return cast_to_signed(e + 256)
    elseif e >= -128 and e <= 127 then
        return e
    elseif e > 127 then
        return cast_to_signed(e - 256)
    end
end

local function cast_to_multi_signed(b)
    return {
        cast_to_signed((b >> 24) & 0xFF),
        cast_to_signed((b >> 16) & 0xFF),
        cast_to_signed((b >> 8) & 0xFF),
        cast_to_signed(b & 0xFF),
    }
end


function M.xor_encode(input)
    local d = WATCHMAN_KEY
    local e = string_to_charcodes(input)
    local g = {}
    for i = 1, #e do
        local xored = e[i] ~ d[(i - 1) % #d + 1]
        local signed = cast_to_signed(xored)
        g[i] = cast_to_signed(-signed)
    end
    return to_hex_string(g)
end

return M