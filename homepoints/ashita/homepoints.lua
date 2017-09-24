_addon.author   = 'Project Tako';
_addon.name     = 'Homepoints';
_addon.version  = '1.0';

require('common');

-- Packet masks to display all homepoint options
local masks = 
{
	[1] = string.char(0xFF, 0xFF, 0xFF, 0xFF),
	[2] = string.char(0xFF, 0xFF, 0xFF, 0xFF),
	[3] = string.char(0xFF, 0xFF, 0xFF, 0xFF),
	[4] = string.char(0xFF, 0xFF, 0xFF, 0xFF);
};

-- Event id for cancel/nothing
local cancel_result = 0x40000000;
local cancel_result_seq = string.char(0x00, 0x00, 0x00, 0x40);

-- Replace the third char (0x02, 0x00, 0xXX, 0x00) with the hex value of the homepoint index located here:
-- https://github.com/DarkstarProject/darkstar/blob/master/scripts/globals/homepoint.lua
-- i.e. homepoints[55]  = { 2, 24,     243,    -24,      62,   0, 204, 1000}; -- Fei'Yin #1 = 55 = 0x37
local destination = string.char(0x02, 0x00, 0x1D, 0x00);

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
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	-- check to see if the incoming packet is an event packet
	if (id == 0x34) then
		-- read the event id from the packet
		local event_id = struct.unpack('h', packet, 0x2C + 1);
		-- check to see if the event id is a homepoint event
		if (event_id >= 0x21FC and event_id <= 0x2200) then
			-- force the homepoint masks to include all homepoints, not just the one's we've unlocked
			local new_packet = (packet:sub(0x00 + 1, 0x0B + 1) .. masks[1] .. masks[2] .. masks[3] .. masks[4] .. packet:sub(0x1C + 1)):totable();
			AddIncomingPacket(id, new_packet);
			return true;
		end
	end

	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
	-- check to see if the outgoing packet is an event packet
	if (id == 0x5B) then
		-- read the target index so we can get the entity name, lazy
		local target_index = struct.unpack('h', packet, 0x0C + 1);
		-- get entity name
		local entity_name = AshitaCore:GetDataManager():GetEntity():GetName(target_index);

		-- sometimes this is nil, not completely sure why but doesn't hurt to check
		if (entity_name ~= nil) then
			-- check to see if we're eventing a HP
			if (entity_name:startswith('Home Point')) then
				-- get the result id
				local result_id = struct.unpack('I', packet, 0x08 + 1);

				-- they canceled it, let's intercept
				if (result_id == cancel_result) then
					-- force the result to our desired destination
					local new_packet = (packet:sub(0x00 + 1, 0x07 + 1) .. destination .. packet:sub(0x0C + 1)):totable();
					AddOutgoingPacket(id, new_packet);
					return true;
				end
			end
		end
	end

	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()

end);