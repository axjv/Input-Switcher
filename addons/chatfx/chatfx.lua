local acutil = require('acutil')
local checkChatFrame = ui.GetFrame('chat')
local CHAT_FX_TIMER = nil
local i = 1
local style = 1
local speed = 10
local messageTable = {}
local message = 'Hello world'
local CHAT_FX_STYLES = {
	'Marquee';
	'Open and close';
	'Letter by letter';
}
CHAT_SYSTEM(' ')
CHAT_SYSTEM('ChatFX successfully loaded.')
CHAT_SYSTEM('Send message: /!! <message>')
CHAT_SYSTEM('Set message: /!!set <style> <speed>')
CHAT_SYSTEM('Style is a number from 1-3, speed is in frames per second.')
CHAT_SYSTEM(' ')

function CHATFX_ON_INIT()
	acutil.slashCommand('/!!',CHAT_FX_CMD)
	acutil.slashCommand('/!!set',CHAT_FX_SETTINGS)
	checkChatFrame = ui.GetFrame('chat')
end

function CHAT_FX_SET_MSG(msg,style)
	messageTable = {}
	message = msg:sub(2)
	if style == 1 then -- Marquee
		spaces = ''
		for i = 1,50 - message:len() do
			spaces = spaces..' '
		end

		for k = 1, message:len() do
			local a = message:sub(k)..spaces..message:sub(1,k-1)
			table.insert(messageTable,a)
		end
		for k = 1, spaces:len() do
			local b = spaces:sub(k)..message..spaces:sub(1,k-1)
			table.insert(messageTable,b)
		end
	end
	if style == 2 then -- open and close
		table.insert(messageTable,'||')
		mid = math.ceil(message:len()/2)
		for i = 0, mid do
			local a = '|'..message:sub(mid-i,mid+i)..'|'
			table.insert(messageTable,a)
		end
		length = #messageTable
		for i = 0, length-1 do
			local a = messageTable[length-i]
			table.insert(messageTable,a)
		end
	end
	if style == 3 then -- one letter at a time
		for i = 1,string.len(message) do
			table.insert(messageTable,message:sub(1,i))
		end
		table.insert(messageTable,message)
		table.insert(messageTable,message)
		table.insert(messageTable,message)
		for i = 1, string.len(message) do
			table.insert(messageTable,message:sub(1,string.len(message)-i))
		end
		table.insert(messageTable,'')
	end
	-- if style == 4 then -- blink
	-- 	table.insert(messageTable,message)
	-- 	table.insert(messageTable,'')
	-- end
end


function CHAT_FX_SEND_MSG()
	if checkChatFrame:IsVisible() == 0 then
		if i <= #messageTable then
			ui.Chat('!!'..messageTable[i])
			i = i+1
		else
			i = 1
		end
	end
	return;
end

function CHAT_FX_CMD(command)
	local cmd = command[1]

	-- if cmd == 'style' then
		-- style = tonumber(command[1])
		-- return;
	-- end
	if cmd then
		local cmdstring = ''
		for k,v in pairs(command) do
			cmdstring = cmdstring..' '..v
		end
		CHAT_FX_SET_MSG(cmdstring,style)
		frame = ui.CreateNewFrame('bandicam','CHAT_FX_FRAME')
		frame:ShowWindow(1)
		CHAT_FX_TIMER = GET_CHILD(frame, "addontimer", "ui::CAddOnTimer");
		CHAT_FX_TIMER:SetUpdateScript('CHAT_FX_SEND_MSG');
		CHAT_FX_TIMER:EnableHideUpdate(1)
		CHAT_FX_TIMER:Stop();
		CHAT_FX_TIMER:Start(1/speed);
		return;
	end
	CHAT_FX_SET_MSG('')
	ui.Chat('!!')
	ui.DestroyFrame('CHAT_FX_FRAME')
	return;
end

function CHAT_FX_SETTINGS(command)
	style = tonumber(table.remove(command,1))
	speed = tonumber(table.remove(command,1))
	CHAT_SYSTEM('Chat style set to: '..CHAT_FX_STYLES[style])
	CHAT_SYSTEM('Speed set to: '..speed..' frames per second.')
end
