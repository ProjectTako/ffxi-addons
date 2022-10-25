_addon.author   = 'Project Tako';
_addon.name     = 'React (based on the Windower addon with the same name)';
_addon.version  = '1.0';

require('common');
require('ffxi.enums');
local actions = require('actions');
local monster_abils = require('monster_abils');

local react = 
{
	['reactions'] = { },
	['job'] = 0
};

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- load the monster_abils dat file
	monster_abils.load();

	-- try to load any saved settings
	local file = string.format('%s/settings/react_%s_%s.json', _addon.path, AshitaCore:GetDataManager():GetParty():GetMemberName(0), AshitaCore:GetDataManager():GetPlayer():GetMainJob());
	if (ashita.file.file_exists(file)) then
		react['reactions'] = ashita.settings.load_merged(file, react['reactions']);
	end

	-- set current job so we can see if we change jobs later
	react['job'] = AshitaCore:GetDataManager():GetPlayer():GetMainJob();
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
	-- get command args
	local args = cmd:args();

	if (args[1] == "/react") then
		-- add an action to react to
		if (args[2]:lower() == 'add') then
			-- make sure we have enough data..
			if (#args < 6) then
				print('[React] Not enough arguments to add an action.');
				return false;
			end

			-- I don't like how this looks, but it be like that
			local actor_name = args[3];
			local action_name = args[4];
			local state = args[5];
			local reaction = args[6];


			-- check to see if we're already tracking this actor
			if (react['reactions'][actor_name] ~= nil) then	
				-- check to see if we're already tracking this action name,
				-- and if not, setup default table
				if (react['reactions'][actor_name][action_name] == nil) then
					react['reactions'][actor_name][action_name] = { };
				end
			else
				-- we weren't tracking this actor_name
				react['reactions'][actor_name] = { };
				react['reactions'][actor_name][action_name] = { };
			end

			-- insert action 
			react['reactions'][actor_name][action_name][state] = reaction;

			print(string.format('[React] Action Name: %s for Actor: %s successfully added.', action_name, actor_name));

			return true;
		elseif (args[2]:lower() == 'list') then
			print('[React] Listing all actions...');
			for key, value in pairs(react['reactions']) do
				for kkey, vvalue in pairs(value) do
					for kkkey, vvvalue in pairs(vvalue) do
						print(string.format('[React] %s %s %s => %s', key, kkkey, kkey, vvvalue));
					end
				end
			end
		elseif (args[2]:lower() == 'save') then
			ashita.settings.save(string.format('%s/settings/react_%s_%s.json', _addon.path, AshitaCore:GetDataManager():GetParty():GetMemberName(0), AshitaCore:GetDataManager():GetPlayer():GetMainJob()), react['reactions']);
		end
	end

	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_text
-- desc: Called when the game client has begun to add a new line of text to the chat box.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_text
-- desc: Called when the game client is sending text to the server.
--       (This gets called when a command, chat, etc. is not handled by the client and is being sent to the server.)
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_text', function(mode, message, modifiedmode, modifiedmessage, blocked)
    return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	if (id == 0x028) then
		-- parse action
		local action = actions.parse(packet);
		if (action ~= nil and action['actor_id'] ~= 0) then
			-- if we have an actor then we can find them in the entity list
			local actor = nil;
			local target = nil

			local player = GetPlayerEntity();

			if (player == nil) then
				return false;
			end

			-- loop through entity array to find actor and target
			for x = 0, 0x8FF do
				local entity = GetEntity(x);
				if (entity ~= nil) then
					if (entity['ServerId'] == action['actor_id']) then
						actor = entity;
					end

					if (entity['ServerId'] == action['main_target']) then
						target = entity;
					end
				end

				if (actor and target) then
					break;
				end
			end

			-- make sure we have a valid actor, the actor is not our player,
			-- the actor is a mob OR we are the target
			if (actor ~= nil and target~= nil and actor['ServerId'] ~= player['ServerId'] and (bit.band(actor['SpawnFlags'], 0x0010) == 0x0010 or target['ServerId'] == player['ServerId'])) then				
				if (react['reactions'][actor['Name']] ~= nil) then
					-- first check if it's a category, we don't care about auto attacks, for example
					if (actions.action_category_matters(action['action_type'])) then
						local action_name = 'unknown';
						-- if it's a mob, read the ability from the monster_abils data
						-- otherwise, we can use the built in Ashita ResourceManager to get the abil name
						if (bit.band(actor['SpawnFlags'], 0x0010) == 0x0010) then
							local id = actions.get_action_id(action) - 256;
							if (id > -1) then
								action_name = monster_abils.get_ability_by_id(id);
							end
						else
							if (actions.validate_action(action)) then
								action_name = actions.get_action_name(action);
							end
						end 

						-- make sure we have a valid abil name
						if (action_name ~= nil and action_name ~= 'unknown') then
							-- check to see if we're monitoring this action name
							if (react['reactions'][actor['Name']][action_name] ~= nil) then
								-- get the state (begin, finish)
								local state = actions.get_action_state(action['action_type']);
								
								-- if we're monitoring that state, process the reaction
								if (react['reactions'][actor['Name']][action_name][state] ~= nil) then
									process_reaction(react['reactions'][actor['Name']][action_name][state], action_name, actor, target);
								end
							end
						end
					end
				end
			end
		end
	elseif (id == 0x061) then
		local main_job = struct.unpack('b', packet, 0x0C + 1);
		if (react['job'] ~= main_job) then
			local file = string.format('%s/settings/react_%s_%s.json', _addon.path, AshitaCore:GetDataManager():GetParty():GetMemberName(0), main_job);
			if (ashita.file.file_exists(file)) then
				print('[React] Loading user job file..');
				react['reactions'] = ashita.settings.load_merged(file, react['reactions']);
			else
				print('[React] Resetting reactions because no user job file exists.');
				react['reactions'] = { };
			end

			react['job'] = main_job;
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
	-- save settings on unload
	if (react['reactions'] ~= nil) then
		ashita.settings.save(string.format('%s/settings/react_%s_%s.json', _addon.path, AshitaCore:GetDataManager():GetParty():GetMemberName(0), AshitaCore:GetDataManager():GetPlayer():GetMainJob()), react['reactions']);
	end
end);

---------------------------------------------------------------------------------------------------
-- func: process_reaction
-- desc: Processes the user action when we detect the action being used.
---------------------------------------------------------------------------------------------------
function process_reaction(reaction, action_name, actor, target)
	if (reaction ~= nil) then
		local player = GetPlayerEntity();

		if (reaction == 'turnaround' or reaction == 'facemob') then
			local angle = (math.atan2((actor['Movement']['LocalPosition']['Z'] - player['Movement']['LocalPosition']['Z']), (actor['Movement']['LocalPosition']['X'] - player['Movement']['LocalPosition']['X'])) * 180 / math.pi) * -1.0;
			if (reaction == 'turnaround') then
				angle = angle + 180;
			end

			local radian = math.degree2rad(angle);
			if (radian) then
				ashita.memory.write_float(player['WarpPointer'] + 0x48, radian);
				ashita.memory.write_float(player['WarpPointer'] + 0x5D8, radian);
			end
		else
			AshitaCore:GetChatManager():QueueCommand(replace_data(reaction, action_name, actor, target), 1);
		end
	end
end

---------------------------------------------------------------------------------------------------
-- func: replace_data
-- desc: Let's users use variables in their reaction which we replace with actual data
---------------------------------------------------------------------------------------------------
function replace_data(data, action_name, actor, target)
	return data:gsub('%$action.name', action_name)
			   :gsub('%$actor.id', actor['ServerId']):gsub('%$actor.index', actor['TargetIndex']):gsub('%$actor.name', actor['Name'])
			   :gsub('%$target.id', target['ServerId']):gsub('%$target.index', target['TargetIndex']):gsub('%$target.name', target['Name']);
end