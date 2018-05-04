_addon.name = 'EquipViewer';
_addon.version = '1.0';
_addon.author = 'Project Tako';
_addon.commands = { 'equipviewer', 'ev' };

require('core');
local bit = require('bit')
local http = require("socket.http");

local default_config = 
{
	position = { 900, 800 },
	color = 0xFFFFFFFF,
	background_color = 0x40000000,
	size = 32
};

local equipViewerConfig = default_config;

local equipViewer;

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
windower.register_event('load', function()
	-- Create instance of our "class"
	equipViewer = EquipViewer();

	-- Create the icons folder if it doesn't exist. Do this on load rather than when downloading icons to avoid checking it multiple times.
	local icon_path = windower.addon_path  .. 'icons';
	if not (windower.dir_exists(icon_path)) then
		windower.create_dir(icon_path);
	end

	-- set the size before we do anything else, since if we do it after it'll redo a lot of work
	equipViewer:SelectSize(equipViewerConfig['size']);

	-- Inject the functions it needs to create onscreen objects
	equipViewer:InjectPrimitiveDependancies(windowerPimitiveCreate, windowerPrimitiveSetPosition, windowerPrimitiveSetSize, windowerPrimitiveSetFixToTexture, windowerPrimitiveSetVisibility, windowerPrimitiveSetColor, windowerSetText, windowerPrimitiveSetTextureFromFile, windowerPrimitiveDelete);
	-- inject the functions it needs to get equipment info
	equipViewer:InjectInventoryDependancies(windowerGetEquippedItemId, windowerGetTexturePath);

	-- create onscreen objects
	equipViewer:Create(equipViewerConfig['position'][1], equipViewerConfig['position'][2], equipViewerConfig['color'], equipViewerConfig['background_color']);

	-- update equipment for initial load
	equipViewer:Update();
end);

---------------------------------------------------------------------------------------------------
-- func: addon command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
windower.register_event('addon command', function (...)
	-- get the command and command args
	local cmd  = (...) and (...):lower();
    local cmd_args = { select(2, ...) };

    -- move the position
    if (cmd == 'position' or cmd == 'pos') then
    	if (#cmd_args < 2) then
    		return;
    	end

    	equipViewerConfig['position'] = { tonumber(cmd_args[1]), tonumber(cmd_args[2]) };
    	equipViewer:Move(equipViewerConfig['position'][1], equipViewerConfig['position'][2]);
    end

    if (cmd == 'size') then
    	if (#cmd_args < 1) then
    		return;
    	end

    	local size = tonumber(cmd_args[1]);
    	local validSize = equipViewer:SelectSize(size);
		if (validSize > -1) then
			equipViewerConfig['size'] = size;

			equipViewer:Resize(equipViewerConfig['position'][1], equipViewerConfig['position'][2], equipViewerConfig['size']);
		end
    end
end);

---------------------------------------------------------------------------------------------------
-- func: incoming chunk
-- desc: Called when our addon receives an incoming chunk.
---------------------------------------------------------------------------------------------------
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
	-- Equipment or Inventory Finish
	if (id == 0x37 or id == 0x1D) then
		-- update equipment
		equipViewer:Update();
	end
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing chunk
-- desc: Called when our addon receives an outgoing chunk.
---------------------------------------------------------------------------------------------------

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
	-- Action or Equipment Changed packet
	if (id == 0x1A or id == 0x50) then
		-- update equipment
		equipViewer:Update();
	end
end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
windower.register_event('unload', function()
	-- delete all of the objects
	equipViewer:Delete();
end);

function windowerPimitiveCreate(name)
	windower.prim.create(name);
end

function windowerSetText(name, text)

end

function windowerPrimitiveSetPosition(name, x, y)
	windower.prim.set_position(name, x, y);
end

function windowerPrimitiveSetSize(name, x, y)
	windower.prim.set_size(name, x, y)
end

function windowerPrimitiveSetFixToTexture(name, fitToTextture)
	windower.prim.set_fit_to_texture(name, fitToTextture);
end

function windowerPrimitiveSetVisibility(name, visible)
	windower.prim.set_visibility(name, visible);
end

function windowerPrimitiveSetColor(name, color)
	local a = bit.band(bit.rshift(color, 24), 0xFF);
	local r = bit.band(bit.rshift(color, 16), 0xFF);
	local g = bit.band(bit.rshift(color, 8), 0xFF);
	local b = bit.band(color, 0xFF);

	windower.prim.set_color(name, a, r, g, b);
end

function windowerPrimitiveSetTextureFromFile(name, texturePath)
	windower.prim.set_texture(name, texturePath);
end

function windowerPrimitiveDelete(name)
	--windower.prim.delete(name);
end

function windowerGetEquippedItemId(slot, slot_name)
	local inventory = windower.ffxi.get_items();
	local equipment = inventory['equipment'];

	return windower.ffxi.get_items(equipment[string.format('%s_bag', slot_name)], equipment[slot_name]).id;
end

function windowerGetTexturePath(itemId)
	local path = windower.addon_path  .. 'icons/' .. equipViewerConfig['size'] .. '/' .. itemId .. '.png';
	if (windower.file_exists(path)) then
		return path;
	else
		local body, code = http.request(string.format('http://static.ffxiah.com/images/icon/%d.png', itemId));
		if not (body) then
			print(string.format('Could not find or retrieve icon file for item id %d. HTTP Code: %d', itemId, code));
			return windower.addon_path .. 'icons/0.png';
		end

		local f = assert(io.open(path, 'wb'));
		f:write(body);
		f:close();

		return path;
	end
end