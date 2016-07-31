local regenframe = nil
local regenTimer = imcTime.GetAppTime()
local regenTimeElapsed = 0
local regenTime = 20
local stat = info.GetStat(session.GetMyHandle())
local prevSP = stat.SP
local settings = {}
local default = {pos = {x = 470,y = 60},lock = 1}
local acutil = require('acutil')

function REGENTIMER_ON_INIT(addon, frame)
    frame:ShowWindow(1);
    CHAT_SYSTEM('Regen timer loaded. /regenlock to lock frame.')
    acutil.slashCommand('/regenlock',REGEN_TIMER_LOCK)
    REGEN_TIMER_LOADSETTINGS()
    REGEN_TIMER_CREATE_FRAME()
    addon:RegisterMsg('FPS_UPDATE', 'CHECK_REGEN_FRAME_EXIST');

end

function CHECK_REGEN_FRAME_EXIST()
    if regenframe == nil then
        REGEN_TIMER_CREATE_FRAME()
    end
end

function REGEN_TIMER_CREATE_FRAME()
    regenframe = ui.CreateNewFrame('regentimer','REGEN_TIMER_FRAME')
    regenframe:SetPos(settings.pos.x,settings.pos.y)
    regenframe:EnableHitTest(settings.lock)
    regenframe:ShowWindow(1)
    regenframe:SetBorder(5, 0, 0, 0)
    regentime = regenframe:CreateOrGetControl('richtext','regentimetext',0,0,0,0)
    regentime = tolua.cast(regentime,'ui::CRichText')
    regentime:SetGravity(ui.CENTER_HORZ,ui.BOTTOM)
    regentime:EnableHitTest(0)
    REGEN_TIMER = GET_CHILD(regenframe, "addontimer", "ui::CAddOnTimer");
    REGEN_TIMER:SetUpdateScript('REGEN_TIMER_UPDATE');
    REGEN_TIMER:EnableHideUpdate(1)
    REGEN_TIMER:Stop();
    REGEN_TIMER:Start(0.1);
    regenframe:SetEventScript(ui.LBUTTONUP, "REGEN_DRAG_STOP")
end

function REGEN_TIMER_LOADSETTINGS()
    local s, err = acutil.loadJSON("../addons/regentimer/settings.json");
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
    REGEN_TIMER_SAVESETTINGS()
end

function REGEN_TIMER_SAVESETTINGS()
    acutil.saveJSON("../addons/regentimer/settings.json", settings);
end

function REGEN_TIMER_LOCK()
    settings.lock = math.abs(settings.lock-1)
    REGEN_TIMER_SAVESETTINGS()
    REGEN_TIMER_CREATE_FRAME()
    if settings.lock == 1 then
        CHAT_SYSTEM("Regen timer frame unlocked.")
        return;
    end
    CHAT_SYSTEM("Regen timer frame locked.")
end


function REGEN_DRAG_STOP()
    settings.pos.x = regenframe:GetX()
    settings.pos.y = regenframe:GetY()
    REGEN_TIMER_SAVESETTINGS()
end

function REGEN_TIMER_UPDATE()
    regenTimeElapsed = imcTime.GetAppTime() - regenTimer
    local timeElapsedSecs = math.floor(regenTimeElapsed)
    local redlerp = math.floor(math.lerp(0,255,1-regenTimeElapsed/10))

    local greenlerp = math.floor(math.lerp(0,255,regenTimeElapsed/10))
    if regenTimeElapsed >= 10 then
        redlerp = 0
        greenlerp = 255
    end
    local regenTextColor = rgbToHex({redlerp,greenlerp,0})
    local regenTextString = timeElapsedSecs
    if regenTimeElapsed > 10 then
        regenTextString = regenTextString..' (Sit!)'
    end
    regentime:SetText('{@st41}{s18}{'..regenTextColor..'}'..regenTextString)
    local regenBuffTable = TEST_BUFF_REGEN()
    if regenBuffTable["SP Recovery"] == nil then
        if stat.SP > prevSP then
            regenTimeElapsed = 0
            regenTimer = imcTime.GetAppTime()
        end
    end
    if regenBuffTable["Rest"] == 1 then
        regenTime = 10
    else
        regenTime = 20
    end
    if regenTimeElapsed > regenTime then
        regenTimeElapsed = 0
        regenTimer = imcTime.GetAppTime()
    end
    prevSP = stat.SP
end

function TEST_BUFF_REGEN()
    local buffsTable = {}
    local buff_ui = _G['s_buff_ui']
    local handle  = session.GetMyHandle();
    for j = 0 , buff_ui["buff_group_cnt"] do
        local slotlist = buff_ui["slotlist"][j];
        if buff_ui["slotcount"][j] ~= nil and buff_ui["slotcount"][j] >= 0 then
          for i = 0,  buff_ui["slotcount"][j] - 1 do
              local slot = slotlist[i];
                local icon      = slot:GetIcon();
                local iconInfo  = icon:GetInfo();
                local buffIndex = icon:GetUserIValue("BuffIndex");
                local buff      = info.GetBuff(handle, iconInfo.type, buffIndex);
                local cls       = GetClassByType('Buff', iconInfo.type);
                if buff ~= nil then
                    buffName = dictionary.ReplaceDicIDInCompStr(cls.Name)
                    if buffName == "SP Recovery" or buffName == "Rest" then
                        buffsTable[buffName] = 1
                    end
                end
            end
        end
    end
    return buffsTable
end

function rgbToHex(rgb)
    local hexadecimal = '#'

    for key, value in pairs(rgb) do
        local hex = ''

        while(value > 0)do
            local index = math.fmod(value, 16) + 1
            value = math.floor(value / 16)
            hex = string.sub('0123456789ABCDEF', index, index) .. hex           
        end

        if(string.len(hex) == 0)then
            hex = '00'

        elseif(string.len(hex) == 1)then
            hex = '0' .. hex
        end

        hexadecimal = hexadecimal .. hex
    end
    return hexadecimal
end
