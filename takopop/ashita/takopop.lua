_addon.author   = 'Project Tako';
_addon.name     = 'TakoPop';
_addon.version  = '1.0';

require('common');

-- local settings that tell the addon how many cells to buy, use, etc.
local settings = 
{
	cells = 
	{
		colbat = { buy = true, amount = 96 },
		rubicund = { buy = true, amount = 96 }
	}, { 'buy', 'amount' },
	displacer_count = 5,
	cell_count = 1
};

-- Holds if we've traded cells and phase displacers
local has_traded = false;

-- cancel results
local cancel_result = 0x40000000;
local cancel_result_seq = string.char(0x00, 0x00, 0x00, 0x40);

---------------------------------------------------------------------------------------------------
-- func: count_cells
-- desc: Loops through the players inventory storage and counts how many cells are there
---------------------------------------------------------------------------------------------------
local function count_cells()
	-- get the players inventory
	local inventory = AshitaCore:GetDataManager():GetInventory();
	-- cell counts
	local colbalt_count = 0;
	local rubicund_count = 0;

	-- loop through inventory and check for cells
	for index = 1, inventoy:GetContainerMax(0), 1 do
		-- get inventory item at index
		local item = inventory:GetItem(0, index);

		-- item id 3434 = colbalt cell
		-- item id 3435 = rubicund cell
		if (item['Id'] == 3434) then
			colbalt_count = colbalt_count + item['Count'];
		elseif (item['Id'] == 3435) then
			rubicund_count = rubicund_count + item['Count'];
		end
	end

	return colbalt_count, rubicund_count;
end

---------------------------------------------------------------------------------------------------
-- func: read_inventory
-- desc: Loops through the players inventory storage and get the index and counts to be used in our trade packet
---------------------------------------------------------------------------------------------------
local function read_inventory()
	-- get the players inventory
	local inventory = AshitaCore:GetDataManager():GetInventory();
	-- holds the inventory slot and count for cells and displacers
	local colbalt_slot = 0;
	local colbalt_count = 0;
	local rubicund_slot = 0;
	local rubicund_count = 0;
	local displacer_slot = 0;
	local displacer_count = 0;

	-- loop through inventory and get slots and counts
	for index = 1, inventory:GetContainerMax(0), 1 do
		-- get inventory item at index
		local item = inventory:GetItem(0, index);

		-- If there's multiple stacks/slots of a cell/displacer, use which ever slot has more
		if (item['Id'] == 3434) then
			-- item id 3434 = colbalt cell
			-- check if we already found them
			if (colbalt_slot > 0) then
				-- check to see if the newly found cells have a higher count
				if (item['Count'] > colbalt_count) then
					-- set slot index and count
					colbalt_slot = item['Index'];
					colbalt_count = item['Count'];
				end
			else
				-- set slot index and count
				colbalt_slot = item['Index'];
				colbalt_count = item['Count'];
			end
		elseif (item['Id'] == 3435) then
			-- item id 3435 = rubicund cell
			-- check if we already found them
			if (rubicund_slot > 0) then
				-- check to see if the newly found cells have a higher count
				if (item['Count'] > rubicund_count) then
					-- set slot index and count
					rubicund_slot = item['Index'];
					rubicund_count = item['Count'];
				end
			else
				-- set slot index and count
				rubicund_slot = item['Index'];
				rubicund_count = item['Count'];
			end
		elseif (item['Id'] == 3853) then
			-- item id 3853 = phase displacers
			-- check if we already found them
			if (displacer_slot > 0) then
				-- check to see if the newly found displacers have a higher count
				if (item['Count'] > displacer_count) then
					-- set slot index and count
					displacer_slot = item['Index'];
					displacer_count = item['Count'];
				end
			else
				-- set slot index and count
				displacer_slot = item['Index'];
				displacer_count = item['Count'];
			end
		end
	end

	-- if there is more cells/displacers in that slot index than we want to use, cap them at that
	if (colbalt_count > settings['cell_count']) then
		colbalt_count = settings['cell_count'];
	end

	if (rubicund_count > settings['cell_count']) then
		rubicund_count = settings['cell_count'];
	end

	if (displacer_count > settings['displacer_count']) then
		displacer_count = settings['displacer_count'];
	end

	return colbalt_slot, colbalt_count, rubicund_slot, rubicund_count, displacer_slot, displacer_count;
end

---------------------------------------------------------------------------------------------------
-- func: get_rift
-- desc: Get the needed information about a Planar Rift to use for the trade packet injection 
---------------------------------------------------------------------------------------------------
local function get_rift()
	-- get the entity manager
	local entity_manager = AshitaCore:GetDataManager():GetEntity();
	-- loop through entity array looking for a planar rift in range of us and in range of trading
	for index = 0, 4096, 1 do
		-- check to see if the name matches
		if (entity_manager:GetName(index) == 'Planar Rift') then
			-- check distance to make sure it's in range of trading
			-- take distance in the entity struct and get the square root of it to get actual in game distance
			-- Math.Sqrt(entity.Distance) = real distance
			-- Math.Sqrt(36) = 6; max trade distance = 5.9 in game
			if (entity_manager:GetDistance(index) < 36.0) then
				-- return needed information for the trade packet
				return entity_manager:GetTargetIndex(index), entity_manager:GetServerId(index);
			end
		end
	end

	-- we didn't find a rift, bummer.
	return -1, -1;
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
	if (args[1] ~= '/takopop') then
		return false;
	end

	-- this will attempt to find a planar rift, and if it does find it, trade cells/displacers to it
	if (args[2] == 'voidwatch' or args[2] == 'vw') then
		-- attempt to find the rift
		local target_index, target_server_id = get_rift();
		if (target_index == -1 or target_server_id == -1) then
			print('Could not find a Planar Rift within trade distance.');
			return true;
		end

		-- read inventory to find slots and counts
		local colbalt_slot, colbalt_count, rubicund_slot, rubicund_count, displacer_slot, displacer_count = read_inventory();
		-- should put this somewhere else, but lazy
		local number_of_items = 3;

		-- construct the menu_item_packet
		local menu_item_packet = struct.pack('bbbbIIIIIIIIIIIbbbbbbbbbbhI', 0x36, 0x20, 0x00, 0x00, target_server_id, colbalt_count, rubicund_count, displacer_count, 0, 0, 0, 0, 0, 0, 0, colbalt_slot, rubicund_slot, displacer_slot, 0, 0, 0, 0, 0, 0, 0, target_index, number_of_items):totable();
		-- inject packet
		AddOutgoingPacket(0x36, menu_item_packet);
		-- set has_traded to true to allow it to pop it
		has_traded = true;

		return true;
	end

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
	-- check to see it's an event packet
	if (id == 0x5B) then
		-- read the data from the packet
		local event_target_id = struct.unpack('I', packet, 0x04 + 1);
		local result_id = struct.unpack('I', packet, 0x08 + 1);
		local target_index = struct.unpack('H', packet, 0x0C + 1);
		local queue_next_event = struct.unpack('H', packet, 0x0E + 1);
		local zone_id = struct.unpack('H', packet, 0x10 + 1);
		local event_id = struct.unpack('H', packet, 0x12 + 1);

		-- get the entity to use later
		local entity_name = AshitaCore:GetDataManager():GetEntity():GetName(target_index);

		-- if it's the voidwatch officer
		if (entity_name == 'Voidwatch Officer') then
			-- if the event has been canceled, that's the signal for us to change the event result to what we want to buy
			if (result_id == cancel_result) then
				-- check to see how many cells we need to buy
				local colbalt_count, rubicund_count = cell_count();
				local colbat_needed = settings['cells']['colbat']['amount'] - colbalt_count;
				local rubicund_needed = settings['cells']['rubicund']['amount'] - rubicund_count;

				-- if we need to buy colbalt cells
				if (colbat_needed > 0 and settings['cells']['colbat']['buy']) then
					-- print to user showing how many cells we're buying.
					print(string.format('[TakoPop] Buying %d Colbalt Cells', colbat_needed));
					-- change result id to what we want.
					-- option is apart of the third char
					-- count is packed into the third and fourth chars
					local new_packet = (packet:sub(1, 8) .. string.char(0x02, 0x00, 0x01 + ((colbat_needed * 64) % 256), math.floor((colbat_needed * 64) / 256)) .. packet:sub(13)):totable();
					AddOutgoingPacket(id, new_packet);

					return true;
				elseif (rubicund_needed > 0 and settings['cells']['rubicund']['buy']) then
					-- print to user showing how many cells we're buying.
					print(string.format('[TakoPop] Buying %d Rubicund Cells', colbat_needed));
					-- change result id to what we want.
					-- option is apart of the third char
					-- count is packed into the third and fourth chars
					local new_packet = (packet:sub(1, 8) .. string.char(0x02, 0x00, 0x02 + ((rubicund_needed * 64) % 256), math.floor((rubicund_needed * 64) / 256)) .. packet:sub(13)):totable();
					AddOutgoingPacket(id, new_packet);

					return true;
				end
			end
		elseif (entity_name == 'Planar Rift') then
			-- if the event has been canceled, it's the signal to force the event result to start the void watch with max displacers 
			if (result_id == cancel_result) then
				-- check to make sure we've traded. waste of stones otherwise
				if (has_traded) then
					-- char 0 = 0x01 + 0x10 per displacer
					-- i.e. 0x11 = start with 1 displacer
					--      0x21 = start with 2 displacers
					local new_packet = (packet:sub(1, 8) .. string.char(0x51, 0x00, 0x00, 0x00) .. packet:sub(13)):totable();
					AddOutgoingPacket(id, new_packet);
					has_traded = false;

					return true;
				else
					print('[TakoPop] Nothing has been traded. Not forcing pop.');
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