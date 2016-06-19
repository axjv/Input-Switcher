local acutil = require('acutil');
settings = {}
local default = {
	checkVal = 5;
	alerts = 1;
	sound = 1;
	}
	
local skillName = ' '
local fullName = ' '
local prevName = ' '
local cdCheck = settings.checkVal
local curTime = 0
local totalTime = 0
local obj = nil
local counter = 0
local offset = 0
local queue = {}
local oldVal = {}
local skillCd = {}
skillFrame = {}
iconFrame = {}
iconSlots = {}

local screenWidth = ui.GetClientInitialWidth();
local screenHeight = ui.GetClientInitialHeight();

function cdTracker_LoadSettings()
	local s, err = acutil.loadJSON("../addons/cdtracker/settings.json");
	if err then
		settings = default
		cdTracker_SaveSettings()
	else
		settings = s
		for k,v in pairs(default) do
			if not s[k] then
				settings[k] = v
			end
		end
	end
end

function cdTracker_SaveSettings()
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
		settings.sound = not settings.sound
		cdTracker_SaveSettings()
		if settings.sound == 1 then
			return CHAT_SYSTEM('CD ready sound on.')
		else
			return CHAT_SYSTEM('CD ready sound off.')
		end
	end
end

function CDTRACKER_ON_INIT(addon, frame)
	acutil.setupHook(ICON_USE_HOOKED,'ICON_USE')
	acutil.setupHook(ICON_UPDATE_SKILL_COOLDOWN_HOOKED,'ICON_UPDATE_SKILL_COOLDOWN')
	acutil.slashCommand('/cd',cdTracker_SetVal)
	cdTracker_LoadSettings()
end
	
function ICON_USE_HOOKED(object, reAction)
	_G['ICON_USE_OLD'](object, reAction);
	local iconPt = object;
	if iconPt  ~=  nil then
		local icon = tolua.cast(iconPt, 'ui::CIcon');
		local iconInfo = icon:GetInfo();
		local skillInfo = session.GetSkill(iconInfo.type);
		if skillInfo ~= nil then
			curTime = skillInfo:GetCurrentCoolDownTime();
			local sklObj = GetIES(skillInfo:GetObject());
			skillName = GetClassByType("Skill", sklObj.ClassID).ClassName
			fullName = string.sub(string.match(skillName,'_.+'),2):gsub("%u", " %1"):sub(2)
		end
		local cdCheck = math.ceil(curTime/1000)
		if cdCheck ~= 0 then
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			
			ui.AddText('SystemMsgFrame',fullName..' ready in '..cdCheck..' seconds.')
		end
	else
		return;
	end
end

function ICON_UPDATE_SKILL_COOLDOWN_HOOKED(icon)
	if settings.alerts == 0 then
		return _G['ICON_UPDATE_SKILL_COOLDOWN_OLD'](icon)
	end
	local iconInfo = icon:GetInfo();
	local skillInfo = session.GetSkill(iconInfo.type);
	if skillInfo ~= nil then
		
		curTime = skillInfo:GetCurrentCoolDownTime();
		totalTime = skillInfo:GetTotalCoolDownTime();
		local sklObj = GetIES(skillInfo:GetObject());
		obj = GetClassByType("Skill", sklObj.ClassID);
		skillName = GetClassByType("Skill", sklObj.ClassID).ClassName
		
		fullName = string.sub(string.match(skillName,'_.+'),2):gsub("%u", " %1"):sub(2)
		skillCd[fullName] = curTime
		if queue[fullName] == nil then
			queue[fullName] = -1
		end
	end
	cdCheck = math.ceil(skillCd[fullName]/1000)
	if settings.checkVal >= cdCheck and cdCheck~=oldVal[fullName] then
		if oldVal[fullName] == 1 and cdCheck == 0 then
			if settings.sound == 1 then
				imcSound.PlaySoundEvent('button_click_stats_up');
			end
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			ui.AddText('SystemMsgFrame',' ')
			
			ui.AddText('SystemMsgFrame',fullName..' ready.')
			oldVal[fullName] = 0
			DRAW_READY_ICON(obj,2.5,tonumber(FIND_NEXT_SLOT(iconSlots,fullName)),60,60)
			iconSlots[tostring(FIND_NEXT_SLOT(iconSlots,fullName))] = 0
			counter = counter - 1
			if counter == 0 then
				-- for k,v in pairs(queue) do
					-- ui.DestroyFrame('SKILL_FRAME_'..v)
				-- end
				offset = 0
			end
			queue[fullName] = -1
			return curTime, totalTime;
		end
		ui.AddText('SystemMsgFrame',' ')
		ui.AddText('SystemMsgFrame',' ')
		ui.AddText('SystemMsgFrame',' ')
		
		ui.AddText('SystemMsgFrame',fullName..' ready in '..cdCheck..' seconds.')
		oldVal[fullName] = cdCheck
		if queue[fullName] == -1 and cdCheck > 0 then
			if FIND_NEXT_SLOT(iconSlots,0) == nil then
				iconSlots[tostring(counter)] = fullName
				queue[fullName] = counter
			else
				iconSlots[tostring(FIND_NEXT_SLOT(iconSlots,0))] = fullName
				queue[fullName] = tonumber(FIND_NEXT_SLOT(iconSlots,fullName))
			end
			counter = counter + 1
		end
		if skillCd[fullName] < 500 then
			local countUp = 500 - skillCd[fullName]
			local scaleUp = 50 + (countUp/500)*10
			DRAW_READY_ICON(obj,0.5,tonumber(FIND_NEXT_SLOT(iconSlots,fullName)),scaleUp,scaleUp)
		else
			DRAW_READY_ICON(obj,0.5,tonumber(FIND_NEXT_SLOT(iconSlots,fullName)),50,50)
		end
	end
	return curTime, totalTime;
end

function FIND_NEXT_SLOT(slotArr, searchVal)
	local minK = 9999
	for k,v in pairs(slotArr) do
		if v == searchVal then
			if tonumber(k) < tonumber(minK) then
				minK = k
			end
		end
	end
	if tonumber(minK) < 9999 then
		return minK
	else
		return nil;
	end
end

function DRAW_READY_ICON(obj,duration,iconPos,sizex,sizey)
	if iconPos/2 == math.floor(iconPos/2) then
		offset = 0 - 65 + 65*(iconPos/2)
	else
		offset = 0 - 65 - 65*(math.ceil(iconPos/2))
	end
	local iconname = "Icon_" .. obj.Icon
	skillFrame[iconPos] = ui.CreateNewFrame('cdtracker','SKILL_FRAME_'..iconPos)
	skillFrame[iconPos]:ShowWindow(1)
	skillFrame[iconPos]:SetDuration(duration)
	if sizex == 60 then
		skillFrame[iconPos]:SetOffset(screenWidth/2+offset-5, screenHeight/3.6-5);
	else
		skillFrame[iconPos]:SetOffset(screenWidth/2+offset, screenHeight/3.6);
	end
	iconFrame[iconPos] = GET_CHILD(skillFrame[iconPos], 'iconFrame', 'ui::CPicture')
	iconFrame[iconPos]:SetImage(iconname)
	iconFrame[iconPos]:Resize(sizex,sizey)
	iconFrame[iconPos]:SetGravity(ui.LEFT, ui.TOP);
end