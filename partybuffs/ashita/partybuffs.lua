_addon.author   = 'Project Tako';
_addon.name     = 'PartyBuffs';
_addon.version  = '1.1';

require('common');
require('d3d8');

-- holds our config such as on screen position and if the primitive objects are locked
local party_buffs =
{
	['show_distance'] = true,
	['window'] =
	{
		['x'] = 800,
		['y'] = 600
	},
	['menu'] = 
	{
		['x'] = 0,
		['y'] = 0
	},
	['scale'] = 
	{
		['x'] = 0,
		['y'] = 0
	},
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
	-- thanks tparty for letting me know these even existed.
	-- read config
	party_buffs['window']['x'] = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'window_x', 800);
	party_buffs['window']['y'] = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'window_y', 600);
	party_buffs['menu']['x'] = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'menu_x', 0);
	party_buffs['menu']['y'] = AshitaCore:GetConfigurationManager():get_int32('boot_config', 'menu_y', 0);

	-- sanity checks
	if (party_buffs['menu']['x'] <= 0) then
		party_buffs['menu']['x'] = party_buffs['window']['x'];
	end

	if (party_buffs['menu']['y'] <= 0) then
		party_buffs['menu']['y'] = party_buffs['window']['y'];
	end

	party_buffs['scale']['x'] = party_buffs['window']['x'] / party_buffs['menu']['x'];
	party_buffs['scale']['y'] = party_buffs['window']['y'] / party_buffs['menu']['y'];

	-- create the sprite that will hold the buff icons
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
				['buffs'] = { }
			};
		end

		-- create font object for this members distance
		local f = AshitaCore:GetFontManager():Create(string.format('__party_buffs_addon_%d', x));
		f:SetColor(0xFFFFFFFF);
	    f:SetFontFamily('Comic Sans MS');
	    f:SetFontHeight(8 * party_buffs['scale']['y']);
	    f:SetBold(true);
	    f:SetRightJustified(true);
	    f:SetPositionX(0);
	    f:SetPositionY(0);
	    f:SetText('0.0');
	    f:SetLocked(true);
	    f:SetVisibility(true);
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
		party_data = { };
		-- create default party_data table
		for x = 1, 5, 1 do
			-- look up id and add defaults to table
			local server_id = AshitaCore:GetDataManager():GetParty():GetMemberServerId(x);
			if (server_id ~= 0) then
				party_data[server_id] =
				{
					['id'] = server_id,
					['buffs'] = { }
				};
			end

			local f = AshitaCore:GetFontManager():Create(string.format('__party_buffs_addon_%d', x));
			f:SetVisibility(false);
		end
	-- party effects packet
	elseif (id == 0x76) then
		-- loop through the packet and read buff data
		for x = 0, 4, 1 do
			-- get party members server id, and make sure we have data for them
			local server_id = struct.unpack('I', packet, x * 0x30 + 0x04 + 1);
			if (party_data[server_id] ~= nil) then
				party_data[server_id]['buffs'] = { };
				for i = 0, 31, 1 do
					local mask = bit.band(bit.rshift(struct.unpack('b', packet, bit.rshift(i, 2) + (x * 0x30 + 0x0C) + 1), 2 * (i % 4)), 3);
					if (struct.unpack('b', packet, (x * 0x30 + 0x14) + i + 1) ~= -1 or mask > 0) then
						local buffId = bit.bor(struct.unpack('B', packet, (x * 0x30 + 0x14) + i + 1), bit.lshift(mask, 8));
						if (buffId ~= nil and buffId > 1) then
							party_data[server_id]['buffs'][i] = buffId;
						end
					end
				end

				--table.sort(party_data[server_id]['buffs']);
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

    local player_zone = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);

    -- make sure we are actually in a party
    if (AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount() > 1) then
	    -- offests to know where to render the next buff icon
	    
	    --local yoffset = party_buffs['party_size_offset'][AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount()];
	    local posx = party_buffs['window']['x'] - (171 * party_buffs['scale']['x']);
	    local posy = party_buffs['window']['y'] - (40 * party_buffs['scale']['y']);

	    -- loop and render
	    party_buffs['sprite']:Begin();

	    for x = 1, 5, 1 do
	    	local xoffset = 0;
	    	local f = AshitaCore:GetFontManager():Get(string.format('__party_buffs_addon_%d', x));

	    	if (player_zone ~= AshitaCore:GetDataManager():GetParty():GetMemberZone(x) or AshitaCore:GetDataManager():GetParty():GetMemberActive(x) == 0) then
	    		f:SetVisibility(false);
	    	else
	    		for key, value in pairs(textures[x]) do
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
			    		local xpos = posx - xoffset;
			    		local ypos = posy - ((AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount() - 1 - x) * (20 * party_buffs['scale']['y']));
			    		party_buffs['sprite']:Draw(value['texture']:Get(), rect, nil, nil, 0.0, D3DXVECTOR2(xpos, ypos), color);

			    		-- adjust offset
			    		xoffset = xoffset + party_buffs['size'];
			    	end
	    		end

	    		if (party_buffs['show_distance']) then
		    		local distance = AshitaCore:GetDataManager():GetEntity():GetDistance(AshitaCore:GetDataManager():GetParty():GetMemberTargetIndex(x));
		    		f:SetPositionX(posx - xoffset + 10);
		    		f:SetPositionY(posy - ((AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount() - 1 - x) * (20 * party_buffs['scale']['y'])));
		    		f:SetText(string.format(string.format('%.1f', math.sqrt(distance))));
	            	f:SetVisibility(true);
	            else
	            	f:SetVisibility(false);
	            end

	            xoffset = xoffset + party_buffs['size'];
	    	end
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
	for x = 1, 5, 1 do
		AshitaCore:GetFontManager():Delete(string.format('__party_buffs_addon_%d', x));
	end
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