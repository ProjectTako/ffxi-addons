_addon.author   = 'Project Tako';
_addon.name     = 'EquipViewer';
_addon.version  = '1.0';

require('common');
require('core');
local http = require("socket.http");

local default_config = 
{
	position = { 500, 500 },
	color = 0xFFFFFFFF,
	background_color = 0x40000000
};

local equipViewerConfig = default_config;

local equipViewer;

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('load', function()
	-- load the config
	equipViewerConfig = ashita.settings.load_merged(_addon.path .. 'settings/settings.json', equipViewerConfig);

	-- Create the icons folder if it doesn't exist. Do this on load rather than when downloading icons to avoid checking it multiple times.
	local icon_path = _addon.path .. '\\icons';
	if not (ashita.file.dir_exists(icon_path)) then
		ashita.file.dir_create(icon_path);
	end

	-- Create instance of our "class"
	equipViewer = EquipViewer();

	-- Inject the functions it needs to create onscreen objects
	equipViewer:InjectPrimitiveDependancies(ashitaPrimitiveCreate, ashitaPrimitiveSetPosition, ashitaPrimitiveSetSize, ashitaPrimitiveSetFixToTexture, ashitaPrimitiveSetVisibility, ashitaPrimitiveSetColor, ashitaSetText, ashitaPrimitiveSetTextureFromFile, ashitePrimitiveDelete);
	-- inject the functions it needs to get equipment info
	equipViewer:InjectInventoryDependancies(ashitaGetEquippedItemId, ashitaGetTexturePath);

	-- create onscreen objects
	equipViewer:Create(equipViewerConfig['position'][1], equipViewerConfig['position'][2], equipViewerConfig['color'], equipViewerConfig['background_color']);

	-- update equipment for initial load
	equipViewer:Update();
end);

---------------------------------------------------------------------------------------------------
-- func: command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
ashita.register_event('command', function(cmd, nType)
	-- get command args
	local args = cmd:args();

	-- ensure it's one of our commands
	if (args[1] ~= '/equipviewer') then
		return false;
	end

	if (args[2] == 'position' or args[2] == 'pos') then
		if (#args < 4) then
			return false;
		end

		equipViewerConfig['position'] = { tonumber(args[3]), tonumber(args[4]) };
		equipViewer:Move(equipViewerConfig['position'][1], equipViewerConfig['position'][2]);
	end 
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('incoming_packet', function(id, size, packet)
	-- Equipment or Inventory Finish
	if (id == 0x37 or id == 0x1D) then
		-- update equipment
		equipViewer:Update();
	end
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing_packet
-- desc: Called when our addon receives an outgoing packet.
---------------------------------------------------------------------------------------------------
ashita.register_event('outgoing_packet', function(id, size, packet)
	-- Action or Equipment Changed packet
	if (id == 0x1A or id == 0x50) then
		-- update equipment
		equipViewer:Update();
	end
	return false;
end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
ashita.register_event('unload', function()
	-- save the config
	ashita.settings.save(_addon.path .. 'settings/settings.json', equipViewerConfig);
	-- delete all of the objects
	equipViewer:Delete();
end);


-- Functions to work with Font/Primitive Objects
function ashitaPrimitiveCreate(name)
	local f = AshitaCore:GetFontManager():Create(name);
	f:SetAutoResize(false);
	f:SetLocked(true);
end

function ashitaSetText(name, text)
	AshitaCore:GetFontManager():Get(name):SetText(text);
end

function ashitaPrimitiveSetPosition(name, x, y)
	AshitaCore:GetFontManager():Get(name):SetPositionX(x);
	AshitaCore:GetFontManager():Get(name):SetPositionY(y);
end

function ashitaPrimitiveSetSize(name, x, y)
	AshitaCore:GetFontManager():Get(name):GetBackground():SetWidth(x);
	AshitaCore:GetFontManager():Get(name):GetBackground():SetHeight(y);
end

function ashitaPrimitiveSetFixToTexture(name, fitToTextture)
	
end

function ashitaPrimitiveSetVisibility(name, visible)
	AshitaCore:GetFontManager():Get(name):SetVisibility(visible);
	AshitaCore:GetFontManager():Get(name):GetBackground():SetVisibility(visible);
end

function ashitaPrimitiveSetColor(name, color)
	AshitaCore:GetFontManager():Get(name):SetColor(color);
	AshitaCore:GetFontManager():Get(name):GetBackground():SetColor(color);
end

function ashitaPrimitiveSetTextureFromFile(name, texturePath)
	AshitaCore:GetFontManager():Get(name):GetBackground():SetTextureFromFile(texturePath);
end

function ashitePrimitiveDelete(name)
	AshitaCore:GetFontManager():Delete(name);
end

-- Inventory Functions
function ashitaGetEquippedItemId(slot, slot_name)
	local inventory = AshitaCore:GetDataManager():GetInventory();
	local equipment = inventory:GetEquippedItem(slot);
	local index = equipment.ItemIndex;

	if (index == 0) then
		return 0;
	end

	-- item is in inventory
	if (index < 2048) then
		return inventory:GetItem(0, index).Id;
	elseif (index < 2560) then -- wardrobe 1
		return inventory:GetItem(8, index - 2048).Id;
	elseif (index < 2816) then -- wardrobe 2
		return inventory:GetItem(10, index - 2560).Id;
	elseif (index < 3072) then -- wardrobe 3
		return inventory:GetItem(11, index - 2816).Id;
	elseif (index < 3328) then -- wardrobe 4
		return inventory:GetItem(12, index - 3072).Id;
	else -- shouldn't ever happen, but yeah.
		return 0;
	end
end

-- Pathing functions
function ashitaGetTexturePath(itemId)
	local path = _addon.path .. '\\icons\\' .. itemId .. '.png';
	if (ashita.file.file_exists(path)) then
		return path;
	else
		local body, code = http.request(string.format('http://static.ffxiah.com/images/icon/%d.png', itemId));
		if not (body) then
			print(string.format('Could not find or retrieve icon file for item id %d. HTTP Code: %d', itemId, code));
			return _addon.path .. '\\icons\\0.png';
		end

		local f = assert(io.open(path, 'wb'));
		f:write(body);
		f:close();

		return path;
	end
end