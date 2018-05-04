require('class');

local ___functions = { };

local slotMapping = 
{
	[0] = { slot = 0, slot_name = 'main' },
	[1] = { slot = 1, slot_name = 'sub' },
	[2] = { slot = 2, slot_name = 'range' },
	[3] = { slot = 3, slot_name = 'ammo' }, 
	[4] = { slot = 4, slot_name = 'head' },
	[5] = { slot = 9, slot_name = 'neck' },
	[6] = { slot = 11, slot_name = 'left_ear' },
	[7] = { slot = 12, slot_name = 'right_ear' },
	[8] = { slot = 5, slot_name = 'body' },
	[9] = { slot = 6, slot_name = 'hands' },
	[10] = { slot = 13, slot_name = 'left_ring' },
	[11] = { slot = 14, slot_name = 'right_ring' },
	[12] = { slot = 15, slot_name = 'back' },
	[13] = { slot = 10, slot_name = 'waist' },
	[14] = { slot = 7, slot_name = 'legs' },
	[15] = { slot = 8, slot_name = 'feet' }
}, { slot, slot_name };

local sizes = { 16, 32, 48, 64 };
local selectedSize = sizes[2];

EquipViewer = class(function()

end);

function EquipViewer:SelectSize(size)
	-- don't use tables:contains here to avoid needing extra includes
	for x = 1, #sizes, 1 do
		if (sizes[x] == size) then
			selectedSize = sizes[x];

			return selectedSize;
		end
	end

	return -1;
end

function EquipViewer:InjectPrimitiveDependancies(createPrimitiveObject, setPosition, setSize, setFixToTexture, setVisibility, setColor, setText, setTexture, deletePrimitiveObject)
	___functions['createPrimitiveObject'] = createPrimitiveObject;
	___functions['setPosition'] = setPosition;
	___functions['setSize'] = setSize;
	___functions['setFixToTexture'] = setFixToTexture;
	___functions['setVisibility'] = setVisibility;
	___functions['setColor'] = setColor;
	___functions['setText'] = setText;
	___functions['setTexture'] = setTexture;
	___functions['deletePrimitiveObject'] = deletePrimitiveObject;
end

function EquipViewer:InjectInventoryDependancies(getEquippedItemId, getTexturePath)
	___functions['getEquippedItemId'] = getEquippedItemId;
	___functions['getTexturePath'] = getTexturePath;
end

function EquipViewer:Create(startX, startY, color, background_color)
	-- background
	___functions['createPrimitiveObject']('__equipViewer_background');
	___functions['setPosition']('__equipViewer_background', startX, startY);
	___functions['setSize']('__equipViewer_background', (selectedSize * 4), (selectedSize * 4));
	___functions['setVisibility']('__equipViewer_background', true);
	___functions['setColor']('__equipViewer_background', background_color);

	-- equipment slots
	for x = 0, 15, 1 do
		local posX = startX + ((x % 4) * selectedSize);
		local posY = startY + (math.floor(x / 4) * selectedSize);

		___functions['createPrimitiveObject'](string.format('__equipViewer_slot%d', x));
		___functions['setPosition'](string.format('__equipViewer_slot%d', x), posX, posY);
		___functions['setVisibility'](string.format('__equipViewer_slot%d', x), true);
		___functions['setColor'](string.format('__equipViewer_slot%d', x), color);
		___functions['setSize'](string.format('__equipViewer_slot%d', x), selectedSize, selectedSize);
	end
end

function EquipViewer:Move(startX, startY)
	___functions['setPosition']('__equipViewer_background', startX, startY);

	for x = 0, 15, 1 do
		local posX = startX + ((x % 4) * selectedSize);
		local posY = startY + (math.floor(x / 4) * selectedSize);
		___functions['setPosition'](string.format('__equipViewer_slot%d', x), posX, posY);
	end
end

function EquipViewer:Resize(startX, startY, size)
	___functions['setSize']('__equipViewer_background', (selectedSize * 4), (selectedSize * 4));

	for x = 0, 15, 1 do
		local posX = startX + ((x % 4) * selectedSize);
		local posY = startY + (math.floor(x / 4) * selectedSize);

		___functions['setPosition'](string.format('__equipViewer_slot%d', x), posX, posY);
		___functions['setSize'](string.format('__equipViewer_slot%d', x), selectedSize, selectedSize);
	end

	EquipViewer:Update();
end

function EquipViewer:Update()
	-- loop through equipment slots
	for slotIndex, equipSlot in pairs(slotMapping) do
		-- get the inventory slot id of the equipped item
		local itemId = ___functions['getEquippedItemId'](equipSlot['slot'], equipSlot['slot_name']);
		local texturePath = ___functions['getTexturePath'](itemId);

		if (itemId == 0 or itemId == 65535) then
			___functions['setVisibility'](string.format('__equipViewer_slot%d', slotIndex), false);
		else
			___functions['setVisibility'](string.format('__equipViewer_slot%d', slotIndex), true);
		end
		___functions['setTexture'](string.format('__equipViewer_slot%d', slotIndex), texturePath);
	end
end

function EquipViewer:Delete()
	___functions['deletePrimitiveObject']('__equipViewer_background');

	for x = 0, 15, 1 do
		___functions['deletePrimitiveObject'](string.format('__equipViewer_slot%d', x));
	end
end