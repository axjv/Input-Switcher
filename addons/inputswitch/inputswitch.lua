local acutil = require('acutil');

ui.SysMsg("Input switcher loaded! To use, type /inputswitch.")
function INPUTSWITCH_ON_INIT(addon, frame)
	acutil.slashCommand('/inputswitch',inputSwitch_parse);
end

function inputSwitch_parse(command)
	local cmd = table.remove(command,1);
	if (cmd == 'kb') then
		config.ChangeXMLConfig("ControlMode", 2);
		UPDATE_CONTROL_MODE();
		return ui.SysMsg('Keyboard mode enabled.');
	end
	if (cmd == 'mouse') then
		config.ChangeXMLConfig("ControlMode", 3);
		UPDATE_CONTROL_MODE();
		return ui.SysMsg('Mouse mode enabled.')
	end
	if (cmd == 'toggle') then
		if config.GetXMLConfig("ControlMode") == 3 then
			config.ChangeXMLConfig("ControlMode", 2)
			UPDATE_CONTROL_MODE();
			return ui.SysMsg('Keyboard mode enabled.')
		end
		config.ChangeXMLConfig("ControlMode", 3)
		UPDATE_CONTROL_MODE();
		return ui.SysMsg('Mouse mode enabled.')
	end
	return ui.SysMsg('Type /inputswitch kb to enable keyboard, /inputswitch mouse to enable mouse, or /inputswitch toggle to toggle.')
end