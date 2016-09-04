local acutil = require('acutil');
local effectFrame = nil
local timer = imcTime.GetAppTime()
local timeElapsed = 0
local lowMode = 0
local effectMode = {'{#00cc00}on','{#cccc00}low','{#cc0000}off','{#cc0000}BOSS'}
local bossMode = false
local hiddenFrames = {}
CHAT_SYSTEM('SFX Toggle loaded. Commands:{nl}/effect{nl}/effect thresh <t1> <t2> <t3>{nl}/effect players <num>{nl}/effect mobs <num>{nl}/effect boss')

function SFXTOGGLE_ON_INIT(addon, frame)
	frame:ShowWindow(1);
	acutil.slashCommand('/effect',SFX_CHAT_CMD);
    addon:RegisterMsg('FPS_UPDATE', 'FPS_SFXTOGGLE');
    effectFrame = ui.CreateNewFrame('bandicam','EFFECTS_FRAME')
    effectFrame:SetBorder(5, 0, 0, 0)
    effectText = effectFrame:CreateOrGetControl('richtext','effecttext',0,0,0,0)
    effectText = tolua.cast(effectText,'ui::CRichText')
    effectText:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    effectText:SetText('{@st41}{s18}Effects: {#00cc00}on')
    SFXTOGGLE_LOADSETTINGS()
end
local default = {thresh = {5,10,20}, enable = 1, players = 15, mobs = 20}
local settings = {}

function SFXTOGGLE_LOADSETTINGS()
    local s, err = acutil.loadJSON("../addons/sfxtoggle/settings.json");
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
    SFXTOGGLE_SAVESETTINGS()
end

function SFXTOGGLE_SAVESETTINGS()
    acutil.saveJSON("../addons/sfxtoggle/settings.json", settings);
end


function FPS_SFXTOGGLE(frame, msg, argStr, argNum)
    effectFrame = ui.GetFrame('EFFECTS_FRAME')
    if settings.enable == 0 then
        if effectFrame ~= nil then
            effectFrame:ShowWindow(0)
        end
        return;
    end
    timeElapsed = imcTime.GetAppTime() - timer
    if effectFrame == nil then
        effectFrame = ui.CreateNewFrame('bandicam','EFFECTS_FRAME')
        effectFrame:SetBorder(5, 0, 0, 0)
        effectText = effectFrame:CreateOrGetControl('richtext','effecttext',0,0,0,0)
        effectText = tolua.cast(effectText,'ui::CRichText')
        effectText:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
        effectText:SetText('{@st41}{s18}Effects: '..effectMode[lowMode+1])
    end
    effectFrame:ShowWindow(1)
    if bossMode then
        for i = 0,200 do
            local charbaseinfo = ui.GetFrame('charbaseinfo1_'..i)
            if charbaseinfo ~= nil then
                if charbaseinfo:IsVisible() == 1 then
                    table.insert(hiddenFrames,'charbaseinfo1_'..i)
                    charbaseinfo:ShowWindow(0)
                end
            end
        end
    local selectedObjects, selectedObjectsCount = SelectObject(GetMyPCObject(), 1000000, 'ALL');
    for i = 1, selectedObjectsCount do
        local handle = GetHandle(selectedObjects[i]);

        if handle ~= nil then
            if info.IsPC(handle) == 1 then
                local shopFrame = ui.GetFrame('SELL_BALLOON_'..handle)
                if shopFrame ~= nil then
                    if shopFrame:IsVisible() == 1 then
                        table.insert(hiddenFrames,'SELL_BALLOON_'..handle)
                        shopFrame:ShowWindow(0)
                    end
                end
            end
        end
    end

    end
    if timeElapsed > 3 then
        timeElapsed = 0
        timer = imcTime.GetAppTime()
        local fpsnumber = tonumber(argStr)
        if bossMode then
            imcperfOnOff.EnableIMCEffect(0);
            imcperfOnOff.EnableEffect(1);
            effectSwitch = -1
            SET_EFFECT_MODE(effectSwitch)
            return;
        end
        -- enter no effects below thresh 1
        if fpsnumber < settings.thresh[1] and lowMode ~= 2 then
            effectSwitch = 0
            lowMode = 2
            imcperfOnOff.EnableIMCEffect(0);
            imcperfOnOff.EnableEffect(0);
            SET_EFFECT_MODE(effectSwitch)
        -- enter low effects from no effects above thresh 2
        elseif fpsnumber > settings.thresh[2] and lowMode == 2 then
            effectSwitch = 0
            lowMode = 1
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
            SET_EFFECT_MODE(effectSwitch)
        -- enter low effects from full effects below thresh 2
        elseif fpsnumber < settings.thresh[2] and lowMode == 0 then
            effectSwitch = 0
            lowMode = 1
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
            SET_EFFECT_MODE(effectSwitch)
        -- enter full effects above thresh 3
        elseif fpsnumber > settings.thresh[3] and lowMode ~= 0 then
            effectSwitch = 1
            lowMode = 0
            SET_EFFECT_MODE(effectSwitch)
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
        -- enter low effects below thresh 3
        elseif fpsnumber < settings.thresh[3] and lowMode ~= 1 then
            effectSwitch = 0
            lowMode = 1
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
            SET_EFFECT_MODE(effectSwitch)
        end
    end
end

function SET_EFFECT_MODE(effectSwitch)
    if bossMode then
        graphic.SetDrawActor(-1)
        graphic.SetDrawMonster(30)

    end
    graphic.EnableFastLoading(1)
    if effectSwitch == 0 then
        graphic.SetDrawActor(settings.players)
        graphic.SetDrawMonster(settings.mobs)
    elseif effectSwitch == 1 then
        graphic.SetDrawActor(100)
        graphic.SetDrawMonster(100)
    end
    if effectFrame ~= nil then
        if effectSwitch == -1 then
            effectText:SetText('{@st41}{s18}Effects: '..effectMode[4])
        else
            effectText:SetText('{@st41}{s18}Effects: '..effectMode[lowMode+1])
        end
    end
    local effect = effectSwitch
    if effect == -1 then effect = 0 end

    imcperfOnOff.EnableDeadParts(effect);    
    graphic.EnableBlur(0);
    -- geScene.option.SetShadowMapSize(effect);
    -- geScene.option.SetUseSSAO(effect);
    -- geScene.option.SetSSAOMethod(effect);
    -- geScene.option.SetUseCharacterWaterReflection(effect);
    -- geScene.option.SetUseBGWaterReflection(effect);
    -- geScene.option.SetUseShadowMap(effect);
    -- graphic.ApplyGammaRamp(effect);
    graphic.EnableBloom(effect);
    graphic.EnableCharEdge(effect);
    graphic.EnableDepth(effect);
    graphic.EnableFXAA(effect);
    graphic.EnableGlow(effect);
    graphic.EnableHighTexture(effect);
    graphic.EnableSharp(effect);
    graphic.EnableSoftParticle(effect);
    graphic.EnableStencil(effect);
    graphic.EnableWater(effect);
    graphic.EnableHighTexture(effect);  
end

function SFX_CHAT_CMD(command)
    local cmd  = ''
    if #command > 0 then
        cmd = table.remove(command, 1)
    else
        settings.enable = math.abs(settings.enable - 1)
        return SFX_TOGGLE()
    end
    if cmd == 'boss' then
        bossMode = not bossMode
        if bossMode then
            SET_EFFECT_MODE(-1)
            return ui.AddText('SystemMsgFrame','Boss mode enabled.')
        else
            effectSwitch = 0
            SFX_SHOW_HIDDEN_FRAMES()
            imcperfOnOff.EnableIMCEffect(1)
            imcperfOnOff.EnableEffect(1);
            SET_EFFECT_MODE(effectSwitch)
            return ui.AddText('SystemMsgFrame','Boss mode disabled.')
        end
    end
    if cmd == 'thresh' then
        local t1 = tonumber(table.remove(command, 1))
        local t2 = tonumber(table.remove(command, 1))
        local t3 = tonumber(table.remove(command, 1))
        if type(t1) == 'number' and type(t2) == 'number' and type(t3) == 'number' then
            settings.thresh = {t1,t2,t3}
            CHAT_SYSTEM(t1..' fps: Effects off{nl}'..t2..' fps: Low effects{nl}'..t3..' fps: Full effects{nl}')
            return SFXTOGGLE_SAVESETTINGS()
        end
    end
    if cmd == 'players' or cmd == 'mobs' then
        local arg1 = tonumber(table.remove(command, 1))
        if type(arg1) == 'number' then
            settings[cmd] = arg1
            CHAT_SYSTEM('Limit '..cmd..' drawing to '..arg1..'.')
            return SFXTOGGLE_SAVESETTINGS()
        end
    end
    CHAT_SYSTEM('Invalid command.{nl}Available commands: /effect - toggles effect automation{nl}/effect thresh <thresh1> <thresh2> <thresh3> - sets cutoff for no effects, low effects, and full effects{nl}/effect players <num> - sets number of players to draw on low effects{nl}/effect mobs <num> - sets number of mobs to draw on low effects{nl}/effect boss - toggles boss mode')
    CHAT_SYSTEM('Current Settings{nl}effect: '..settings.enable..'{nl}thresh: '..settings.thresh[1]..', '..settings.thresh[2]..', '..settings.thresh[3]..'{nl}players: '..settings.players..'{nl}mobs: '..settings.mobs)
    SFXTOGGLE_SAVESETTINGS()
    return;
end

function SFX_TOGGLE()
    if settings.enable == 0 then
        ui.AddText('SystemMsgFrame','Effect automation off.')
        imcperfOnOff.EnableIMCEffect(1);
        imcperfOnOff.EnableEffect(1);
        SET_EFFECT_MODE(1)
    else
        ui.AddText('SystemMsgFrame','Effect automation on.')
    end
    return SFXTOGGLE_SAVESETTINGS()
end

function SFX_SHOW_HIDDEN_FRAMES()
    for k,v in pairs(hiddenFrames) do
        local frame = ui.GetFrame(v)
        if frame ~= nil then
            frame:ShowWindow(1)
        end
    end
    hiddenFrames = {}
end