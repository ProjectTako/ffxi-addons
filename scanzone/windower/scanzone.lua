_addon.name = 'ScanZone';
_addon.version = '1.0';
_addon.author = 'Project Tako';
_addon.commands = { 'scanzone', 'sz' };

require('pack');
local bit = require('bit')

local scanning = false;
local scanning_index = 0;

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

					if (bit.band(updatemask, 0x08)) then
						local name = '';
						for i = 1, (#original - 0x34), 1 do
							local t = original:unpack('c', 0x34 + i);
							name = name .. string.char(t);
						end

						if (name ~= nil and name ~= '') then
							windower.add_to_chat(128, string.format("[ScanZone]Name: %s", name));
						end
					end

					if (bit.band(updatemask, 0x01)) then
						local x, z, y = original:unpack('fff', 0x0C + 1);
						if (x ~= nil and z ~= nil and y ~= nil) then
							windower.add_to_chat(128, string.format("[ScanZone]Position: (%.2f, %.2f, %.2f)", x, y, z));
						end
					end

					if (bit.band(updatemask, 0x04)) then
						local hpp, animation, status = original:unpack('ccc', 0x1E + 1);

						windower.add_to_chat(128, string.format("[ScanZone]HPP: %d", hpp));
						windower.add_to_chat(128, string.format("[ScanZone]Status: %d", status));
					end
				end
			end
		end
	end
end)