currentChatType = 'Normal'

function PERSISTENTCHAT_ON_INIT()
    if _G['ui'].ProcessReturnKey_OLD == nil then
        _G['ui'].ProcessReturnKey_OLD = _G['ui'].ProcessReturnKey;
    end
    _G['ui'].ProcessReturnKey = ui.ProcessReturnKey_HOOKED;
end

function ui.ProcessReturnKey_HOOKED()
    chatTypes = {Shout = 1, Party = 2, Guild = 3, Normal = 4}

    local frame = ui.GetFrame('chat');
    local titleCtrl = GET_CHILD(frame,'edit_to_bg');
    local name  = GET_CHILD(titleCtrl,'title_to');

    if currentChatType ~= name:GetText() and frame:IsVisible() == 0 then
        ui.SetChatType(chatTypes[currentChatType])
    end
    currentChatType = name:GetText()
    _G['ui'].ProcessReturnKey_OLD();
end
