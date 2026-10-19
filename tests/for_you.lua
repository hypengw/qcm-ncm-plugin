package.path = 'src/?.lua;' .. package.path
local null = {}
local calls = 0
package.preload['qcm.mod'] = function()
    return {null = null, inner = {id = 7, device_id = function() return 'test' end,
        new_session_id = function() return 'scope' end}, crypto = {}, enum = {ItemType = {}, SyncState = {}}}
end
package.preload.json = function() return {} end
package.preload.crypto = function() return {} end
package.preload.client = function()
    return {new = function() return {perform = function() calls = calls + 1; error('metadata requested network') end} end}
end
local provider = require('provider')
local ctx = setmetatable({libraries = function() return {{library_id = 9}} end}, {
    __index = function(_, key) error('unexpected metadata context method ' .. key) end,
})
local entries = provider.for_you_items(ctx)
assert(#entries == 4 and calls == 0)
assert(entries[1].entry_key == 'daily' and entries[1].target.native_id == 'recommend/daily')
assert(entries[1].target.library_id == 9 and entries[1].target.type == 'Mix')
assert(entries[1].primary_action == 'OpenItem' and entries[1].play_action == 'PlayItem')
local radios = require('radio').entries()
assert(#radios == 10 and radios[3].native_id == 'heart/liked' and radios[3].name == '心动模式')
for i = 2, 4 do
    local entry = entries[i]
    assert(entry.target.native_id == radios[i-1].native_id and entry.target.library_id == null)
    assert(entry.presentation.style == 'Radio' and entry.presentation.cover.type == 'RadioCurrent')
    assert(entry.primary_action == 'ActivateRadio' and entry.play_action == 'ActivateRadio')
end
ctx.libraries = function() return {} end
assert(#provider.for_you_items(ctx) == 3 and calls == 0)
print('for_you: metadata, identities, order and actions passed')
