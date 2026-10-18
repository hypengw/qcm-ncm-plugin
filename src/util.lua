local M = {}

function M.positive_id(value)
    if math.type(value) == 'integer' and value > 0 then return tostring(value) end
    assert(type(value) == 'string' and value:match('^%d+$'), 'invalid positive ID')
    value = value:gsub('^0+', '')
    assert(value ~= '', 'invalid positive ID')
    return value
end

function M.array(value)
    assert(type(value) == 'table', 'expected an array')
    local size = #value
    for key in pairs(value) do
        assert(math.type(key) == 'integer' and key >= 1 and key <= size, 'expected an array')
    end
    for i = 1, size do assert(value[i] ~= nil, 'expected an array') end
    return value
end

function M.extract_image_id(url)
    return string.match(url, "/(%d+)%.(%a+)$")
end
assert('109951164111703663' == M.extract_image_id('https://p1.music.126.net/5JLQMl8xASllDubCWb9WHw==/109951164111703663.jpg'))
assert('18686200114669622' == M.extract_image_id('http://p2.music.126.net/VnZiScyynLG7atLIZ2YPkw==/18686200114669622.jpg'))

return M
