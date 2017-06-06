_addon.name    = 'Menus';
_addon.author  = 'Project Tako';
_addon.version = '1.0';
_addon.command = { 'menus', 'm' };

require ('common');

ashita.register_event('load', function()

end);

ashita.register_event('unload', function()

end);

ashita.register_event('command', function(cmd, nType)
	local args = cmd:args();

	-- Ensure it's a menus command.
	if (args[1] ~= '/menus' and args[1] ~= '/m') then
		return false;
	end

	-- Make sure we have enough args to begin with.
	if (#args < 2) then
		return false;
	end

	if (args[2] == 'open') then
		if (args[3] == 'db' or args[3] == 'deliverybox') then
			local delivery_box_packet = struct.pack('bbbbbbb', 0x4D, 0x20, 0x00, 0x00, 0x0E, 0xFF, 0xFF):totable();
			AddOutgoingPacket(0x4D, delivery_box_packet);
			return true;
		elseif (args[3] == 'send' or args[3] == 'sendbox') then
			local delivery_box_packet = struct.pack('bbbbbbb', 0x4D, 0x20, 0x00, 0x00, 0x0D, 0xFF, 0xFF):totable();
			AddOutgoingPacket(0x4D, delivery_box_packet);
			return true;
		elseif (args[3] == 'ah' or args[3] == 'auctionhouse') then 
			local auction_house_packet = struct.pack('bbbbbbb', 0x4C, 0x1E, 0x00, 0x00, 0x02, 0xFF, 0x01):totable();
			AddIncomingPacket(0x4C, auction_house_packet);
			return true;
		elseif (args[3] == 'mh' or args[3] == 'moghouse') then
			local mog_house_packet = struct.pack('bbbb', 0x2E, 0x02, 0x00, 0x00):totable();
			AddIncomingPacket(0x2E, mog_house_packet);
			return true;
		end
	end

	return false;
end);