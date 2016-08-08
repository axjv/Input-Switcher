local acutil = require('acutil')

function BATTLEMODE_ON_INIT()
    acutil.slashCommand('bm',TOGGLE_BATTLE_MODE)
    battleModeStatus = 0
    addon:RegisterMsg('FPS_UPDATE','CREATE_BATTLE_MODE_FRAME')
end
focusedFrames = {}
battleframe = nil

function CREATE_BATTLE_MODE_FRAME()
    battleframe = ui.GetFrame('BATTLEMODE_FRAME')
    if battleframe == nil then
        battleframe = ui.CreateNewFrame('bandicam','BATTLEMODE_FRAME')
        UPDATE_BATTLE_MODE()
    end
    return battleframe
end

function UPDATE_FRAME_HITTEST()
    local curFrame = ui.GetFocusFrame()
    if curFrame ~= nil then
        if focusedFrames[curFrame:GetName()] == nil then
            focusedFrames[curFrame:GetName()] = curFrame:IsEnableHitTest()
        end
        if curFrame:GetName() ~= 'buff' then
            curFrame:EnableHitTest(0)
        end
    end
end

function TOGGLE_BATTLE_MODE()
    battleModeStatus = math.abs(battleModeStatus-1)
    UPDATE_BATTLE_MODE()
    if battleModeStatus == 0 then
        CHAT_SYSTEM('Battle mode off')
    else
        CHAT_SYSTEM('Battle mode on')
    end
end

function UPDATE_BATTLE_MODE()
    battleframe = CREATE_BATTLE_MODE_FRAME()
    BATTLEMODE_TIMER = GET_CHILD(battleframe, "addontimer", "ui::CAddOnTimer");
        if battleModeStatus == 0 then
        BATTLEMODE_TIMER:Stop()
        for k,v in pairs(focusedFrames) do
            local hitTestFrame = ui.GetFrame(k)
            if hitTestFrame ~= nil then
                local val
                if v == true then val = 1 else val = 0 end
                hitTestFrame:EnableHitTest(1)
            end
        end
        focusedFrames = {}
    else
        BATTLEMODE_TIMER:SetUpdateScript('UPDATE_FRAME_HITTEST');
        BATTLEMODE_TIMER:EnableHideUpdate(1)
        BATTLEMODE_TIMER:Stop();
        BATTLEMODE_TIMER:Start(0.1);
    end
end
