local acutil = require('acutil');
local effectFrame = nil
local timer = imcTime.GetAppTime()
local timeElapsed = 0
local lowMode = 0
local effectMode = {'{#00cc00}on','{#cccc00}low','{#cc0000}off'}
CHAT_SYSTEM('SFX Toggle loaded. Commands:{nl}/effect{nl}/effect thresh <t1> <t2> <t3>{nl}/effect players <num>{nl}/effect mobs <num>')

function SFXTOGGLE_ON_INIT(addon, frame)
	frame:ShowWindow(1);
	acutil.slashCommand('/effect',SFX_CHAT_CMD);
    addon:RegisterMsg('FPS_UPDATE', 'FPS_SFXTOGGLE');
    effectFrame = ui.CreateNewFrame('bandicam','EFFECTS_FRAME')
    effectFrame:ShowWindow(1)
    effectFrame:SetBorder(5, 0, 0, 0)
    effectText = effectFrame:CreateOrGetControl('richtext','effecttext',0,0,0,0)
    effectText = tolua.cast(effectText,'ui::CRichText')
    effectText:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    effectText:SetText('{@st41}{s18}Effects: {#00cc00}on')
    effectText:ShowWindow(1)
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
    timeElapsed = imcTime.GetAppTime() - timer
    effectFrame = ui.GetFrame('EFFECTS_FRAME')
    if effectFrame == nil then
        effectFrame = ui.CreateNewFrame('bandicam','EFFECTS_FRAME')
        effectFrame:ShowWindow(1)
        effectFrame:SetBorder(5, 0, 0, 0)
        effectText = effectFrame:CreateOrGetControl('richtext','effecttext',0,0,0,0)
        effectText = tolua.cast(effectText,'ui::CRichText')
        effectText:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
        effectText:SetText('{@st41}{s18}Effects: '..effectMode[lowMode+1])
    end
    if settings.enable == 1 and timeElapsed > 3 then
        timeElapsed = 0
        timer = imcTime.GetAppTime()
        local fpsnumber = tonumber(argStr)
        if fpsnumber < settings.thresh[1] then
            effectSwitch = 0
            lowMode = 2
            imcperfOnOff.EnableIMCEffect(0);
            imcperfOnOff.EnableEffect(0);
            SET_EFFECT_MODE(effectSwitch)
        elseif fpsnumber > settings.thresh[2] and lowMode == 2 then
            effectSwitch = 0
            lowMode = 1
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
            SET_EFFECT_MODE(effectSwitch)
        elseif fpsnumber < settings.thresh[2] and lowMode == 0 then
            effectSwitch = 0
            lowMode = 1
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
            SET_EFFECT_MODE(effectSwitch)
        elseif fpsnumber > settings.thresh[3] and lowMode ~= 0 then
            effectSwitch = 1
            lowMode = 0
            SET_EFFECT_MODE(effectSwitch)
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
        end
    end
end

function SET_EFFECT_MODE(effectSwitch)
    graphic.EnableFastLoading(1)
    if effectSwitch == 0 then
        graphic.SetDrawActor(settings.players)
        graphic.SetDrawMonster(settings.mobs)
    else
        graphic.SetDrawActor(100)
        graphic.SetDrawMonster(100)
    end
    if effectFrame ~= nil then
        effectText:SetText('{@st41}{s18}Effects: '..effectMode[lowMode+1])
    end
    imcperfOnOff.EnableDeadParts(effectSwitch);
    
    graphic.EnableBlur(0);
    -- geScene.option.SetShadowMapSize(effectSwitch);
    -- geScene.option.SetUseSSAO(effectSwitch);
    -- geScene.option.SetSSAOMethod(effectSwitch);
    -- geScene.option.SetUseCharacterWaterReflection(effectSwitch);
    -- geScene.option.SetUseBGWaterReflection(effectSwitch);
    -- geScene.option.SetUseShadowMap(effectSwitch);
    -- graphic.ApplyGammaRamp(effectSwitch);
    graphic.EnableBloom(effectSwitch);
    graphic.EnableCharEdge(effectSwitch);
    graphic.EnableDepth(effectSwitch);
    graphic.EnableFXAA(effectSwitch);
    graphic.EnableGlow(effectSwitch);
    graphic.EnableHighTexture(effectSwitch);
    graphic.EnableSharp(effectSwitch);
    graphic.EnableSoftParticle(effectSwitch);
    graphic.EnableStencil(effectSwitch);
    graphic.EnableWater(effectSwitch);
    graphic.EnableHighTexture(effectSwitch);  
end

function SFX_CHAT_CMD(command)
    local cmd  = ''
    if #command > 0 then
        cmd = table.remove(command, 1)
    else
        settings.enable = math.abs(settings.enable - 1)
        return SFX_TOGGLE()
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
    CHAT_SYSTEM('Invalid command.{nl}Available commands: /effect - toggles effect automation{nl}/effect thresh <thresh1> <thresh2> <thresh3> - sets cutoff for no effects, low effects, and full effects{nl}/effect players <num> - sets number of players to draw on low effects{nl}/effect mobs <num> - sets number of mobs to draw on low effects{nl}')
    CHAT_SYSTEM('Current Settings{nl}effect: '..settings.enable..'{nl}thresh: '..settings.thresh[1]..', '..settings.thresh[2]..', '..settings.thresh[3]..'{nl}players: '..settings.players..'{nl}mobs: '..settings.mobs)
    SFXTOGGLE_SAVESETTINGS()
    return;
end

function SFX_TOGGLE()
    if settings.enable == 0 then
        CHAT_SYSTEM('Effect automation off.')
        effectText:ShowWindow(0)
        imcperfOnOff.EnableIMCEffect(1);
        imcperfOnOff.EnableEffect(1);
        SET_EFFECT_MODE(1)
    else
        CHAT_SYSTEM('Effect automation on.')
        effectText:ShowWindow(1)
    end
end