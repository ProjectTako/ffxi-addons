local monster_abils = { };

monster_abils['data'] = { };

-- the path to the DAT file: 
-- JP: ROM\27\79.dat
-- EN: ROM\27\80.dat
monster_abils['dat_path'] = 'ROM\\27\\80.DAT';

local function get_file_size(file_reader)
	local current = file_reader:seek();
	local size = file_reader:seek('end');
	file_reader:seek('set', current);

	return size;
end

function monster_abils.load()
	if (monster_abils['dat_path'] ~= nil and monster_abils['dat_path'] ~= '') then
		local file = io.open(string.format('%s\\..\\FINAL FANTASY XI\\%s', ashita.file.get_install_dir(), monster_abils['dat_path']), 'rb');
		if (file ~= nil) then
			-- get the full size of the file as we'll need it to validate
			local size = get_file_size(file);

			-- basic file validation
			local file_size = struct.unpack('I', file:read(4), 1);

			if (file_size ~= (0x10000000 + size - 4)) then
				return;
			end

			-- get the position of the first text entry, and validate
			local first = bit.bxor(struct.unpack('I', file:read(4), 1), 0x80808080);
			if ((first % 4) ~= 0 or first > size or first < 8) then
				return;
			end

			-- get how many total entries there will be
			local entry_count = first / 4;

			-- read through the file getting the position of each entry
			local entries = { };
			entries[0] = first;

			for x = 1, entry_count do 
				entries[x] = bit.bxor(struct.unpack('I', file:read(4), 1), 0x80808080);
			end

			entries[#entries + 1] = size - 4;

			for x = 0, entry_count do
				if (entries[x] < 4 * entry_count or 4 + entries[x] > size) then
					break;
				end

				-- entry starts at entries[x] and ends at entries[x + 1];
				file:seek('set', 4 + entries[x]);
				local data = file:read(entries[x + 1] - entries[x]);
				local text_bytes = { }

				-- this is how SE 'encrypts' their data
				for i = 1, #data do
					text_bytes[i] = bit.bxor(struct.unpack('B', data, i), 0x80);
				end

				local text = '';
				for i = 1, #text_bytes do
					if (string.char(text_bytes[i]) == '\0') then
						break;
					end

					text = text .. string.char(text_bytes[i]);
				end

				monster_abils['data'][x] = text:trim();
			end
		end
	end
end

function monster_abils.get_ability_by_id(id)
	return monster_abils['data'][id] or nil;
end

function monster_abils.get_ability_id_by_name(name)
	for key, value in pairs(monster_abils['data']) do
		if (value == name) then
			return key;
		end
	end
end

return monster_abils;