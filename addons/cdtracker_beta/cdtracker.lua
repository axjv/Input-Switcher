local acutil = require('acutil')

settings = {}
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
	skin = 'box_glass'
	}
	
soundTypes = {'button_click_stats_up','quest_count','quest_event_start','quest_success_2','sys_alarm_mon_kill_count','quest_event_click','sys_secret_alarm', 'travel_diary_1','button_click_4'}

cdTrackSkill = {}
cdTrackSkill['Slots'] = {}
cdTrackSkill['icon'] = {}
skillIndex = 1

CD_DRAG_STATE = false

timer = imcTime.GetAppTime()
local msgDisplay = 0

local screenWidth = ui.GetClientInitialWidth();
local screenHeight = ui.GetClientInitialHeight();

function CDTRACKER_ON_INIT(addon, frame)
	acutil.setupHook(ICON_USE_HOOKED,'ICON_USE')
	acutil.setupHook(ICON_UPDATE_SKILL_COOLDOWN_HOOKED,'ICON_UPDATE_SKILL_COOLDOWN')
	acutil.slashCommand('/cd',cdTracker_SetVal)
	CDTRACKER_LOADSETTINGS()
end

function CD_DRAG_START()
	CD_DRAG_STATE = true
end

function CD_DRAG_STOP()
	CD_DRAG_STATE = false
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

function cdTracker_SetVal(command)
	local cmd = table.remove(command,1);
	if (type(tonumber(cmd)) == "number") then
		settings.checkVal = tonumber(cmd)
		CDTRACKER_SAVESETTINGS()
		return CHAT_SYSTEM('CD alert set to '..cmd..' seconds.')
	end
	if (cmd == 'x') then
		local posType = table.remove(command, 1)
		local val = table.remove(command, 1)
		if posType == 'skill' and type(tonumber(val)) == 'number' then
			settings.skillPosX = val
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Skill x set to '..val..'.')
		end
		if posType == 'buff' and type(tonumber(val)) == 'number' then
			settings.buffPosX = val
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Buff x set to '..val..'.')
		end
		return CHAT_SYSTEM('Invalid value.')
	end
	if (cmd == 'y') then
		local posType = table.remove(command, 1)
		local val = table.remove(command, 1)
		if posType == 'skill' and type(tonumber(val)) == 'number' then
			settings.skillPosY = val
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Skill y set to '..val..'.')
		end
		if posType == 'buff' and type(tonumber(val)) == 'number' then
			settings.buffPosY = val
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Buff y set to '..val..'.')
		end
		return CHAT_SYSTEM('Invalid value.')	
	end
	if (cmd == 'on') then
		settings.alerts = 1
		CDTRACKER_SAVESETTINGS()
		return CHAT_SYSTEM('CD alerts on.');
		end
	if (cmd == 'off') then
		settings.alerts = 0
		CDTRACKER_SAVESETTINGS()
		return CHAT_SYSTEM('CD alerts off.')
	end
	if (cmd == 'sound') then
		local soundVal = table.remove(command,1)
		if soundVal ~= nil then
			if type(tonumber(soundVal)) == 'number' then
				settings.soundtype = math.floor(tonumber(soundVal))
				imcSound.PlaySoundEvent(soundTypes[settings.soundtype])
				CDTRACKER_SAVESETTINGS()
				return CHAT_SYSTEM('Sound type set to '..settings.soundtype..'.')
			end
			return CHAT_SYSTEM('Invalid sound value.')
		end
		if settings.sound == 1 then
			settings.sound = 0
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Sound off.')
		else
			settings.sound = 1
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Sound on.')
		end
	end
	if (cmd == 'icon') then
		if settings.icon == 1 then
			settings.icon = 0
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Icon off.')
		else
			settings.icon = 1
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Icon on.')
		end
	end
	if (cmd == 'text') then
		if settings.text == 1 then
			settings.text = 0
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Text off.')
		else
			settings.text = 1
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Text on.')
		end
	end
	if (cmd == 'skin') then
		skintype = table.remove(command,1)
		settings.skin = skintype
		CDTRACKER_SAVESETTINGS()
		return CHAT_SYSTEM('Skin set to '..settings.skin..'.')
	end
	if (cmd == 'list') then
		GET_SKILL_LIST()
		for k,v in ipairs(skillList) do
			local alertstatus = 'on'
			local chatstatus = 'off'
			if settings.ignoreList[v] ~= nil then
				if settings.ignoreList[v] == 1 then
					alertstatus = 'off'
				end
			end
			if settings.chatList[v] ~= nil then
				if settings.chatList[v] == 1 then
					chatstatus = 'on'
				end
			end
			CHAT_SYSTEM('ID '..k..': '..v..' - alert '..alertstatus..' - chat '..chatstatus)
		end
		return;
	end
	if (cmd == 'alert') then
		local skillID = table.remove(command,1)
		if skillList[tonumber(skillID)] ~= nil then
			if settings.ignoreList[skillList[tonumber(skillID)]] == 1 then
				settings.ignoreList[skillList[tonumber(skillID)]] = 0
				CDTRACKER_SAVESETTINGS()
				return CHAT_SYSTEM('Alerts on for '..skillList[tonumber(skillID)]..'.')
			end
			settings.ignoreList[skillList[tonumber(skillID)]] = 1
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Alerts off for '..skillList[tonumber(skillID)]..'.')
		end
		return CHAT_SYSTEM('Invalid skill ID.')
	end
	if (cmd == 'chat') then
		local skillID = table.remove(command,1)
		if skillList[tonumber(skillID)] ~= nil then
			if settings.chatList[skillList[tonumber(skillID)]] == 1 then
				settings.chatList[skillList[tonumber(skillID)]] = 0
				CDTRACKER_SAVESETTINGS()
				return CHAT_SYSTEM('Chat alerts off for '..skillList[tonumber(skillID)]..'.')
			end
			settings.chatList[skillList[tonumber(skillID)]] = 1
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Chat alerts on for '..skillList[tonumber(skillID)]..'.')
		end
		return CHAT_SYSTEM('Invalid skill ID.')
	end
	if cmd == 'status' then
		CHAT_SYSTEM(' ')
		if settings.alerts == 0 then
			CHAT_SYSTEM('CD Tracker: off')
		else
			CHAT_SYSTEM('CD Tracker: on')
		end
		if settings.icon == 0 then
			CHAT_SYSTEM('Icon: off')
		else
			CHAT_SYSTEM('Icon: on')
		end
		if settings.text == 0 then
			CHAT_SYSTEM('Text: off')
		else
			CHAT_SYSTEM('Text: on')
		end
	if cmd == 'buffs' then
		if settings.buffs == 1 then
			settings.buffs = 0
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Buffs off.')
		else
			settings.buffs = 1
			CDTRACKER_SAVESETTINGS()
			return CHAT_SYSTEM('Buffs on.')
		end
	end
		if settings.sound == 0 then
			CHAT_SYSTEM('Sound: off')
		else
			CHAT_SYSTEM('Sound: on')
		end
		CHAT_SYSTEM('Sound type: '..settings.soundtype)
		CHAT_SYSTEM('X position: '..settings.posX)
		CHAT_SYSTEM('Y position: '..settings.posY)
		CHAT_SYSTEM('Skin: '..settings.skin)
		CHAT_SYSTEM(' ')
		return;
	end
	if (cmd == 'reset') then
		settings = default
		CDTRACKER_SAVESETTINGS()
		return CHAT_SYSTEM('All settings reset to defaults.')
	end
	CHAT_SYSTEM(' ')
	CHAT_SYSTEM('Available commands:')
	CHAT_SYSTEM('/cd on')
	CHAT_SYSTEM('/cd off')
	CHAT_SYSTEM('/cd <seconds>')
	CHAT_SYSTEM('/cd icon')
	CHAT_SYSTEM('/cd text')
	CHAT_SYSTEM('/cd sound')
	CHAT_SYSTEM('/cd sound <number>')
	CHAT_SYSTEM('/cd list')
	CHAT_SYSTEM('/cd alert <ID>')
	CHAT_SYSTEM('/cd chat <ID>')
	CHAT_SYSTEM('/cd skin <skinname>')
	CHAT_SYSTEM('/cd x skill <coords>')
	CHAT_SYSTEM('/cd y skill <coords>')
	CHAT_SYSTEM('/cd x buff <coords>')
	CHAT_SYSTEM('/cd y buff <coords>')
	CHAT_SYSTEM('/cd status')
	CHAT_SYSTEM('/cd reset')
	CHAT_SYSTEM(' ')
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
		for k,v in pairs(cdTrackSkill['Slots']) do
			if v == index then
				return tonumber(k)
			end
		end
		for k,v in ipairs(cdTrackSkill['Slots']) do
			if v == nil then
				cdTrackSkill['Slots'][k] = index
				return tonumber(k)
			end
		end
		table.insert(cdTrackSkill['Slots'],index)
		return #cdTrackSkill['Slots']
	end
	if cdtype == 'BUFF' then
		for k,v in pairs(cdTrackBuff['Slots']) do
			if v == index then
				return tonumber(k)
			end
		end
		for k,v in ipairs(cdTrackBuff['Slots']) do
			if v == nil then
				cdTrackBuff['Slots'][k] = index
				return tonumber(k)
			end
		end
		table.insert(cdTrackBuff['Slots'],index)
		return #cdTrackBuff['Slots']
	end
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
	CDTRACK_BUFF_CHECK()
	local index = CHECK_ICON_EXIST(icon)
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
			-- DRAW_READY_ICON(cdTrackSkill[index]['obj'],2.5,cdTrackSkill[index]['slot'],60,60)
			DISPLAY_SLOT(index, cdTrackSkill[index]['slot'],cdTrackSkill[index]['fullName'],cdTrackSkill[index]['curTimeSecs'], 'SKILL', cdTrackSkill[index]['obj'],2)

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

		DISPLAY_SLOT(index, cdTrackSkill[index]['slot'],cdTrackSkill[index]['fullName'],cdTrackSkill[index]['curTimeSecs'], 'SKILL', cdTrackSkill[index]['obj'],0.5)

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

skillFrame = {}
skillFrame['nameSKILL'] = {}
skillFrame['typeSKILL'] = {}
skillFrame['cooldownSKILL'] = {}
skillFrame['iconSKILL'] = {}
skillFrame['nameBUFF'] = {}
skillFrame['typeBUFF'] = {}
skillFrame['cooldownBUFF'] = {}
skillFrame['iconBUFF'] = {}
skillFrame['nameDEBUFF'] = {}
skillFrame['typeDEBUFF'] = {}
skillFrame['cooldownDEBUFF'] = {}
skillFrame['iconDEBUFF'] = {}

function DISPLAY_SLOT(index, slot, name, cooldown, cdtype, obj, duration)
	local sizeX = 325
	local sizeY = 50
	
	local cdFrame = ui.CreateNewFrame('cdtracker','FRAME_'..cdtype..slot)
	cdFrame:SetSkinName(settings.skin)
	cdFrame:Resize(sizeX,sizeY)

	local iconFrame = ui.CreateNewFrame('cdtracker','ICONFRAME_'..cdtype..slot)
	iconFrame:Resize(50,50)

	skillFrame['name'..cdtype][slot] = cdFrame:CreateOrGetControl('richtext','cd_name_'..cdtype..slot, 0,0,0,0)
	skillFrame['name'..cdtype][slot] = tolua.cast(skillFrame['name'..cdtype][slot],'ui::CRichText')
	skillFrame['type'..cdtype][slot] = cdFrame:CreateOrGetControl('richtext','cd_type_'..cdtype..slot, 0,0,0,0)
	skillFrame['type'..cdtype][slot] = tolua.cast(skillFrame['type'..cdtype][slot],'ui::CRichText')
	skillFrame['cooldown'..cdtype][slot] = cdFrame:CreateOrGetControl('richtext','cd_cooldown_'..cdtype..slot, 0,0,0,0)
	skillFrame['cooldown'..cdtype][slot] = tolua.cast(skillFrame['cooldown'..cdtype][slot],'ui::CRichText')
	skillFrame['icon'..cdtype][slot] = iconFrame:CreateOrGetControl('picture','cd_icon_'..cdtype..slot, 0,0,0,0)
	skillFrame['icon'..cdtype][slot] = tolua.cast(skillFrame['icon'..cdtype][slot],'ui::CPicture')

	skillFrame['cooldown'..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)
	skillFrame['cooldown'..cdtype][slot]:SetOffset(12,0)

	skillFrame['name'..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)
	skillFrame['name'..cdtype][slot]:SetOffset(155,0)
	
	skillFrame['type'..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)
	skillFrame['type'..cdtype][slot]:SetOffset(45,0)
	
	skillFrame['icon'..cdtype][slot]:SetGravity(ui.LEFT, ui.CENTER_VERT)

	local colors = {red = '{#cc0000}', green = '{#00cc00}', yellow = '{#cccc00}', orange = '{#cc6600}'}
	if cdtype == 'SKILL' then
		local totalCd = cdTrackSkill[index]['totalTime']
		if cooldown == 0 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.green..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.green..'-')
		elseif cooldown < (totalCd/1000)*.33 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.yellow..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.yellow..cooldown)
		elseif cooldown < (totalCd/1000)*.66 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.orange..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.orange..cooldown)
		else
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.red..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.red..cooldown)
		end
		skillFrame['type'..cdtype][slot]:SetText('{@st41}{s18}{#ffe600}[SKILL]')
	end
	if cdtype == 'BUFF' then

		if cooldown == 0 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.red..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.red..'-')
		elseif cooldown <= 5 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.orange..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.orange..cooldown)
		elseif cooldown < 10 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.yellow..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.yellow..cooldown)
		else
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.green..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.green..cooldown)
		end
		skillFrame['type'..cdtype][slot]:SetText('{@st41}{s18}{#00e6cf}[BUFF]')
	end
	if cdtype == 'DEBUFF' then
		if cooldown == 0 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.green..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.green..'-')
		elseif cooldown <= 5 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.yellow..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.yellow..cooldown)
		elseif cooldown < 10 then
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.orange..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.orange..cooldown)
		else
			skillFrame['name'..cdtype][slot]:SetText('{@st41}{s18}'..colors.red..name)
			skillFrame['cooldown'..cdtype][slot]:SetText('{@st41}{s18}'..colors.red..cooldown)
		end
		skillFrame['type'..cdtype][slot]:SetText('{@st41}{s18}{#cc0000}[DEBUFF]')
	end
	
	cdFrame:Resize(skillFrame['name'..cdtype][slot]:GetWidth()+170,sizeY)
	
	
	cdFrame:ShowWindow(1)
	cdFrame:SetDuration(2)
	
	local iconname = "Icon_" .. obj.Icon
	skillFrame['icon'..cdtype][slot]:SetImage(iconname)
	skillFrame['icon'..cdtype][slot]:SetEnableStretch(1)
	skillFrame['icon'..cdtype][slot]:Resize(50,50)
	
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
	cdFrame:SetEventScript(ui.LBUTTONDOWN, "CD_DRAG_START");
	cdFrame:SetEventScript(ui.LBUTTONUP, "CD_DRAG_STOP");
	
	if CD_DRAG_STATE == true then
		if cdtype == 'SKILL' then
			settings.skillPosX = cdFrame:GetX()
			settings.skillPosY = cdFrame:GetY()-60*slot
		end
		if cdtype == 'BUFF' or cdtype == 'DEBUFF' then
			settings.buffPosX = cdFrame:GetX()
			settings.buffPosY = cdFrame:GetY()-60*slot
		end
	end
	if CD_DRAG_STATE == false then
		if cdtype == 'SKILL' then
			cdFrame:MoveFrame(settings.skillPosX,settings.skillPosY+60*slot)
			iconFrame:MoveFrame(settings.skillPosX-65,settings.skillPosY+60*slot)
		end
		if cdtype == 'BUFF' or cdtype == 'DEBUFF' then
			cdFrame:MoveFrame(settings.buffPosX,settings.buffPosY+60*slot)
			iconFrame:MoveFrame(settings.buffPosX-65,settings.buffPosY+60*slot)
		end
	end
end

function GET_SKILL_LIST()
	skillList = {}
	for k,v in pairs(cdTrackSkill) do
		if type(tonumber(k)) == 'number' then
			table.insert(skillList, cdTrackSkill[k]['fullName'])
			CHAT_SYSTEM(cdTrackSkill[k]['fullName'])
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

buff_ui = {};
buff_ui["buff_group_cnt"] = 2;	-- 0 : buff(limitcount) / 1 : buff / 2 : debuff
buff_ui["slotsets"] = {};
buff_ui["slotlist"] = {};
buff_ui["captionlist"] = {};
buff_ui["slotcount"] = {};
buff_ui["txt_x_offset"] = 1;
buff_ui["txt_y_offset"] = 1;

cdTrackBuff = {}
cdTrackBuff['time'] = {}
cdTrackBuff['prevTime'] = {}
cdTrackBuff['name'] = {}
cdTrackBuff['slot'] = {}
cdTrackBuff['class'] = {}
cdTrackBuff['Slots'] = {}

function CDTRACK_BUFF_CHECK()
	if settings.buffs == 0 then
		return;
	end
	local buff_ui = _G['s_buff_ui']
	local handle = session.GetMyHandle();
	local updated = 0;
	for j = 0 , buff_ui["buff_group_cnt"] do
		local slotlist = buff_ui["slotlist"][j];
		local captlist = buff_ui["captionlist"][j];
		if buff_ui["slotcount"][j] ~= nil and buff_ui["slotcount"][j] >= 0 then
    		for i = 0,  buff_ui["slotcount"][j] - 1 do
    			local slot		= slotlist[i];
    			local text		= captlist[i];
    
				local icon 		= slot:GetIcon();
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
	if ID ~= 4532 then
		if cdTrackBuff['class'][name].Group1 == 'Debuff' then
			bufftype = 'DEBUFF'
		else
			bufftype = 'BUFF'
		end
		if cdTrackBuff['prevTime'][name] ~= cdTrackBuff['time'][name] then
			cdTrackBuff['slot'][name] = FIND_NEXT_SLOT(name, 'BUFF')
			if cdTrackBuff['time'][name] == 0 and cdTrackBuff['prevTime'][name] == 1 then
				if settings.sound == 1 then
					-- if settings.soundtype > 0 and settings.soundtype <= table.getn(soundTypes) then
						-- imcSound.PlaySoundEvent(soundTypes[settings.soundtype]);
					-- else
						-- imcSound.PlaySoundEvent(soundTypes[1])
					-- end
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
	end
	return;
end