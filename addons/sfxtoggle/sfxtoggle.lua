local acutil = require('acutil');
local effectFrame = nil
local timer = imcTime.GetAppTime()
local timeElapsed = 0

function SFXTOGGLE_ON_INIT(addon, frame)
	frame:ShowWindow(1);
	acutil.slashCommand('/effect',SFX_TOGGLE);
    addon:RegisterMsg('FPS_UPDATE', 'FPS_SFXTOGGLE');
    effectFrame = ui.CreateNewFrame('bandicam','EFFECTS_FRAME')
    effectFrame:ShowWindow(1)
    effectFrame:SetBorder(5, 0, 0, 0)
    effectText = effectFrame:CreateOrGetControl('richtext','effecttext',0,0,0,0)
    effectText = tolua.cast(effectText,'ui::CRichText')
    effectText:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    effectText:SetText('{@st41}{s18}Effects: {#00cc00}on')
    effectText:ShowWindow(1)
end

local effectToggle = 1
local lowMode = 0
local effectMode = {'{#00cc00}on','{#cccc00}low','{#cc0000}off'}
local fpsThresh = {5,10,20}

function FPS_SFXTOGGLE(frame, msg, argStr, argNum)
    timeElapsed = timeElapsed + (imcTime.GetAppTime() - timer)
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
    if effectToggle == 1 and timeElapsed > 3 then
        timeElapsed = 0
        timer = imcTime.GetAppTime()
        local fpsnumber = tonumber(argStr)
        if fpsnumber < fpsThresh[1] then
            effectSwitch = 0
            lowMode = 2
            imcperfOnOff.EnableIMCEffect(0);
            imcperfOnOff.EnableEffect(0);
            SET_EFFECT_MODE(effectSwitch)
        elseif fpsnumber > fpsThresh[2] and lowMode == 2 then
            effectSwitch = 0
            lowMode = 1
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
            SET_EFFECT_MODE(effectSwitch)
        elseif fpsnumber < fpsThresh[2] and lowMode == 0 then
            effectSwitch = 0
            lowMode = 1
            imcperfOnOff.EnableIMCEffect(1);
            imcperfOnOff.EnableEffect(1);
            SET_EFFECT_MODE(effectSwitch)
        elseif fpsnumber > fpsThresh[3] and lowMode ~= 0 then
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
        graphic.SetDrawActor(15)
        graphic.SetDrawMonster(20)
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

function SFX_TOGGLE()
    if effectToggle == 1 then
        CHAT_SYSTEM('Effect automation off.')
        effectToggle = 0
        effectText:ShowWindow(0)
        imcperfOnOff.EnableIMCEffect(1);
        imcperfOnOff.EnableEffect(1);
        SET_EFFECT_MODE(1)
    else
        CHAT_SYSTEM('Effect automation on.')
        effectToggle = 1
        effectText:ShowWindow(1)
    end
end