_addon.author   = 'Gobbo, Project Tako';
_addon.name     = 'ex';
_addon.version  = '1.0';

require('common');

local default_config = 
{
	position = { 500, 500 },
	color = 0xFFFFFFFF,
	background_color = 0x40000000
};

local exConfig = default_config;

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- load the config
	exConfig = ashita.settings.load_merged(_addon.path .. 'settings/settings.json', exConfig);

	-- create our test on screen objects
	local f = AshitaCore:GetFontManager():Create('test-object');
	f:SetVisibility(true);
	f:SetPositionX(100);
	f:SetPositionY(100);
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType) 
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	-- action packet
	if (id == 0x28) then
		local actor_id = struct.unpack('I', packet, 0x04 + 1);

		local target_count = struct.unpack('b', packet, 0x09 + 1);

		-- holds the bitOffset for unpacking bits
		local bitOffset = 82;

		-- unpack the action type
		-- 82 bits in. 0x0A:0x02 = 82
		-- action type is 4 bits wide
		local action_type = ashita.bits.unpack_be(packet, bitOffset, 4);
		-- adjust the offset
		bitOffset = bitOffset + 4;

		-- adjust the bitOffset
		bitOffset = bitOffset + 64;

		-- create our targets table, empty
		local targets = { };

		-- loop through how many targets there are
		for x = 1, target_count do
			-- empty target
			targets[x] = { };

			-- get the id of the target
			targets[x].id = ashita.bits.unpack_be(packet, bitOffset, 32);
			-- adjust the offset
			bitOffset = bitOffset + 32;

			-- get the action count
			targets[x].action_count = ashita.bits.unpack_be(packet, bitOffset, 4) + 1;
			-- adjust the offset
			bitOffset = bitOffset + 4;

			-- empty actions table
			targets[x].actions = { };

			-- loop through the action count
			for i = 1, targets[x].action_count do
				targets[x].actions[i] = { };
				-- get the targets reaction
				targets[x].actions[i].reaction = ashita.bits.unpack_be(packet, bitOffset, 5);
				-- adjust the offset
				bitOffset = bitOffset + 5;

				-- get the targets animation
				targets[x].actions[i].animation = ashita.bits.unpack_be(packet, bitOffset, 12);
				-- adjust the offset
				bitOffset = bitOffset + 12;

				-- get the targets special effect
				-- this is related to melee attacks somehow
				-- 0 = Miss/Magic | 1 = Death | 32 = Successful Melee | 34 = Critical Hit
				targets[x].actions[i].effect = ashita.bits.unpack_be(packet, bitOffset, 7);
				-- adjust the offset
				bitOffset = bitOffset + 7;

				-- get the targets knockback
				targets[x].actions[i].knockback = ashita.bits.unpack_be(packet, bitOffset, 3);
				-- adjust the offset
				bitOffset = bitOffset + 3;

				-- get the targets param
				targets[x].actions[i].param = ashita.bits.unpack_be(packet, bitOffset, 17);
				-- adjust the offset
				bitOffset = bitOffset + 17;

				-- get the targets message id
				targets[x].actions[i].message_id = ashita.bits.unpack_be(packet, bitOffset, 10);
				-- adjust the offset
				bitOffset = bitOffset + 10;

				-- adjust the offset manually
				bitOffset = bitOffset + 31;

				-- get if there is a subeffect. 0 = false 1 = true
				-- this is related only en-effects like Enfire
				-- any hidden added effects result in 0
				targets[x].actions[i].subeffect = ashita.bits.unpack_be(packet, bitOffset, 1);
				-- adjust the offset
				bitOffset = bitOffset + 1;

				-- check if there's a sub effect
				if (targets[x].actions[i].subeffect == 1) then
					-- get the targets add_effect
					targets[x].actions[i].add_effect = ashita.bits.unpack_be(packet, bitOffset, 10);
					-- adjust the offset
					bitOffset = bitOffset + 10;

					-- get the targets add_effect_param
					targets[x].actions[i].add_effect_param = ashita.bits.unpack_be(packet, bitOffset, 17);
					-- adjust the offset
					bitOffset = bitOffset + 17;

					-- get the targets add_effect_message
					targets[x].actions[i].add_effect_message = ashita.bits.unpack_be(packet, bitOffset, 10);
					-- adjust the offset
					bitOffset = bitOffset + 10;
				end

				-- get if there is a spikes. 0 = false 1 = true
				targets[x].actions[i].spikes = ashita.bits.unpack_be(packet, bitOffset, 1);
				-- adjust the offset
				bitOffset = bitOffset + 1;

				-- check if there's spikes
				if (targets[x].actions[i].spikes == 1) then
					-- get the targets spikes_effect
					targets[x].actions[i].spikes_effect = ashita.bits.unpack_be(packet, bitOffset, 10);
					-- adjust the offset
					bitOffset = bitOffset + 10;

					-- get the targets spikes_param
					targets[x].actions[i].spikes_param = ashita.bits.unpack_be(packet, bitOffset, 14);
					-- adjust the offset
					bitOffset = bitOffset + 17;

					-- get the targets spikes_message
					targets[x].actions[i].spikes_message = ashita.bits.unpack_be(packet, bitOffset, 10);
					-- adjust the offset
					bitOffset = bitOffset + 10;
				end
			end
		end

		for index,value in pairs(targets) do
			print(value.actions[1].message_id);
			local f = AshitaCore:GetFontManager():Get('test-object');
			f:SetText(string.format('Action Message Id: %d', value.actions[1].message_id));
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
	AshitaCore:GetFontManager():Delete('test-object');
end);
