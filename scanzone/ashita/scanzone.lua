_addon.author   = 'Project Tako';
_addon.name     = 'ScanZone';
_addon.version  = '2.1';

require('common');
local dats = require('datmap');

-- imgui controls and variables
local imgui_variables = 
{
	['var_ShowWindow'] 				 = { nil, ImGuiVar_BOOLCPP, true },
	['var_TrackMobs_InputMobName'] 	 = { nil, ImGuiVar_CDSTRING, 50 },
	['var_TrackMobs_ListBoxResults'] = { nil, ImGuiVar_INT32, 1 }
};


-- variables for adding tracked mobs  
local last_input = nil;
local search_delay = 1.0;
local last_search = os.time();
local search_results = { };
local last_click = -1;

-- keep track of tracked mobs
local tracked_entites = { };
local scanning_entites = { };

-- variables for manually scanning through /commands
local manual_scan = 
{
	['index'] = 0,
	['scanning'] = false
};

-- keep track of all entites 
local entity_array = { };

local function find_mob_by_name(name_to_find)
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
			if (type(dat) ~= 'table') then
				return { };
			end

			for datNum = 1, #dat, 1 do
				-- open the dat file
				local file = io.open(string.format('%s\\..\\FINAL FANTASY XI\\%s', ashita.file.get_install_dir(), dat[datNum]), 'rb');
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
	end

	return results;
end

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- initialize imgui and it's variables
	for key, value in pairs(imgui_variables) do
		-- if it's data type CDSTRING, the third argument is the max length
		-- otherwise initialize var with that datatype
		if (value[2] >= ImGuiVar_CDSTRING) then
			imgui_variables[key][1] = imgui.CreateVar(value[2], value[3]);
		else 
			imgui_variables[key][1] = imgui.CreateVar(value[2]);
		end

		-- if there's a default value, set it
		-- we don't do this for CDSTRING
		-- default values are the third key on non-CDSTRING ones
		if (#value > 2 and value[2] < ImGuiVar_CDSTRING) then
			imgui.SetVarValue(imgui_variables[key][1], value[3]);
		end
	end

	-- set imgui window size for next created window
	imgui.SetNextWindowSize(300, 300, ImGuiSetCond_FirstUseEver);
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
	-- get command args
	local args = cmd:args();

	-- ensure it's a scanzone command
	if (args[1] ~= '/scanzone') then
		return false;
	end

	-- user wants to toggle ui
	if (args[2] == 'on' or args[2] == 'toggle') then
		imgui.SetVarValue(imgui_variables['var_ShowWindow'][1], not imgui.GetVarValue(imgui_variables['var_ShowWindow'][1]));
	elseif (args[2] == 'scan') then -- user wants to do a manual scan
		-- make sure we have an arg passed in for the target index
		if (#args < 3) then
			print('[Scan Zone]Not enough arguments! Please provide a target index to scan for.');
			return false;
		end
		-- convert to a number, the arg will be passed in as hex
		local target_index = tonumber(args[3], 16);
		-- make sure we have something
		if (target_index ~= nil) then
			manual_scan['index'] = target_index;
			local scan_packet = struct.pack('bbbbhbb', 0x16, 0x08, 0x00, 0x00, target_index, 0x00, 0x00):totable();
			AddOutgoingPacket(0x16, scan_packet);
			manual_scan['scanning'] = true;

			print('[ScanZone]Scanning for entity...');
			return true;
		end
	end

	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Called when the game client has begun to add a new line of text to the chat box.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, chat)
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	-- zone
	if (id == 0x0A) then
		entity_array = { };
		tracked_entites = { };
		scanning_entites = { };

		--imgui_variables['var_TrackMobs_InputMobName'][1] = '';
		imgui.SetVarValue(imgui_variables['var_TrackMobs_InputMobName'][1], '');
	end
	-- npc or player entity update
	if (id == 0x0D or id == 0x0E) then
		-- read data that is always there
		local target_id = struct.unpack('I', packet, 0x04 + 1);
		local target_index = struct.unpack('h', packet, 0x08 + 1);
		local updatemask = struct.unpack('b', packet, 0x0A + 1);

		-- check to make sure we have something in this table for the mob, if not, put defaults
		if (entity_array[target_id] == nil) then
			entity_array[target_id] = 
			{ 
				['id'] = target_id, 
				['index'] = index, 
				['name'] = '', 
				['position'] = 
				{
					['x'] = 0.00,
					['z'] = 0.00,
					['y'] = 0.00
				},
				['hpp'] = 0,
				['animation'] = 0,
				['status'] = 7
			};
		end

		-- data that we may or may not end up reading out
		local name = '';
		local x = 0;
		local z = 0; 
		local y = 0;
		local hpp = 0;
		local animation = 0;
		local status = 0;

		-- make sure we have an update mask
		if (updatemask ~= nil) then
			-- 0x01 = UPDATE_POS
			if (bit.band(updatemask, 0x01) == 0x01) then
				x, z, y = struct.unpack('fff', packet, 0x0C + 1);

				entity_array[target_id]['position'] = { ['x'] = x, ['z'] = z, ['y']  = y };
			end

			if (bit.band(updatemask, 0x04) == 0x04) then
				hpp, animation, status = struct.unpack('bbb', packet, 0x1E + 1);
				entity_array[target_id]['hpp'] = hpp;
				entity_array[target_id]['animation'] = animation;
				entity_array[target_id]['status'] = status;
			end

			-- 0x08 = UPDATE_NAME
			if (bit.band(updatemask, 0x08) == 0x08) then
				for x = 1, (#packet - 0x34), 1 do
					local t = struct.unpack('c', packet, 0x34 + x);
					if (t ~= 0) then
						name = name .. t;
					end

					entity_array[target_id]['name'] = name;
				end
			end
		end

		if (manual_scan['scanning']) then
			if (target_index == manual_scan['index']) then
				manual_scan['scanning'] = false;
				manual_scan['index'] = 0;

				if (target_id ~= 0) then
					print(string.format('[ScanZone]Found Entity: %d (0x%X)', target_id, target_id));
				end

				if (name ~= nil and name ~= '') then
					print(string.format('[ScanZone]Name: %s', name));
				end

				if (x ~= nil and z ~= nil and y ~= nil) then
					print(string.format('[ScanZone]Position: (%.2f, %.2f, %.2f)', x, y, z));
				end

				if (hpp ~= nil) then
					print(string.format('[ScanZone]HPP: %d', hpp));
				end

				if (status ~= nil) then
					print(string.format('[ScanZone]Status: %d', status));
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
	if (id == 0x0A) then
		entity_array = { };
		tracked_entites = { };
		scanning_entites = { };
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
	-- if we're not showing the window, don't do anything
	if (imgui.GetVarValue(imgui_variables['var_ShowWindow'][1]) == false) then
        return;
    end

    -- Begin rendering the window
    if (imgui.Begin('Scan Zone - Project Tako', imgui_variables['var_ShowWindow'][1], ImGuiWindowFlags_AlwaysAutoResize)) then
    	-- Begin rendering collapsed header
    	if (imgui.CollapsingHeader('Track Mobs')) then
    		imgui.InputText('Mob Name', imgui_variables['var_TrackMobs_InputMobName'][1], imgui_variables['var_TrackMobs_InputMobName'][3]);

    		-- only read from the dats every so often to avoid overhead
    		if (os.time() >= (last_search + search_delay)) then
    			-- get the text box text
	    		local input = imgui.GetVarValue(imgui_variables['var_TrackMobs_InputMobName'][1]);
	    		-- only search if it's a new input value and not blank
	    		if (input ~= '' and input ~= last_input) then
	    			last_input = input;
		    		local entities = find_mob_by_name(input);
		    		
		    		if (entities and #entities > 0) then
		    			search_results = entities;
			    	else
			    		search_results = { };
			    	end
			    elseif (input == nil or input == '') then
			    	search_results = { };
		    	end
		    end

		    -- make sure we have results
		    if (#search_results > 0) then
		    	local output = '';
		    	for key, value in pairs(search_results) do
		    		output = output .. string.format('%s - 0x%X\0', value['name'], value['index']);
		    	end

		    	if (imgui.ListBox('Search Results', imgui_variables['var_TrackMobs_ListBoxResults'][1], output)) then
		    		local click_index = imgui.GetVarValue(imgui_variables['var_TrackMobs_ListBoxResults'][1]);
		    		if (click_index) then
		    			--print(imgui.GetVarValue(imgui_variables['var_TrackMobs_ListBoxResults'][1]));
		    			if (click_index == last_click) then
		    				local entity = search_results[imgui.GetVarValue(imgui_variables['var_TrackMobs_ListBoxResults'][1]) + 1];
		    				if (entity ~= nil) then
		    					table.insert(tracked_entites, entity);

		    					-- create variable so it is closeable
					    		local closeable_key = string.format('var_%s-%d_closable', entity['name'], entity['index']);
					    		if (imgui_variables[closeable_key] == nil) then
					    			imgui_variables[closeable_key] = { nil, ImGuiVar_BOOLCPP };

					    			imgui_variables[closeable_key][1] = imgui.CreateVar(imgui_variables[closeable_key][2]);
					    		end

					    		imgui.SetVarValue(imgui_variables[closeable_key][1], true);

		    					last_click = -1;
		    				end
		    			else 
		    				last_click = click_index;
		    			end
		    		end
		    	end
		    end
    	end

    	imgui.Separator();

    	-- loop through tracked entites and make imgui data for each
    	for key, value in pairs(tracked_entites) do
    		-- check to see if they closed this mob and remove if so
    		local closeable_key = string.format('var_%s-%d_closable', value['name'], value['index']);
    		if (imgui.GetVarValue(imgui_variables[closeable_key][1]) == false) then
				tracked_entites[key] = nil;
    		else
    			-- create ui
	    		if (imgui.CollapsingHeader(string.format('%s - 0x%X', value['name'], value['index']), imgui_variables[closeable_key][1])) then
	    			-- if we haven't scanned for it ever, or it's been too long, send a scan packet
					if (scanning_entites[value['index']] == nil or os.time() >= (scanning_entites[value['index']] + 10.0)) then
						local scan_packet = struct.pack('bbbbhbb', 0x16, 0x08, 0x00, 0x00, value['index'], 0x00, 0x00):totable();
						AddOutgoingPacket(0x16, scan_packet);	

						scanning_entites[value['index']] = os.time();
					end

	    			if (entity_array[value['id']] ~= nil) then
	    				-- get the entity from the array
	    				local entity = entity_array[value['id']];

	    				-- print some of the basic data
	    				imgui.Text(string.format('HPP: %d', entity['hpp']));
	    				imgui.SameLine();
	    				imgui.Text(string.format('Animation: %d', entity['animation']));
	    				imgui.SameLine();
	    				local status_text = '';
	    				if (entity['status'] == 0) then
	    					status_text = 'NPC';
	    				elseif (entity['status'] == 1) then
	    					status_text = 'Alive';
	    				elseif (entity['status'] == 2) then
	    					status_text = 'Disappear';
	    				else
	    					status_text = 'Dead';
	    				end
	    				imgui.Text(string.format('Status: %s', status_text));

	    				-- position data
	    				imgui.Text(string.format('Position: (%.2f, %.2f, %.2f)', entity['position']['x'], entity['position']['y'], entity['position']['z']));

	    				-- button for warping
	    				imgui.PushID(entity['id']);
	    				if (imgui.Button('Warp To Mob')) then
	    					-- get player index
	    					local player_index = AshitaCore:GetDataManager():GetParty():GetMemberTargetIndex(0);
	    					-- get player warp pointer
	    					local player_warp_ptr = AshitaCore:GetDataManager():GetEntity():GetWarpPointer(player_index);

	    					-- write position 
	    					-- x axis
	    					ashita.memory.write_float(player_warp_ptr + 0x34, entity['position']['x']);
							ashita.memory.write_float(player_warp_ptr + 0x5C4, entity['position']['x']);
							-- z axis
							ashita.memory.write_float(player_warp_ptr + 0x38, entity['position']['z']);
							ashita.memory.write_float(player_warp_ptr + 0x5C8, entity['position']['z']);
							-- y axis
							ashita.memory.write_float(player_warp_ptr + 0x3C, entity['position']['y']);
							ashita.memory.write_float(player_warp_ptr + 0x5CC, entity['position']['y']);
	    				end
	    				imgui.PopID();
	    			end
	    		end
	    	end

    		imgui.Separator();
    	end
    end

    -- End rendering
    imgui.End();
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
	-- delete imgui stuff
	for key, value in pairs(imgui_variables) do
        if (imgui_variables[key][1] ~= nil) then
            imgui.DeleteVar(imgui_variables[key][1]);
        end
        imgui_variables[key][1] = nil;
    end
end);