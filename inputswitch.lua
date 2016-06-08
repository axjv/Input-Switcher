function INPUTSWITCH_ON_INIT(addon, frame)
	frame:ShowWindow(1);
	frame:RunUpdateScript("INPUT_UPDATE", 0, 0, 0, 1);
end

function INPUT_UPDATE(frame)

	if keyboard.IsKeyPressed("LALT") == 1 then
		if keyboard.IsKeyPressed("NUMPAD4") == 1 then
			config.ChangeXMLConfig("ControlMode", 2);
			session.config.SetMouseMode(false);
			UPDATE_CONTROL_MODE()
		elseif keyboard.IsKeyPressed("NUMPAD6") == 1 then 
			config.ChangeXMLConfig("ControlMode", 3);
			session.config.SetMouseMode(true);
			UPDATE_CONTROL_MODE()
		end
	end
	return 1;
end