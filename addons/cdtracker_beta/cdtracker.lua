local acutil = require('acutil')
local _G = _G

local settings = {}
local default = {
    alerts           = true;
    buffPosX         = 100;
    buffPosY         = 200;
    buffs            = true;
    chatList         = {};
    checkVal         = 5;
    firstTimeMessage = false;
    ignoreList       = {};
    lock             = false;
    message          = {};
    size             = 1;
    skillPosX        = 700;
    skillPosY        = 225;
    skills           = true;
    skin             = 1;
    sound            = true;
    soundtype        = 1;
    text             = true;
    }

local soundTypes = {'button_click_stats_up','quest_count','quest_event_start','quest_success_2','sys_alarm_mon_kill_count','quest_event_click','sys_secret_alarm', 'travel_diary_1','button_click_4'}

local frameSkins = {'box_glass', 'slot_name', 'shadow_box', 'frame_bg', 'textview', 'chat_window', 'tooltip1'}
-- store skill/buff
local skillIndex      = 1
cdTrackSkill          = {}
cdTrackSkill['Slots'] = {}
cdTrackSkill['icon']  = {}

local cdTrackBuff = {}
cdBuffList        = {'time','prevTime','slot','class','Slots'}
for k,v in pairs(cdBuffList) do
    cdTrackBuff[v] = {}
end

local cdTrackType = {}
-- store frame data
skillFrame        = {}
local cdTypeList  = {'SKILL','BUFF','DEBUFF'}
local cdFrameList = {'name_','type_','cooldown_','icon_','iconFrame_','cdFrame_'}
for kf,vf in pairs(cdFrameList) do
    for kt,vt in pairs(cdTypeList) do
        skillFrame[vf..vt] = {}
    end
end

local CD_DRAG_STATE  = false
-- timer for chat notification
local timer          = imcTime.GetAppTime()
local msgDisplay     = false
local castMessage    = false
local checkChatFrame = ui.GetFrame('chat')
-- begin main body
function CDTRACKER_ON_INIT(addon, frame)
    acutil.setupHook(ICON_USE_HOOKED,'ICON_USE')
    acutil.setupHook(ICON_UPDATE_SKILL_COOLDOWN_HOOKED,'ICON_UPDATE_SKILL_COOLDOWN')
    acutil.setupHook(SetKeyboardSelectMode_HOOKED,'SetKeyboardSelectMode')
    addon:RegisterMsg('RESTQUICKSLOT_OPEN', 'QUICKSLOTNEXPBAR_KEEPVISIBLE');
    addon:RegisterMsg('RESTQUICKSLOT_CLOSE', 'QUICKSLOTNEXPBAR_RESTORE');
    cdTrackSkill          = {}
    cdTrackSkill['Slots'] = {}
    cdTrackSkill['icon']  = {}
    skillIndex            = 1
    for k,v in pairs(cdBuffList) do
        cdTrackBuff[v] = {}
    end
    checkChatFrame = ui.GetFrame('chat')
    acutil.slashCommand('/cd',CD_TRACKER_CHAT_CMD)
    CDTRACKER_LOADSETTINGS()
    if not settings.firstTimeMessage then
        ui.MsgBox("{s18}{#c70404}Important:{nl} {nl}{#000000}CDTracker Beta settings have been changed, if you are upgrading from an older version please reset using{nl} {nl}{#03134d}/cd reset{nl} {nl}This message will only show once.","helpBoxTable.helpBox_1()","helpBoxTable.helpBox_1()");
        settings.firstTimeMessage = true
        CDTRACKER_SAVESETTINGS()
    end
    local convertList = {settings.ignoreList, settings.chatList, settings.message}
    for k,v in pairs(convertList) do
        for i,j in pairs(v) do
            if string.sub(i,1,1) ~= '[' then
                v['[Skill] '..i] = j
                v[i] = nil
            end
        end
    end
    CDTRACKER_SAVESETTINGS()
end

local kbSelectMode = 0
function SetKeyboardSelectMode_HOOKED(mode)
    kbSelectMode = mode
    return _G['SetKeyboardSelectMode_OLD'](mode)
end

-- if resting, keep skillbar alive
function QUICKSLOTNEXPBAR_KEEPVISIBLE()
    local quickSlotBar = ui.GetFrame('quickslotnexpbar')
    ui.OpenFrame('quickslotnexpbar')
    quickSlotBar:SetVisible(0)
end
-- restore old skillbar on stand
function QUICKSLOTNEXPBAR_RESTORE()
    local quickSlotBar = ui.GetFrame('quickslotnexpbar')
    quickSlotBar:SetVisible(1)
end

function CD_DRAG_START()
    CD_DRAG_STATE = true
end

function CD_DRAG_STOP(cdtype, slot)
    CD_DRAG_STATE = false
    local cdFrame = skillFrame['cdFrame_'..cdtype][tonumber(slot)]
    local xPos    = cdFrame:GetX()
    local yPos    = cdFrame:GetY()

    if cdtype == 'SKILL' then
        settings.skillPosX = xPos
        settings.skillPosY = yPos-60*settings.size*slot
    else
        settings.buffPosX = xPos
        settings.buffPosY = yPos-60*settings.size*slot
    end
    cdFrame:SetDuration(1)
    CDTRACKER_SAVESETTINGS()
end

function CDTRACKER_LOADSETTINGS()
    local s, err = acutil.loadJSON("../addons/cdtracker/settings.json");
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
    CDTRACKER_SAVESETTINGS()
end

function CDTRACKER_SAVESETTINGS()
    table.sort(settings)
    acutil.saveJSON("../addons/cdtracker/settings.json", settings);
end

function BOOL_TO_WORD(cond)
    return (cond == true) and 'on' or 'off'
end

local mt = {__index = function (t,k)
    return function()
        if type(tonumber(k)) == 'number' then
            settings.checkVal = tonumber(k) CHAT_SYSTEM('CD alerts set to '..k..' seconds.')
        else
            CHAT_SYSTEM('Invalid command. Valid command format: /cd <command>'..
            '{nl} {nl}'..
            '{nl}Toggle commands: on, off, sound, text, buffs, skills, lock, alert <ID>, chat <ID> <message>'..
            '{nl}Setting commands: <number>, sound <number>, skin <number>, size <number>, skillX <number>, skillY <number>, buffX <number>, buffY <number>'..
            '{nl}Status commands: list, status'..
            '{nl}System commands: reset, help help all'..
            '{nl} {nl}'..
            '{nl}For more information, type /cd help <command>.'..
            '{nl} {nl}')
        end
  end
end;
}

helpBoxTable = {
    helpBox_1 = function() ui.MsgBox("{s18}{#1908e3}Main commands:{#000000}{nl} {nl}{#03134d}"..
        "/cd <number>{#000000} will set the notification time in seconds.{nl} {nl}{#03134d}"..
        "/cd on, /cd off{nl}/cd text, /cd sound{#000000} {nl}are all toggle commands.{nl} {nl}{#03134d}"..
        "/cd buffs, cd skills{#000000} toggles the buff/skill window on and off.{nl} {nl}{#03134d}"..
        "/cd sound <number>{#000000} will set the sound type. (Default: 1){nl} {nl}{#03134d}"..
        "/cd skin <number>{#000000} will set the skin type. (Default: 1) ","helpBoxTable.helpBox_2()","helpBoxTable.helpBox_2()") end;
    helpBox_2 = function() ui.MsgBox("{s18}{#1908e3}Layout commands:{#000000}{nl} {nl}{#03134d}"..
        "/cd size <number>{#000000} will let you modify the size scaling of windows. (Default: 1){nl} {nl}{#03134d}"..
        "/cd skillX <number>{nl}/cd skillY <number>{nl}"..
        "/cd buffX <number>{nl}/cd buffY <number>{nl} {nl}{#000000}allow you to manually position the skill and buff windows. Dragging also works.{nl} {nl}{#03134d}"..
        "/cd lock{nl} {nl}{#000000} will lock all frames in place.{nl} {nl}{#03134d}"..
        "/cd showframes{nl}{#000000}will show you draggable frames to set window positions.","helpBoxTable.helpBox_3()","helpBoxTable.helpBox_3()") end;
    helpBox_3 = function() ui.MsgBox("{s18}{#1908e3}Skill customization:{#000000}{nl} {nl}{#03134d}"..
        "/cd list{#000000} will list all skills alphabetically with their ID number.{nl} {nl}{#03134d}"..
        "/cd alert <ID>{#000000} toggles alerts for a specific skill.{nl} {nl}{#03134d}"..
        "/cd chat <ID> <message>{#000000} toggles yellowtext (!!) broadcasting for specific skills. Message is optional custom message when casting.","helpBoxTable.helpBox_4()","helpBoxTable.helpBox_4()") end;
    helpBox_4 = function() ui.MsgBox("{s18}{#1908e3}System commands:{#000000}{nl} {nl}{#03134d}"..
        "/cd reset{#000000} will reset all settings to default.{nl} {nl}{#03134d}"..
        "/cd help <command>{#000000} will show a short explanation about a command.{nl} {nl}{#03134d}"..
        "/cd help all{#000000} will show this help box.","","Nope") end
}

local CD_HELP_TABLE = {
    alert      = function() CHAT_SYSTEM('Usage: /cd alert will toggle cooldown alerts for a single skill.') end;
    all        = function() helpBoxTable.helpBox_1() end;
    buffs      = function() CHAT_SYSTEM('Usage: /cd buffs will toggle buff tracking on and off.{nl}Default: '..default.buffs) end;
    buffX      = function() CHAT_SYSTEM('Usage: /cd buffX <coords> will set the x coordinates for the buff window.{nl}Default: '..default.buffPosX) end;
    buffY      = function() CHAT_SYSTEM('Usage: /cd buffY <coords> will set the y coordinates for the buff window.{nl}Default: '..default.buffPosY) end;
    chat       = function() CHAT_SYSTEM('Usage: /cd chat <ID> <message> will toggle chat alerts for a single skill. Message is optional message to send when casting.') end;
    help       = function() CHAT_SYSTEM('Usage: /cd help <command> will open what you\'re reading.') end;
    list       = function() CHAT_SYSTEM('Usage: /cd list will list all skills along with their ID.') end;
    lock       = function() CHAT_SYSTEM('Usage: /cd lock will lock all frames in place.{nl}Default: Off') end;
    off        = function() CHAT_SYSTEM('Usage: /cd off will turn all alerts off.{nl}Default: '..default.alerts) end;
    on         = function() CHAT_SYSTEM('Usage: /cd on will reenable alerts. Your settings will be saved.{nl}Default: On') end;
    reset      = function() CHAT_SYSTEM('Usage: /cd reset will reset all settings to default.') end;
    showframes = function() CHAT_SYSTEM('Usage: /cd showframes will show and set current positions of windows.') end;
    size       = function() CHAT_SYSTEM('Usage: /cd size <scale> will change the size of all cooldown windows.{nl}Default: '..default.size) end;
    skills     = function() CHAT_SYSTEM('Usage: /cd skills will toggle skill tracking on and off.{nl}Default: '..default.skills) end;
    skillX     = function() CHAT_SYSTEM('Usage: /cd skillX <coords> will set the x coordinates for the skill window.{nl}Default: '..default.skillPosX) end;
    skillY     = function() CHAT_SYSTEM('Usage: /cd skillY <coords> will set the y coordinates for the skill window.{nl}Default: '..default.skillPosY) end;
    skin       = function() CHAT_SYSTEM('Usage: /cd skin <number> will change the skin of the cooldown tracker.{nl}Default: '..default.skin) end;
    sound      = function() CHAT_SYSTEM('Usage: /cd sound will toggle sound alerts on and off. /cd sound <number> will change the sound played.{nl}Default: '.. default.soundtype) end;
    text       = function() CHAT_SYSTEM('Usage: /cd text will toggle text alerts on and off.{nl}Default: '..default.text) end;
}

local CD_SETTINGS_TABLE = {
    on         = function() settings.alerts = true CHAT_SYSTEM('Alerts on.') end;
    off        = function() settings.alerts = false CHAT_SYSTEM('Alerts off.') end;
    sound      = function(num)
                if type(num)                       == 'number' then
                    settings.soundtype             = num
                    CHAT_SYSTEM('Soundtype set to '..num..'.')
                    imcSound.PlaySoundEvent(soundTypes[settings.soundtype]);
                    return;
                end
                settings.sound                     = not settings.sound
                CHAT_SYSTEM('Sound set to '..BOOL_TO_WORD(settings.sound)..'.')
                end;
    text       = function() settings.text = not settings.text CHAT_SYSTEM('Text set to '..BOOL_TO_WORD(settings.text)..'.') end;
    alert      = function(ID)
                if ID <= #skillList then
                    listType = skillList
                else
                    listType = buffList
                    ID = ID - #skillList
                end
                if settings.ignoreList[listType[ID]]  ~= nil then
                    settings.ignoreList[listType[ID]] = not settings.ignoreList[listType[ID]]
                else
                    settings.ignoreList[listType[ID]] = true
                end
                return CHAT_SYSTEM('Alerts for '..listType[ID]..' set to '..BOOL_TO_WORD(not settings.ignoreList[listType[ID]])..'.') end;
    chat       = function(ID, castmessage)
                if castmessage                         ~= nil then
                    settings.message[skillList[ID]]    = castmessage
                    CHAT_SYSTEM(skillList[ID]..' on cast will show: '..castmessage)
                    return;
                end
                if settings.chatList[skillList[ID]]    ~= nil then
                    settings.chatList[skillList[ID]]   = not settings.chatList[skillList[ID]]
                    if not settings.chatList[skillList[ID]] then
                        ui.Chat('!!')
                    end
                    CHAT_SYSTEM('Chat for '..skillList[ID]..' set to '..BOOL_TO_WORD(settings.chatList[skillList[ID]])..'.')
                    return;
                end
                settings.chatList[skillList[ID]]       = true
                CHAT_SYSTEM('Chat for '..skillList[ID]..' set to on.') end;
    skillX     = function(num) settings.skillPosX = num CHAT_SYSTEM('Skill X set to '..num..'.') end;
    skillY     = function(num) settings.skillPosY = num CHAT_SYSTEM('Skill Y set to '..num..'.') end;
    buffX      = function(num) settings.buffPosX = num CHAT_SYSTEM('Buff X set to '..num..'.') end;
    buffY      = function(num) settings.buffPosY = num CHAT_SYSTEM('Buff Y set to '..num..'.') end;
    showframes = function() CDTRACKER_SHOW_FRAMES() end;
    skin       = function(num) settings.skin = num CHAT_SYSTEM('Skin set to '..num..'.') end;
    list       = function() GET_SKILL_LIST() local skillStr = 'Skills:{nl}'
                for k,v in ipairs(skillList) do
                    skillStr = skillStr..'ID '..k..': '..v..' - alert '..BOOL_TO_WORD(not settings.ignoreList[v])..' - chat '..BOOL_TO_WORD(settings.chatList[v])..'{nl}'
                end
                GET_BUFF_LIST()
                if #buffList > 0 then
                    skillStr = '{nl}'..skillStr..'Buffs:{nl}'
                    for k,v in ipairs(buffList) do
                        skillStr = skillStr..'ID '..k+#skillList..': '..v..' - alert '..BOOL_TO_WORD(not settings.ignoreList[v])..'{nl}'
                    end

                end
                CHAT_SYSTEM(skillStr)
                end;
    lock       = function() settings.lock = not settings.lock CHAT_SYSTEM('Frame lock '..BOOL_TO_WORD(settings.lock)..'.') end;
    buffs      = function() settings.buffs = not settings.buffs CHAT_SYSTEM('Buffs set to '..BOOL_TO_WORD(settings.buffs)..'.') end;
    skills     = function() settings.skills = not settings.skills CHAT_SYSTEM('Skills set to '..BOOL_TO_WORD(settings.skills)..'.') end;
    reset      = function() local ftMessage = settings.firstTimeMessage settings = default settings.firstTimeMessage = ftMessage CHAT_SYSTEM('Settings reset to defaults.') end;
    help       = function(func) CD_HELP_TABLE[func]() end;
    size       = function(num) settings.size = num CHAT_SYSTEM('Size scaling set to '..num..'.') end;
    status     = function() CHAT_SYSTEM('{nl} {nl}cdtracker status{nl}Alerts: '..BOOL_TO_WORD(settings.alerts)..
                '{nl}Text: '..BOOL_TO_WORD(settings.text)..
                '{nl}Sound: '..BOOL_TO_WORD(settings.sound)..
                '{nl}Lock: '..BOOL_TO_WORD(settings.lock)..
                '{nl}Soundtype: '..settings.soundtype..
                '{nl}Skin: '..settings.skin..
                '{nl}Size: '..settings.size..
                '{nl}Skill window coords: '..settings.skillPosX..', '..settings.skillPosY..
                '{nl}Buff window coords: '..settings.buffPosX..', '..settings.buffPosY..
                '{nl}Skill window toggle: '..BOOL_TO_WORD(settings.skills)..
                '{nl}Buff window toggle: '..BOOL_TO_WORD(settings.buffs)) end
}

setmetatable(CD_SETTINGS_TABLE, mt)
setmetatable(CD_HELP_TABLE, mt)

function CD_TRACKER_CHAT_CMD(command)
    local cmd  = ''
    local arg1 = ''
    local arg2 = ''
    if #command > 0 then
        cmd = table.remove(command, 1)
    end
    if #command > 0 then
        arg1 = table.remove(command, 1)
        if cmd ~= 'help' then
            arg1 = tonumber(arg1)
        end
    end
    if #command > 0 then
        arg2 = table.remove(command,1)
        while #command > 0 do
            arg2 = arg2..' '..table.remove(command,1)
        end
        CD_SETTINGS_TABLE[cmd](arg1, arg2)
    else
        CD_SETTINGS_TABLE[cmd](arg1)
    end
    CDTRACKER_SAVESETTINGS()
    return;
end
-- limit icon function calls
function CHECK_ICON_EXIST(icon)
    for k,v in pairs(cdTrackSkill['icon']) do
        if v == icon then
            return k
        end
    end
    newIconInfo = GRAB_SKILL_INFO(icon)
    for k,v in pairs(cdTrackSkill) do
        if cdTrackSkill[k]['fullName'] == newIconInfo['fullName'] then
            cdTrackSkill[k] = newIconInfo
            cdTrackSkill['icon'][k] = icon
            return k
        end
    end
    cdTrackSkill[skillIndex] = newIconInfo
    cdTrackSkill['icon'][skillIndex] = icon
    skillIndex = skillIndex+1
    return skillIndex-1
end

function GRAB_SKILL_INFO(icon)
    local tTime     = 0;
    local cTime     = 0;
    local iconInfo  = icon:GetInfo();
    local skillInfo = session.GetSkill(iconInfo.type);
    local sklObj    = GetIES(skillInfo:GetObject());
    if skillInfo ~= nil then
        cTime     = skillInfo:GetCurrentCoolDownTime();
        tTime     = skillInfo:GetTotalCoolDownTime();
        skillName = GetClassByType("Skill", sklObj.ClassID).ClassName
    end
    local skillInfoTable = {
    sklInfo     = skillInfo;
    curTime     = cTime;
    curTimeSecs = math.ceil(cTime/1000);
    totalTime   = tTime;
    obj         = GetClassByType("Skill", sklObj.ClassID);
    prevTime    = 0;
    slot        = 0;
    fullName    = string.sub(string.match(skillName,'_.+'),2):gsub("%u", " %1"):sub(2)
    }
    return skillInfoTable;
end
-- calculate frame position for each index
function FIND_NEXT_SLOT(index, cdtype)
    if cdtype == 'SKILL' then
        cdTrackType = cdTrackSkill
    else
        cdTrackType = cdTrackBuff
    end
    -- first see if index exists
    for k,v in pairs(cdTrackType['Slots']) do
        if v == index then
            return tonumber(k)
        end
    end
    -- if not, then place in first empty slot
    for i = 1,100 do
        if cdTrackType['Slots'][i] == nil then
            cdTrackType['Slots'][i] = index
            return i
        end
    end
end

function ICON_USE_HOOKED(object, reAction)
    _G['ICON_USE_OLD'](object, reAction);
    -- CHANGE_MOUSE_CURSOR("MORU", "MORU_UP", "CURSOR_CHECK_REINF");
    -- RESET_MOUSE_CURSOR();
    local iconPt = object;
    if iconPt  ~=  nil then
        local icon = tolua.cast(iconPt, 'ui::CIcon');
        local index = CHECK_ICON_EXIST(icon)
        cdTrackSkill[index]['curTime']     = cdTrackSkill[index]['sklInfo']:GetCurrentCoolDownTime();
        cdTrackSkill[index]['curTimeSecs'] = math.ceil(cdTrackSkill[index]['curTime']/1000)
        if cdTrackSkill[index]['curTimeSecs'] ~= 0 then
            for i = 1,3 do
                ui.AddText('SystemMsgFrame',' ')
            end
            ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
        end
        if settings.chatList['[Skill] '..cdTrackSkill[index]['fullName']] == true and cdTrackSkill[index]['curTimeSecs'] == 0 and checkChatFrame:IsVisible() == 0 then
            if settings.message['[Skill] '..cdTrackSkill[index]['fullName']] then
                ui.Chat('!!'..settings.message['[Skill] '..cdTrackSkill[index]['fullName']])
            else
                local skillName = SANITIZE_SKILL_NAME(cdTrackSkill[index]['fullName']);
                ui.Chat('!!Casting '..skillName..'!');
            end
            msgDisplay  = true
            castMessage = true
            timer       = imcTime.GetAppTime()
        end
    else
        return;
    end
end

function ICON_UPDATE_SKILL_COOLDOWN_HOOKED(icon)
    if settings.alerts == false then
        return _G['ICON_UPDATE_SKILL_COOLDOWN_OLD'](icon)
    end
    local index = CHECK_ICON_EXIST(icon)
    if index == 1 and settings.buffs == true then    -- run once every loop through all skills
        CDTRACK_BUFF_CHECK()
    end

    cdTrackSkill[index]['curTime']     = cdTrackSkill[index]['sklInfo']:GetCurrentCoolDownTime();
    cdTrackSkill[index]['totalTime']   = cdTrackSkill[index]['sklInfo']:GetTotalCoolDownTime();
    cdTrackSkill[index]['curTimeSecs'] = math.ceil(cdTrackSkill[index]['curTime']/1000)

    if cdTrackSkill[index]['prevTime'] - cdTrackSkill[index]['curTimeSecs'] > 1 then
        cdTrackSkill[index]['prevTime'] = cdTrackSkill[index]['curTimeSecs']
        return cdTrackSkill[index]['curTime'], cdTrackSkill[index]['totalTime'];
    end
    if settings.checkVal >= cdTrackSkill[index]['curTimeSecs'] and cdTrackSkill[index]['prevTime'] ~= cdTrackSkill[index]['curTimeSecs'] then
        -- skill ready
        if cdTrackSkill[index]['curTimeSecs'] == 0 then
            if settings.chatList['[Skill] '..cdTrackSkill[index]['fullName']] == true and checkChatFrame:IsVisible() == 0 and not castMessage then
                local skillName = SANITIZE_SKILL_NAME(cdTrackSkill[index]['fullName']);
                ui.Chat('!!'..skillName..' ready!')
                msgDisplay = true
                timer = imcTime.GetAppTime()
            end
            if settings.ignoreList['[Skill] '..cdTrackSkill[index]['fullName']] ~= true then
                if settings.sound == true then
                    if settings.soundtype > 0 and settings.soundtype <= table.getn(soundTypes) then
                        imcSound.PlaySoundEvent(soundTypes[settings.soundtype]);
                    else
                        imcSound.PlaySoundEvent(soundTypes[1])
                    end
                end
                if settings.text == true then
                    for i = 1,3 do
                        ui.AddText('SystemMsgFrame',' ')
                    end
                    ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready.')
                end
                if settings.skills == true then
                    DISPLAY_SLOT(index, cdTrackSkill[index]['slot'],cdTrackSkill[index]['fullName'],cdTrackSkill[index]['curTimeSecs'], 'SKILL', cdTrackSkill[index]['obj'],2)
                end
            end
            cdTrackSkill[index]['prevTime'] = 0
            return cdTrackSkill[index]['curTime'], cdTrackSkill[index]['totalTime'];
        end
        -- show skill on cd
        if settings.chatList['[Skill] '..cdTrackSkill[index]['fullName']] == true and checkChatFrame:IsVisible() == 0 and not castMessage then
            local skillName = SANITIZE_SKILL_NAME(cdTrackSkill[index]['fullName']);
            ui.Chat('!!'..skillName..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
            msgDisplay = true
            timer = imcTime.GetAppTime()
        end
        if settings.ignoreList['[Skill] '..cdTrackSkill[index]['fullName']] ~= true then
            if settings.text == true then
                for i = 1,3 do
                    ui.AddText('SystemMsgFrame',' ')
                end
                ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
            end
            if settings.skills == true then
                cdTrackSkill[index]['slot'] = FIND_NEXT_SLOT(index,'SKILL')
                DISPLAY_SLOT(index, cdTrackSkill[index]['slot'],cdTrackSkill[index]['fullName'],cdTrackSkill[index]['curTimeSecs'], 'SKILL', cdTrackSkill[index]['obj'],2)
            end
        end
    end
    if settings.chatList['[Skill] '..cdTrackSkill[index]['fullName']] == true then
        if TIME_ELAPSED(2) and msgDisplay == true and checkChatFrame:IsVisible() == 0 then
            ui.Chat('!!')
            castMessage = false
            msgDisplay  = false
        end
    end
    cdTrackSkill[index]['prevTime'] = cdTrackSkill[index]['curTimeSecs']
    return cdTrackSkill[index]['curTime'], cdTrackSkill[index]['totalTime'];
end
-- begin buff section
-- retrieve all buff info
function CDTRACK_BUFF_CHECK()
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
                    cdTrackBuff['time'][cls.Name]  = math.ceil(buff.time/1000)
                    cdTrackBuff['class'][cls.Name] = cls
                    if settings.ignoreList['[Buff] '..dictionary.ReplaceDicIDInCompStr(cls.Name)] ~= true then
                        CDTRACK_BUFF_DISPLAY(cls.Name,buff.buffID)
                    end
                end
            end
        end
    end
end
-- prepare buff data for display
function CDTRACK_BUFF_DISPLAY(name,ID)
    local bufftype = ''
    if cdTrackBuff['class'][name].Group1 == 'Debuff' then
        bufftype = 'DEBUFF'
    else
        bufftype = 'BUFF'
    end
    if cdTrackBuff['prevTime'][name] ~= cdTrackBuff['time'][name] then
        cdTrackBuff['slot'][name] = FIND_NEXT_SLOT(name, 'BUFF')
        if cdTrackBuff['time'][name] == 0 and cdTrackBuff['prevTime'][name] == 1 then
            if settings.sound == true then
                imcSound.PlaySoundEvent("sys_jam_slot_equip");
            end
            DISPLAY_SLOT(name, cdTrackBuff['slot'][name],name,cdTrackBuff['time'][name], bufftype, cdTrackBuff['class'][name],2)
            cdTrackBuff['prevTime'][name] = 0
            return;
        end
        DISPLAY_SLOT(name, cdTrackBuff['slot'][name],name,cdTrackBuff['time'][name], bufftype, cdTrackBuff['class'][name],2)
    end
    cdTrackBuff['prevTime'][name] = cdTrackBuff['time'][name]
    return;
end
-- draw frame to screen
function DISPLAY_SLOT(index, slot, name, cooldown, cdtype, obj, duration)
    if kbSelectMode == 1 then
        return;
    end
    CLEANUP_SLOTS()
    cdFrame   = ui.CreateNewFrame('cdtracker','FRAME_'..cdtype..slot)
    iconFrame = ui.CreateNewFrame('cdtracker','ICONFRAME_'..cdtype..slot)

    skillFrame['cdFrame_'..cdtype][slot]   = cdFrame
    skillFrame['iconFrame_'..cdtype][slot] = iconFrame

    local skinSetting = frameSkins[settings.skin]
    if skinSetting == nil then
        cdFrame:SetSkinName(frameSkins[1])
    else
        cdFrame:SetSkinName(frameSkins[settings.skin])
    end
    -- create elements
    for kf,vf in pairs(cdFrameList) do
        if vf == 'iconFrame_' or vf == 'cdFrame_' then
        elseif vf == 'icon_' then
            skillFrame[vf..cdtype][slot] = iconFrame:CreateOrGetControl('picture','cd_icon_'..cdtype..slot, 0,0,0,0)
            skillFrame[vf..cdtype][slot] = tolua.cast(skillFrame[vf..cdtype][slot],'ui::CPicture')
        else
            skillFrame[vf..cdtype][slot] = cdFrame:CreateOrGetControl('richtext','cd_'..vf..cdtype..slot, 0,0,0,0)
            skillFrame[vf..cdtype][slot] = tolua.cast(skillFrame[vf..cdtype][slot],'ui::CRichText')
        end
        skillFrame[vf..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)
        skillFrame[vf..cdtype][slot]:EnableHitTest(0)
    end
    cdFrame:Resize(settings.size * 325,settings.size * 50)
    iconFrame:Resize(settings.size * 50,settings.size * 50)
    if settings.lock then
        cdFrame:EnableHitTest(0)
    else
        cdFrame:EnableHitTest(1)
        cdFrame:SetEventScript(ui.LBUTTONDOWN, "CD_DRAG_START");
        cdFrame:SetEventScript(ui.LBUTTONUP, "CD_DRAG_STOP('"..cdtype.."',"..slot..")");
    end
    iconFrame:EnableHitTest(0)
    -- position elements
    skillFrame['cooldown_'..cdtype][slot]:SetOffset(math.ceil(15*settings.size),0)
    skillFrame['name_'..cdtype][slot]:SetOffset(math.ceil(140*settings.size),0)
    skillFrame['type_'..cdtype][slot]:SetOffset(math.ceil(50*settings.size),0)

    local fontSize   = math.ceil(18 * settings.size)
    local colors     = {red = '{#cc0000}', green = '{#00cc00}', yellow = '{#cccc00}', orange = '{#cc6600}'}
    local cdtext     = '{@st41}{s'..fontSize..'}'
    local cdtextdata = {color = '', cd = '', type = '', name = name}
    -- set display options
    if cdtype == 'SKILL' then
        cdtextdata.type = '{#ffe600}[SKILL]'
        local totalCd = cdTrackSkill[index]['totalTime']
        if cooldown == 0 then
            cdtextdata.color, cdtextdata.cd = colors.green, '-'
        elseif cooldown < (totalCd/1000)*.33 then
            cdtextdata.color, cdtextdata.cd = colors.yellow, cooldown
        elseif cooldown < (totalCd/1000)*.66 then
            cdtextdata.color, cdtextdata.cd = colors.orange, cooldown
        else
            cdtextdata.color, cdtextdata.cd = colors.red, cooldown
        end
    end
    if cdtype == 'BUFF' then
        cdtextdata.type = '{#00e6cf}[BUFF]'
        if cooldown == 0 then
            cdtextdata.color, cdtextdata.cd = colors.red, '-'
        elseif cooldown <= 5 then
            cdtextdata.color, cdtextdata.cd = colors.orange, cooldown
        elseif cooldown < 10 then
            cdtextdata.color, cdtextdata.cd = colors.yellow, cooldown
        else
            cdtextdata.color, cdtextdata.cd = colors.green, cooldown
        end
    end
    if cdtype == 'DEBUFF' then
        cdtextdata.type = '{#cc0000}[DEBUFF]'
        if cooldown == 0 then
            cdtextdata.color, cdtextdata.cd = colors.green, '-'
        elseif cooldown <= 5 then
            cdtextdata.color, cdtextdata.cd = colors.yellow, cooldown
        elseif cooldown < 10 then
            cdtextdata.color, cdtextdata.cd = colors.orange, cooldown
        else
            cdtextdata.color, cdtextdata.cd = colors.red, cooldown
        end
    end
    skillFrame['name_'..cdtype][slot]:SetText(cdtext..cdtextdata.color..cdtextdata.name)
    skillFrame['cooldown_'..cdtype][slot]:SetText(cdtext..cdtextdata.color..cdtextdata.cd)
    skillFrame['type_'..cdtype][slot]:SetText(cdtext..cdtextdata.type)

    cdFrame:Resize(skillFrame['name_'..cdtype][slot]:GetWidth()+math.ceil(170*settings.size),math.ceil(settings.size*50))

    local iconname = "Icon_" .. obj.Icon
    skillFrame['icon_'..cdtype][slot]:SetImage(iconname)
    skillFrame['icon_'..cdtype][slot]:SetEnableStretch(1)
    skillFrame['icon_'..cdtype][slot]:Resize(math.ceil(settings.size * 50),math.ceil(settings.size * 50))

    cdFrame:ShowWindow(1)
    cdFrame:SetDuration(duration)

    if CD_DRAG_STATE == true then
        return iconFrame:ShowWindow(0);
    end
    -- move frame to correct position
    local movePosX, movePosY = nil
    if cdtype == 'SKILL' then
        movePosX, movePosY = settings.skillPosX, settings.skillPosY
    else
        movePosX, movePosY = settings.buffPosX, settings.buffPosY
    end
    cdFrame:MoveFrame(movePosX,movePosY+math.ceil(60*settings.size)*slot)
    iconFrame:MoveFrame(movePosX-math.ceil(65*settings.size),movePosY + math.ceil(60*settings.size)*slot)
    iconFrame:ShowWindow(1)
    -- visible duration based on cooldown
    if cdtype == 'SKILL' then
        local totalCd = cdTrackSkill[index]['totalTime']
        if cooldown == 0 then
            iconFrame:SetDuration(2)
        elseif cooldown <= .33*(totalCd/1000) then
            iconFrame:SetDuration(0.25)
        elseif cooldown <= .66*(totalCd/1000) then
            iconFrame:SetDuration(0.5)
        else
            iconFrame:SetDuration(1)
        end
    end
    if cdtype == 'BUFF' or cdtype == 'DEBUFF' then
        if cooldown == 0 then
            iconFrame:SetDuration(2)
        elseif cooldown < 3 then
            iconFrame:SetDuration(0.25)
        elseif cooldown < 5 then
            iconFrame:SetDuration(0.33)
        elseif cooldown < 10 then
            iconFrame:SetDuration(0.5)
        else
            iconFrame:SetDuration(2)
        end
    end
end
-- sort and list skills for settings
function GET_SKILL_LIST()
    skillList = {}
    for k,v in pairs(cdTrackSkill) do
        if type(tonumber(k)) == 'number' then
            skillList[k] = '[Skill] '..cdTrackSkill[k]['fullName']
        end
    end
    table.sort(skillList)
end

function GET_BUFF_LIST()
    buffList = {}
    for k,v in pairs(cdTrackBuff['class']) do
        local buffname = dictionary.ReplaceDicIDInCompStr(k)
        table.insert(buffList, '[Buff] '..buffname)
    end
    table.sort(buffList)
end

-- time calc for chat notification
function TIME_ELAPSED(val)
    local elapsed = imcTime.GetAppTime() - timer
    if elapsed > val then
        timer = imcTime.GetAppTime()
        return true
    end
    return false
end
function CDTRACKER_SHOW_FRAMES()
    DISPLAY_SLOT(1, 1, 'Skill Frame', 1, 'SKILL', cdTrackSkill[1]['obj'], 999)
    DISPLAY_SLOT(1, 1, 'Buff Frame', 1, 'BUFF',  cdTrackSkill[1]['obj'], 999)
end

function CLEANUP_SLOTS()
    local cdtypes = {'SKILL','BUFF'}
    for index, cdtype in pairs(cdtypes) do
        for slot = 1,#skillFrame['cdFrame_'..cdtype] do
            if ui.IsFrameVisible('FRAME_'..cdtype..slot) == 0 then
                if cdtype == 'SKILL' and cdTrackSkill['Slots'][slot] ~= nil then
                    cdTrackSkill['Slots'][slot] = nil
                end
                if cdtype == 'BUFF' and cdTrackBuff['Slots'][slot] ~= nil then
                    cdTrackBuff['Slots'][slot] = nil
                end
            end
        end
    end
end

function SANITIZE_SKILL_NAME(skillName)
    local blockedSkillNameList = {
        {search = 'Mass Heal', replace = 'Mаss Heal'} -- a here is U+0430
    }

    for i = 1, #blockedSkillNameList do
        local pattern = blockedSkillNameList[i];
        if (string.find(skillName, pattern.search)) then
            return string.gsub(skillName, pattern.search, pattern.replace);
        end
    end
    return skillName;
end