local acutil = require('acutil')
local default = {
    blacklist = {
        charbaseinfo = 1;
        charframe = 1;
        expviewer = 1;
        headsupdisplay = 1;
        minimap = 1;
        partyinfo = 1;
        questinfoset_2 = 1;
        quickslotnexpbar = 1;
        sysmenu = 1;
        weaponswap = 1
    }
}

local settings = {}
local focusedFrames = {}
local battleframe = nil
local contextFrame = nil
local bmButton = nil
local curFrameName = nil
local bmConfigFrame = nil
local BM_CONFIG_TIMER = nil
local bmIsConfig = false
-- local bmStatusFrame = {}
local bmToggleButton = {}
local battleModeStatus = 0
CHAT_SYSTEM('Battlemode loaded. Type /bm config to configure.')

function BATTLEMODE_ON_INIT(addon,frame)
    acutil.slashCommand('bm',TOGGLE_BATTLE_MODE)
    if battleModeStatus == nil then
        battleModeStatus = 0
    end
    -- battleModeStatus = 0
    addon:RegisterMsg('FPS_UPDATE','UPDATE_BATTLE_MODE')

end

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
    bmToggleButton['frame'] = ui.GetFrame('BM_TOGGLE_BUTTON_FRAME')
    if bmToggleButton['frame'] == nil then 
        bmToggleButton['frame'] = ui.CreateNewFrame('battlemode','BM_TOGGLE_BUTTON_FRAME')

        bmToggleButton['frame']:Resize(200,200)
        bmToggleButton['frame']:SetPos(0,0)

        bmToggleButton['frame']:SetLayerLevel(1000)
        bmToggleButton['frame']:ShowWindow(1)
        bmToggleButton['button'] = bmToggleButton['frame']:CreateOrGetControl('button','BM_TOGGLE_BUTTON',0,0,100,35)
        bmToggleButton['button'] = tolua.cast(bmToggleButton['button'],'ui::CButton')
        bmToggleButton['button']:SetClickSound("button_click_big");
        bmToggleButton['button']:SetOverSound("button_over");
        bmToggleButton['button']:SetSkinName("quest_box");

        bmToggleButton['button']:ShowWindow(1)
        bmToggleButton['button']:SetEventScript(ui.LBUTTONUP, "BATTLEMODE_LBUTTON_UP");
    end
    if battleModeStatus == 0 then
        bmToggleButton['button']:SetText("{@st41}{#ff0000}{s18}bm off")
    else
        bmToggleButton['button']:SetText("{@st41}{#009900}{s18}bm on");
    end

    return battleframe
end

function BATTLEMODE_LBUTTON_UP()
    ui.Chat("/bm")
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
    bmButton:SetEventScript(ui.RBUTTONUP, "BATTLEMODE_RBUTTON_UP")
    local curFrame = ui.GetFocusFrame()
    if curFrame ~= nil then
        if curFrameName ~= curFrame:GetName() and curFrame:GetName() ~= 'BATTLEMODE_CONTEXT' then
            contextFrame:SetPos(curFrame:GetX()+curFrame:GetWidth()/2-contextFrame:GetWidth()/2,curFrame:GetY()+curFrame:GetHeight()/2-contextFrame:GetHeight()/2)
            contextFrame:ShowWindow(1)
            contextFrame:EnableHitTest(1)

            if settings.blacklist[curFrame:GetName()] == nil then
                bmButton:SetText('{#009900}'..curFrame:GetName())
                bmButton:SetEventScript(ui.LBUTTONUP, "BATTLEMODE_CONFIG_LBUTTON_UP_FOR_BLACKLIST");
            else
                bmButton:SetText('{#ff0000}'..curFrame:GetName())
                bmButton:SetEventScript(ui.LBUTTONUP, "BATTLEMODE_CONFIG_LBUTTON_UP_FOR_WHITELIST");
            end
            bmButton:SetEventScriptArgString(ui.LBUTTONUP, curFrame:GetName());

            contextFrame:Resize(bmButton:GetWidth(),contextFrame:GetHeight())
            curFrameName = curFrame:GetName()
            
        end
    else
        if contextFrame:GetX() == 0 and contextFrame:GetY() == 0 then
            curFrameName = 'quickslotnexpbar'
            local quickSlot = ui.GetFrame('quickslotnexpbar')
            if quickSlot ~= nil then
                contextFrame:ShowWindow(1)
                contextFrame:EnableHitTest(1)
                contextFrame:SetPos(quickSlot:GetX()+quickSlot:GetWidth()/2-contextFrame:GetWidth()/2,quickSlot:GetY()+quickSlot:GetHeight()/2-contextFrame:GetHeight()/2)

                if settings.blacklist['quickslotnexpbar'] == nil then
                    bmButton:SetText('{#009900}quickslotnexpbar')
                    bmButton:SetEventScript(ui.LBUTTONUP, "BATTLEMODE_CONFIG_LBUTTON_UP_FOR_BLACKLIST");
                else
                    bmButton:SetText('{#ff0000}quickslotnexpbar')
                    bmButton:SetEventScript(ui.LBUTTONUP, "BATTLEMODE_CONFIG_LBUTTON_UP_FOR_WHITELIST");
                end
                bmButton:SetEventScriptArgString(ui.LBUTTONUP, curFrameName);
                contextFrame:Resize(bmButton:GetWidth(),contextFrame:GetHeight())
            end
        end
    end
end

function BATTLEMODE_RBUTTON_UP()
    ui.Chat('/bm config')
end

function BATTLEMODE_CONFIG_LBUTTON_UP_FOR_BLACKLIST(frame, ctrl, frameName)
    ui.Chat("/bm blacklist "..frameName)
end

function BATTLEMODE_CONFIG_LBUTTON_UP_FOR_WHITELIST(frame, ctrl, frameName)
    ui.Chat("/bm whitelist "..frameName)
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
            CHAT_SYSTEM('Entering battlemode configuration.{nl}Frame names in red will be turned off in battlemode. {nl}{nl}If you cannot click the button, you can type /bm whitelist <framename> or /bm blacklist <framename>.{nl}Right click the button to exit, or type /bm config again.')
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

        bmButton:SetEventScript(ui.LBUTTONUP, "BATTLEMODE_CONFIG_LBUTTON_UP_FOR_WHITELIST");
        bmButton:SetEventScriptArgString(ui.LBUTTONUP, framename);

        return BATTLEMODE_SAVESETTINGS()
    end
    if cmd == 'whitelist' then
        framename = table.remove(command,1)
        for k,v in pairs(settings.blacklist) do
            if k == framename then
                settings.blacklist[k] = nil
                bmButton:SetText('{#009900}'..framename)
                CHAT_SYSTEM('Frame '..framename..' removed from blacklist.')

                bmButton:SetEventScript(ui.LBUTTONUP, "BATTLEMODE_CONFIG_LBUTTON_UP_FOR_BLACKLIST");
                bmButton:SetEventScriptArgString(ui.LBUTTONUP, framename);

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
        CHAT_SYSTEM('Battle mode off.')
        bmToggleButton['button']:SetText("{@st41}{#ff0000}{s18}bm off");
    else
        CHAT_SYSTEM('Battle mode on.')
        bmToggleButton['button']:SetText("{@st41}{#009900}{s18}bm on");
    end
end