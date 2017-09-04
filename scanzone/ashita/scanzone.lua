_addon.author   = 'Project Tako';
_addon.name     = 'ScanZone';
_addon.version  = '1.1';

require('common');
local dats = require('datmap');

local scan_zone = 
{
	target_index = 0,
	scanning = false 
};

local function find(name_to_find)
	-- table to hold our results
	local results = { };
	-- our current zone id, which we will need to figure out the path of the dat file
	local zone_id = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
	-- check to make sure the zone is valid, just in case
	if (zone_id > 0) then
		-- read the dats table to get the path for the current zone
		local dat = dats[zone_id];
		-- make sure we have a valid dat file path
		if (dat ~= nil) then
			-- open the dat file
			local file = io.open(string.format('%s\\..\\FINAL FANTASY XI\\%s', ashita.file.get_install_dir(), dat), 'rb');
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
						local t = struct.unpack('c', data, x);
						-- check to make sure it's not a terminating/null char
						if (t ~= '\0') then
							-- valid char, append
							name = name .. t;
						end
					end

					-- unpack the id, which always starts at the same position
					local id = struct.unpack('I', data, 29);	

					-- check to see if the name of the entity in the dat contains the name we're looking for
					if (name:lower():contains(name_to_find:lower())) then
						-- add it to our results table 
						results[#results + 1] = { name = name, id = id, index = bit.band(id, 0xFFF) };
					end
				end
			end
		end
	end

	return results;
end

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

	-- ensure it's one of our commands
	if (args[1] ~= '/scanzone') then
		return false;
	end

	-- user wants to scan
	if (args[2] == 'scan') then
		-- make sure we have an arg passed in for the target index
		if (#args < 3) then
			print('[Scan Zone]Not enough arguments! Please provide a target index to scan for.');
			return false;
		end

		-- convert to a number, the arg will be passed in as hex
		local target_index = tonumber(args[3], 16);
		-- make sure we have something
		if (target_index ~= nil) then
			-- set the target index we're scanning for
			scan_zone.target_index = target_index;

			-- create and inject an outgoing packet 
			local scan_packet = struct.pack('bbbbbbbb', 0x16, 0x08, 0x00, 0x00, (scan_zone.target_index % 256), math.floor(scan_zone.target_index / 256), 0x00, 0x00):totable();
			AddOutgoingPacket(0x16, scan_packet);

			-- notify that we're actively scanning
			scan_zone.scanning = true;

			-- user feedback
			print('[Scan Zone]Scanning for entity...');
			return true;
		end
	elseif (args[2] == 'find') then -- user wants to find the target index of an entity in the dat file
		-- validate we have enough for a partial name
		if (#args < 3) then
			print('[Scan Zone]Not enough arguments! Please provide an entity name to find.');
			return false;
		end

		-- loop through the args in case they passed in a name with a space (e.g. Home Point).
		local name_to_search = args[3];
		for x = 4, #args, 1 do
			name_to_search = string.format('%s %s', name_to_search, args[x]);
		end

		-- search the dats
		local entities = find(name_to_search);
		-- check to see if we found any
		if (entities and #entities > 0) then
			for key, value in pairs(entities) do
				print(string.format('[Scan Zone]Found entity with name: %s. TargetIndex: 0x%X', value['name'], value['index']));
			end
		else
			print(string.format('[Scan Zone]Did not find any entites with name: %s', name_to_search));
		end
	end 
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	if (id == 0x0E) then
		if (scan_zone.scanning) then
			local target_index = struct.unpack('h', packet, 0x08 + 1);

			if (target_index == scan_zone.target_index) then
				scan_zone.scanning = false;
				scan_zone.target_index = 0;

				local updatemask = struct.unpack('b', packet, 0x0A + 1);
				if (updatemask ~= nil) then
					local id = struct.unpack('I', packet, 0x04 + 1);
					if (id ~= nil) then
						print(string.format('[ScanZone]Found Entity: %d (0x%X)', id, id));
					end

					if (bit.band(updatemask, 0x08)) then
						local name = '';
						for x = 1, (#packet - 0x34), 1 do
							local t = struct.unpack('c', packet, 0x34 + x);
							if (t ~= 0) then
								name = name .. t;
							end
						end

						if (name ~= nil and name ~= '') then
							print(string.format('[ScanZone]Name: %s', name));
						end
					end

					if (bit.band(updatemask, 0x01)) then
						local x, z, y = struct.unpack('fff', packet, 0x0C + 1);
						if (x ~= nil and z ~= nil and y ~= nil) then
							print(string.format('[ScanZone]Position: (%.2f, %.2f, %.2f)', x, y, z));
						end
					end

					if (bit.band(updatemask, 0x04)) then
						local hpp, animation, status = struct.unpack('bbb', packet, 0x1E + 1);
						if (hpp ~= nil) then
							print(string.format('[ScanZone]HPP: %d', hpp));
						end

						if (status ~= nil) then
							print(string.format('[ScanZone]Status: %d', status));
						end
					end
				end
			end
		end
	end
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
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()

end);
