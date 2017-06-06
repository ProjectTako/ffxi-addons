_addon.author   = 'Project Tako';
_addon.name     = 'ScanZone';
_addon.version  = '1.0';

require('common');

local scan_zone = 
{
	target_index = 0,
	scanning = false 
};

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

	if (args[2] == 'scan') then
		if (#args < 3) then
			return false;
		end

		local target_index = tonumber(args[3], 16);
		if (target_index ~= nil) then
			scan_zone.target_index = target_index;

			local scan_packet = struct.pack('bbbbbbbb', 0x16, 0x08, 0x00, 0x00, (scan_zone.target_index % 256), math.floor(scan_zone.target_index / 256), 0x00, 0x00):totable();
			AddOutgoingPacket(0x16, scan_packet);

			scan_zone.scanning = true;

			print('[Scan Zone]Scanning for entity...');
			return true;
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
						print(string.format('[ScanZone]Found Entity: %d', id));
					end

					local name = '';
					for x = 1, (#packet - 0x34), 1 do
						local t = struct.unpack('c', 0x34 + x);
						name = name .. string.char(t);
					end

					if (name ~= nil and name ~= '') then
						print(string.format('[ScanZone]Name: %s', name));
					end

					local x, z, y = struct.unpack('fff', packet, 0x0C + 1);
					if (x ~= nil and z ~= nil and y ~= nil) then
						print(string.format('[ScanZone]Position: (%.2f, %.2f, %.2f)', x, y, z));
					end

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
