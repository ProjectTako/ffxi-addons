_addon.name = 'ScanZone';
_addon.version = '1.0';
_addon.author = 'Project Tako';
_addon.commands = { 'scanzone', 'sz' };

require('pack');
require('strings');
local bit = require('bit')
local dats = require('datmap');

local scanning = false;
local scanning_index = 0;

local function find(name_to_find)
	-- table to hold our results
	local results = { };
	-- our current zone id, which we will need to figure out the path of the dat file
	local zone_id = windower.ffxi.get_info()['zone'];
	-- check to make sure the zone is valid, just in case
	if (zone_id > 0) then
		-- read the dats table to get the path for the current zone
		local dat = dats[zone_id];
		-- make sure we have a valid dat file path
		if (dat ~= nil) then
			if (type(dat) ~= 'table') then
				return { };
			end

			for datNum = 1, #dat, 1 do
				if (dat[datNum] ~= nil) then
					-- open the dat file
					local file = io.open(string.format('C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\%s', dat[datNum]), 'rb');
					-- verify we have a valid file handle
					if (file ~= nil) then
						-- lazy way of doing it, we will break when we don't read any more data
						while (true) do
							-- read data. each entry is 32 bytes long
							-- 28 bytes = name. 4 bytes = server id. server id & 0xFFF = target index
							local data = file:read(32);
							-- if this is true, it's generally because we're at the end of the file
							if (data == nil) then
								break;
							end
							
							-- lets attempt to read the entities name from the dat file
							local name = '';
							for x = 1, 28, 1 do
								-- read the character at the position in the string
								local t = string.char(data:unpack('c', x)); -- struct.unpack('c', data, x);
								-- check to make sure it's not a terminating/null char
								if (t ~= '\0') then
									-- valid char, append
									name = name .. t;
								end
							end
							
							-- unpack the id, which always starts at the same position
							local id = data:unpack('I', 29); -- struct.unpack('I', data, 29);	

							-- check to see if the name of the entity in the dat contains the name we're looking for
							if (string.contains(name:lower(), name_to_find:lower())) then
								-- add it to our results table 
								results[#results + 1] = { name = name, id = id, index = bit.band(id, 0xFFF) };
							end
						end
					end
				end
			end
		end
	end

	return results;
end

windower.register_event('addon command', function (...)
	local cmd  = (...) and (...):lower();
    local cmd_args = { select(2, ...) };

	if (#cmd_args < 1) then
		windower.add_to_chat(128, "Not enough arguments");
		return;
	end

	if (cmd == 'scan') then
		local target_index = tonumber(cmd_args[1], 16);

		if (target_index ~= nil) then
			scanning_index = target_index;
			windower.packets.inject_outgoing(0x16, string.char(0x16, 0x08, 0x00, 0x00, (target_index % 256), math.floor(target_index / 256), 0x00, 0x00));
			scanning = true;

			windower.add_to_chat(128, "[ScanZone]Scanning for entity...");
		end
	elseif (cmd == 'find') then
		local name_to_search = table.concat(cmd_args, ' ');
		local entities = find(name_to_search);
		
		if (entities and #entities > 0) then
			for key, value in pairs(entities) do
				windower.add_to_chat(128, string.format('[Scan Zone]Found entity with name: %s. TargetIndex: 0x%X', value['name'], value['index']));
			end
		else
			windower.add_to_chat(128, string.format('[Scan Zone]Did not find any entites with name: %s', name_to_search));
		end
	end
end)

windower.register_event('incoming chunk', function(id, original, modified, injected)
	if (id == 0x0E) then
		if (scanning == true) then
			local target_index = original:unpack('h', 0x08 + 1);

			if (target_index == scanning_index) then
				scanning = false;
				scanning_index = 0;

				local updatemask = original:unpack('b', 0x0A + 1);
				if (updatemask ~= nil) then
					local id = original:unpack('I', 0x04 + 1);
					if (id ~= nil) then
						windower.add_to_chat(128, string.format("[ScanZone]Found Entity: %d", id));
					end

					if (bit.band(updatemask, 0x08) == 0x08) then
						local name = '';
						for i = 1, (#original - 0x34), 1 do
							local t = original:unpack('c', 0x34 + i);
							name = name .. string.char(t);
						end

						if (name ~= nil and name ~= '') then
							windower.add_to_chat(128, string.format("[ScanZone]Name: %s", name));
						end
					end

					if (bit.band(updatemask, 0x01) == 0x01) then
						local x, z, y = original:unpack('fff', 0x0C + 1);
						if (x ~= nil and z ~= nil and y ~= nil) then
							windower.add_to_chat(128, string.format("[ScanZone]Position: (%.2f, %.2f, %.2f)", x, y, z));
						end
					end

					if (bit.band(updatemask, 0x04) == 0x04) then
						local hpp, animation, status = original:unpack('ccc', 0x1E + 1);

						windower.add_to_chat(128, string.format("[ScanZone]HPP: %d", hpp));
						windower.add_to_chat(128, string.format("[ScanZone]Status: %d", status));
					end
				end
			end
		end
	end
end)