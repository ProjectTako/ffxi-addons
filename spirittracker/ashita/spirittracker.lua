_addon.author   = 'Project Tako';
_addon.name     = 'Spirit Tracker';
_addon.version  = '1.0';

require('common');

local config = 
{
	['zone'] = 0xF6,
	['event'] = 0x1AA,
	['tracking'] = false,
	['fed'] = false,
	['spirit'] = 0,
	['font'] = 
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
	}
};

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- load our config
	config = ashita.settings.load_merged(_addon.path .. '/settings/spirittracker.json', config);

	-- create our font object
	local font = AshitaCore:GetFontManager():Create('__spirit_tracker_addon');
	font:SetColor(config['font']['color']);
	font:SetFontFamily(config['font']['family']);
	font:SetFontHeight(config['font']['size']);
	font:SetPositionX(config['font']['position']['x']);
	font:SetPositionY(config['font']['position']['y']);
	font:SetVisibility(config['font']['visible']);
	font:GetBackground():SetColor(config['font']['bgcolor']);
	font:GetBackground():SetVisibility(config['font']['bgvisible']);
	font:SetText(string.format('Total Spirit: %d', config['spirit']));
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
	-- get command args
	local args = cmd:args();

	-- Ensure it's a spirittracker command.
	if (args[1] ~= '/spirittracker') then
		return false;
	end

	-- Make sure we have enough args to begin with.
	if (#args < 2) then
		return false;
	end

	-- toggle visibility
	if (args[2] == 'visible') then
		-- toggle the visibility in the config
		config['font']['visible'] = not config['font']['visible'];

		-- set the new visibility
		local font = AshitaCore:GetFontManager():Create('__spirit_tracker_addon');
		font:SetVisibility(config['font']['visible']);

		return true;
	end

	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: newchat
-- desc: Called when the game client has begun to add a new line of text to the chat box.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, chat)
	-- check to make sure we're tracking before we do expensive string work
	if (config['tracking']) then
		-- check to see if it's a spirit message
		if (chat:find('imbue the item with %d+ spirit.')) then
			-- check to see if we just did an action on the focuser. 
			-- for some reason, this message gets sent three times, we only want to count it once
			if (config['fed']) then 
				-- read how much spirit we got from the chat message
				local count = tonumber(chat:match('%d+'));
				-- basic sanity checks
				if (count ~= 0) then
					-- update the total spirit we have
					config['spirit'] = config['spirit'] + count;
					-- set this flag to false, to prevent adding duplicate lines
					config['fed'] = false;
				end
			end
		end
	end
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	-- check for event packet
	if (id == 0x34) then
		-- read the zone id out of the packet
		local zone_id = struct.unpack('h', packet, 0x2A + 1);
		-- read the event id out of the packet
		local event_id = struct.unpack('h', packet, 0x2C + 1);

		-- check to make sure the event id is one we care about, as well as the zone id is correct
		if (event_id == config['event'] and zone_id == config['zone']) then
			-- if it's the start event, start the tracking
			config['tracking'] = true;
		end
	end
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
	-- check for event packet
	if (id == 0x5B) then
		-- see if we are currently tracking, if not we don't need to check anything
		if (config['tracking']) then
			-- read the result id out of the packet
			local result_id = struct.unpack('I', packet, 0x08 + 1);
			-- read the queue next event flag out of the packet 
			local queue_next_event = struct.unpack('h', packet, 0x0E + 1);
			-- read the zone id out of the packet
			local zone_id = struct.unpack('h', packet, 0x10 + 1);
			-- read the event id out of the packet
			local event_id = struct.unpack('h', packet, 0x12 + 1);

			-- check to make sure the event id is one we care about, as well as the zone id is correct
			if (event_id == config['event'] and zone_id == config['zone']) then
				-- if we exited the Focuser, the queue next event flag will be 0. 
				-- if we feed, or do anything else, it will be 1.
				if (queue_next_event == 0) then
					-- stop tracking
					config['tracking'] = false;
				else 
					-- this is here because for some reason it sends the chat line three times.
					-- set this flag to let the incomint text event handler know we should read the first one
					if (result_id >= 0x80000000) then
						config['fed'] = true;
					end
				end
			end
		end
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
	-- get our font object
	local font = AshitaCore:GetFontManager():Get('__spirit_tracker_addon');
	font:SetText(string.format('Total Spirit: %d', config['spirit']));
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
	local font = AshitaCore:GetFontManager():Get('__spirit_tracker_addon');
	-- read the position incase the user has dragged the font object
	config['font']['position']['x'] = font:GetPositionX();
	config['font']['position']['y'] = font:GetPositionY();

	-- save our config
	ashita.settings.save(_addon.path .. '/settings/spirittracker.json', config);

	-- delete font object
	AshitaCore:GetFontManager():Delete('__spirit_tracker_addon');
end);