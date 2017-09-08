_addon.author   = 'Project Tako';
_addon.name     = 'FastCraft';
_addon.version  = '1.0';

require('common');

-- holds whether or not we should instantly complete the synth.
local bFastCraft = false;
-- holds the synth result (break/nq/hq) for when we instantly complete the synth.
local mSynthResult = '';
-- table that holds the last non-fast synthed craft info
local mCraftItem = 
{
	["crystal"] = 0,
	["ingredient_count"] = 0,
	["ingredients"] = { } 
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
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Called when the game client has begun to add a new line of text to the chat box.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, chat)
	-- if the chat line is the synth being interrupted, block that chat line and add a new one 
	if (chat == 'Synthesis interrupted. You lost the crystal and materials you were using.' and mSynthResult) then
		-- format the new chat line to tell us the synth result
		local new_chat_line = string.format('[FastCraft] Synthesis Result: %s', mSynthResult);

		-- reset the synth result
		mSynthResult = '';

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
		-- read the player server id out of the packet
		local player = struct.unpack('I', packet, 0x04 + 1);

		-- read the param, which in this packet is the result of the synth
		local param = struct.unpack('b', packet, 0x0C + 1);

		-- check to make sure this packet is pretaining to our player
		if (player == AshitaCore:GetDataManager():GetParty():GetMemberServerId(0) and bFastCraft) then
			-- check the param and set a message based on the out come
			if (param == 0) then
				mSynthResult = 'Success - NQ.';
			elseif (param == 1) then
				mSynthResult = 'Break.';
			elseif (param == 2) then
				mSynthResult = 'Success - HQ.';
			else
				mSynthResult = string.format('Unknown Synth Result. Param: %d', param);
			end

			-- inject a Synth Complete packet
			local synth_complete_packet = struct.pack('bbbbIbbbbbbbb', 0x59, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00):totable(); 
			AddOutgoingPacket(0x59, synth_complete_packet);
		end
	elseif (id == 0x6F) then -- Synth Message
		-- when a successful synth does happen, set the craft to instantly complete.
		bFastCraft = true;
	end

	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
	-- Make sure it's an outgoing synth packet
	if (id == 0x96) then
		-- read the crystal and ingredient count. Reading crystal index just lets us do it in one struct.unpack
		local crystal, crystal_index, ingredient_count = struct.unpack('hbb', packet, 0x06 + 1);
		-- table to hold the ingredients for the synth to check to see if it's a new synth. If it is, we should turn off "fast" so we can use /lastsynth
		local ingredients = { };
		-- loop through ingredients and store them
		for x = 0, ingredient_count - 1, 1 do
			ingredients[x + 1] = struct.unpack('h', packet, 0x0A + x + 1);
		end

		-- check to see if the crystal or ingredient count is different, if it is, turn off "fast" for /lastsynth
		if (crystal ~= mCraftItem['crystal'] or ingredient_count ~= mCraftItem['ingredient_count']) then
			bFastCraft = false;
			mCraftItem['crystal'] = crystal;
			mCraftItem['ingredient_count'] = ingredient_count;
			mCraftItem['ingredients'] = ingredients;
		else
			-- crystal and ingredient count are the same, check to actual mats and do the same
			for x = 1, ingredient_count, 1 do
				if (ingredients[x] ~= mCraftItem['ingredients'][x]) then
					bFastCraft = false;
					mCraftItem['crystal'] = crystal;
					mCraftItem['ingredient_count'] = ingredient_count;
					mCraftItem['ingredients'] = ingredients;
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