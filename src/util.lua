local M = {}

function M.extract_image_id(url)
    return string.match(url, "/(%d+)%.(%a+)$")
end
assert('109951164111703663' == M.extract_image_id('https://p1.music.126.net/5JLQMl8xASllDubCWb9WHw==/109951164111703663.jpg'))
assert('18686200114669622' == M.extract_image_id('http://p2.music.126.net/VnZiScyynLG7atLIZ2YPkw==/18686200114669622.jpg'))

return M
