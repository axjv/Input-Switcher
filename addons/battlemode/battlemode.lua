local acutil = require('acutil')
local default = {blacklist = {}}
local settings = {}


function BATTLEMODE_ON_INIT()

    acutil.slashCommand('bm',TOGGLE_BATTLE_MODE)
    battleModeStatus = 0
    addon:RegisterMsg('FPS_UPDATE','CREATE_BATTLE_MODE_FRAME')
    CHAT_SYSTEM('Battlemode loaded. Type /bm config to configure.')
end
focusedFrames = {}
battleframe = nil

function BATTLEMODE_LOADSETTINGS()
    local s, err = acutil.loadJSON("../addons/battlemode/settings.json");
    if err then
        settings = default
    else
        settings = s
        for k,v in pairs(default) do
            if s[k] == nil then
                settings[k] = v
            end
        end
    end
    BATTLEMODE_SAVESETTINGS()
end

function BATTLEMODE_SAVESETTINGS()
    acutil.saveJSON("../addons/battlemode/settings.json", settings);
end

function CREATE_BATTLE_MODE_FRAME()
    battleframe = ui.GetFrame('BATTLEMODE_FRAME')
    if battleframe == nil then
        battleframe = ui.CreateNewFrame('bandicam','BATTLEMODE_FRAME')
        UPDATE_BATTLE_MODE()
    end
    return battleframe
end

function SET_FRAME_HITTEST()
    for k,v in pairs(settings.blacklist) do
        local curFrameName = k
        local curFrame = ui.GetFrame(curFrameName)
        if curFrame ~= nil then
            if focusedFrames[curFrameName] == nil then
                focusedFrames[curFrameName] = curFrame:IsEnableHitTest()
            end
            curFrame:EnableHitTest(0)
        end
    end
end

function UPDATE_FRAME_HITTEST()
    local curFrame = ui.GetFocusFrame()
    if curFrame ~= nil then
        if focusedFrames[curFrame:GetName()] == nil then
            focusedFrames[curFrame:GetName()] = curFrame:IsEnableHitTest()
        end
        if settings.blacklist[curFrame:GetName()] ~= nil then
            curFrame:EnableHitTest(0)
        end
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
        SET_FRAME_HITTEST()
        BATTLEMODE_TIMER:SetUpdateScript('UPDATE_FRAME_HITTEST');
        BATTLEMODE_TIMER:EnableHideUpdate(1)
        BATTLEMODE_TIMER:Stop();
        BATTLEMODE_TIMER:Start(0.1);
    end
end

local contextFrame = nil
local bmButton = nil
local curFrameName = nil
local bmConfigFrame = nil
local BM_CONFIG_TIMER = nil
local bmIsConfig = false

function BATTLEMODE_CONFIG(configState)
    if contextFrame == nil then
        contextFrame = ui.CreateNewFrame('battlemode','BATTLEMODE_CONTEXT')
    end
    contextFrame:Resize(200,50)
    contextFrame:SetPos(0,0)
    contextFrame:SetLayerLevel(1000)
    bmButton = contextFrame:CreateOrGetControl('button','BATTLEMODE_BUTTON',0,0,200,50)
    bmButton = tolua.cast(bmButton,'ui::CButton')
    bmButton:SetClickSound("button_click_big");
    bmButton:SetOverSound("button_over");
    bmButton:SetSkinName("test_pvp_btn");
    bmButton:ShowWindow(1)

    bmConfigFrame = ui.CreateNewFrame('bandicam','BATTLEMODE_CONFIG_FRAME')
    BM_CONFIG_TIMER = GET_CHILD(bmConfigFrame, "addontimer", "ui::CAddOnTimer");
    BM_CONFIG_TIMER:SetUpdateScript('BATTLEMODE_CONFIG_UPDATE');
    BM_CONFIG_TIMER:EnableHideUpdate(1)
    BM_CONFIG_TIMER:Stop();
    if not configState then
        BM_CONFIG_TIMER:Start(0.1);
    else
        contextFrame:ShowWindow(0)
    end
end

function BATTLEMODE_CONFIG_UPDATE()
    bmButton:SetEventScript(ui.RBUTTONUP, "ui.Chat('/bm config')")
    local curFrame = ui.GetFocusFrame()
    if curFrame ~= nil then

        if curFrameName ~= curFrame:GetName() and curFrame:GetName() ~= 'BATTLEMODE_CONTEXT' then
            contextFrame:SetPos(curFrame:GetX()+curFrame:GetWidth()/2-contextFrame:GetWidth()/2,curFrame:GetY()+curFrame:GetHeight()/2-contextFrame:GetHeight()/2)
            contextFrame:ShowWindow(1)
            contextFrame:EnableHitTest(1)
            if settings.blacklist[curFrame:GetName()] == nil then
                bmButton:SetText('{#009900}'..curFrame:GetName())
                bmButton:SetEventScript(ui.LBUTTONUP, "ui.Chat('/bm blacklist "..curFrame:GetName().."')");
            else
                bmButton:SetText('{#ff0000}'..curFrame:GetName())
                bmButton:SetEventScript(ui.LBUTTONUP, "ui.Chat('/bm whitelist "..curFrame:GetName().."')");
            end
            curFrameName = curFrame:GetName()
            
        end
    else
        curFrameName = curFrame:GetName()
        if contextFrame:GetX() == 0 and contextFrame:GetY() == 0 then
            local quickSlot = ui.GetFrame('quickslotnexpbar')
            if quickSlot ~= nil then
                contextFrame:ShowWindow(1)
                contextFrame:EnableHitTest(1)
                contextFrame:SetPos(quickSlot:GetX()+quickSlot:GetWidth()/2-contextFrame:GetWidth()/2,quickSlot:GetY()+quickSlot:GetHeight()/2-contextFrame:GetHeight()/2)
                if settings.blacklist['quickslotnexpbar'] == nil then
                    bmButton:SetText('{#009900}quickslotnexpbar')
                    bmButton:SetEventScript(ui.LBUTTONUP, "ui.Chat('/bm blacklist quickslotnexpbar')");
                else
                    bmButton:SetText('{#ff0000}quickslotnexpbar')
                    bmButton:SetEventScript(ui.LBUTTONUP, "ui.Chat('/bm whitelist quickslotnexpbar')");
                end
            end
        end
    end
end

function TOGGLE_BATTLE_MODE(command)
    BATTLEMODE_LOADSETTINGS()
    cmd = table.remove(command,1)
    local framename = nil
    if cmd == 'config' then
        if battleModeStatus == 1 then
            TOGGLE_BATTLE_MODE({})
        end
        if not bmIsConfig then
            CHAT_SYSTEM('Entering battlemode configuration.{nl}Frame names in red will be turned off in battlemode. If you cannot click the button, you can type /bm whitelist <framename> or /bm blacklist <framename>.{nl}Right click the button to exit, or type /bm config again.')
        else
            CHAT_SYSTEM('Exiting battlemode configuration.')
        end
        
        BATTLEMODE_CONFIG(bmIsConfig)
        bmIsConfig = not bmIsConfig
        return BATTLEMODE_SAVESETTINGS()
    end
    if cmd == 'blacklist' then
        framename = table.remove(command,1)
        settings.blacklist[framename] = 1
        bmButton:SetText('{#ff0000}'..framename)
        CHAT_SYSTEM('Frame '..framename..' added to blacklist.')
        bmButton:SetEventScript(ui.LBUTTONUP, "ui.Chat('/bm whitelist "..framename.."')");
        return BATTLEMODE_SAVESETTINGS()
    end
    if cmd == 'whitelist' then
        framename = table.remove(command,1)
        for k,v in pairs(settings.blacklist) do
            if k == framename then
                settings.blacklist[k] = nil
                bmButton:SetText('{#009900}'..framename)
                CHAT_SYSTEM('Frame '..framename..' removed from blacklist.')
                bmButton:SetEventScript(ui.LBUTTONUP, "ui.Chat('/bm blacklist "..framename.."')");
            end
        end
        return BATTLEMODE_SAVESETTINGS()
    end
    if cmd == 'reset' then
        CHAT_SYSTEM('Resetting all settings.')
        settings = {}
        BATTLEMODE_SAVESETTINGS()
        BATTLEMODE_LOADSETTINGS()
        return;
    end
    if bmIsConfig and battleModeStatus == 0 then
        return CHAT_SYSTEM('Exit configuration before toggling battlemode on!')
    end

    battleModeStatus = math.abs(battleModeStatus-1)
    UPDATE_BATTLE_MODE()
    if battleModeStatus == 0 then
        CHAT_SYSTEM('Battle mode off,')
    else
        CHAT_SYSTEM('Battle mode on.')
    end
end