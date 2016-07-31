currentChatType = 1

function PERSISTENTCHAT_ON_INIT()
    if _G['ui'].ProcessReturnKey_OLD == nil then
        _G['ui'].ProcessReturnKey_OLD = _G['ui'].ProcessReturnKey;
    end
    _G['ui'].ProcessReturnKey = ui.ProcessReturnKey_HOOKED;
end

function ui.ProcessReturnKey_HOOKED()
    local frame = ui.GetFrame('chat')
    local chattype_frame = ui.GetFrame('chattypelist')
    local name = config.GetConfig('ChatTypeNumber')

    if currentChatType ~= name and frame:IsVisible() == 0 and currentChatType ~= 5 then
        config.SetConfig('ChatTypeNumber',currentChatType)
        ui.SetChatType(currentChatType-1)
    end
    currentChatType = name
    _G['ui'].ProcessReturnKey_OLD();
end