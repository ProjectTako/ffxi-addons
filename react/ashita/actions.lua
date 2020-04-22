local actions = { };

function actions.parse(packet)
	-- holds the final action table we'll return
	local action = { };
	-- get the work size. 
	-- this can be used to calculate the final bitOffset if we cared to compare to make sure we read it all
	local work_size = struct.unpack('b', packet, 0x04 + 1);

	-- the id of the actor performing the action
	action['actor_id'] = struct.unpack('I', packet, 0x05 + 1);

	-- the number of targets the action does stuff to
	action['target_count'] = struct.unpack('b', packet, 0x09 + 1);

	-- since the action packet uses a lot of bitpacking, we want to hold our current bitOffset.
	-- it's annoying that we'll need to increment the offset after each read, but what can you do?
	-- start at 82 because fuck me
	-- 0x0A-0x0F aren't completely know
	local bitOffset = 82;

	-- the type of action 
	-- https://github.com/DarkstarProject/darkstar/blob/5078b8b1b71c30af4a5fbcb9075787e5a9a3cd3f/src/map/packets/action.h#L35
	action['action_type'] = ashita.bits.unpack_be(packet, bitOffset, 4);
	-- increment the bitOffset the length of the read/unpack
	bitOffset = bitOffset + 4;

	-- if we just always read starting at bit 86, with a length of 12, what could go wrong?
	action['action_id'] = ashita.bits.unpack_be(packet, bitOffset, 12);
	action['recast'] = ashita.bits.unpack_be(packet, 118, 10);

	-- adjust the bitOffset. We do a straight 64 here as that is how many bit 0x0A-0x0F take up
	bitOffset = bitOffset + 64;

	-- at this point, the ds server thing loops through an action list.. 
	-- I don't think it's possible for us to get this 'action list'. 
	-- however, I don't think there's ever more than one action in the action list...

	-- our table to hold data for each target
	action['targets'] = { };
	-- loop through each target and read stuff
	for x = 1, action['target_count'] do
		action['targets'][x] = { };

		action['targets'][x]['id'] = ashita.bits.unpack_be(packet, bitOffset, 32);
		bitOffset = bitOffset + 32;

		if (action['main_target'] == nil) then
			action['main_target'] = action['targets'][x]['id'];
		end

		-- the number of action targets
		action['action_target_count'] = ashita.bits.unpack_be(packet, bitOffset, 4);
		bitOffset = bitOffset + 4;
		
		action['targets'][x]['actions'] = { };
		for i = 1, action['action_target_count'] do
			action['targets'][x]['actions'][i] = { };
			-- read certain data from packet
			action['targets'][x]['actions'][i]['reaction'] = ashita.bits.unpack_be(packet, bitOffset, 5);
			bitOffset = bitOffset + 5;

			action['targets'][x]['actions'][i]['animation'] = ashita.bits.unpack_be(packet, bitOffset, 12);
			bitOffset = bitOffset + 12;

			action['targets'][x]['actions'][i]['effect'] = ashita.bits.unpack_be(packet, bitOffset, 7);
			bitOffset = bitOffset + 7;

			action['targets'][x]['actions'][i]['knockback'] = ashita.bits.unpack_be(packet, bitOffset, 3);
			bitOffset = bitOffset + 3;

			action['targets'][x]['actions'][i]['param'] = ashita.bits.unpack_be(packet, bitOffset, 17);
			bitOffset = bitOffset + 17;

			action['targets'][x]['actions'][i]['message'] = ashita.bits.unpack_be(packet, bitOffset, 10);
			bitOffset = bitOffset + 10;

			-- adjust offset manually
			action['targets'][x]['actions'][i]['unknown'] = ashita.bits.unpack_be(packet, bitOffset, 31);
			bitOffset = bitOffset + 31;

			-- if there's a subeffect, 0 = false, 1 = true
			action['targets'][x]['actions'][i]['subeffect'] = ashita.bits.unpack_be(packet, bitOffset, 1);
			bitOffset = bitOffset + 1;

			if (action['targets'][x]['actions'][i]['subeffect'] == 1) then
				action['targets'][x]['actions'][i]['add_effect'] = ashita.bits.unpack_be(packet, bitOffset, 10);
				bitOffset = bitOffset + 10;

				action['targets'][x]['actions'][i]['add_effect_param'] = ashita.bits.unpack_be(packet, bitOffset, 17);
				bitOffset = bitOffset + 17;

				action['targets'][x]['actions'][i]['add_effect_message'] = ashita.bits.unpack_be(packet, bitOffset, 10);
				bitOffset = bitOffset + 10;
			end

			action['targets'][x]['actions'][i]['spikes'] = ashita.bits.unpack_be(packet, bitOffset, 1);
			bitOffset = bitOffset + 1;

			if (action['targets'][x]['actions'][i]['spikes'] == 1) then
				action['targets'][x]['actions'][i]['spikes_effect'] = ashita.bits.unpack_be(packet, bitOffset, 10);
				bitOffset = bitOffset + 10;

				action['targets'][x]['actions'][i]['spikes_param'] = ashita.bits.unpack_be(packet, bitOffset, 14);
				bitOffset = bitOffset + 14;

				action['targets'][x]['actions'][i]['spikes_message'] = ashita.bits.unpack_be(packet, bitOffset, 10);
				bitOffset = bitOffset + 10;
			end
		end
	end

	return action;
end

function actions.validate_action(action)
	if (action == nil) then
		return false;
	end

	-- depending on the category, we need to validate certain params
	-- check basic info like, actor id, target id, and if it's a spell/ja/ws, make sure the action id or param seems valid
	if (action['action_type'] == 0x01 or action['action_type'] == 0x02 or action['action_type'] == 0x05 or action['action_type'] == 0x09 or action['action_type'] == 0x0C) then
		return (action['actor_id'] ~= 0 and action['targets'] ~= nil and action['main_target'] ~= 0);
	elseif (action['action_type'] == 0x03) then
		local ws = AshitaCore:GetResourceManager():GetAbilityById(action['action_id']);
		if (ws ~= nil) then
			return (action['actor_id'] ~= 0 and action['targets'] ~= nil and action['main_target'] ~= 0 and ws['Id'] == action['action_id']);
		end
	elseif (action['action_type'] == 0x04) then
		local spell = AshitaCore:GetResourceManager():GetSpellById(action['action_id']);
		if (spell ~= nil) then
			return (action['actor_id'] ~= 0 and action['targets'] ~= nil and action['main_target'] ~= 0 and spell['Id'] == action['action_id']);
		end
	elseif (action['action_type'] == 0x06 or action['action_type'] == 0x0D or action['action_type'] == 0x0E or action['action_type'] == 0x0F) then
		local ja = AshitaCore:GetResourceManager():GetAbilityById(action['action_id']);
		if (ja ~= nil) then
			return (action['actor_id'] ~= 0 and action['targets'] ~= nil and action['main_target'] ~= 0 and ja['Id'] == action['action_id']);
		end
	elseif (action['action_type'] == 0x07) then
		if (action['action_id'] ~= 0) then
			local ws = AshitaCore:GetResourceManager():GetAbilityById(action['targets'][1]['actions'][1]['param']);
			if (ws ~= nil) then
				return (action['actor_id'] ~= 0 and action['targets'] ~= nil and action['main_target'] ~= 0 and ws['Id'] == action['targets'][1]['actions'][1]['param']);
			end
		end
	elseif (action['action_type'] == 0x08) then
		if (action['action_id'] ~= 0) then
			local spell = AshitaCore:GetResourceManager():GetSpellById(action['targets'][1]['actions'][1]['param']);
			if (spell ~= nil) then
				return (action['actor_id'] ~= 0 and action['targets'] ~= nil and action['main_target'] ~= 0 and spell['Id'] == action['targets'][1]['actions'][1]['param']);
			end
		end
	elseif (action['action_type'] == 0x0B) then
		local ja = AshitaCore:GetResourceManager():GetAbilityById(action['action_id']);
		if (ja ~= nil) then
			return (action['actor_id'] ~= 0 and action['targets'] ~= nil and action['main_target'] ~= 0 and ja['Id'] == action['action_id']);
		end
	end

	return false;
end

function actions.get_action_state(category)
	if (category == 0x07 or category == 0x08 or category == 0x09 or category == 0x0C) then
		return 'begin';
	else
		return 'finish';
	end
end

function actions.get_action_name(action)
	if (action == nil) then
		return 'none';
	end

	if (action['action_type'] == 0x01) then
		return 'melee';
	elseif (action['action_type'] == 0x02 or action['action_type'] == 0x0C) then
		return 'ranged attack';
	elseif (action['action_type'] == 0x03 or action['action_type'] == 0x06 or action['action_type'] == 0x0B or action['action_type'] == 0x0D or action['action_type'] == 0x0E or action['action_type'] == 0x0F) then 
		return AshitaCore:GetResourceManager():GetAbilityById(action['action_id'])['Name'][0];
	elseif (action['action_type'] == 0x04) then
		return AshitaCore:GetResourceManager():GetSpellById(action['action_id'])['Name'][0]; 
	elseif (action['action_type'] == 0x05) then
		return AshitaCore:GetResourceManager():GetItemById(action['action_id'])['Name'][0]; 
	elseif (action['action_type'] == 0x07) then
		return AshitaCore:GetResourceManager():GetAbilityById(action['targets'][1]['actions'][1]['param'])['Name'][0];
	elseif (action['action_type'] == 0x08) then
		return AshitaCore:GetResourceManager():GetSpellById(action['targets'][1]['actions'][1]['param'])['Name'][0];
	elseif (action['action_type'] == 0x09) then
		return AshitaCore:GetResourceManager():GetItemById(action['targets'][1]['actions'][1]['param'])['Name'][0];
	elseif (action['action_type'] == 0x0A) then
		return 'unknown';
	else
		return 'unknown';
	end
end

function actions.get_action_id(action)
	if (action == nil) then
		return 'none';
	end

	if (action['action_type'] == 0x01 or action['action_type'] == 0x02 or action['action_type'] == 0x0C) then
		return action['action_id'];
	elseif (action['action_type'] == 0x03 or action['action_type'] == 0x06 or action['action_type'] == 0x0B or action['action_type'] == 0x0D or action['action_type'] == 0x0E or action['action_type'] == 0x0F) then 
		return action['action_id'];
	elseif (action['action_type'] == 0x04) then
		return action['action_id'];
	elseif (action['action_type'] == 0x05) then
		return action['action_id'];
	elseif (action['action_type'] == 0x07) then
		return action['targets'][1]['actions'][1]['param'];
	elseif (action['action_type'] == 0x08) then
		return action['targets'][1]['actions'][1]['param'];
	elseif (action['action_type'] == 0x09) then
		return action['targets'][1]['actions'][1]['param'];
	elseif (action['action_type'] == 0x0A) then
		return 0;
	else
		return 0;
	end
end

function actions.action_category_matters(action_type)
	return (action_type ~= 0x01 and action_type ~= 0x02 and action_type ~= 0x0A and action_type ~= 0x0C);
end

return actions;