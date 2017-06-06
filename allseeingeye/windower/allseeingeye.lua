_addon.name = 'AllSeeingEye'
_addon.version = '1.0'
_addon.author = 'Project Tako'

windower.register_event('incoming chunk',function(id, data, modified, injected, blocked)
	if (id == 14) then		
		local status = data:byte(0x21)
		if (status == 2 or status == 6 or status == 7) then
			local packet = data:sub(1, 32) .. '0' .. data:sub(34, 34) .. '0' .. data:sub(36, 41) .. '0' .. data:sub(43);

			return packet
		else
			return data;
		end
	end
end)