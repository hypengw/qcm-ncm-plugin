local provider = {}
local Client = require('client')

local inner = qcm.inner
local client = Client.new(inner:device_id())

--function provider.from_model(custom_data)
--    local data = json.decode(custom_data)
--    state.base_url = data.base_url
--    state.token = data.token
--end
--
--function provider.to_model()
--    return json.encode({
--        base_url = state.base_url,
--        token = state.token
--    })
--end

function provider.login(auth_info)
    local Api = require('api.login')
    local res = client:perform(Api.new("ttt", "mmmm"), 30)
    error("something went wrong: " .. res.code .. res.text)
end

function provider.sync()
end

function provider.image(item_id, image_type)
end

function provider.audio(item_id)
end

return provider
