local acutil = require('acutil')
local _G = _G

local settings = {}
local default = {
    alerts           = true;
    buffPosX         = 100;
    buffPosY         = 200;
    buffs            = true;
    chatList         = {};
    chattype         = 1;
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
    time             = {}
    }

local soundTypes = {'button_click_stats_up','quest_count','quest_event_start','quest_success_2','sys_alarm_mon_kill_count','quest_event_click','sys_secret_alarm', 'travel_diary_1','button_click_4'}

local frameSkins = {'box_glass', 'slot_name', 'shadow_box', 'frame_bg', 'textview', 'chat_window', 'tooltip1'}

local chatTypes = {'!!','/p '}

-- store skill/buff
local skillIndex      = 1
cdTrackSkill          = {}
cdTrackSkill['Slots'] = {}
cdTrackSkill['icon']  = {}

cdTrackBuff = {}
cdBuffList        = {'time','prevTime','slot','class','Slots','active'}
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
    acutil.setupHook(QUICKSLOTNEXPBAR_ON_DROP_HOOKED,'QUICKSLOTNEXPBAR_ON_DROP')
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
    acutil.slashCommand('/cdtracker',CDTRACKER_TOGGLE_FRAME)
    CDTRACKER_LOADSETTINGS()
    if not settings.firstTimeMessage then
        ui.MsgBox("{s18}{#c70404}Important:{nl} {nl}{#000000}CDTracker Beta settings have been changed, if you are upgrading from an older version please reset using{nl} {nl}{#03134d}/cd reset{nl} {nl}This message will only show once.","helpBoxTable.helpBox_1()","helpBoxTable.helpBox_1()");
        settings.firstTimeMessage = true
        CDTRACKER_SAVESETTINGS()
    end
    local convertList = {settings.ignoreList, settings.chatList, settings.message, settings.time}
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

function QUICKSLOTNEXPBAR_ON_DROP_HOOKED(frame, control, argStr, argNum)
    skillIndex      = 1
    cdTrackSkill          = {}
    cdTrackSkill['Slots'] = {}
    cdTrackSkill['icon']  = {}
    return _G['QUICKSLOTNEXPBAR_ON_DROP_OLD'](frame, control, argStr, argNum)
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
        "/cd chat <ID> <message>{#000000} toggles broadcasting for specific skills. Message is optional custom message when casting.{nl} {nl}{#03134d}"..
        "/cd chattype <type>{#000000} changes chat channel for broadcasting. 1 = All, 2 = Party. (Default 1){nl} {nl}{#03134d}"..
        "/cd time <ID> <time> {#000000} sets individual skill timers.","helpBoxTable.helpBox_4()","helpBoxTable.helpBox_4()") end;
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
    chattype   = function() CHAT_SYSTEM('Usage: /cd chattype <type> will set the chat type, type 1 = All, type 2 = Party.') end;
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
    time       = function() CHAT_SYSTEM('Usage: /cd time <ID> <time> allows you to set timers for individual skills.{nl}Default: '..default.checkVal) end;
}

local CD_SETTINGS_TABLE = {
    on         = function() settings.alerts = true CHAT_SYSTEM('Alerts on.') end;
    off        = function() settings.alerts = false CHAT_SYSTEM('Alerts off.') end;
    sound      = function(num)
                if type(num)                       == 'number' then
                    settings.soundtype             = num
                    CHAT_SYSTEM('Soundtype set to '..soundTypes[num]..'.')
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
                    if not settings.chatList[skillList[ID]] and settings.chattype == 1 then
                        ui.Chat('!!')
                    end
                    CHAT_SYSTEM('Chat for '..skillList[ID]..' set to '..BOOL_TO_WORD(settings.chatList[skillList[ID]])..'.')
                    return;
                end
                settings.chatList[skillList[ID]]       = true
                CHAT_SYSTEM('Chat for '..skillList[ID]..' set to on.') end;

    chattype   = function(num) local ctype = {'all', 'party'} if num == 1 or num == 2 then settings.chattype = num CHAT_SYSTEM('Chat type set to '..ctype[num]..'.') else CHAT_SYSTEM('Invalid chat type.') end ui.Chat('!!') end;

    time       = function(ID, customtime)
                if customtime ~= nil and type(tonumber(customtime)) == 'number' then
                    settings.time[skillList[ID]]       = tonumber(customtime)
                    CHAT_SYSTEM('Time for '..skillList[ID]..' set to '..customtime..'.')
                else
                    CHAT_SYSTEM('Invalid time value.')
                end
                return;
                end;
    skillX     = function(num) settings.skillPosX = num CHAT_SYSTEM('Skill X set to '..num..'.') end;
    skillY     = function(num) settings.skillPosY = num CHAT_SYSTEM('Skill Y set to '..num..'.') end;
    buffX      = function(num) settings.buffPosX = num CHAT_SYSTEM('Buff X set to '..num..'.') end;
    buffY      = function(num) settings.buffPosY = num CHAT_SYSTEM('Buff Y set to '..num..'.') end;
    showframes = function() CDTRACKER_SHOW_FRAMES() end;
    skin       = function(num) settings.skin = num CHAT_SYSTEM('Skin set to '..frameSkins[num]..'.') end;
    list       = function() GET_SKILL_LIST() local skillStr = 'Skills:{nl}'
                for k,v in ipairs(skillList) do
                    local time = settings.checkVal
                    if settings.time[v] ~= nil then
                        time = settings.time[v]
                    end
                    skillStr = skillStr..'ID '..k..': '..v..' - alert '..BOOL_TO_WORD(not settings.ignoreList[v])..' - chat '..BOOL_TO_WORD(settings.chatList[v])..' - time '..time..'{nl}'
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

cdLastSkillCast = nil

function ICON_USE_HOOKED(object, reAction)
    
    local iconPt = object;
    if iconPt  ~=  nil then
        local icon = tolua.cast(iconPt, 'ui::CIcon');
        local iconInfo = icon:GetInfo()
        if iconInfo.category == 'Skill' then
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
                if cdLastSkillCast == cdTrackSkill[index]['fullName'] and not TIME_ELAPSED(1) then
                else
                    if settings.message['[Skill] '..cdTrackSkill[index]['fullName']] then
                        ui.Chat(chatTypes[settings.chattype]..SANITIZE_CHAT_OUTPUT(settings.message['[Skill] '..cdTrackSkill[index]['fullName']]))
                    else
                        ui.Chat(chatTypes[settings.chattype]..'Casting '..SANITIZE_CHAT_OUTPUT(cdTrackSkill[index]['fullName']..'!'))
                    end
                    if settings.chattype == 1 then
                        msgDisplay  = true
                        castMessage = true
                    else
                        msgDisplay  = false
                        castMessage = false
                    end
                    timer = imcTime.GetAppTime()
                end
                cdLastSkillCast = cdTrackSkill[index]['fullName']
            end
        end
    end
    return _G['ICON_USE_OLD'](object, reAction);
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
    local skillCheckVal = settings.checkVal
    if settings.time['[Skill] '..cdTrackSkill[index]['fullName']] ~= nil then
        skillCheckVal = tonumber(settings.time['[Skill] '..cdTrackSkill[index]['fullName']])
    end
    if skillCheckVal >= cdTrackSkill[index]['curTimeSecs'] and cdTrackSkill[index]['prevTime'] ~= cdTrackSkill[index]['curTimeSecs'] then
        -- skill ready
        if cdTrackSkill[index]['curTimeSecs'] == 0 then
            if settings.chatList['[Skill] '..cdTrackSkill[index]['fullName']] == true and checkChatFrame:IsVisible() == 0 and not castMessage then
                ui.Chat(chatTypes[settings.chattype]..SANITIZE_CHAT_OUTPUT(cdTrackSkill[index]['fullName']..' ready!'))
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
            ui.Chat(chatTypes[settings.chattype]..SANITIZE_CHAT_OUTPUT(cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.'))
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
        if TIME_ELAPSED(2) and msgDisplay == true and checkChatFrame:IsVisible() == 0 and settings.chattype == 1 then
            ui.Chat('!!')
            timer = imcTime.GetAppTime()
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
    local buffID = {}

    local cdPrevActive = {}
    for k,v in pairs(cdTrackBuff['active']) do
        cdPrevActive[k] = v
        cdTrackBuff['active'][k] = 0
    end

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
                    cdTrackBuff['active'][cls.Name] = 1
                    buffID[cls.Name] = buff.buffID
                end
            end
        end
        -- for k,v in pairs(cdTrackBuff['active']) do
        --     if cdPrevActive[k] == 0 and v == 0 then
        --     elseif cdPrevActive[k] == 1 and v == 0 then



    end
    for k,v in pairs(cdTrackBuff['active']) do 
        if settings.ignoreList['[Buff] '..dictionary.ReplaceDicIDInCompStr(k)] ~= true then
            CDTRACK_BUFF_DISPLAY(k,buffID[k],cdPrevActive[k])
        end
    end
end
-- prepare buff data for display
function CDTRACK_BUFF_DISPLAY(name,ID,prevActive)
    local bufftype = ''
    if cdTrackBuff['class'][name].Group1 == 'Debuff' then
        bufftype = 'DEBUFF'
    else
        bufftype = 'BUFF'
    end
    if cdTrackBuff['active'][name] == 1 then
        cdTrackBuff['slot'][name] = FIND_NEXT_SLOT(name, 'BUFF')
    end

    if cdTrackBuff['active'][name] == 0 and prevActive == 1 then
        if settings.sound == true then
            imcSound.PlaySoundEvent("sys_jam_slot_equip");
        end
        DISPLAY_SLOT(name, cdTrackBuff['slot'][name],name,cdTrackBuff['time'][name], bufftype, cdTrackBuff['class'][name],0.1,ID)
        cdTrackBuff['prevTime'][name] = 0
        return;
    end

    if cdTrackBuff['prevTime'][name] ~= cdTrackBuff['time'][name] then
        DISPLAY_SLOT(name, cdTrackBuff['slot'][name],name,cdTrackBuff['time'][name], bufftype, cdTrackBuff['class'][name],2,ID)
    end
    cdTrackBuff['prevTime'][name] = cdTrackBuff['time'][name]
    if cdTrackBuff['active'][name] == 1 then
        DISPLAY_SLOT(name, cdTrackBuff['slot'][name],name,cdTrackBuff['time'][name], bufftype, cdTrackBuff['class'][name],2,ID)
    end
    return;
end
-- draw frame to screen
function DISPLAY_SLOT(index, slot, name, cooldown, cdtype, obj, duration, buffArg)
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
    -- if cdtype == 'BUFF' then
    --     iconFrame:EnableHitTest(1)
    --     iconFrame:EnableDrop(0);
    --     iconFrame:EnableDrag(0);
    --     iconFrame:SetEventScript(ui.RBUTTONUP, 'packet.ReqRemoveBuff(buffArg)');
    -- else
    --     iconFrame:EnableHitTest(0)
    -- end
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
            iconFrame:SetDuration(0.1)
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

function SANITIZE_CHAT_OUTPUT(words)
    badword = IsBadString(words)
    if badword ~= nil then
        if badword:find(' ') ~= nil then
            badword_sanitized = badword:gsub(' ',' ')
            words = words:gsub(badword,badword_sanitized)
        else
            words = words:gsub(badword, badword:sub(1,1)..'@dicID_^*$BADWORDS_20150317_000001$*^'..badword:sub(2))
        end
        return SANITIZE_CHAT_OUTPUT(words)
    else
        return words
    end
end



-- Begin UI




cdTrackerUI = nil
cdTrackerSkillsUI = nil
cdTrackerUIObjects = {}

function CD_CLOSE_FRAMES()
    cdTrackerUI = ui.GetFrame('CDTRACKER_UI')
    cdTrackerSkillsUI = ui.GetFrame('CDTRACKER_SKILLS_UI')

    if cdTrackerUI ~= nil then
        cdTrackerUI:ShowWindow(0)
    end
    if cdTrackerSkillsUI ~= nil then
        cdTrackerSkillsUI:ShowWindow(0)
    end
end

function CDTRACKER_CREATE_FRAME()
    CDTRACKER_LOADSETTINGS()
    cdTrackerUI = ui.CreateNewFrame('cdtracker','CDTRACKER_UI')
    cdTrackerUI:SetLayerLevel(100)
    cdTrackerUI:SetSkinName(frameSkins[7])
    cdTrackerUI:Resize(500,500)
    cdTrackerUI:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    cdTrackerUI:SetEventScript(ui.RBUTTONUP,'CD_CLOSE_FRAMES')

    cdTrackerUIObjects['header'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_HEADER', 0,15,200,55)
    cdTrackerUIObjects['header'] = tolua.cast(cdTrackerUIObjects['header'],'ui::CRichText')
    cdTrackerUIObjects['header']:SetText('{@st66b}{s24}{#ffffff}Cooldown Tracker Settings{/}')
    cdTrackerUIObjects['header']:SetSkinName("textview");
    cdTrackerUIObjects['header']:EnableHitTest(0)
    cdTrackerUIObjects['header']:SetGravity(ui.CENTER_HORZ,ui.TOP)

    cdTrackerUIObjects['close'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_CLOSE', 460,10,30,30)
    cdTrackerUIObjects['close'] = tolua.cast(cdTrackerUIObjects['close'],'ui::CButton')
    cdTrackerUIObjects['close']:SetText('{@st66b}X{/}')
    cdTrackerUIObjects['close']:SetClickSound("button_click_big");
    cdTrackerUIObjects['close']:SetOverSound("button_over");
    cdTrackerUIObjects['close']:SetEventScript(ui.LBUTTONUP, "CD_CLOSE_FRAMES");
    cdTrackerUIObjects['close']:SetSkinName("test_pvp_btn");

    cdTrackerUIObjects['enabled'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_ENABLED', 30,55,200,30)
    cdTrackerUIObjects['enabled'] = tolua.cast(cdTrackerUIObjects['enabled'],'ui::CButton')
    if settings.alerts then enabled = '{#00cc00}on' else enabled = '{#cc0000}off' end
    cdTrackerUIObjects['enabled']:SetText('{@st66b}{#ffffff}cdtracker: '..enabled..'{/}')
    cdTrackerUIObjects['enabled']:SetClickSound("button_click_big");
    cdTrackerUIObjects['enabled']:SetOverSound("button_over");
    cdTrackerUIObjects['enabled']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('enabled')");
    cdTrackerUIObjects['enabled']:SetSkinName("quest_box");

    cdTrackerUIObjects['skills'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_SKILLWINDOW', 30,90,200,30)
    cdTrackerUIObjects['skills'] = tolua.cast(cdTrackerUIObjects['skills'],'ui::CButton')
    if settings.skills then skills = '{#00cc00}on' else skills = '{#cc0000}off' end
    cdTrackerUIObjects['skills']:SetText('{@st66b}{#ffffff}skills: '..skills..'{/}')

    cdTrackerUIObjects['skills']:SetClickSound("button_click_big");
    cdTrackerUIObjects['skills']:SetOverSound("button_over");
    cdTrackerUIObjects['skills']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('skills')");
    cdTrackerUIObjects['skills']:SetSkinName("quest_box");

    cdTrackerUIObjects['buffs'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_BUFFWINDOW', 30,125,200,30)
    cdTrackerUIObjects['buffs'] = tolua.cast(cdTrackerUIObjects['buffs'],'ui::CButton')
    if settings.buffs then buffs = '{#00cc00}on' else buffs = '{#cc0000}off' end
    cdTrackerUIObjects['buffs']:SetText('{@st66b}{#ffffff}buffs: '..buffs..'{/}')
    cdTrackerUIObjects['buffs']:SetClickSound("button_click_big");
    cdTrackerUIObjects['buffs']:SetOverSound("button_over");
    cdTrackerUIObjects['buffs']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('buffs')");
    cdTrackerUIObjects['buffs']:SetSkinName("quest_box");

    cdTrackerUIObjects['text'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_TEXT', 30,160,200,30)
    cdTrackerUIObjects['text'] = tolua.cast(cdTrackerUIObjects['text'],'ui::CButton')
    if settings.text then text = '{#00cc00}on' else text = '{#cc0000}off' end
    cdTrackerUIObjects['text']:SetText('{@st66b}{#ffffff}text: '..text..'{/}')
    cdTrackerUIObjects['text']:SetClickSound("button_click_big");
    cdTrackerUIObjects['text']:SetOverSound("button_over");
    cdTrackerUIObjects['text']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('text')");
    cdTrackerUIObjects['text']:SetSkinName("quest_box");

    cdTrackerUIObjects['sound'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_SOUND', 30,195,200,30)
    cdTrackerUIObjects['sound'] = tolua.cast(cdTrackerUIObjects['sound'],'ui::CButton')
    if settings.sound then sound = '{#00cc00}on' else sound = '{#cc0000}off' end
    cdTrackerUIObjects['sound']:SetText('{@st66b}{#ffffff}sound: '..sound..'{/}')
    cdTrackerUIObjects['sound']:SetClickSound("button_click_big");
    cdTrackerUIObjects['sound']:SetOverSound("button_over");
    cdTrackerUIObjects['sound']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('sound')");
    cdTrackerUIObjects['sound']:SetSkinName("quest_box");

    cdTrackerUIObjects['lock'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_LOCK', 30,230,200,30)
    cdTrackerUIObjects['lock'] = tolua.cast(cdTrackerUIObjects['lock'],'ui::CButton')
    if settings.lock then lock = '{#00cc00}on' else lock = '{#cc0000}off' end
    cdTrackerUIObjects['lock']:SetText('{@st66b}{#ffffff}lock: '..lock..'{/}')
    cdTrackerUIObjects['lock']:SetClickSound("button_click_big");
    cdTrackerUIObjects['lock']:SetOverSound("button_over");
    cdTrackerUIObjects['lock']:SetEventScript(ui.LBUTTONUP, "TOGGLE_CD('lock')");
    cdTrackerUIObjects['lock']:SetSkinName("quest_box");

    cdTrackerUIObjects['showframes'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_SHOWFRAMES', 30,265,200,30)
    cdTrackerUIObjects['showframes'] = tolua.cast(cdTrackerUIObjects['showframes'],'ui::CButton')
    cdTrackerUIObjects['showframes']:SetText('{@st66b}{#ffffff}show frames{/}')
    cdTrackerUIObjects['showframes']:SetClickSound("button_click_big");
    cdTrackerUIObjects['showframes']:SetOverSound("button_over");
    cdTrackerUIObjects['showframes']:SetEventScript(ui.LBUTTONUP, "ui.Chat('/cd showframes')");
    cdTrackerUIObjects['showframes']:SetSkinName("quest_box");

    cdTrackerUIObjects['time'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_TIME', 270,95,200,30)
    cdTrackerUIObjects['time'] = tolua.cast(cdTrackerUIObjects['time'],'ui::CRichText')
    cdTrackerUIObjects['time']:SetText('{@st66b}{#ffffff}time:{/}')
    cdTrackerUIObjects['time']:SetSkinName("textview");
    cdTrackerUIObjects['time']:EnableHitTest(0)

    cdTrackerUIObjects['timebox'] = cdTrackerUI:CreateOrGetControl('edit','CDTRACKER_TIMEBOX', 320,90,50,30)
    cdTrackerUIObjects['timebox'] = tolua.cast(cdTrackerUIObjects['timebox'],'ui::CEditControl')

    cdTrackerUIObjects['timelabel'] = cdTrackerUIObjects['timebox']:CreateOrGetControl('richtext','CDTRACKER_TIMELABEL', 0,0,30,30)
    cdTrackerUIObjects['timelabel'] = tolua.cast(cdTrackerUIObjects['timelabel'],'ui::CRichText')
    cdTrackerUIObjects['timelabel']:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    cdTrackerUIObjects['timelabel']:EnableHitTest(0)
    cdTrackerUIObjects['timelabel']:SetText('{@st66b}{#ffffff}'..settings.checkVal)

    cdTrackerUIObjects['timebox']:SetEventScript(ui.LBUTTONUP,"cdTrackerUIObjects['timelabel']:ShowWindow(0)")
    cdTrackerUIObjects['timebox']:SetLostFocusingScp("cdTrackerUIObjects['timelabel']:ShowWindow(1)")
    cdTrackerUIObjects['timebox']:SetEventScript(ui.ENTERKEY,"CD_SET_MAIN_TIME")

    cdTrackerUIObjects['size'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_SIZE', 270,130,200,30)
    cdTrackerUIObjects['size'] = tolua.cast(cdTrackerUIObjects['size'],'ui::CRichText')
    cdTrackerUIObjects['size']:SetText('{@st66b}{#ffffff}size:{/}')
    cdTrackerUIObjects['size']:SetSkinName("textview");
    cdTrackerUIObjects['size']:EnableHitTest(0)

    cdTrackerUIObjects['sizebox'] = cdTrackerUI:CreateOrGetControl('edit','CDTRACKER_SIZEBOX', 320,125,50,30)
    cdTrackerUIObjects['sizebox'] = tolua.cast(cdTrackerUIObjects['sizebox'],'ui::CEditControl')
    cdTrackerUIObjects['sizebox']:SetEventScript(ui.ENTERKEY,"CD_SET_SIZE")

    cdTrackerUIObjects['sizelabel'] = cdTrackerUIObjects['sizebox']:CreateOrGetControl('richtext','CDTRACKER_SIZELABEL', 0,0,30,30)
    cdTrackerUIObjects['sizelabel'] = tolua.cast(cdTrackerUIObjects['sizelabel'],'ui::CRichText')
    cdTrackerUIObjects['sizelabel']:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    cdTrackerUIObjects['sizelabel']:EnableHitTest(0)
    cdTrackerUIObjects['sizelabel']:SetText('{@st66b}{#ffffff}'..settings.size)

    cdTrackerUIObjects['sizebox']:SetEventScript(ui.LBUTTONUP,"cdTrackerUIObjects['sizelabel']:ShowWindow(0)")
    cdTrackerUIObjects['sizebox']:SetLostFocusingScp("cdTrackerUIObjects['sizelabel']:ShowWindow(1)")
    cdTrackerUIObjects['sizebox']:SetEventScript(ui.ENTERKEY,"CD_SET_SIZE")

    cdTrackerUIObjects['skin'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_SKIN',35,310,200,30)
    cdTrackerUIObjects['skin'] = tolua.cast(cdTrackerUIObjects['skin'],'ui::CRichText')
    cdTrackerUIObjects['skin']:SetText('{@st66b}{#ffffff}skin:{/}')
    cdTrackerUIObjects['skin']:SetSkinName("textview");
    cdTrackerUIObjects['skin']:EnableHitTest(0)

    cdTrackerUIObjects['skindroplist'] = cdTrackerUI:CreateOrGetControl('droplist','CDTRACKER_SKINDROPLIST', 100,310,375,20)
    cdTrackerUIObjects['skindroplist'] = tolua.cast(cdTrackerUIObjects['skindroplist'],'ui::CDropList')
    cdTrackerUIObjects['skindroplist']:SetSkinName('droplist_normal')

    for k,v in pairs(frameSkins) do 
        cdTrackerUIObjects['skindroplist']:AddItem(k,v,0,"ui.Chat('/cd skin "..k.."')")
    end
    cdTrackerUIObjects['skindroplist']:SelectItem(settings.skin-1)

    cdTrackerUIObjects['soundtype'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_SOUNDTYPE', 35,345,200,30)
    cdTrackerUIObjects['soundtype'] = tolua.cast(cdTrackerUIObjects['soundtype'],'ui::CRichText')
    cdTrackerUIObjects['soundtype']:SetText('{@st66b}{#ffffff}sound:{/}')
    cdTrackerUIObjects['soundtype']:SetSkinName("textview");
    cdTrackerUIObjects['soundtype']:EnableHitTest(0)

    cdTrackerUIObjects['soundtypedroplist'] = cdTrackerUI:CreateOrGetControl('droplist','CDTRACKER_SOUNDTYPEDROPLIST', 100,345,375,20)
    cdTrackerUIObjects['soundtypedroplist'] = tolua.cast(cdTrackerUIObjects['soundtypedroplist'],'ui::CDropList')
    cdTrackerUIObjects['soundtypedroplist']:SetSkinName('droplist_normal')

    for k,v in pairs(soundTypes) do 
        cdTrackerUIObjects['soundtypedroplist']:AddItem(k,v,0,"ui.Chat('/cd sound "..k.."')")
    end
    cdTrackerUIObjects['soundtypedroplist']:SelectItem(settings.soundtype-1)

    cdTrackerUIObjects['chattype'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_CHATTYPE', 270,230,200,30)
    cdTrackerUIObjects['chattype'] = tolua.cast(cdTrackerUIObjects['chattype'],'ui::CButton')
    if settings.chattype == 1 then chattype = 'all' else chattype = 'party' end
    cdTrackerUIObjects['chattype']:SetText('{@st66b}{#ffffff}chat type: '..chattype..'{/}')
    cdTrackerUIObjects['chattype']:SetClickSound("button_click_big");
    cdTrackerUIObjects['chattype']:SetOverSound("button_over");
    cdTrackerUIObjects['chattype']:SetEventScript(ui.LBUTTONUP, "CD_CHANGE_CHAT_TYPE");
    cdTrackerUIObjects['chattype']:SetSkinName("quest_box");

    cdTrackerUIObjects['autochatswap'] = cdTrackerUI:CreateOrGetControl('richtext','CDTRACKER_AUTOCHATSWAP', 270,270,200,30)
    cdTrackerUIObjects['autochatswap'] = tolua.cast(cdTrackerUIObjects['autochatswap'],'ui::CRichText')
    cdTrackerUIObjects['autochatswap']:SetText('{@st66b}{#ffffff}PvP auto party chat:{/}')
    cdTrackerUIObjects['autochatswap']:SetSkinName("textview");
    cdTrackerUIObjects['autochatswap']:EnableHitTest(0)

    cdTrackerUIObjects['autochatswapbox'] = cdTrackerUI:CreateOrGetControl('checkbox','CDTRACKER_BUTTON_AUTOCHATSWAPBOX',420,270,20,20)
    cdTrackerUIObjects['autochatswapbox'] = tolua.cast(cdTrackerUIObjects['autochatswapbox'],'ui::CCheckBox')
    cdTrackerUIObjects['autochatswapbox']:Resize(20,20)

    cdTrackerUIObjects['skillslist'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_SKILLSLIST', 270,55,200,30)
    cdTrackerUIObjects['skillslist'] = tolua.cast(cdTrackerUIObjects['skillslist'],'ui::CButton')
    cdTrackerUIObjects['skillslist']:SetText('{@st66b}{#ffffff}individual skill settings{/}')
    cdTrackerUIObjects['skillslist']:SetClickSound("button_click_big");
    cdTrackerUIObjects['skillslist']:SetOverSound("button_over");
    cdTrackerUIObjects['skillslist']:SetEventScript(ui.LBUTTONUP, "CD_LIST");
    cdTrackerUIObjects['skillslist']:SetSkinName("quest_box");

    cdTrackerUIObjects['reset'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_RESET', 270,450,200,30)
    cdTrackerUIObjects['reset'] = tolua.cast(cdTrackerUIObjects['reset'],'ui::CButton')
    cdTrackerUIObjects['reset']:SetText('{@st66b}{#ff0000}reset all settings{/}')
    cdTrackerUIObjects['reset']:SetClickSound("button_click_big");
    cdTrackerUIObjects['reset']:SetOverSound("button_over");
    cdTrackerUIObjects['reset']:SetEventScript(ui.LBUTTONUP, "CD_RESET_ALL_SETTINGS");
    cdTrackerUIObjects['reset']:SetSkinName("quest_box");

    cdTrackerUIObjects['helpbox'] = cdTrackerUI:CreateOrGetControl('button','CDTRACKER_BUTTON_HELPBOX', 30,450,200,30)
    cdTrackerUIObjects['helpbox'] = tolua.cast(cdTrackerUIObjects['helpbox'],'ui::CButton')
    cdTrackerUIObjects['helpbox']:SetText('{@st66b}{#ffff00}chat command help{/}')
    cdTrackerUIObjects['helpbox']:SetClickSound("button_click_big");
    cdTrackerUIObjects['helpbox']:SetOverSound("button_over");
    cdTrackerUIObjects['helpbox']:SetEventScript(ui.LBUTTONUP, "ui.Chat('/cd help all')");
    cdTrackerUIObjects['helpbox']:SetSkinName("quest_box");

end

function CD_RESET_ALL_SETTINGS()
    ui.MsgBox("{s24}{#ff0000}WARNING!{#000000}{nl} {nl}{#03134d}"..
        "{s18}Are you sure you want to reset all settings? This cannot be undone.","ui.Chat('/cd reset')","Nope")
end

function RETURN_SKILL_LIST()
    skillList = {}
    for k,v in pairs(cdTrackSkill) do
        if type(tonumber(k)) == 'number' then
            skillList[k] = '[Skill] '..cdTrackSkill[k]['fullName']
        end
    end
    table.sort(skillList)
    return skillList
end

function RETURN_BUFF_LIST()
    buffList = {}
    for k,v in pairs(cdTrackBuff['class']) do
        local buffname = dictionary.ReplaceDicIDInCompStr(k)
        table.insert(buffList, '[Buff] '..buffname)
    end
    table.sort(buffList)
    return buffList
end

function CD_MAINMENU()
    CD_CLOSE_FRAMES()
    CDTRACKER_TOGGLE_FRAME()
    if cdTrackerSkillsUI ~= nil then
        cdTrackerUI:SetPos(cdTrackerSkillsUI:GetX(),cdTrackerSkillsUI:GetY())
    end
end

function CD_LIST()
    CD_CLOSE_FRAMES()
    GET_SKILL_LIST()
    GET_BUFF_LIST()
    CDTRACKER_LOADSETTINGS()
    cdTrackerSkillsUI = ui.CreateNewFrame('cdtracker','CDTRACKER_SKILLS_UI')
    cdTrackerSkillsUI:SetLayerLevel(100)
    -- cdTrackerSkillsUI:EnableHitTest(0)
    cdTrackerSkillsUI:SetSkinName(frameSkins[7])
    cdTrackerSkillsUI:Resize(800,510)
    if cdTrackerUI~=nil then
        cdTrackerSkillsUI:SetPos(cdTrackerUI:GetX(),cdTrackerUI:GetY())
    end
    cdTrackerSkillsUI:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
    cdTrackerSkillsUI:SetEventScript(ui.RBUTTONUP,'CD_MAINMENU')
    cdTrackerSkillsUI:ShowWindow(1)

    cdTrackerUIObjects['close'] = cdTrackerSkillsUI:CreateOrGetControl('button','CDTRACKER_BUTTON_CLOSE', 760,10,30,30)
    cdTrackerUIObjects['close'] = tolua.cast(cdTrackerUIObjects['close'],'ui::CButton')
    cdTrackerUIObjects['close']:SetText('{@st66b}X{/}')
    cdTrackerUIObjects['close']:SetClickSound("button_click_big");
    cdTrackerUIObjects['close']:SetOverSound("button_over");
    cdTrackerUIObjects['close']:SetEventScript(ui.LBUTTONUP, "CD_CLOSE_FRAMES");
    cdTrackerUIObjects['close']:SetSkinName("test_pvp_btn");

    skillList = RETURN_SKILL_LIST()
    buffList = RETURN_BUFF_LIST()
    dots = '.........................................................................................................................................................................................'

    cdGroupBox = cdTrackerSkillsUI:CreateOrGetControl('groupbox','CDTRACKER_GROUPBOX',10,50,780,420)
    cdGroupBox = tolua.cast(cdGroupBox,'ui::CGroupBox')
    cdGroupBox:SetSkinName("textview")
    cdGroupBox:EnableHittestGroupBox(false)
    cdGroupBox:RemoveAllChild()

    cdTrackerUIObjects['skillname'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLNAME', 20,20,200,30)
    cdTrackerUIObjects['skillname'] = tolua.cast(cdTrackerUIObjects['skillname'],'ui::CRichText')
    cdTrackerUIObjects['skillname']:SetText('{@st66b}{#ffffff}Name{/}')
    cdTrackerUIObjects['skillname']:SetSkinName("textview");
    cdTrackerUIObjects['skillname']:EnableHitTest(0)

    cdTrackerUIObjects['skillalert'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLALERT', 300,20,200,30)
    cdTrackerUIObjects['skillalert'] = tolua.cast(cdTrackerUIObjects['skillalert'],'ui::CRichText')
    cdTrackerUIObjects['skillalert']:SetText('{@st66b}{#ffffff}Alerts{/}')
    cdTrackerUIObjects['skillalert']:SetSkinName("textview");
    cdTrackerUIObjects['skillalert']:EnableHitTest(0)

    cdTrackerUIObjects['skillchat'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLCHAT', 400,20,200,30)
    cdTrackerUIObjects['skillchat'] = tolua.cast(cdTrackerUIObjects['skillchat'],'ui::CRichText')
    cdTrackerUIObjects['skillchat']:SetText('{@st66b}{#ffffff}Chat{/}')
    cdTrackerUIObjects['skillchat']:SetSkinName("textview");
    cdTrackerUIObjects['skillchat']:EnableHitTest(0)

    cdTrackerUIObjects['skillmessage'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLMESSAGE', 525,20,200,30)
    cdTrackerUIObjects['skillmessage'] = tolua.cast(cdTrackerUIObjects['skillmessage'],'ui::CRichText')
    cdTrackerUIObjects['skillmessage']:SetText('{@st66b}{#ffffff}Message{/}')
    cdTrackerUIObjects['skillmessage']:SetSkinName("textview");
    cdTrackerUIObjects['skillmessage']:EnableHitTest(0)

    cdTrackerUIObjects['skilltime'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLTIME', 685,20,200,30)
    cdTrackerUIObjects['skilltime'] = tolua.cast(cdTrackerUIObjects['skilltime'],'ui::CRichText')
    cdTrackerUIObjects['skilltime']:SetText('{@st66b}{#ffffff}Time{/}')
    cdTrackerUIObjects['skilltime']:SetSkinName("textview");
    cdTrackerUIObjects['skilltime']:EnableHitTest(0)

    cdTrackerUIObjects['skillhelp'] = cdTrackerSkillsUI:CreateOrGetControl('richtext','CDTRACKER_SKILLHELP',20,475,200,30)
    cdTrackerUIObjects['skillhelp'] = tolua.cast(cdTrackerUIObjects['skillhelp'],'ui::CRichText')
    cdTrackerUIObjects['skillhelp']:SetText('{@st66b}{#ffffff}Right-click to return to the main menu.{/}')
    cdTrackerUIObjects['skillhelp']:SetSkinName("textview");
    cdTrackerUIObjects['skillhelp']:EnableHitTest(0)

    cdTrackerUIObjects['skillrefresh'] = cdTrackerSkillsUI:CreateOrGetControl('button','CDTRACKER_SKILLREFRESH',600,475,200,30)
    cdTrackerUIObjects['skillrefresh'] = tolua.cast(cdTrackerUIObjects['skillrefresh'],'ui::CButton')
    cdTrackerUIObjects['skillrefresh']:SetText('{@st66b}{#ffffff}refresh{/}')
    cdTrackerUIObjects['skillrefresh']:SetClickSound("button_click_big");
    cdTrackerUIObjects['skillrefresh']:SetOverSound("button_over");
    cdTrackerUIObjects['skillrefresh']:SetSkinName('quest_box')
    cdTrackerUIObjects['skillrefresh']:SetEventScript(ui.LBUTTONUP,"CD_LIST()")


    offset = 0
    for k, v in ipairs(skillList) do

        skillname = v:gsub('%[Skill%]','')

        cdTrackerUIObjects['skill'..k] = cdGroupBox:CreateOrGetControl('richtext','CDTRACKER_BUTTON_SKILL_'..k,10,10+offset,100,100)
        cdTrackerUIObjects['skill'..k] = tolua.cast(cdTrackerUIObjects['skill'..k],'ui::CRichText')
        cdTrackerUIObjects['skill'..k]:SetText('{@st66b}{#ffff55}[Skill]{#ffffff}'..skillname..'{/}')
        cdTrackerUIObjects['skill'..k]:EnableHitTest(0)

        cdTrackerUIObjects['skillalert'..k] = cdGroupBox:CreateOrGetControl('checkbox','CDTRACKER_BUTTON_SKILLALERT_'..k,300,10+offset,100,100)
        cdTrackerUIObjects['skillalert'..k] = tolua.cast(cdTrackerUIObjects['skillalert'..k],'ui::CCheckBox')
        cdTrackerUIObjects['skillalert'..k]:Resize(20,20)
        if settings.ignoreList[v] == true then
            cdTrackerUIObjects['skillalert'..k]:SetCheck(0)
        else
            cdTrackerUIObjects['skillalert'..k]:SetCheck(1)
        end
        cdTrackerUIObjects['skillalert'..k]:SetEventScript(ui.LBUTTONUP,"ui.Chat('/cd alert "..k.."') CDTRACKER_LOADSETTINGS() if settings.ignoreList[v] == true then cdTrackerUIObjects['skillalert'..k]:SetCheck(0) else cdTrackerUIObjects['skillalert'..k]:SetCheck(1) end")



        cdTrackerUIObjects['skillchat'..k] = cdGroupBox:CreateOrGetControl('checkbox','CDTRACKER_BUTTON_SKILLCHAT_'..k,400,10+offset,100,100)
        cdTrackerUIObjects['skillchat'..k] = tolua.cast(cdTrackerUIObjects['skillchat'..k],'ui::CCheckBox')
        cdTrackerUIObjects['skillchat'..k]:Resize(20,20)
        if settings.chatList[v] == true then
            cdTrackerUIObjects['skillchat'..k]:SetCheck(1)
        end
        cdTrackerUIObjects['skillchat'..k]:SetEventScript(ui.LBUTTONUP,"ui.Chat('/cd chat "..k.."') CDTRACKER_LOADSETTINGS() if settings.chatList[v] == true then cdTrackerUIObjects['skillchat'..k]:SetCheck(1) else cdTrackerUIObjects['skillchat'..k]:SetCheck(0) end")

        cdTrackerUIObjects['skillmessage'..k] = cdGroupBox:CreateOrGetControl('button','CDTRACKER_BUTTON_SKILLMESSAGE'..k, 450,10+offset,200,25)
        cdTrackerUIObjects['skillmessage'..k] = tolua.cast(cdTrackerUIObjects['skillmessage'..k],'ui::CButton')
        if settings.message[v] ~= nil then
            cdTrackerUIObjects['skillmessage'..k]:SetText('{@st46b}{s12}{#ffffff}'..settings.message[v]..'{/}')
            cdTrackerUIObjects['skillmessage'..k]:SetTextTooltip('{@st46b}{s12}{#ffffff}'..settings.message[v]..'{/}')
        else
            cdTrackerUIObjects['skillmessage'..k]:SetText('{@st46b}{s12}{#ffffff}Set Message{/}')
            cdTrackerUIObjects['skillmessage'..k]:SetTextTooltip('{@st46b}{s12}{#ffffff}Set Message{/}')
        end
        cdTrackerUIObjects['skillmessage'..k]:Resize(200,25)
        cdTrackerUIObjects['skillmessage'..k]:SetClickSound("button_click_big");
        cdTrackerUIObjects['skillmessage'..k]:SetOverSound("button_over");
        cdTrackerUIObjects['skillmessage'..k]:SetSkinName('quest_box')
        cdTrackerUIObjects['skillmessage'..k]:SetEventScript(ui.LBUTTONUP,"CD_SET_CHAT_MESSAGE("..k..")")
    
        cdTrackerUIObjects['skilltime'..k] = cdGroupBox:CreateOrGetControl('edit','CDTRACKER_SKILLTIME'..k, 685,10+offset,50,30)
        cdTrackerUIObjects['skilltime'..k] = tolua.cast(cdTrackerUIObjects['skilltime'..k],'ui::CEditControl')

        cdTrackerUIObjects['skilltimelabel'..k] = cdTrackerUIObjects['skilltime'..k]:CreateOrGetControl('richtext','CDTRACKER_SKILLTIMELABEL'..k, 0,0,30,30)
        cdTrackerUIObjects['skilltimelabel'..k] = tolua.cast(cdTrackerUIObjects['skilltimelabel'..k],'ui::CRichText')
        cdTrackerUIObjects['skilltimelabel'..k]:SetGravity(ui.CENTER_HORZ,ui.CENTER_VERT)
        cdTrackerUIObjects['skilltimelabel'..k]:EnableHitTest(0)

        if settings.time[v] == nil then
            cdTrackerUIObjects['skilltimelabel'..k]:SetText('{@st66b}{#ffffff}'..settings.checkVal)
        else
            cdTrackerUIObjects['skilltimelabel'..k]:SetText('{@st66b}{#ffffff}'..settings.time[v])
        end

        cdTrackerUIObjects['skilltime'..k]:SetEventScript(ui.LBUTTONUP,"cdTrackerUIObjects['skilltimelabel"..k.."']:ShowWindow(0)")
        cdTrackerUIObjects['skilltime'..k]:SetLostFocusingScp("cdTrackerUIObjects['skilltimelabel"..k.."']:ShowWindow(1)")
        cdTrackerUIObjects['skilltime'..k]:SetEventScript(ui.ENTERKEY,"CD_SET_TIME("..k..")")

        cdTrackerUIObjects['skill_'..k] = cdGroupBox:CreateOrGetControl('richtext','CDTRACKER_BUTTON_SKILL__'..k,10,25+offset,100,5)
        cdTrackerUIObjects['skill_'..k] = tolua.cast(cdTrackerUIObjects['skill_'..k],'ui::CRichText')
        cdTrackerUIObjects['skill_'..k]:SetText('{@st66b}{#708090}'..dots..'{/}')
        cdTrackerUIObjects['skill_'..k]:EnableHitTest(0)

        offset = offset+35
    end

    for k,v in ipairs(buffList) do 
        buffname = v:gsub('%[Buff%]','')
        cdTrackerUIObjects['buff'..k] = cdGroupBox:CreateOrGetControl('richtext','CDTRACKER_BUTTON_BUFF_'..k,10,10+offset,100,100)
        cdTrackerUIObjects['buff'..k] = tolua.cast(cdTrackerUIObjects['buff'..k],'ui::CRichText')
        cdTrackerUIObjects['buff'..k]:SetText('{@st66b}{#ccffff}[Buff]{#ffffff}'..buffname..'{/}')
        cdTrackerUIObjects['buff'..k]:EnableHitTest(0)

        cdTrackerUIObjects['buffalert'..k] = cdGroupBox:CreateOrGetControl('checkbox','CDTRACKER_BUTTON_BUFFALERT_'..k,300,10+offset,100,100)
        cdTrackerUIObjects['buffalert'..k] = tolua.cast(cdTrackerUIObjects['buffalert'..k],'ui::CCheckBox')
        cdTrackerUIObjects['buffalert'..k]:Resize(20,20)
        if settings.ignoreList[v] == true then
            cdTrackerUIObjects['buffalert'..k]:SetCheck(0)
        else
            cdTrackerUIObjects['buffalert'..k]:SetCheck(1)
        end
        cdTrackerUIObjects['buffalert'..k]:SetEventScript(ui.LBUTTONUP,"ui.Chat('/cd alert "..k+#skillList.."') CDTRACKER_LOADSETTINGS() if settings.ignoreList[v] == true then cdTrackerUIObjects['buffalert'..k]:SetCheck(0) else cdTrackerUIObjects['buffalert'..k]:SetCheck(1) end")

        cdTrackerUIObjects['buff_'..k] = cdGroupBox:CreateOrGetControl('richtext','CDTRACKER_BUTTON_BUFF__'..k,10,25+offset,100,5)
        cdTrackerUIObjects['buff_'..k] = tolua.cast(cdTrackerUIObjects['buff_'..k],'ui::CRichText')
        cdTrackerUIObjects['buff_'..k]:SetText('{@st66b}{#708090}'..dots..'{/}')
        cdTrackerUIObjects['buff_'..k]:EnableHitTest(0)

        offset = offset+35
    end

end

function TOGGLE_CD(setting)
    CDTRACKER_LOADSETTINGS()
    if setting == 'enabled' then
        if settings.alerts then
            ui.Chat('/cd off')
        else
            ui.Chat('/cd on')
        end
        CDTRACKER_LOADSETTINGS()
        if settings.alerts then enabled = '{#00cc00}on' else enabled = '{#cc0000}off' end
        cdTrackerUIObjects['enabled']:SetText('{@st66b}{#ffffff}cdtracker:'..enabled..'{/}')
        return;
    end
    ui.Chat('/cd '..setting)
    CDTRACKER_LOADSETTINGS()
    if settings[setting] then enabled = '{#00cc00}on' else enabled = '{#cc0000}off' end
    cdTrackerUIObjects[setting]:SetText('{@st66b}{#ffffff}'..setting..':'..enabled..'{/}')
end

function CD_CHANGE_CHAT_TYPE()
    CDTRACKER_LOADSETTINGS()
    if settings.chattype == 1 then
        ui.Chat('/cd chattype 2')
    else
        ui.Chat('/cd chattype 1')
    end
    CDTRACKER_LOADSETTINGS()
    if settings.chattype == 1 then chattype = 'all' else chattype = 'party' end
    cdTrackerUIObjects['chattype']:SetText('{@st66b}{#ffffff}chat type: '..chattype..'{/}')
end

function CDTRACKER_TOGGLE_FRAME()
    cdTrackerUI = ui.GetFrame('CDTRACKER_UI')
    if cdTrackerUI == nil then
        CDTRACKER_CREATE_FRAME()
    elseif cdTrackerUI:IsVisible() == 1 then
        cdTrackerUI:ShowWindow(0)
    end
end

function CD_SET_TIME(id)
    local TempTime = cdTrackerUIObjects['skilltime'..id]:GetText()

    ui.Chat('/cd time '..id..' '..TempTime)
    
    cdTrackerUIObjects['skilltimelabel'..id]:SetText('{@st66b}{#ffffff}'..TempTime..'{/}')
    cdTrackerUIObjects['skilltimelabel'..id]:ShowWindow(1)
    cdTrackerUIObjects['skilltime'..id]:SetText('')
    cdTrackerUIObjects['skilltime'..id]:ReleaseFocus()

end

function CD_SET_MAIN_TIME()
    local TempTime = cdTrackerUIObjects['timebox']:GetText()
    if TempTime == '' then
        return;
    end

    ui.Chat('/cd '..TempTime)
    cdTrackerUIObjects['timelabel']:SetText('{@st66b}{#ffffff}'..TempTime..'{/}')
    cdTrackerUIObjects['timelabel']:ShowWindow(1)

    CDTRACKER_CREATE_FRAME()
    cdTrackerUIObjects['timebox']:SetText('')
    cdTrackerUIObjects['timebox']:ReleaseFocus()

end

function CD_SET_SIZE()
    size = cdTrackerUIObjects['sizebox']:GetText()
    if size == '' then
        return;
    end

    ui.Chat('/cd size '..size)
    cdTrackerUIObjects['sizelabel']:SetText('{@st66b}{#ffffff}'..size..'{/}')
    cdTrackerUIObjects['sizelabel']:ShowWindow(1)

    CDTRACKER_CREATE_FRAME()
    cdTrackerUIObjects['sizebox']:SetText('')
    cdTrackerUIObjects['sizebox']:ReleaseFocus()
end


function CD_SEND_CHAT_MESSAGE(id)
    message = cdTrackerUIObjects['skillmessageinput'..id]:GetText()
    local skills = RETURN_SKILL_LIST()
    if message == '' then
        settings.message[skillList[id]] = nil
        CDTRACKER_SAVESETTINGS()
        CDTRACKER_LOADSETTINGS()
        cdTrackerUIObjects['skillmessage'..id]:SetText('{@st46b}{s12}{#ffffff}Set Message{/}')
        ui.DestroyFrame('CDTRACKER_INPUT')
        CD_LIST()
        return;
    end
    ui.Chat('/cd chat '..id..' '..message)

    cdTrackerUIObjects['skillmessage'..id]:SetText('{@st46b}{s12}{#ffffff}'..message..'{/}')
    ui.DestroyFrame('CDTRACKER_INPUT')
    CD_LIST()
end

function CD_SET_CHAT_MESSAGE(id)
    cdTrackerInput =  ui.CreateNewFrame('cdtracker','CDTRACKER_INPUT')
    cdTrackerInput:SetLayerLevel(101)
    cdTrackerInput:EnableHitTest(1)
    cdTrackerInput:Resize(500,50)
    cdTrackerUIObjects['skillmessageinput'..id] = cdTrackerInput:CreateOrGetControl('edit','CDTRACKER_SKILLMESSAGEINPUT'..id, 0,0,500,30)
    cdTrackerUIObjects['skillmessageinput'..id] = tolua.cast(cdTrackerUIObjects['skillmessageinput'..id],'ui::CEditControl')
    cdTrackerUIObjects['skillmessageinput'..id]:AcquireFocus()
    cdTrackerUIObjects['skillmessageinput'..id]:SetEnable(1)
    cdTrackerUIObjects['skillmessageinput'..id]:SetEventScript(ui.ENTERKEY,"CD_SEND_CHAT_MESSAGE("..id..")")
end
