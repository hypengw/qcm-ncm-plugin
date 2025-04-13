local provider = {}

-- Store provider state
local state = {
    base_url = nil,
    token = nil,
    device_id = "lua-provider"
}

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
end

function provider.sync()
end

function provider.image(item_id, image_type)
end

function provider.audio(item_id)
end

return provider
