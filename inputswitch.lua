local acutil = require('acutil');
local loaded = 0
function INPUTSWITCH_ON_INIT(addon, frame)
	if (loaded == 0) then
		acutil.slashCommand('/inputswitch',parse);
		ui.SysMsg("Input switcher loaded! To use, type /inputswitch.")
		loaded = 1
	end
end 
function INPUTSWITCH(x)
	if (x == 0) then
		config.ChangeXMLConfig("ControlMode", 2);
		session.config.SetMouseMode(false);
		UPDATE_CONTROL_MODE()
	elseif (x == 1) then 
		config.ChangeXMLConfig("ControlMode", 3);
		session.config.SetMouseMode(true);
		UPDATE_CONTROL_MODE()
	end
	return 0;
end

function parse(command)
	local cmd = table.remove(command,1);
	if (cmd == 'kb') then
		INPUTSWITCH(0)
		return ui.SysMsg('Keyboard mode enabled.');
	end
	if (cmd == 'mouse') then
		INPUTSWITCH(1)
		return ui.SysMsg('Mouse mode enabled.')
	end
	if (not cmd) then
		return ui.SysMsg('Type /inputswitch kb to enable keyboard, or /inputswitch mouse to enable mouse.')
	end
end