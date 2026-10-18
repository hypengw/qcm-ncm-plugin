local M = {}

local modes = {
    {value = 'DEFAULT', name = '默认模式', description = '沿着目前喜好继续聆听'},
    {value = 'FAMILIAR', name = '熟悉模式', description = '喜欢过的歌曲与相似推荐'},
    {value = 'EXPLORE', name = '探索模式', description = '多元曲风与小众佳作'},
}

function M.configuration(native_id)
    if native_id ~= 'roaming/fm' then return {} end
    return {{key = 'mode', name = '推荐模式', value = 'DEFAULT', options = modes}}
end

function M.mode(native_id, configuration)
    configuration = configuration or {}
    for key in pairs(configuration) do
        assert(native_id == 'roaming/fm' and key == 'mode', 'unsupported radio configuration: ' .. key)
    end
    local mode = configuration.mode or 'DEFAULT'
    for _, option in ipairs(modes) do
        if option.value == mode then return mode end
    end
    error('unsupported roaming mode: ' .. tostring(mode))
end

return M
