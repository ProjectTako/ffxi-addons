_addon.author   = 'Project Tako';
_addon.name     = 'Fast Cutscene';
_addon.version  = '1.0';

require('common');
require('ffxi.targets');

local variables = 
{ 
	['zoning'] = false,
	['enabled'] = false,
	['divisor'] = 1,
	['excluded_npcs'] =
	{
		'Home Point #1',
		'Home Point #2',
		'Home Point #3',
		'Home Point #4',
		'Home Point #5',
		'Dimensional Portal',
		'Door: Back to Town',
		'Entry Gate'
	},
	last_status = 0
};


---------------------------------------------------------------------------------------------------
-- func: change_fps_divisor
-- desc: finds and writes the desired fps divisor to memory. I got this from fps.lua (thanks Atom0s)
---------------------------------------------------------------------------------------------------
local function change_fps_divisor(divisor)
	-- find pointer
	local pointer = ashita.memory.findpattern('FFXiMain.dll', 0, '81EC000100003BC174218B0D', 0, 0);
	if (pointer ~= 0) then
	    -- get address
	    local addr = ashita.memory.read_uint32(ashita.memory.read_uint32(pointer + 0x0C));

	    -- write divisor
	    ashita.memory.write_uint32(addr + 0x30, divisor);
	end
end

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	local player = GetPlayerEntity();

	-- status 4 is 'event' status
	if (player ~= nil and player['Status'] == 4) then
		change_fps_divisor(0);
	end
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
	-- get command args
	local args = cmd:args();

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
	local target = ashita.ffxi.targets.get_target('t');
	-- Zone In
	if (id == 0x00A) then
		if (variables['zoning']) then
			variables['zoning'] = false;

			if (variables['enabled']) then
				change_fps_divisor(variables['divisor']);
				variables['enabled'] = false;
			end
		end
	elseif (id == 0x00D) then -- player entity update 
		-- check update mask to make sure it's update 
		if (struct.unpack('b', packet, 0x0A + 1) == 0x1F) then
			-- check to see if packet is for our character
			local target_index = struct.unpack('h', packet, 0x08 + 1);
			if (target_index == AshitaCore:GetDataManager():GetParty():GetMemberTargetIndex(0)) then
				-- read status
				local status = struct.unpack('b', packet, 0x1F + 1);
				-- status 0x04 is event
				if (status ~= variables['last_status']) then
					if (status == 0x04) then
						if not (target ~= nil and table.hasvalue(variables['excluded_npcs'], target['Name'])) then
							change_fps_divisor(0);
							variables['enabled'] = true;
						end
					elseif (variables['last_status'] == 0x04 and variables['enabled']) then
						change_fps_divisor(variables['divisor']);
						variables['enabled'] = false;
					end

					variables['last_status'] = status;
				end
			end
		end
	elseif (id == 0x032 or id == 0x034) then -- event 
		if not (target ~= nil and table.hasvalue(variables['excluded_npcs'], target['Name'])) then
			if (variables['zoning'] == false and variables['enabled'] == false) then
				change_fps_divisor(0);
				variables['enabled'] = true;
			end
		end
	elseif (id == 0x037) then --character sync
		-- read status
		local status = struct.unpack('b', packet, 0x30 + 1);
		-- status 0x04 is event
		if (status ~= variables['last_status']) then
			if (status == 0x04) then
				if not (target ~= nil and table.hasvalue(variables['excluded_npcs'], target['Name'])) then
					change_fps_divisor(0);
					variables['enabled'] = true;
				end
			elseif (variables['last_status'] == 0x04 and variables['enabled']) then
				change_fps_divisor(variables['divisor']);
				variables['enabled'] = false;
			end

			variables['last_status'] = status;
		end
	--elseif (id == 0x052) then -- release
		--if (variables['enabled'] and variables['zoning'] == false) then
			--variables['enabled'] = false;
			--change_fps_divisor(variables['divisor']);
		--end
	end
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
	-- Leave Zone / Logout packet
	if (id == 0x00D) then
		if (variables['enabled']) then
			variables['enabled'] = false;
			change_fps_divisor(variables['divisor']);
		end

		variables['zoning'] = true;
	elseif (id == 0x5B) then -- event packet
		local result_id = struct.unpack('I', packet, 0x08 + 1);
		if (result_id == 0x40000000) then
			if (variables['enabled']) then
				change_fps_divisor(variables['divisor']);
				variables['enabled'] = false;
			end
		end
	end
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
	variables['enabled'] = false;
	change_fps_divisor(variables['divisor']);
end);