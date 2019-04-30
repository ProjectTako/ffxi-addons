_addon.author   = 'Project Tako';
_addon.name     = 'PartyBuffs';
_addon.version  = '1.0';

require('common');
require('d3d8');

-- holds our config such as on screen position and if the primitive objects are locked
local party_buffs =
{
	['resolution'] =
	{
		['x'] = 1920,
		['y'] = 1080
	},
	['offset'] = 
	{
		['x'] = 180,
		['y'] = 5
	},
	['party_size_offset'] = { },
	['sprite'] = nil,
	['size'] = 20,
	['exclusions'] = { }
};

-- holds all of the data of our party members. Names, id, buffs etc
local party_data = 
{

};

-- holds information on texture data
-- key here is party member index
local textures =
{
	[1] = { },
	[2] = { },
	[3] = { },
	[4] = { },
	[5] = { }
};

----------------------------------------------------------------------------------------------------
-- func: load_file_texture
-- desc: Loads a buff icon texture from the /addons/partybuffs/icons/ folder with the given buff id
----------------------------------------------------------------------------------------------------
local function load_file_texture(buffId)
	-- get the path
	local path = string.format('%s\\icons\\%s.png', _addon.path, buffId);

	-- create texture
	--local res, texture = ashita.d3dx.CreateTextureFromFileA(path);
	local res, _, _, texture = ashita.d3dx.CreateTextureFromFileExA(path, party_buffs['size'], party_buffs['size'], 1, 0, D3DFMT_A8R8G8B8, 1, 0xFFFFFFFF, 0xFFFFFFFF, 0xFF000000);
	if (res ~= 0) then
		local _, err = ashita.d3dx.GetErrorStringA(res);
        print(string.format('[Error] Failed to load background texture for slot: %s - Error: (%08X) %s', name, res, err));
        return nil;
	end

	return texture;
end

----------------------------------------------------------------------------------------------------
-- func: update_party_member_texture
-- desc: Loops through all party members and updates their buff textures
----------------------------------------------------------------------------------------------------
local function update_party_member_texture()
	-- loop through our party members
	for x = 1, 5, 1 do
		-- reset textures 
		for key, value in pairs(textures[x]) do
			if (value['texture'] ~= nil) then
				value['texture']:Release();
				value['texture'] = nil;
				value['id'] = 0;
			end
		end

		-- get the party member id
		local id = AshitaCore:GetDataManager():GetParty():GetMemberServerId(x);
		-- check to see if we have this id in our party data
		if (party_data[id] ~= nil) then
			-- loop through their buffs
			for i, buffid in pairs(party_data[id]['buffs']) do
				-- default values
				textures[x][i] = 
				{
					['texture'] = nil,
					['id'] = 0
				};

				-- buff id 0xFF means no buff 
				if (buffid == 0xFF) then
					-- if there's no buff, do some clean up
					if (textures[x][i] ~= nil) then
						if (textures[x][i]['texture'] ~= nil) then
							textures[x][i]['texture']:Release();
							textures[x][i]['texture'] = nil;
						end

						textures[x][i]['id'] = buffid;
					end
				else
					if not (party_buffs['exclusions'][buffid] ~= nil) then
						-- valid buff, check to see if it's a different buff than was previously in that 'slot'
						if (textures[x][i] ~= nil and textures[x][i]['id'] ~= buffid) then

							-- set buff id and load texture
							textures[x][i]['id'] = buffid;
							textures[x][i]['texture'] = load_file_texture(buffid);
						end
					end
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- create the sprite 
	local res, sprite = ashita.d3dx.CreateSprite();

	-- if there's an error, get the error string and print
	if (res ~= 0) then
		local _, err = ashita.d3dx.GetErrorStringA(res);
		error(string.format('[Error] Failed to create sprite. - Error: (%08X) %s', res, err));
	end

	-- set the sprite data
	party_buffs['sprite'] = sprite;

	-- create default party_data table
	for x = 1, 5, 1 do
		-- look up id and add defaults to table
		local id = AshitaCore:GetDataManager():GetParty():GetMemberServerId(x);
		if (id ~= 0) then
			party_data[id] =
			{
				['id'] = AshitaCore:GetDataManager():GetParty():GetMemberServerId(x),
				['member_index'] = AshitaCore:GetDataManager():GetParty():GetMemberIndex(x),
				['buffs'] = { }
			};
		end
	end

	-- figure out where the starting position is for when you have any number of party members
	for x = 2, 6, 1 do
		party_buffs['party_size_offset'][x] = (party_buffs['resolution']['y'] - party_buffs['offset']['y']) - (20 * x);
	end

	-- load exclusions if the file exists
	local path = string.format('%s\\exclusions.lua', _addon.path);
	if (ashita.file.file_exists(path)) then
		party_buffs['exclusions'] = require('exclusions');
	end

	-- at this point we /probably/ won't have any buffs yet, but doesn't hurt to call it
	update_party_member_texture();
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
	-- zone packet, clean up textures
	if (id == 0x0A) then
		for x = 1, 5, 1 do
			for key, value in pairs(textures[x]) do
				if (value['texture'] ~= nil) then
					value['texture']:Release();
					value['texture'] = nil;
					value['id'] = 0;
				end
			end
		end
	-- party update packet
	elseif (id == 0xDD) then
		local server_id = struct.unpack('I', packet, 0x04 + 1);
		local member_number = struct.unpack('b', packet, 0x1A + 1);
		if (party_data[server_id] == nil or party_data[server_id]['member_index'] ~= member_number) then
			party_data[server_id] = 
			{
				['id'] = server_id,
				['member_index'] = member_number,
				['buffs'] = { }
			};
		end
	-- party effects packet
	elseif (id == 0x76) then
		-- loop through the packet and read buff data
		for x = 0, 4, 1 do
			local server_id = struct.unpack('I', packet, x * 0x30 + 0x04 + 1);
			if (party_data[server_id]) then
				party_data[server_id]['buffs'] = { };
				for i = 0, 31, 1 do
					local mask = bit.band(bit.rshift(struct.unpack('b', packet, bit.rshift(i, 2) + (x * 0x30 + 0x0C) + 1), 2 * (i % 4)), 3);
					if (struct.unpack('b', packet, (x * 0x30 + 0x14) + i + 1) ~= -1 or mask > 0) then
						local buffId = bit.bor(struct.unpack('B', packet, (x * 0x30 + 0x14) + i + 1), bit.lshift(mask, 8));
						if (buffId > 1) then
							party_data[server_id]['buffs'][i] = buffId;
						end
					end
				end

				table.sort(party_data[server_id]['buffs']);
			end
		end

		update_party_member_texture();
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

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
	-- make sure we have a valid sprite
	if (party_buffs['sprite'] == nil) then
		return;
	end

	-- don't render if objects are being hidden
	if (AshitaCore:GetFontManager():GetHideObjects()) then
        return;
    end

    -- make sure we are actually in a party
    if (AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount() > 1) then
	    -- offests to know where to render the next buff icon
	    local xoffset = 0;
	    local yoffset = party_buffs['party_size_offset'][AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount()];

	    -- loop and render
	    party_buffs['sprite']:Begin();

	    for k, v in pairs(textures) do
	    	if (AshitaCore:GetDataManager():GetParty():GetMemberActive(k) == 1) then
		    	for key, value in pairs(v) do
			    	-- create a rectangle 
			    	-- size is equal to value in the settings/size valeu
			    	local rect = RECT();
			    	rect.left = 0;
			    	rect.top = 0;
			    	rect.right = party_buffs['size'];
			    	rect.bottom = party_buffs['size'];

			    	-- rendering color, argb
			    	local color = math.d3dcolor(255, 255, 255, 255);

			    	-- render the buff icon texture, we have to manually keep track of the offset here
			    	if (value['texture'] ~= nil) then
			    		-- draw 
			    		local xpos = ((party_buffs['resolution']['x'] - party_buffs['offset']['x']) - xoffset);
			    		local ypos = yoffset + ((k - 1) * 20);
			    		party_buffs['sprite']:Draw(value['texture']:Get(), rect, nil, nil, 0.0, D3DXVECTOR2(xpos, ypos), color);

			    		-- adjust offset
			    		xoffset = xoffset + party_buffs['size'];
			    	end

			    end
		    end

		    xoffset = 0;
	    end

	    party_buffs['sprite']:End();
	end
end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
	-- clean up
	for key, value in pairs(textures) do
		if (value ~= nil and value['texture'] ~= nil) then
			value['texture']:Release();
			value['texture'] = nil;
		end
	end

	if (party_buffs['sprite'] ~= nil) then
		party_buffs['sprite']:Release()
		party_buffs['sprite'] = nil;
	end
end);