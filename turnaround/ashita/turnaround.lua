_addon.author   = 'Project Tako';
_addon.name     = 'TurnAround';
_addon.version  = '1.0';

require('common');
require('mathex');

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()

end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
	-- get command args
	local args = cmd:args();

	if (args[1] == '/turnaround' or args[1] == '/ta') then
		-- get player index
		local index = AshitaCore:GetDataManager():GetParty():GetMemberTargetIndex(0); 
		if (index ~= 0) then
			-- get player
			local player = GetEntity(index);
			-- get target
			local target = GetEntity(AshitaCore:GetDataManager():GetTarget():GetTargetIndex());

			if (player ~= nil and target ~= nil) then
				-- calculate the angle that would face away from target
				local angle = (math.atan2((target['Movement']['LocalPosition']['Z'] - player['Movement']['LocalPosition']['Z']), (target['Movement']['LocalPosition']['X'] - player['Movement']['LocalPosition']['X'])) * 180 / math.pi) * -1.0;
				local radian = math.degree2rad(angle + 180);

				if (radian) then
					ashita.memory.write_float(player['WarpPointer'] + 0x48, radian);
					ashita.memory.write_float(player['WarpPointer'] + 0x5D8, radian);
				end
			elseif (player ~= nil and target == nil) then
				-- get current angle and calculate to just face opposite of where we currently are
				local angle = (player['Movement']['LocalPosition']['Yaw'] * 180.0 / math.pi);
				local radian = math.degree2rad(angle + 180);

				if (radian) then
					ashita.memory.write_float(player['WarpPointer'] + 0x48, radian);
					ashita.memory.write_float(player['WarpPointer'] + 0x5D8, radian);
				end
			end
		end
	end

	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Called when the game client has begun to add a new line of text to the chat box.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_text
-- desc: Called when the game client is sending text to the server.
--       (This gets called when a command, chat, etc. is not handled by the client and is being sent to the server.)
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: prerender
-- desc: Called before our addon is about to render.
---------------------------------------------------------------------------------------------------
ashita.register_event('prerender', function()

end);

---------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when our addon is being rendered.
---------------------------------------------------------------------------------------------------
ashita.register_event('render', function()

end);

---------------------------------------------------------------------------------------------------
-- func: timer_pulse
-- desc: Called when our addon is rendering it's scene.
---------------------------------------------------------------------------------------------------
ashita.register_event('timer_pulse', function()

end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()

end);