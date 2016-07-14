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
	chatList = {}
	}
soundTypes = {'button_click_stats_up','quest_count','quest_event_start','quest_success_2','sys_alarm_mon_kill_count','quest_event_click','sys_secret_alarm', 'travel_diary_1','button_click_4'}

cdTrackSkill = {}
skillFrame = {}
iconFrame = {}
cdTrackSkill['Slots'] = {}
cdTrackSkill['icon'] = {}
skillList = {}
skillIndex = 1


timer = imcTime.GetAppTime()
local msgDisplay = 0

local screenWidth = ui.GetClientInitialWidth();
local screenHeight = ui.GetClientInitialHeight();

function CDTRACKER_ON_INIT(addon, frame)
	acutil.setupHook(ICON_USE_HOOKED,'ICON_USE')
	acutil.setupHook(ICON_UPDATE_SKILL_COOLDOWN_HOOKED,'ICON_UPDATE_SKILL_COOLDOWN')
	acutil.slashCommand('/cd',cdTracker_SetVal)
	cdTrackSkill = {}
	skillFrame = {}
	iconFrame = {}
	cdTrackSkill['Slots'] = {}
	cdTrackSkill['icon'] = {}
	skillList = {}
	skillIndex = 1
	cdTracker_LoadSettings()
end

function cdTracker_LoadSettings()
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
	cdTracker_SaveSettings()
end

function cdTracker_SaveSettings()
	table.sort(settings)
	acutil.saveJSON("../addons/cdtracker/settings.json", settings);
end


function cdTracker_SetVal(command)
	local cmd = table.remove(command,1);
	if (type(tonumber(cmd)) == "number") then
		settings.checkVal = tonumber(cmd)
		cdTracker_SaveSettings()
		return CHAT_SYSTEM('CD alert set to '..cmd..' seconds.')
	end
	if (cmd == 'on') then
		settings.alerts = 1
		cdTracker_SaveSettings()
		return CHAT_SYSTEM('CD alerts on.');
		end
	if (cmd == 'off') then
		settings.alerts = 0
		cdTracker_SaveSettings()
		return CHAT_SYSTEM('CD alerts off.')
	end
	if (cmd == 'sound') then
		local soundVal = table.remove(command,1)
		if soundVal ~= nil then
			if type(tonumber(soundVal)) == 'number' then
				settings.soundtype = math.floor(tonumber(soundVal))
				imcSound.PlaySoundEvent(soundTypes[settings.soundtype])
				cdTracker_SaveSettings()
				return CHAT_SYSTEM('Sound type set to '..settings.soundtype..'.')
			end
			return CHAT_SYSTEM('Invalid sound value.')
		end
		if settings.sound == 1 then
			settings.sound = 0
			cdTracker_SaveSettings()
			return CHAT_SYSTEM('Sound off.')
		else
			settings.sound = 1
			cdTracker_SaveSettings()
			return CHAT_SYSTEM('Sound on.')
		end
	end
	if (cmd == 'icon') then
		if settings.icon == 1 then
			settings.icon = 0
			cdTracker_SaveSettings()
			return CHAT_SYSTEM('Icon off.')
		else
			settings.icon = 1
			cdTracker_SaveSettings()
			return CHAT_SYSTEM('Icon on.')
		end
	end
	if (cmd == 'text') then
		if settings.text == 1 then
			settings.text = 0
			cdTracker_SaveSettings()
			return CHAT_SYSTEM('Text off.')
		else
			settings.text = 1
			cdTracker_SaveSettings()
			return CHAT_SYSTEM('Text on.')
		end
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
				cdTracker_SaveSettings()
				return CHAT_SYSTEM('Alerts on for '..skillList[tonumber(skillID)]..'.')
			end
			settings.ignoreList[skillList[tonumber(skillID)]] = 1
			cdTracker_SaveSettings()
			return CHAT_SYSTEM('Alerts off for '..skillList[tonumber(skillID)]..'.')
		end
		return CHAT_SYSTEM('Invalid skill ID.')
	end
	if (cmd == 'chat') then
		local skillID = table.remove(command,1)
		if skillList[tonumber(skillID)] ~= nil then
			if settings.chatList[skillList[tonumber(skillID)]] == 1 then
				settings.chatList[skillList[tonumber(skillID)]] = 0
				cdTracker_SaveSettings()
				return CHAT_SYSTEM('Chat alerts off for '..skillList[tonumber(skillID)]..'.')
			end
			settings.chatList[skillList[tonumber(skillID)]] = 1
			cdTracker_SaveSettings()
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
		if settings.sound == 0 then
			CHAT_SYSTEM('Sound: off')
		else
			CHAT_SYSTEM('Sound: on')
		end
		CHAT_SYSTEM('Sound type: '..settings.soundtype)
		CHAT_SYSTEM(' ')
		return;
	end
	if (cmd == 'reset') then
		settings = default
		cdTracker_SaveSettings()
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
	CHAT_SYSTEM('/cd status')
	CHAT_SYSTEM('/cd reset')
	CHAT_SYSTEM(' ')
	cdTracker_SaveSettings()
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


function FIND_NEXT_SLOT(index)
	for k,v in pairs(cdTrackSkill['Slots']) do
		if v == index then
			return tonumber(k)
		end
	end
	table.insert(cdTrackSkill['Slots'],index)
	return #cdTrackSkill['Slots']
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
			local skillName = SANITIZE_SKILL_NAME(cdTrackSkill[index]['fullName']);
			ui.Chat('!!Casting '..skillName..'!')
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
				local skillName = SANITIZE_SKILL_NAME(cdTrackSkill[index]['fullName']);
				ui.Chat('!!'..skillName..' ready!')
				msgDisplay = 1
				timer = imcTime.GetAppTime()
			end
			cdTrackSkill[index]['prevTime'] = 0
			DRAW_READY_ICON(cdTrackSkill[index]['obj'],2.5,cdTrackSkill[index]['slot'],60,60)
			table.remove(cdTrackSkill['Slots'],FIND_NEXT_SLOT(index))
			return cdTrackSkill[index]['curTime'], cdTrackSkill[index]['totalTime'];
		end

		if settings.text == 1 and settings.ignoreList[cdTrackSkill[index]['fullName']] ~= 1 then
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			
			ui.AddText('SystemMsgFrame',cdTrackSkill[index]['fullName']..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
		end
		if settings.chatList[cdTrackSkill[index]['fullName']] == 1 then
			local skillName = SANITIZE_SKILL_NAME(cdTrackSkill[index]['fullName']);
			ui.Chat('!!'..skillName..' ready in '..cdTrackSkill[index]['curTimeSecs']..' seconds.')
			msgDisplay = 1
			timer = imcTime.GetAppTime()
		end
		
		if settings.ignoreList[cdTrackSkill[index]['fullName']] ~= 1 then
			cdTrackSkill[index]['slot'] = FIND_NEXT_SLOT(index)
		end
		
		if cdTrackSkill[index]['curTime'] < 500 and settings.ignoreList[cdTrackSkill[index]['fullName']] ~= 1 then
			local countUp = 500 - cdTrackSkill[index]['curTime']
			local scaleUp = 50 + (countUp/500)*10
			DRAW_READY_ICON(cdTrackSkill[index]['obj'],0.5,cdTrackSkill[index]['slot'],scaleUp,scaleUp)
		else
			DRAW_READY_ICON(cdTrackSkill[index]['obj'],0.5,cdTrackSkill[index]['slot'],50,50)
		end
		

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

 
function DRAW_READY_ICON(obj,duration,skillSlot,sizeX,sizeY)
	if settings.icon == 0 then
		return;
	end
	skillSlot = skillSlot-1
	if skillSlot/2 == math.floor(skillSlot/2) then
		offset = 0 - 65 + 65*(skillSlot/2)
	else
		offset = 0 - 65 - 65*(math.ceil(skillSlot/2))
	end
	local iconname = "Icon_" .. obj.Icon
	skillFrame[skillSlot] = ui.CreateNewFrame('cdtracker','SKILL_FRAME_'..skillSlot)
	skillFrame[skillSlot]:ShowWindow(1)
	skillFrame[skillSlot]:SetDuration(duration)
	if sizeX == 60 then
		skillFrame[skillSlot]:SetOffset(screenWidth/2+offset-5, screenHeight/3.6-5);
	else
		skillFrame[skillSlot]:SetOffset(screenWidth/2+offset, screenHeight/3.6);
	end
	iconFrame[skillSlot] = GET_CHILD(skillFrame[skillSlot], 'iconFrame', 'ui::CPicture')
	iconFrame[skillSlot]:SetImage(iconname)
	iconFrame[skillSlot]:Resize(sizeX,sizeY)
	iconFrame[skillSlot]:SetGravity(ui.LEFT, ui.TOP);
end



function GET_SKILL_LIST()
	skillList = {}
	for k,v in pairs(cdTrackSkill) do
		if type(tonumber(k)) == 'number' then
			table.insert(skillList, cdTrackSkill[k]['fullName'])
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