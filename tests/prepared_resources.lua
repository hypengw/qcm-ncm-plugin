local calls = 0
local sent = {}
local function builder(url)
    local request = {url = url}
    function request:stream(options)
        self.timeout = options.headers_timeout_ms
        return self
    end
    function request:headers(headers)
        self.request_headers = headers
        return self
    end
    function request:send()
        sent[#sent + 1] = self
        return self
    end
    return request
end
package.preload.client = function()
    return {new = function()
        return {perform = function()
            calls = calls + 1
            return {data = {{url = 'https://example.invalid/signed-audio'}}}
        end}
    end}
end
package.preload.json = function() return {} end
package.preload.crypto = function() return {encrypt_id = tostring} end
package.preload['api.song.enhance.player.url.v1'] = function()
    return {new = function(id) return {id = id} end}
end
package.preload['qcm.mod'] = function()
    return {
        inner = {device_id = function() return 'test' end},
        crypto = {}, enum = {ItemType = {}, SyncState = {}},
        get_http_client = function() return {get = function(_, url) return builder(url) end} end,
    }
end
local provider = dofile(arg[1] or 'src/provider.lua')
local audio = provider.prepare_audio('123')
assert(calls == 1 and #sent == 0)
assert(audio.url == 'https://example.invalid/signed-audio' and audio.timeout == 30000)
local image = provider.prepare_image('123', '456', 'Primary')
assert(image.url:match('/456.jpg%?param=400x400$') and image.timeout == 30000)
assert(#sent == 0)
local response = provider.audio('123', {Range = 'bytes=0-255'})
assert(calls == 2 and #sent == 1 and response.request_headers.Range == 'bytes=0-255')
print('prepared resource tests passed')
