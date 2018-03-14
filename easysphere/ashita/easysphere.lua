_addon.author   = 'Project Tako';
_addon.name     = 'EasySphere';
_addon.version  = '1.0';

require('common');

-- table holds all of the potential sphere items to look for when looking at our inventory
local m_SphereItems = 
{ 
	[4098] = { 551, 544, 1088, 1112, 1125, 1145, 1146, 1149, 1653, 1686, 1720, 1721, 1722, 1723, 2463, 4600, 9766, 9768, 9770, 9771 },
	[4100] = { 543, 549, 606, 607, 608, 609, 904, 1017, 1089, 1090, 1147, 1148, 1209, 1696, 2461, 2462, 9764, 9765, 9769 }
};

-- table to hold crystal => cluser mapping in the case we need to use a cluster
local m_ClusterMap = 
{
	[4098] = 4106,
	[4100] = 4108
};

-- table to hold our synth results, just so we can keep track 
local m_SynthResults = 
{
	['session'] = 
	{
		['total'] = 0,
		['breaks'] = 0,
		['success'] = 0,
		['hqs'] = 0
	},
	['total'] = 
	{
		['total'] = 0,
		['breaks'] = 0,
		['success'] = 0,
		['hqs'] = 0
	}
};

-- holds the synth result (break/nq/hq) for when we instantly complete the synth.
local m_SynthResultMessage = '';

-- flag to tell the addon to finish the synth instantly, rather than waiting for the entire animation
local b_FastCraft = false;

-- flag that holds whether we just used a cluster, so that apon incomming item packet, we can check to see if it's the crystal
local b_UsedCluster = false;

-- our on-screen font object config
local m_FontConfig = 
{
	['family'] = 'Comic Sans MS',
	['size'] = 10,
	['color'] = 0xFFFFFFFF,
	['position'] = 
	{
		['x'] = 100,
		['y'] = 100
	},
	['bgcolor'] = 0x80000000,
	['bgvisible'] = true,
	['visible'] = true
};

-- mule mode variables

-- flag that tells the addon if we're in mule mode or not. 
local b_MuleMode = false;

-- time we last tried a synth
local m_LastSynthAttempt = os.time();

-- delay (in seconds) between synth attempts
local m_SynthDelay = 3;

-- action queue
local m_ActionQueue = { };

-- queue delay
local m_ActionDelay = 1;

-- holds last action time of attempting to process the queue.
local m_ActionQueueTime = 0;

---------------------------------------------------------------------------------------------------
-- func: find synth
-- desc: Finds the required items in our inventory to do a synth
---------------------------------------------------------------------------------------------------
local function find_synth()
	-- to have a synth, we need both the crystal and the sphere item
	local synth = 
	{ 
		['crystal'] = 0, 
		['crystal index'] = 0, 
		['sphere item'] = 0, 
		['sphere item index'] = 0 
	};

	-- get the players inventory
	local inventory = AshitaCore:GetDataManager():GetInventory();

	for index = 1, inventory:GetContainerMax(0), 1 do
		-- get inventory item at index
		local item = inventory:GetItem(0, index);

		-- loop through the potential sphere items
		for crystal, sphereItems in pairs(m_SphereItems) do
			-- loop through each sphere item
			for key, sphereItem in pairs(sphereItems) do
				-- if the item is the sphere item, set the synth data to that
				if (item['Id'] == sphereItem) then
					synth['sphere item'] = item['Id'];
					synth['sphere item index'] = index;
					synth['crystal'] = crystal;
					break;
				end
			end
		end
	end

	-- if we have a crystal and other items set, we need to find the crystal index. It's annoying to have to reloop, but... whatever
	if (synth['crystal'] ~= 0 and synth['sphere item'] ~= 0 and synth['sphere item index'] ~= 0) then
		for index = 1, inventory:GetContainerMax(0), 1 do
			local item = inventory:GetItem(0, index);
			if (item['Id'] == synth['crystal']) then
				synth['crystal index'] = index;
				break;
			end
		end

		-- check to see if we have everything we need

		if (synth['crystal index'] ~= 0) then
			return true, synth;
		end
	end

	return false, synth;
end

---------------------------------------------------------------------------------------------------
-- func: build recipe hash
-- desc: Not completely sure how this was figured out. Was taken from the Windower crafty addon.
---------------------------------------------------------------------------------------------------
local function build_recipe_hash(crystal, itemId, itemCount)
	local c = ((crystal % 6505) % 4238) % 4096;
	local m = (c + 1) * 6 + 77;
	local b = (c + 1) * 42 + 31;
	local m2 = (8 * c + 26) + (itemId - 1) * (c + 35);

	return (m * itemId + b + m2 * (itemCount - 1)) % 127;
end

---------------------------------------------------------------------------------------------------
-- func: send synth packet
-- desc: Builds and sends a synth packet
---------------------------------------------------------------------------------------------------
local function send_synth_packet(synth)
	-- set our flag to instantly craft
	b_FastCraft = true;

	-- build the recipe hash, no idea how/what this is.
	local hash = build_recipe_hash(synth['crystal'], synth['sphere item'], 1);

	-- check to make sure we have everything we need for the synth packet
	local packet = struct.pack('bbbbbbhbbhhhhhhhhbbbbbbbbh', 0x96, 0x12, 0x00, 0x00, hash, 0x00, synth['crystal'], synth['crystal index'], 0x01, synth['sphere item'], 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, synth['sphere item index'], 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00):totable();
	--AddOutgoingPacket(0x96, packet);
	table.insert(m_ActionQueue, { 0x96, packet });
end

---------------------------------------------------------------------------------------------------
-- func: find cluster
-- desc: Checks to see if we have a cluster for the respective crystal
---------------------------------------------------------------------------------------------------
local function find_cluster(crystal)
	-- get the players inventory
	local inventory = AshitaCore:GetDataManager():GetInventory();

	for index = 1, inventory:GetContainerMax(0), 1 do
		-- get inventory item at index
		local item = inventory:GetItem(0, index);
		if (item['Id'] == m_ClusterMap[crystal]) then
			return index, 0;
		end
	end

	return 0, 0;
end

---------------------------------------------------------------------------------------------------
-- func: send use item packet
-- desc: builds and sends a use item packet to use a cluster
---------------------------------------------------------------------------------------------------
local function send_use_item_packet(slot, bag)
	-- get our players server id, as it's needed in the packet
	local id = AshitaCore:GetDataManager():GetParty():GetMemberServerId(0);

	-- get our players target index, as it's needed in the packet
	local index = AshitaCore:GetDataManager():GetParty():GetMemberTargetIndex(0);

	local packet = struct.pack('bbbbIIhbbbbbb', 0x37, 0x10, 0x00, 0x00, id, 0x00, index, slot, 0x00, bag, 0x00, 0x00, 0x00):totable();
	--AddOutgoingPacket(0x37, packet);
	table.insert(m_ActionQueue, { 0x37, packet });
end

---------------------------------------------------------------------------------------------------
-- func: flow
-- desc: goes through the flow of finding a synth, using a cluster if needed, etc.
---------------------------------------------------------------------------------------------------
local function flow()
	-- check to see if we have a synth
	local success, synth = find_synth();

	-- if we have everything we need, send the synth packet
	if (success) then
		send_synth_packet(synth);
	else
		-- if the reason it failed was that we didn't have a crystal, check to see if we have a cluster we can use
		if (synth['sphere item index'] ~= 0 and synth['crystal'] ~= 0 and synth['crystal index'] == 0) then
			-- attempt to find a cluster in our inventory
			local clusterIndex, bag = find_cluster(synth['crystal']);
			if (clusterIndex ~= 0) then
				-- send a use item packet
				send_use_item_packet(clusterIndex, bag);
				-- we can't just send the synth packet here
				-- 1) we don't have a crystal index/slot
				-- 2) what if the cluster usage fails, or we don't have one
				--send_synth_packet(synth);
				-- set flag to look for incoming item packet for clusters
				b_UsedCluster = true;
			else
				if (b_MuleMode == false) then
					print('[EasySphere] Unable to find crystal or cluster.');
				end
			end
		else
			if (b_MuleMode == false) then
				print('[EasySphere] Unable to find synth item.');
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- load previous synth results
	m_SynthResults = ashita.settings.load_merged(_addon.path .. '/settings/EasySphere_Synth.json', m_SynthResults);
	-- load font config
	m_FontConfig = ashita.settings.load_merged(_addon.path .. '/settings/EasySphere_Font.json', m_FontConfig);
	-- create our font object
	local font = AshitaCore:GetFontManager():Create('__easy_sphere_addon');
	font:SetColor(m_FontConfig['color']);
	font:SetFontFamily(m_FontConfig['family']);
	font:SetFontHeight(m_FontConfig['size']);
	font:SetPositionX(m_FontConfig['position']['x']);
	font:SetPositionY(m_FontConfig['position']['y']);
	font:SetVisibility(m_FontConfig['visible']);
	font:GetBackground():SetColor(m_FontConfig['bgcolor']);
	font:GetBackground():SetVisibility(m_FontConfig['bgvisible']);
	font:SetText(string.format('Total Synths: %d (%d)\nSuccess: %d (%d)\nHQs: %d (%d)\nBreaks: %d (%d)', m_SynthResults['session']['total'], m_SynthResults['total']['total'], m_SynthResults['session']['success'], m_SynthResults['total']['success'], m_SynthResults['session']['hqs'], m_SynthResults['total']['hqs'], m_SynthResults['session']['breaks'], m_SynthResults['total']['breaks']));
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
	-- get command args
	local args = cmd:args();

	-- Ensure it's an easysphere command.
	if (args[1] ~= '/easysphere') then
		return false;
	end

	-- Make sure we have enough args to begin with.
	if (#args < 2) then
		return false;
	end

	if (args[2] == 'synth') then
		flow();
	end

	if (args[2] == 'mulemode') then
		b_MuleMode = not b_MuleMode;
	end

	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Called when the game client has begun to add a new line of text to the chat box.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, chat)
	-- if the chat line is the synth being interrupted, block that chat line and add a new one 
	if (chat == 'Synthesis interrupted. You lost the crystal and materials you were using.' and m_SynthResultMessage) then
		-- format the new chat line to tell us the synth result
		local new_chat_line = string.format('[EasySphere] Synthesis Result: %s', m_SynthResultMessage);

		-- reset the synth result
		m_SynthResultMessage = '';

		-- return the new chat line to block the synth interrupted line
		return new_chat_line;
	end

    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	-- Synth Animation Packet
	if (id == 0x30) then
		-- reset the result message
		m_SynthResultMessage = '';
		-- read the player server id out of the packet
		local player = struct.unpack('I', packet, 0x04 + 1);

		-- read the param, which in this packet is the result of the synth
		local param = struct.unpack('b', packet, 0x0C + 1);

		-- check to make sure this packet is pretaining to our player
		if (player == AshitaCore:GetDataManager():GetParty():GetMemberServerId(0)) then
			-- check the param and set a message based on the out come
			if (param == 0) then
				m_SynthResultMessage = 'Success - NQ.';
				m_SynthResults['total']['success'] = m_SynthResults['total']['success'] + 1;
				m_SynthResults['session']['success'] = m_SynthResults['session']['success'] + 1;
			elseif (param == 1) then
				m_SynthResultMessage = 'Break.';
				m_SynthResults['total']['breaks'] = m_SynthResults['total']['breaks'] + 1;
				m_SynthResults['session']['breaks'] = m_SynthResults['session']['breaks'] + 1;
			elseif (param == 2) then
				m_SynthResultMessage = 'Success - HQ.';
				m_SynthResults['total']['success'] = m_SynthResults['total']['success'] + 1;
				m_SynthResults['total']['hqs'] = m_SynthResults['total']['hqs'] + 1;
				m_SynthResults['session']['success'] = m_SynthResults['session']['success'] + 1;
				m_SynthResults['session']['hqs'] = m_SynthResults['session']['hqs'] + 1;
			else
				m_SynthResultMessage = string.format('Unknown Synth Result. Param: %d', param);
			end

			-- increment toal
			m_SynthResults['total']['total'] = m_SynthResults['total']['total'] + 1;
			m_SynthResults['session']['total'] = m_SynthResults['session']['total'] + 1;

			-- save our config
			ashita.settings.save(_addon.path .. '/settings/EasySphere_Synth.json', m_SynthResults);

			if (b_FastCraft) then
				-- inject a Synth Complete packet
				local synth_complete_packet = struct.pack('bbbbIbbbbbbbb', 0x59, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00):totable(); 
				AddOutgoingPacket(0x59, synth_complete_packet);

				b_FastCraft = false;
				print(string.format('[EasySphere] Synthesis Result: %s', m_SynthResultMessage));
			end
		end
	elseif (id == 0x0A) then -- zone packet
		-- reset 'session'
		m_SynthResults['session']['total'] = 0;
		m_SynthResults['session']['success'] = 0;
		m_SynthResults['session']['hqs'] = 0;
		m_SynthResults['session']['breaks'] = 0;
	elseif (id == 0xD2) then -- treasure pool packets
		if (b_MuleMode) then
			local itemId = struct.unpack('h', packet, 0x10 + 1);
        	local itemSlot = struct.unpack('b', packet, 0x14 + 1);

			-- loop through the potential sphere items
			for crystal, sphereItems in pairs(m_SphereItems) do
				-- loop through each sphere item
				for key, sphereItem in pairs(sphereItems) do
					if (sphereItem == itemId) then
						-- lot the item
						local lootItem = struct.pack("bbbbbbb", 0x41, 0x04, 0x00, 0x00, itemSlot, 0x00, 0x00, 0x00):totable();
                		AddOutgoingPacket(0x41, lootItem);
					end
				end
			end
		end
	elseif (id == 0x20) then --inventory item packet
		-- if we're checking for a cluster being used
		if (b_UsedCluster) then
			-- get the item id of thd incoming inventory item
			local itemId = struct.unpack('h', packet, 0x0C + 1);

			-- loop through our cluster map, and if the incomming item id is a crystal we care about
			for crystal, cluster in pairs(m_ClusterMap) do
				if (crystal == itemId) then
					-- set flag to false
					b_UsedCluster = false;
					-- queue up the normal flow
					flow();
					-- break out of loop 
					break;
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
	if (id == 0x96) then
		local data = '';
		local t = packet:totable();

		for x = 1, #t, 1 do
			data = string.format('%s %x ', data, t[x]);
		end

		--print(data);
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
	local font = AshitaCore:GetFontManager():Get('__easy_sphere_addon');
	font:SetText(string.format('Total Synths: %d (%d)\nSuccess: %d (%d)\nHQs: %d (%d)\nBreaks: %d (%d)', m_SynthResults['session']['total'], m_SynthResults['total']['total'], m_SynthResults['session']['success'], m_SynthResults['total']['success'], m_SynthResults['session']['hqs'], m_SynthResults['total']['hqs'], m_SynthResults['session']['breaks'], m_SynthResults['total']['breaks']));

	if (b_MuleMode) then
		if (os.time() >= (m_LastSynthAttempt + m_SynthDelay)) then
			m_LastSynthAttempt = os.time();

			flow();
		end
	end

	if (os.time() >= (m_ActionQueueTime + m_ActionDelay)) then
		m_ActionQueueTime = os.time();

		if (#m_ActionQueue > 0) then
			local data = table.remove(m_ActionQueue, 1);

			AddOutgoingPacket(data[1], data[2]);
		end
	end
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
	-- get our font object
	local font = AshitaCore:GetFontManager():Get('__easy_sphere_addon');
	-- read the position incase the user has dragged the font object
	m_FontConfig['position']['x'] = font:GetPositionX();
	m_FontConfig['position']['y'] = font:GetPositionY();

	-- reset 'session' before we save
	m_SynthResults['session']['total'] = 0;
	m_SynthResults['session']['success'] = 0;
	m_SynthResults['session']['hqs'] = 0;
	m_SynthResults['session']['breaks'] = 0;

	-- save our config
	ashita.settings.save(_addon.path .. '/settings/EasySphere_Synth.json', m_SynthResults);
	ashita.settings.save(_addon.path .. '/settings/EasySphere_Font.json', m_FontConfig);

	-- delete font object
	AshitaCore:GetFontManager():Delete('__easy_sphere_addon');
end);