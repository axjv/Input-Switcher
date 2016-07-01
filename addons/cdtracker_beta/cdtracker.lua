local acutil = require('acutil')
local _G = _G

local settings = {}
local default = {
	checkVal = 5;
	alerts = true;
	sound = true;
	text = true;
	soundtype = 1;
	icon = true;
	ignoreList = {};
	chatList = {};
	skillPosX = 700;
	skillPosY = 225;
	buffPosX = 100;
	buffPosY = 200;
	buffs = true;
	skin = 1;
	size = 1;
	firstTimeMessage = false
	}


local soundTypes = {'button_click_stats_up','quest_count','quest_event_start','quest_success_2','sys_alarm_mon_kill_count','quest_event_click','sys_secret_alarm', 'travel_diary_1','button_click_4'}

local frameSkins = {'box_glass', 'slot_name', 'shadow_box', 'frame_bg', 'textview', 'chat_window', 'tooltip1'}

-- store skill

local skillIndex = 1
cdTrackSkill = {}
cdTrackSkill['Slots'] = {}
cdTrackSkill['icon'] = {}

-- store buff

local cdTrackBuff = {}
cdTrackBuff['time'] = {}
cdTrackBuff['prevTime'] = {}
cdTrackBuff['name'] = {}
cdTrackBuff['slot'] = {}
cdTrackBuff['class'] = {}
cdTrackBuff['Slots'] = {}

-- store frame data

local skillFrame = {}
local cdTypeList = {'SKILL','BUFF','DEBUFF'}
for k,v in pairs(cdTypeList) do
skillFrame['name_'..v] = {}
skillFrame['type_'..v] = {}
skillFrame['cooldown_'..v] = {}
skillFrame['icon_'..v] = {}

skillFrame['iconFrame_'..v] = {}
skillFrame['cdFrame_'..v] = {}
end

local cdTrackType = {}

local CD_DRAG_STATE = false

-- timer for chat notification
local timer = imcTime.GetAppTime()
local msgDisplay = false
local checkChatFrame = ui.GetFrame('chat')

-- begin main body

function CDTRACKER_ON_INIT(addon, frame)
	acutil.setupHook(ICON_USE_HOOKED,'ICON_USE')
	acutil.setupHook(ICON_UPDATE_SKILL_COOLDOWN_HOOKED,'ICON_UPDATE_SKILL_COOLDOWN')
	addon:RegisterMsg('RESTQUICKSLOT_OPEN', 'QUICKSLOTNEXPBAR_KEEPVISIBLE');
	addon:RegisterMsg('RESTQUICKSLOT_CLOSE', 'QUICKSLOTNEXPBAR_RESTORE');
	cdTrackSkill = {}
	cdTrackSkill['Slots'] = {}
	cdTrackSkill['icon'] = {}
	skillIndex = 1
	checkChatFrame = ui.GetFrame('chat')
	acutil.slashCommand('/cd',CD_TRACKER_CHAT_CMD)
	CDTRACKER_LOADSETTINGS()
	if not settings.firstTimeMessage then
		ui.MsgBox("{s18}{#c70404}Important:{nl} {nl}{#000000}CDTracker Beta settings have been changed, if you are upgrading from an older version please reset using{nl} {nl}{#03134d}/cd reset{nl} {nl}This message will only show once.","helpBoxTable.helpBox_1()","helpBoxTable.helpBox_1()");
		settings.firstTimeMessage = true
		CDTRACKER_SAVESETTINGS()
	end

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

 	local xPos = cdFrame:GetX()
	local yPos = cdFrame:GetY()

	if cdtype == 'SKILL' then
		settings.skillPosX = xPos
		settings.skillPosY = yPos-60*settings.size*slot
	elseif cdtype == 'BUFF' or cdtype =='DEBUFF' then
		settings.buffPosX = xPos
		settings.buffPosY = yPos-60*settings.size*slot
	end
	CDTRACKER_SAVESETTINGS()

end

function CDTRACKER_LOADSETTINGS()
	local s, err = acutil.loadJSON("../addons/cdtracker/settings.json");
	if err then
		settings = default
	else
		settings = s
		for k,v in pairs(default) do
			if not s[k] then
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
			CHAT_SYSTEM('Invalid command. Valid command format: /cd <command>')
			CHAT_SYSTEM(' ')
			CHAT_SYSTEM('Toggle commands: on, off, sound, icon, text, buffs, alert <ID>, chat <ID>')
			CHAT_SYSTEM('Setting commands: <number>, sound <number>, skin <number>, skillX <number>, skillY <number>, buffX <number>, buffY <number>')
			CHAT_SYSTEM('Status commands: list, status')
			CHAT_SYSTEM('System commands: reset, help help all')
			CHAT_SYSTEM(' ')
			CHAT_SYSTEM('For more information, type /cd help <command>.')
			CHAT_SYSTEM(' ')
		end
  end
end;
}

helpBoxTable = {
	helpBox_1 = function() ui.MsgBox("{s18}{#1908e3}Main commands:{#000000}{nl} {nl}{#03134d}/cd <number>{#000000} will set the notification time in seconds.{nl} {nl}{#03134d}/cd on, /cd off{nl}/cd icon, /cd text{nl}/cd sound{#000000} {nl}are all toggle commands.{nl} {nl}{#03134d}/cd buffs{#000000} toggles the buff window on and off.{nl} {nl}{#03134d}/cd sound <number>{#000000} will set the sound type. (Default: 1){nl} {nl}{#03134d}/cd skin <number>{#000000} will set the skin type. (Default: 1) ","helpBoxTable.helpBox_2()","helpBoxTable.helpBox_2()") end;
	helpBox_2 = function() ui.MsgBox("{s18}{#1908e3}Layout commands:{#000000}{nl} {nl}{#03134d}/cd size <number>{#000000} will let you modify the size scaling of windows. (Default: 1){nl} {nl}{#03134d}/cd skillX <number>{nl}/cd skillY <number>{nl}/cd buffX <number>{nl}/cd buffY <number>{nl} {nl}{#000000}allow you to manually position the skill and buff windows. Dragging also works. ","helpBoxTable.helpBox_3()","helpBoxTable.helpBox_3()") end;
	helpBox_3 = function() ui.MsgBox("{s18}{#1908e3}Skill customization:{#000000}{nl} {nl}{#03134d}/cd list{#000000} will list all skills alphabetically with their ID number.{nl} {nl}{#03134d}/cd alert <ID>{#000000} toggles alerts for a specific skill.{nl} {nl}{#03134d}/cd chat <ID>{#000000} toggles yellowtext (!!) broadcasting for specific skills.","helpBoxTable.helpBox_4()","helpBoxTable.helpBox_4()") end;
	helpBox_4 = function() ui.MsgBox("{s18}{#1908e3}System commands:{#000000}{nl} {nl}{#03134d}/cd reset{#000000} will reset all settings to default.{nl} {nl}{#03134d}/cd help <command>{#000000} will show a short explanation about a command.{nl} {nl}{#03134d}/cd help all{#000000} will show this help box.","","Nope") end
}


local CD_HELP_TABLE = {
	all = function() helpBoxTable.helpBox_1() end;
	alert = function() CHAT_SYSTEM('Usage: /cd alert will toggle cooldown alerts for a single skill.') end;
	buffX = function() CHAT_SYSTEM('Usage: /cd buffX <coords> will set the x coordinates for the buff window.'); CHAT_SYSTEM('Default: '..default.buffPosX) end;
	buffY = function() CHAT_SYSTEM('Usage: /cd buffY <coords> will set the y coordinates for the buff window.'); CHAT_SYSTEM('Default: '..default.buffPosY) end;
	buffs = function() CHAT_SYSTEM('Usage: /cd buffs will toggle buff tracking on and off.'); CHAT_SYSTEM('Default: '..default.buffs) end;
	chat = function() CHAT_SYSTEM('Usage: /cd chat <ID> will toggle chat alerts for a single skill.') end;
	help = function() CHAT_SYSTEM('Usage: /cd help <command> will open what you\'re reading.') end;
	icon = function() CHAT_SYSTEM('Usage: /cd icon will toggle icon display on and off.') end;
	list = function() CHAT_SYSTEM('Usage: /cd list will list all skills along with their ID.') end;
	off = function() CHAT_SYSTEM('Usage: /cd off will turn all alerts off.'); CHAT_SYSTEM('Default: '..default.alerts) end;
	on = function() CHAT_SYSTEM('Usage: /cd on will reenable alerts. Your settings will be saved.'); CHAT_SYSTEM('Default: On') end;
	reset = function() CHAT_SYSTEM('Usage: /cd reset will reset all settings to default.') end;
	size = function() CHAT_SYSTEM('Usage: /cd size <scale> will change the size of all cooldown windows.'); CHAT_SYSTEM('Default: '..default.size) end;
	skillX = function() CHAT_SYSTEM('Usage: /cd skillX <coords> will set the x coordinates for the skill window.'); CHAT_SYSTEM('Default: '..default.skillPosX) end;
	skillY = function() CHAT_SYSTEM('Usage: /cd skillY <coords> will set the y coordinates for the skill window.'); CHAT_SYSTEM('Default: '..default.skillPosY) end;
	skin = function() CHAT_SYSTEM('Usage: /cd skin <number> will change the skin of the cooldown tracker.'); CHAT_SYSTEM('Default: '..default.skin) end;
	sound = function() CHAT_SYSTEM('Usage: /cd sound will toggle sound alerts on and off. /cd sound <number> will change the sound played.'); CHAT_SYSTEM('Default: '.. default.soundtype) end;
	text = function() CHAT_SYSTEM('Usage: /cd text will toggle text alerts on and off.'); CHAT_SYSTEM('Default: '..default.text) end;
}

local CD_SETTINGS_TABLE = {
on = function() settings.alerts = true CHAT_SYSTEM('Alerts on.') end;
off = function() settings.alerts = false CHAT_SYSTEM('Alerts off.') end;
sound = function(num)
		if type(num) == 'number' then
			settings.soundtype = num
			CHAT_SYSTEM('Soundtype set to '..num..'.')
			imcSound.PlaySoundEvent(soundTypes[settings.soundtype]);
			return;
		end
		settings.sound = not settings.sound
		CHAT_SYSTEM('Sound set to '..BOOL_TO_WORD(settings.sound)..'.')
	end;
text = function() settings.text = not settings.text CHAT_SYSTEM('Text set to '..BOOL_TO_WORD(settings.text)..'.') end;
icon = function() settings.icon = not settings.icon CHAT_SYSTEM('Icon set to '..BOOL_TO_WORD(settings.icon)..'.') end;
alert = function(ID)
	if settings.ignoreList[skillList[ID]] ~= nil then
		settings.ignoreList[skillList[ID]] = not settings.ignoreList[skillList[ID]]
		CHAT_SYSTEM('Alerts for '..skillList[ID]..' set to '..BOOL_TO_WORD(settings.ignoreList[skillList[ID]])..'.')
		return;
	end
	settings.ignoreList[skillList[ID]] = true
	CHAT_SYSTEM('Alerts for '..skillList[ID]..' set to on.') end;
chat = function(ID)
	if settings.chatList[skillList[ID]] ~= nil then
		settings.chatList[skillList[ID]] = not settings.chatList[skillList[ID]]
		CHAT_SYSTEM('Chat for '..skillList[ID]..' set to '..BOOL_TO_WORD(settings.chatList[skillList[ID]])..'.')
		return;
	end
	settings.chatList[skillList[ID]] = true
	CHAT_SYSTEM('Chat for '..skillList[ID]..' set to on.') end;
skillX = function(num) settings.skillPosX = num CHAT_SYSTEM('Skill X set to '..num..'.') end;
skillY = function(num) settings.skillPosY = num CHAT_SYSTEM('Skill Y set to '..num..'.') end;
buffX = function(num) settings.buffPosX = num CHAT_SYSTEM('Buff X set to '..num..'.') end;
buffY = function(num) settings.buffPosY = num CHAT_SYSTEM('Buff Y set to '..num..'.') end;
skin = function(num) settings.skin = num CHAT_SYSTEM('Skin set to '..num..'.') end;
list = function() GET_SKILL_LIST() for k,v in ipairs(skillList) do
	CHAT_SYSTEM('ID '..k..': '..v..' - alert '..BOOL_TO_WORD(settings.ignoreList[v])..' - chat '..BOOL_TO_WORD(settings.chatList[v])) end
end;
buffs = function() settings.buffs = not settings.buffs CHAT_SYSTEM('Buffs set to '..BOOL_TO_WORD(settings.buffs)..'.') end;
reset = function() local ftMessage = settings.firstTimeMessage settings = default settings.firstTimeMessage = ftMessage CHAT_SYSTEM('Settings reset to defaults.') end;
help = function(func) CD_HELP_TABLE[func]() end;
size = function(num) settings.size = num CHAT_SYSTEM('Size scaling set to '..num..'.') end;
status = function() CHAT_SYSTEM('Under construction.') end
}

setmetatable(CD_SETTINGS_TABLE, mt)
setmetatable(CD_HELP_TABLE, mt)

function CD_TRACKER_CHAT_CMD(command)
	local cmd = ''
	local arg1 = ''
	if #command > 0 then
		cmd = table.remove(command, 1)
	end
	if #command > 0 then
		arg1 = table.remove(command, 1)
		if cmd ~= 'help' then
			arg1 = tonumber(arg1)
		end
	end
	CD_SETTINGS_TABLE[cmd](arg1)
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
	cdTrackSkill[skillIndex] = GRAB_SKILL_INFO(icon)
	cdTrackSkill['icon'][skillIndex] = icon
	skillIndex = skillIndex+1
	return skillIndex-1
end

function GRAB_SKILL_INFO(icon)
	local tTime = 0;
	local cTime = 0;
	local iconInfo = icon:GetInfo();
	local skillInfo = session.GetSkill(iconInfo.type);
	local sklObj = GetIES(skillInfo:GetObject());
	if skillInfo ~= nil then
		cTime = skillInfo:GetCurrentCoolDownTime();
		tTime = skillInfo:GetTotalCoolDownTime();
		skillName = GetClassByType("Skill", sklObj.ClassID).ClassName
	end
	local skillInfoTable = {
	sklInfo = skillInfo;
	curTime = cTime;
	curTimeSecs = math.ceil(cTime/1000);
	totalTime = tTime;
	obj = GetClassByType("Skill", sklObj.ClassID);
	prevTime = 0;
	slot = 0;
	fullName = string.sub(string.match(skillName,'_.+'),2):gsub("%u", " %1"):sub(2)
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
	for k,v in pairs(cdTrackType['Slots']) do
		if v == index then
			return tonumber(k)
		end
	end
	for k,v in ipairs(cdTrackType['Slots']) do
		if v == nil then
			cdTrackType['Slots'][k] = index
			return tonumber(k)
		end
	end
	table.insert(cdTrackType['Slots'],index)
	return #cdTrackType['Slots']
end

function ICON_USE_HOOKED(object, reAction)
	_G['ICON_USE_OLD'](object, reAction);
	local iconPt = object;
	if iconPt  ~=  nil then
		local icon = tolua.cast(iconPt, 'ui::CIcon');
		local index = CHECK_ICON_EXIST(icon)
		cdTrackSkill[index]['curTime'] = cdTrackSkill[index]['sklInfo']:GetCurrentCoolDownTime();
		cdTrackSkill[index]['curTimeSecs'] = math.ceil(cdTrackSkill[index]['curTime']/1000)
		if cdTrackSkill[index]['curTimeSecs'] ~= 0 then
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
		end
		if settings.chatList[cdTrackSkill[index]['fullName']] == true and cdTrackSkill[index]['curTimeSecs'] == 0 and checkChatFrame:IsVisible() == 0 then
			ui.Chat('!!Casting '..cdTrackSkill[index]['fullName']..'!')
			msgDisplay = true
			timer = imcTime.GetAppTime()
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
	if index == 1 then
		-- run once every loop through all skills
		CDTRACK_BUFF_CHECK()
	end
	cdTrackSkill[index]['curTime'] = cdTrackSkill[index]['sklInfo']:GetCurrentCoolDownTime();
	cdTrackSkill[index]['totalTime'] = cdTrackSkill[index]['sklInfo']:GetTotalCoolDownTime();
	cdTrackSkill[index]['curTimeSecs'] = math.ceil(cdTrackSkill[index]['curTime']/1000)
	if settings.checkVal >= cdTrackSkill[index]['curTimeSecs'] and cdTrackSkill[index]['prevTime'] ~= cdTrackSkill[index]['curTimeSecs'] then
		if cdTrackSkill[index]['curTimeSecs'] == 0 then
			if settings.sound == true then
				if settings.soundtype > 0 and settings.soundtype <= table.getn(soundTypes) then
					imcSound.PlaySoundEvent(soundTypes[settings.soundtype]);
				else
					imcSound.PlaySoundEvent(soundTypes[1])
				end
			end
			if settings.text == true and settings.ignoreList[cdTrackSkill[index]['fullName']] ~= true then
				ui.AddText('SystemMsgFrame',' ')
				ui.AddText('SystemMsgFrame',' ')
				ui.AddText('SystemMsgFrame',' ')
				ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready.')
			end
			if settings.chatList[cdTrackSkill[index]['fullName']] == true and checkChatFrame:IsVisible() == 0 then
				ui.Chat('!!'..cdTrackSkill[index]['fullName']..' ready!')
				msgDisplay = true
				timer = imcTime.GetAppTime()
			end
			cdTrackSkill[index]['prevTime'] = 0
			DISPLAY_SLOT(index, cdTrackSkill[index]['slot'],cdTrackSkill[index]['fullName'],cdTrackSkill[index]['curTimeSecs'], 'SKILL', cdTrackSkill[index]['obj'])
			cdTrackSkill['Slots'][FIND_NEXT_SLOT(index,'SKILL')] = nil
			return cdTrackSkill[index]['curTime'], cdTrackSkill[index]['totalTime'];
		end
		if settings.text == true and settings.ignoreList[cdTrackSkill[index]['fullName']] ~= true then
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
		end
		if settings.chatList[cdTrackSkill[index]['fullName']] == true and checkChatFrame:IsVisible() == 0 then
			ui.Chat('!!'..cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
			msgDisplay = true
			timer = imcTime.GetAppTime()
		end
		if settings.ignoreList[cdTrackSkill[index]['fullName']] ~= true then
			cdTrackSkill[index]['slot'] = FIND_NEXT_SLOT(index,'SKILL')
		end
		DISPLAY_SLOT(index, cdTrackSkill[index]['slot'],cdTrackSkill[index]['fullName'],cdTrackSkill[index]['curTimeSecs'], 'SKILL', cdTrackSkill[index]['obj'])
	end
	if settings.chatList[cdTrackSkill[index]['fullName']] == true then
		if TIME_ELAPSED(2) and msgDisplay == true and checkChatFrame:IsVisible() == 0 then
			ui.Chat('!!')
			msgDisplay = false
		end
	end
	cdTrackSkill[index]['prevTime'] = cdTrackSkill[index]['curTimeSecs']
	return cdTrackSkill[index]['curTime'], cdTrackSkill[index]['totalTime'];
end

-- begin buff section
-- retrieve all buff info

function CDTRACK_BUFF_CHECK()
	if settings.buffs == false then
		return;
	end
	local buff_ui = _G['s_buff_ui']
	local handle = session.GetMyHandle();
	for j = 0 , buff_ui["buff_group_cnt"] do
		local slotlist = buff_ui["slotlist"][j];
		if buff_ui["slotcount"][j] ~= nil and buff_ui["slotcount"][j] >= 0 then
  		for i = 0,  buff_ui["slotcount"][j] - 1 do
  			local slot = slotlist[i];
				local icon = slot:GetIcon();
				local iconInfo = icon:GetInfo();
				local buffIndex = icon:GetUserIValue("BuffIndex");
				local buff = info.GetBuff(handle, iconInfo.type, buffIndex);
				local cls = GetClassByType('Buff', iconInfo.type);
				if buff ~= nil then
					cdTrackBuff['time'][cls.Name] = math.ceil(buff.time/1000)
					cdTrackBuff['class'][cls.Name] = cls
					CDTRACK_BUFF_DISPLAY(cls.Name,buff.buffID)
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
			cdTrackBuff['Slots'][FIND_NEXT_SLOT(name,'BUFF')] = nil
			return;
		end
		DISPLAY_SLOT(name, cdTrackBuff['slot'][name],name,cdTrackBuff['time'][name], bufftype, cdTrackBuff['class'][name],2)
	end
	cdTrackBuff['prevTime'][name] = cdTrackBuff['time'][name]
	return;
end


-- function CDTRACKER_SHOW_FRAMES()
-- 	local buffFrame = ui.CreateNewFrame('cdtracker','BUFF_POS_FRAME')
-- 	local skillFrame = ui.CreateNewFrame('cdtracker','SKILL_POS_FRAME')
-- 	skillFrame:Resize(settings.size * 325,settings.size * 50)
-- 	buffFrame:Resize(settings.size * 325,settings.size * 50)
-- end
--
-- function CD_SHOW_FRAMES_DRAG_START()
-- end
--
-- function CD_SHOW_FRAMES_DRAG_STOP(cdFrame, cdtype)
--  	local xPos = cdFrame:GetX()
-- 	local yPos = cdFrame:GetY()
--
-- 	if cdtype == 'SKILL' then
-- 		settings.skillPosX = xPos
-- 		settings.skillPosY = yPos-60*settings.size*slot
-- 	elseif cdtype == 'BUFF' or cdtype =='DEBUFF' then
-- 		settings.buffPosX = xPos
-- 		settings.buffPosY = yPos-60*settings.size*slot
-- 	end
-- 	ui.DestroyFrame(cdFrame:GetName())
-- 	CDTRACKER_SAVESETTINGS()
-- end


-- draw all frames

function DISPLAY_SLOT(index, slot, name, cooldown, cdtype, obj)
	cdFrame = ui.CreateNewFrame('cdtracker','FRAME_'..cdtype..slot)
	skillFrame['cdFrame_'..cdtype][slot] = cdFrame
	local skinSetting = frameSkins[settings.skin]
	if skinSetting == nil then
		cdFrame:SetSkinName(frameSkins[1])
	else
		cdFrame:SetSkinName(frameSkins[settings.skin])
	end
	cdFrame:Resize(settings.size * 325,settings.size * 50)
	cdFrame:SetEventScript(ui.LBUTTONDOWN, "CD_DRAG_START");
	cdFrame:SetEventScript(ui.LBUTTONUP, "CD_DRAG_STOP('"..cdtype.."',"..slot..")");

	iconFrame = ui.CreateNewFrame('cdtracker','ICONFRAME_'..cdtype..slot)
	skillFrame['iconFrame_'..cdtype][slot] = iconFrame
	iconFrame:Resize(settings.size * 50,settings.size * 50)

	skillFrame['icon_'..cdtype][slot] = iconFrame:CreateOrGetControl('picture','cd_icon_'..cdtype..slot, 0,0,0,0)
	skillFrame['icon_'..cdtype][slot] = tolua.cast(skillFrame['icon_'..cdtype][slot],'ui::CPicture')
	skillFrame['icon_'..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)

	skillFrame['name_'..cdtype][slot] = cdFrame:CreateOrGetControl('richtext','cd_name_'..cdtype..slot, 0,0,0,0)
	skillFrame['name_'..cdtype][slot] = tolua.cast(skillFrame['name_'..cdtype][slot],'ui::CRichText')
	skillFrame['type_'..cdtype][slot] = cdFrame:CreateOrGetControl('richtext','cd_type_'..cdtype..slot, 0,0,0,0)
	skillFrame['type_'..cdtype][slot] = tolua.cast(skillFrame['type_'..cdtype][slot],'ui::CRichText')
	skillFrame['cooldown_'..cdtype][slot] = cdFrame:CreateOrGetControl('richtext','cd_cooldown_'..cdtype..slot, 0,0,0,0)
	skillFrame['cooldown_'..cdtype][slot] = tolua.cast(skillFrame['cooldown_'..cdtype][slot],'ui::CRichText')

	skillFrame['cooldown_'..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)
	skillFrame['cooldown_'..cdtype][slot]:SetOffset(math.ceil(15*settings.size),0)
	skillFrame['cooldown_'..cdtype][slot]:EnableHitTest(0)

	skillFrame['name_'..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)
	skillFrame['name_'..cdtype][slot]:SetOffset(math.ceil(140*settings.size),0)
	skillFrame['name_'..cdtype][slot]:EnableHitTest(0)

	skillFrame['type_'..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)
	skillFrame['type_'..cdtype][slot]:SetOffset(math.ceil(50*settings.size),0)
	skillFrame['type_'..cdtype][slot]:EnableHitTest(0)


	local fontSize = math.ceil(18 * settings.size)

	local colors = {red = '{#cc0000}', green = '{#00cc00}', yellow = '{#cccc00}', orange = '{#cc6600}'}
	if cdtype == 'SKILL' then
		local totalCd = cdTrackSkill[index]['totalTime']
		if cooldown == 0 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.green..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.green..'-')
		elseif cooldown < (totalCd/1000)*.33 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.yellow..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.yellow..cooldown)
		elseif cooldown < (totalCd/1000)*.66 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.orange..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.orange..cooldown)
		else
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.red..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.red..cooldown)
		end
		skillFrame['type_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}{#ffe600}[SKILL]')
	end
	if cdtype == 'BUFF' then
		if cooldown == 0 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.red..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.red..'-')
		elseif cooldown <= 5 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.orange..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.orange..cooldown)
		elseif cooldown < 10 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.yellow..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.yellow..cooldown)
		else
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.green..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.green..cooldown)
		end
		skillFrame['type_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}{#00e6cf}[BUFF]')
	end
	if cdtype == 'DEBUFF' then
		if cooldown == 0 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.green..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.green..'-')
		elseif cooldown <= 5 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.yellow..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.yellow..cooldown)
		elseif cooldown < 10 then
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.orange..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.orange..cooldown)
		else
			skillFrame['name_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.red..name)
			skillFrame['cooldown_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}'..colors.red..cooldown)
		end
		skillFrame['type_'..cdtype][slot]:SetText('{@st41}{s'..fontSize..'}{#cc0000}[DEBUFF]')
	end

	cdFrame:Resize(skillFrame['name_'..cdtype][slot]:GetWidth()+math.ceil(170*settings.size),math.ceil(settings.size*50))

	local iconname = "Icon_" .. obj.Icon
	skillFrame['icon_'..cdtype][slot]:SetImage(iconname)
	skillFrame['icon_'..cdtype][slot]:SetEnableStretch(1)
	skillFrame['icon_'..cdtype][slot]:Resize(math.ceil(settings.size * 50),math.ceil(settings.size * 50))

	cdFrame:ShowWindow(1)
	cdFrame:SetDuration(2)


	if CD_DRAG_STATE == true then
		iconFrame:ShowWindow(0)
		return;
	end

	if cdtype == 'SKILL' then
		cdFrame:MoveFrame(settings.skillPosX,settings.skillPosY+math.ceil(60*settings.size)*slot)
		iconFrame:MoveFrame(settings.skillPosX-math.ceil(65/325*settings.size * 325),settings.skillPosY + math.ceil(60*settings.size)*slot)
	end
	if cdtype == 'BUFF' or cdtype == 'DEBUFF' then
		cdFrame:MoveFrame(settings.buffPosX,settings.buffPosY+math.ceil(60*settings.size)*slot)
		iconFrame:MoveFrame(settings.buffPosX-math.ceil(65*settings.size),settings.buffPosY + math.ceil(60*settings.size)*slot)
	end

	iconFrame:ShowWindow(1)
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
			skillList[k] = cdTrackSkill[k]['fullName']
		end
	end
	table.sort(skillList)
end

-- time calc for chat notification

function TIME_ELAPSED(val)
	local elapsed = math.floor(imcTime.GetAppTime() - timer)
	if elapsed > val then
		timer = imcTime.GetAppTime()
		return true
	end
	return false
end
