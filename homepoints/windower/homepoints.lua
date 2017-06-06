_addon.name = 'Homepoints';
_addon.version = '1.0';
_addon.author = 'Project Tako';
_addon.commands = { 'homepoints' };

require('pack');

-- Packet masks to display all homepoint options
local masks = 
{
	[1] = string.char(0xFF, 0xFF, 0xFF, 0xFF),
	[2] = string.char(0xFF, 0xFF, 0xFF, 0xFF),
	[3] = string.char(0xFF, 0xFF, 0xFF, 0xFF),
	[4] = string.char(0xFF, 0xFF, 0xFF, 0x1F);
};

-- Event id for cancel/nothing
local cancel_result = 0x40000000;
local cancel_result_seq = string.char(0x00, 0x00, 0x00, 0x40);

-- Replace the third char (0x02, 0x00, 0xXX, 0x00) with the hex value of the homepoint index located here:
-- https://github.com/DarkstarProject/darkstar/blob/master/scripts/globals/homepoint.lua
-- i.e. homepoints[55] = { 2, 24,     243,    -24,      62,   0, 204, 1000}; -- Fei'Yin #1 = 55 = 0x37
-- to convert a number to hex if you don't know how, you can literally google "55 in hex" and it will tell you.
local destination = string.char(0x02, 0x00, 0x37, 0x00);

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
windower.register_event('load', function()

end);

---------------------------------------------------------------------------------------------------
-- func: addon command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
windower.register_event('addon command', function (...)

end);

---------------------------------------------------------------------------------------------------
-- func: incoming chunk
-- desc: Called when our addon receives an incoming chunk.
---------------------------------------------------------------------------------------------------
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
	-- check to see if the incoming packet is an event packet
	if (id == 0x34) then
		-- read the event id from the packet
		local event_id = original:unpack('h', 0x2C + 1);
		-- check to see if the event id is a homepoint event. 
		if (event_id >= 0x21FC and event_id <= 0x21FF) then
			-- foruce the homepoint masks to include all home points, and not just the one's we've unlocked.
			return original:sub(0x01, 0x0B) .. masks[1] .. masks[2] .. masks[3] .. masks[4] .. original:sub(0x1C);
		end
	end
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing chunk
-- desc: Called when our addon receives an outgoing chunk.
---------------------------------------------------------------------------------------------------

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
	-- check to see if the outgoing packet is an event packet
	if (id == 0x5B) then 
		local target_index = original:unpack('h', 0x0C + 1);
		-- get entity name
		local entity_name = (windower.ffxi.get_mob_by_index(target_index))['name'];

		-- sometimes this is nil, doesn't hurt to check
		if (entity_name ~= nil) then
			-- check to see if we're eventing a home point
			if (string.find(entity_name, 'Home Point')) then
				-- get the result id 
				local result_id = original:unpack('I', 0x08 + 1);

				-- they canceled, let's intercept
				if (result_id == cancel_result) then
					return original:sub(0x01, 0x08) .. destination .. original:sub(0x0D);
				end
			end
		end
	end
end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
windower.register_event('unload', function()

end);