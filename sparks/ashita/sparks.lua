_addon.author   = 'ProjectTako';
_addon.name     = 'Sparks';
_addon.version  = '1.0';

require('common');
local item_data = require('item_map');

-- table that holds information on the spark npcs and their menus
-- key is zone id
local m_SparksData =
{
	-- Southern San d'Oria
	[230] = { ['npc_name'] = 'Rolandienne', ['menu_id'] = 995 },
	-- Bastoke Markets
	[235] = { ['npc_name'] = 'Isakoth', ['menu_id'] = 26 },
	-- Windurst Woods
	[241] = { ['npc_name'] = 'Fhelm Jobeizat', ['menu_id'] = 850 },
	-- Western Adoluin
	[256] = { ['npc_name'] = 'Eternal Flame', ['menu_id'] = 5081 }
};

-- holds the flag that indicates if our player is 'busy' in an action (even if we don't see it)
local b_PlayerIsBusy = false;

-- data we'll use in out event update packets
local packet_data = { };
---------------------------------------------------------------------------------------------------
-- func: find sparks npc
-- desc: Looks for and finds the sparks npc in the entity array
---------------------------------------------------------------------------------------------------
local function find_sparks_npc()
	-- table to hold the data we'll need to use later
	local data = { ['index'] = -1, ['id'] = -1 };

	-- get our current zone id
	local zone_id = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
	-- check to make sure we have a sparks npc in this zone
	if (m_SparksData[zone_id] ~= nil) then
		-- get our entity manager
		local entity_manager = AshitaCore:GetDataManager():GetEntity();
		-- loop through the entity array looking for the sparks npc
		for index = 0, 4000, 1 do
			if (entity_manager:GetName(index) == m_SparksData[zone_id]['npc_name']) then
				-- make sure the entity is within interact range (6 yalms)
				-- to get real distance you can sqrt the value, but I'm lazy
				if (entity_manager:GetDistance(index) < 36.0) then
					-- set the data we need, and exit the loop.
					data['id'] = entity_manager:GetServerId(index);
					data['index'] = entity_manager:GetTargetIndex(index);
					break;
				end
			end
		end
	end

	return data;
end

---------------------------------------------------------------------------------------------------
-- func: find item data
-- desc: Loops through the item map and gets the required item data
---------------------------------------------------------------------------------------------------
local function find_item_data(item_name)
	-- loop through the item map
	for key, value in pairs(item_data) do
		-- check to see if the item name is what we want to buy
		if (string.lower(value['name']) == string.lower(item_name)) then
			-- return the item data table
			return value;
		end
	end

	return nil;
end

---------------------------------------------------------------------------------------------------
-- func: send npc interaction packet
-- desc: Constructs and injects an action packet with param 0 (interact) and the given data
---------------------------------------------------------------------------------------------------
local function send_npc_interact_packet(target_id, target_index)
	-- basic validation
	if (target_id ~= nil and target_id > -1 and target_index ~= nil and target_index > -1) then
		-- at this point, we have everything we need, set player busy flag
		b_PlayerIsBusy = true;

		-- construct the packet		
		local packet = struct.pack('bbbbIhhhh', 0x1A, 0x1C, 0x00, 0x00, target_id, target_index, 0x00, 0x00, 0x00):totable();
		-- inject
		AddOutgoingPacket(0x1A, packet);
	end
end

---------------------------------------------------------------------------------------------------
-- func: send event update packet
-- desc: Constructs and injects an event update packet with given data
---------------------------------------------------------------------------------------------------
local function send_event_update_packet(target_id, target_index, item_option, item_index, queue_next_event)
	-- get our current zone id
	local zone_id = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
	local menu_id = m_SparksData[zone_id]['menu_id'];
	-- construct packet
	local packet = struct.pack('bbbbIhhhbbhh', 0x5B, 0x14, 0x00, 0x00, target_id, item_option, item_index, target_index, queue_next_event, 0x00,zone_id, menu_id):totable();
	-- inject
	AddOutgoingPacket(0x5B, packet);
end

---------------------------------------------------------------------------------------------------
-- func: send entity information request packet
-- desc: Constructs and injects an entity information request packet with given data
---------------------------------------------------------------------------------------------------
local function send_entity_information_request_packet(target_index)
	-- create the request packet
	local packet = struct.pack('bbbbhh', 0x16, 0x08, 0x00, 0x00, target_index, 0x00):totable();

	-- inject
	AddOutgoingPacket(0x16, packet);
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

	if (args[1] ~= '/sparks') then
		return false;
	end

	-- command to buy a sparks item
	if (args[2] == 'buy') then
		-- make sure we're not already doing something
		if (b_PlayerIsBusy) then
			print('[Sparks] Player already busy.');
			return true;
		end

		-- check to make sure there is a sparks npc near us.
		local sparks_npc = find_sparks_npc();
		-- validate it is near us
		if (sparks_npc['id'] ~= -1 and sparks_npc['index'] ~= -1) then
			-- we found a sparks npc, now check to see if the item they want to buy is valid
			-- the item will be args[3] and beyond
			local item_name = table.concat(args, ' ', 3);
			-- get item data
			local item_data = find_item_data(item_name);
			-- validate it's a sparks item
			if (item_data ~= nil) then
				-- set out packet data we'll use later
				packet_data['npc'] = sparks_npc;
				packet_data['item'] = item_data;

				-- send action (interact) packet
				send_npc_interact_packet(sparks_npc['id'], sparks_npc['index']);
			end
		end

		-- command has been handled
		return true;
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
	-- 0x32 and 0x34 are event packets
	if (id == 0x32 or id == 0x34) then
		-- check to see if we set the player busy flag
		if (b_PlayerIsBusy) then
			-- we need to send two outgoing event update packets here (0x5B).
			-- following those two event update packets, we must send one entity information request packet (0x16);

			-- first event update packet, biggest thing about this is setting queue next event to 1
			send_event_update_packet(packet_data['npc']['id'], packet_data['npc']['index'], packet_data['item']['option'], packet_data['item']['index'], 1);

			-- second event update packet, we set the 'item_option' to 0, the 'item_index' to a static value of 0x4000 (cancel?) and queue next event to 0
			send_event_update_packet(packet_data['npc']['id'], packet_data['npc']['index'], 0, 0x4000, 0);

			-- finally, send an entity information requests packet for this npc
			send_entity_information_request_packet(packet_data['npc']['index']);

			-- reset out busy flag
			b_PlayerIsBusy = false;
			packet_data = { };

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