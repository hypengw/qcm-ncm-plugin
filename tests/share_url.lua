package.path = 'src/?.lua;' .. package.path
local types = {Song = 101, Album = 51, Artist = 53, Mix = 54, Radio = 55}
package.preload['qcm.mod'] = function()
    return {inner = {id = 7, device_id = function() return 'test' end,
        new_session_id = function() return 'scope' end},
        crypto = {}, enum = {ItemType = types, SyncState = {}}}
end
package.preload.json = function() return {} end
package.preload.crypto = function() return {} end
package.preload.client = function()
    return {new = function() return {perform = function() error('share URL must not request network') end} end}
end
local provider = require('provider')
for kind, path in pairs{Song = 'song', Album = 'album', Artist = 'artist', Mix = 'playlist'} do
    assert(provider.share_url('123', types[kind]) == 'https://music.163.com/' .. path .. '?id=123')
    assert(provider.share_url('000123', types[kind]) == 'https://music.163.com/' .. path .. '?id=123')
    assert(provider.share_url('9007199254740993', types[kind]) == 'https://music.163.com/' .. path .. '?id=9007199254740993')
    for _, id in ipairs{'', '0', '0000', '-1', '1.5', '1&token=secret', '1#fragment', 'recommend/daily', 'roaming/123'} do
        assert(provider.share_url(id, types[kind]) == nil)
    end
    assert(provider.share_url(123, types[kind]) == nil)
    assert(provider.share_url(nil, types[kind]) == nil)
end
assert(provider.share_url('123', types.Radio) == nil)
assert(provider.share_url('123', 0) == nil)
print('share URLs: entity routes, precise IDs, unsupported sources and invalid input passed')
