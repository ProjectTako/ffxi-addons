_addon.name = 'Equip Viewer';
_addon.version = '2.0';
_addon.author = 'Project Tako';
_addon.commands = { 'equipviewer', 'ev' };

require('pack');
require('tables');
local config = require('config');
local primitives = require('images');


local texture_data =
{
	{ slot_name = 'bg', 		slot_id = -1, display_pos = -1, primitive = nil },
	{ slot_name = 'main',		slot_id = 0, display_pos = 0, item_id = 0, primitive = nil },
	{ slot_name = 'sub',		slot_id = 1, display_pos = 1, item_id = 0, primitive = nil },
	{ slot_name = 'range',		slot_id = 2, display_pos = 2, item_id = 0, primitive = nil },
	{ slot_name = 'ammo',		slot_id = 3, display_pos = 3, item_id = 0, primitive = nil },
	{ slot_name = 'head',		slot_id = 4, display_pos = 4, item_id = 0, primitive = nil },
	{ slot_name = 'body',		slot_id = 5, display_pos = 8, item_id = 0, primitive = nil },
	{ slot_name = 'hands',		slot_id = 6, display_pos = 9, item_id = 0, primitive = nil },
	{ slot_name = 'legs',		slot_id = 7, display_pos = 14, item_id = 0, primitive = nil },
	{ slot_name = 'feet',		slot_id = 8, display_pos = 15, item_id = 0, primitive = nil },
	{ slot_name = 'neck',		slot_id = 9, display_pos = 5, item_id = 0, primitive = nil },
	{ slot_name = 'waist',		slot_id = 10, display_pos = 13, item_id = 0, primitive = nil },
	{ slot_name = 'left_ear',	slot_id = 11, display_pos = 6, item_id = 0, primitive = nil },
	{ slot_name = 'right_ear',	slot_id = 12, display_pos = 7, item_id = 0, primitive = nil },	
	{ slot_name = 'left_ring',	slot_id = 13, display_pos = 10, item_id = 0, primitive = nil },
	{ slot_name = 'right_ring',	slot_id = 14, display_pos = 11, item_id = 0, primitive = nil },
	{ slot_name = 'back',		slot_id = 15, display_pos = 12, item_id = 0, primitive = nil },
};

local default_settings =
{
	['pos'] = 
	{
		['x'] = 500,
		['y'] = 500
	},
	['size'] = 32
};


---------------------------------------------------------------------------------------------------
-- func: get_equipped_item
-- desc: Gets the currently equipped item for the slot information provided
---------------------------------------------------------------------------------------------------
local function get_equipped_item(slotName, slotId)
	if (slotId < 0) then
		return nil;
	end

	local equipment = windower.ffxi.get_items()['equipment'];

	return windower.ffxi.get_items(equipment[string.format('%s_bag', slotName)], equipment[slotName]);
end

---------------------------------------------------------------------------------------------------
-- func: update_equipment_textures
-- desc: Updates the texture for all slots if it's a different piece of equipment
---------------------------------------------------------------------------------------------------
local function update_equipment_textures()
	for key, value in pairs(texture_data) do
		local item = get_equipped_item(value['slot_name'], value['slot_id']);
		if (item ~= nil) then
			if (item['id'] == 0 or item['id'] == 65535) then
				--value['primitive']:clear();
				value['primitive']:hide();
				value['primitive']:transparency(1);
				value['item_id'] = 0;
			elseif (value['item_id'] == 0 or value['item_id'] ~= item['id']) then
				value['item_id'] = item['id'];
				local icon_path = string.format('%sicons/%s/%d.png', windower.addon_path, default_settings['size'], value['item_id']);
				if (windower.file_exists(icon_path)) then
					value['primitive']:path(icon_path);
					value['primitive']:transparency(0);
					value['primitive']:show();
				end
			end
			value['primitive']:update();
		end
	end
end

---------------------------------------------------------------------------------------------------
-- func: update_equipment_slot_texture
-- desc: Updates the texture for the given slot if it's a different piece of equipment
---------------------------------------------------------------------------------------------------
local function update_equipment_slot_texture(slotIndex)
	for key, value in pairs(texture_data) do
		if (value['slot_id'] == slotIndex) then
			local item = get_equipped_item(value['slot_name'], value['slot_id']);
			if (item ~= nil) then
				if (item['id'] == 0 or item['id'] == 65535) then
					--value['primitive']:clear();
					value['primitive']:hide();
					value['item_id'] = 0;
				elseif (value['item_id'] == 0 or value['item_id'] ~= item['id']) then
					value['item_id'] = item['id'];
					local icon_path = string.format('%sicons/%s/%d.png', windower.addon_path, default_settings['size'], value['item_id']);
					if (windower.file_exists(icon_path)) then
						value['primitive']:path(icon_path);
						value['primitive']:transparency(0);
						value['primitive']:show();
					end
				end

				value['primitive']:update();
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
-- func: setup_textures
-- desc: Sets up the primitive objects for our equipment
---------------------------------------------------------------------------------------------------
local function setup_textures()
	-- loop through and create the primitive objects
	-- 17 total objects. 1 background, 16 equipment slots
	for key, value in pairs(texture_data) do
		value['item_id'] = 0;
		-- background is treated differently than the rest
		if (value['slot_name'] == 'bg') then
			value['primitive'] = primitives.new({ ['color'] = { ['alpha'] = 128, ['red'] = 0, ['blue'] = 0, ['green'] = 0 }, ['pos'] = { ['x'] = default_settings['pos']['x'], ['y'] = default_settings['pos']['y'] }, ['size'] = { ['width'] = default_settings['size'] * 4, ['height'] = default_settings['size'] * 4 }, ['draggable'] = false });
			value['primitive']:show();
		else
			local pos_x = default_settings['pos']['x'] + ((value['display_pos'] % 4) * default_settings['size']);
			local pos_y = default_settings['pos']['y'] + (math.floor(value['display_pos'] / 4) * default_settings['size']);

			value['primitive'] = primitives.new({ ['color'] = { ['alpha'] = 255, ['red'] = 255, ['blue'] = 255, ['green'] = 255 }, ['texture'] = { ['fit'] = false }, ['pos'] = { ['x'] = pos_x, ['y'] = pos_y }, ['size'] = { ['width'] = default_settings['size'], ['height'] = default_settings['size'] }, ['draggable'] = false });
		end
	end

	update_equipment_textures();
end

---------------------------------------------------------------------------------------------------
-- func: load
-- desc: First called when our addon is loaded.
---------------------------------------------------------------------------------------------------
windower.register_event('load', function()
	default_settings = config.load(default_settings);

	if not (windower.dir_exists(string.format('%sicons', windower.addon_path))) then
		windower.create_dir(string.format('%sicons', windower.addon_path));
	end

	setup_textures();
end);

---------------------------------------------------------------------------------------------------
-- func: addon command
-- desc: Called when our addon receives a command.
---------------------------------------------------------------------------------------------------
windower.register_event('addon command', function (...)
	local cmd  = (...) and (...):lower();
    local cmd_args = { select(2, ...) };

    if (cmd == 'position' or cmd == 'pos') then
    	if (#cmd_args < 2) then
    		return;
    	end

    	default_settings['pos']['x'] = tonumber(cmd_args[1]);
    	default_settings['pos']['y'] = tonumber(cmd_args[2]);

    	for key, value in pairs(texture_data) do
			if (value['primitive'] ~= nil) then
				value['primitive']:destroy();
			end
		end

		setup_textures();
	elseif (cmd == 'size') then
		if (#cmd_args < 1) then
			return;
		end

		default_settings['size'] = tonumber(cmd_args[1]);
		for key, value in pairs(texture_data) do
			if (value['primitive'] ~= nil) then
				value['primitive']:destroy();
			end
		end

		setup_textures();
    end
end);

---------------------------------------------------------------------------------------------------
-- func: incoming chunk
-- desc: Called when our addon receives an incoming chunk.
---------------------------------------------------------------------------------------------------
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
	if (id == 0x0050) then
		local slot = original:unpack('c', 0x05 + 1);
		update_equipment_slot_texture(slot);
	end
end);

---------------------------------------------------------------------------------------------------
-- func: outgoing chunk
-- desc: Called when our addon receives an outgoing chunk.
---------------------------------------------------------------------------------------------------

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)

end);

---------------------------------------------------------------------------------------------------
-- func: prerender
-- desc: Triggers before every rendering tick.
---------------------------------------------------------------------------------------------------
windower.register_event("prerender", function()

end);

---------------------------------------------------------------------------------------------------
-- func: unload
-- desc: Called when our addon is unloaded.
---------------------------------------------------------------------------------------------------
windower.register_event('unload', function()
	for key, value in pairs(texture_data) do
		if (value['primitive'] ~= nil) then
			value['primitive']:destroy();
		end
	end

	config.save(default_settings);
end);
