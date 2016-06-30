local acutil = require('acutil')
local _G = _G

local settings = {}
local default = {
	checkVal = 5;
	alerts = 1;
	sound = 1;
	text = 1;
	soundtype = 1;
	icon = 1;
	ignoreList = {};
	chatList = {};
	skillPosX = 700;
	skillPosY = 225;
	buffPosX = 100;
	buffPosY = 200;
	buffs = 1;
	skin = 1;
	size = 1
	}

local soundTypes = {'button_click_stats_up','quest_count','quest_event_start','quest_success_2','sys_alarm_mon_kill_count','quest_event_click','sys_secret_alarm', 'travel_diary_1','button_click_4'}

local frameSkins = {'box_glass', 'slot_name', 'shadow_box', 'frame_bg', 'textview', 'chat_window', 'tooltip1'}

local cdTrackSkill = {}
cdTrackSkill['Slots'] = {}
cdTrackSkill['icon'] = {}

local cdTrackBuff = {}
cdTrackBuff['time'] = {}
cdTrackBuff['prevTime'] = {}
cdTrackBuff['name'] = {}
cdTrackBuff['slot'] = {}
cdTrackBuff['class'] = {}
cdTrackBuff['Slots'] = {}

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
local skillIndex = 1

local CD_DRAG_STATE = false

local timer = imcTime.GetAppTime()
local msgDisplay = 0

function CDTRACKER_ON_INIT(addon, frame)
	acutil.setupHook(ICON_USE_HOOKED,'ICON_USE')
	acutil.setupHook(ICON_UPDATE_SKILL_COOLDOWN_HOOKED,'ICON_UPDATE_SKILL_COOLDOWN')
	cdTrackSkill = {}
	cdTrackSkill['Slots'] = {}
	cdTrackSkill['icon'] = {}
	skillIndex = 1
	acutil.slashCommand('/cd',CD_TRACKER_CHAT_CMD)
	CDTRACKER_LOADSETTINGS()
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

function NUM_TO_WORD(num)
	if num == 1 then
		return 'on'
	else
		return 'off'
	end
end

local CD_HELP_TABLE = {
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
on = function() settings.alerts = 1 CHAT_SYSTEM('Alerts on.') end;
off = function() settings.alerts = 0 CHAT_SYSTEM('Alerts off.') end;
sound = function(num)
		if type(num) == 'number' then
			settings.soundtype = num
			CHAT_SYSTEM('Soundtype set to '..num..'.')
			imcSound.PlaySoundEvent(soundTypes[settings.soundtype]);
			return;
		end
		settings.sound = math.abs(settings.sound-1)
		CHAT_SYSTEM('Sound set to '..NUM_TO_WORD(settings.sound)..'.')
	end;
text = function() settings.text = math.abs(settings.text-1) CHAT_SYSTEM('Text set to '..NUM_TO_WORD(settings.text)..'.') end;
icon = function() settings.icon = math.abs(settings.icon-1) CHAT_SYSTEM('Icon set to '..NUM_TO_WORD(settings.icon)..'.') end;
alert = function(ID)
	if settings.ignoreList[skillList[ID]] ~= nil then
		settings.ignoreList[skillList[ID]] = not settings.ignoreList[skillList[ID]]
		CHAT_SYSTEM('Alerts for '..skillList[ID]..' set to '..NUM_TO_WORD(settings.ignoreList[skillList[ID]])..'.')
		return;
	end
	settings.ignoreList[skillList[ID]] = 1
	CHAT_SYSTEM('Alerts for '..skillList[ID]..' set to on.') end;
chat = function(ID)
	if settings.chatList[skillList[ID]] ~= nil then
		settings.chatList[skillList[ID]] = not settings.chatList[skillList[ID]]
		CHAT_SYSTEM('Chat for '..skillList[ID]..' set to '..NUM_TO_WORD(settings.chatList[skillList[ID]])..'.')
		return;
	end
	settings.chatList[skillList[ID]] = 1
	CHAT_SYSTEM('Chat for '..skillList[ID]..' set to on.') end;
skillX = function(num) settings.skillPosX = num CHAT_SYSTEM('Skill X set to '..num..'.') end;
skillY = function(num) settings.skillPosY = num CHAT_SYSTEM('Skill Y set to '..num..'.') end;
buffX = function(num) settings.buffPosX = num CHAT_SYSTEM('Buff X set to '..num..'.') end;
buffY = function(num) settings.buffPosY = num CHAT_SYSTEM('Buff Y set to '..num..'.') end;
skin = function(num) settings.skin = num CHAT_SYSTEM('Skin set to '..num..'.') end;
list = function() GET_SKILL_LIST() for k,v in ipairs(skillList) do
	CHAT_SYSTEM('ID '..k..': '..v..' - alert '..NUM_TO_WORD(settings.ignoreList[v])..' - chat '..NUM_TO_WORD(settings.chatList[v])) end
end;
buffs = function() settings.buffs = math.abs(settings.buffs - 1) CHAT_SYSTEM('Buffs set to '..NUM_TO_WORD(settings.buffs)..'.') end;
reset = function() settings = default CHAT_SYSTEM('Settings reset to defaults.') end;
help = function(func) CD_HELP_TABLE[func]() end;
size = function(num) settings.size = num CHAT_SYSTEM('Size scaling set to '..num..'.') end;
status = function() CHAT_SYSTEM('Under construction.') end
}

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
			CHAT_SYSTEM('System commands: reset, help')
			CHAT_SYSTEM(' ')
			CHAT_SYSTEM('For more information, type /cd help <command>.')
			CHAT_SYSTEM(' ')
		end
  end
end;
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
		if settings.chatList[fullName] == 1 and cdCheck == 0 then
			ui.Chat('!!Casting '..cdTrackSkill[index]['fullName']..'!')
			msgDisplay = 1
			timer = imcTime.GetAppTime()
		end
	else
		return;
	end
end

function ICON_UPDATE_SKILL_COOLDOWN_HOOKED(icon)
	if settings.alerts == 0 then
		return _G['ICON_UPDATE_SKILL_COOLDOWN_OLD'](icon)
	end

	local index = CHECK_ICON_EXIST(icon)
	if index == 1 then
		CDTRACK_BUFF_CHECK()
	end
	cdTrackSkill[index]['curTime'] = cdTrackSkill[index]['sklInfo']:GetCurrentCoolDownTime();
	cdTrackSkill[index]['totalTime'] = cdTrackSkill[index]['sklInfo']:GetTotalCoolDownTime();
	cdTrackSkill[index]['curTimeSecs'] = math.ceil(cdTrackSkill[index]['curTime']/1000)
	if settings.checkVal >= cdTrackSkill[index]['curTimeSecs'] and cdTrackSkill[index]['prevTime'] ~= cdTrackSkill[index]['curTimeSecs'] then
		if cdTrackSkill[index]['curTimeSecs'] == 0 then
			if settings.sound == 1 then
				if settings.soundtype > 0 and settings.soundtype <= table.getn(soundTypes) then
					imcSound.PlaySoundEvent(soundTypes[settings.soundtype]);
				else
					imcSound.PlaySoundEvent(soundTypes[1])
				end
			end
			if settings.text == 1 and settings.ignoreList[cdTrackSkill[index]['fullName']] ~= 1 then
				ui.AddText('SystemMsgFrame',' ')
				ui.AddText('SystemMsgFrame',' ')
				ui.AddText('SystemMsgFrame',' ')
				ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready.')
			end
			if settings.chatList[cdTrackSkill[index]['fullName']] == 1 then
				ui.Chat('!!'..cdTrackSkill[index]['fullName']..' ready!')
				msgDisplay = 1
				timer = imcTime.GetAppTime()
			end
			cdTrackSkill[index]['prevTime'] = 0
			DISPLAY_SLOT(index, cdTrackSkill[index]['slot'],cdTrackSkill[index]['fullName'],cdTrackSkill[index]['curTimeSecs'], 'SKILL', cdTrackSkill[index]['obj'])
			cdTrackSkill['Slots'][FIND_NEXT_SLOT(index,'SKILL')] = nil
			return cdTrackSkill[index]['curTime'], cdTrackSkill[index]['totalTime'];
		end
		if settings.text == 1 and settings.ignoreList[cdTrackSkill[index]['fullName']] ~= 1 then
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
		end
		if settings.chatList[cdTrackSkill[index]['fullName']] == 1 then
			ui.Chat('!!'..cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
			msgDisplay = 1
			timer = imcTime.GetAppTime()
		end
		if settings.ignoreList[cdTrackSkill[index]['fullName']] ~= 1 then
			cdTrackSkill[index]['slot'] = FIND_NEXT_SLOT(index,'SKILL')
		end
		DISPLAY_SLOT(index, cdTrackSkill[index]['slot'],cdTrackSkill[index]['fullName'],cdTrackSkill[index]['curTimeSecs'], 'SKILL', cdTrackSkill[index]['obj'])
	end
	if settings.chatList[fullName] == 1 then
		if TIME_ELAPSED(2) and msgDisplay == 1 then
			ui.Chat('!!')
			msgDisplay = 0
		end
	end
	cdTrackSkill[index]['prevTime'] = cdTrackSkill[index]['curTimeSecs']
	return cdTrackSkill[index]['curTime'], cdTrackSkill[index]['totalTime'];
end

function CDTRACK_BUFF_CHECK()
	if settings.buffs == 0 then
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
			if settings.sound == 1 then
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

function GET_SKILL_LIST()
	skillList = {}
	for k,v in pairs(cdTrackSkill) do
		if type(tonumber(k)) == 'number' then
			skillList[k] = cdTrackSkill[k]['fullName']
		end
	end
	table.sort(skillList)
end

function TIME_ELAPSED(val)
	local elapsed = math.floor(imcTime.GetAppTime() - timer)
	if elapsed > val then
		timer = imcTime.GetAppTime()
		return true
	end
	return false
end
