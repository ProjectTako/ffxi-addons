_addon.author   = 'Gobbo';
_addon.name     = 'SC Heroes';
_addon.version  = '1.0';

require('common');
require 'ffxi.targets';
local default_config =
{
	max_displayed = 4,
    font =
    {
        family      = 'Arial',
        size        = 15,
        color       = 0xFFFFFFFF,
        position    = { 900, 800 },
        bgcolor     = 0x80000000,
        bgvisible   = true,
    }
};
Text = 
{

};

ashita.register_event('load', function()
	-- load the config
	exConfig = ashita.settings.load_merged(_addon.path .. 'settings/settings.json', exConfig);

	-- create our test on screen objects
		local display_ws = AshitaCore:GetFontManager():Create('display_ws');
		local display_sc = AshitaCore:GetFontManager():Create('display_sc');
		local display_ws = AshitaCore:GetFontManager():Get('display_ws');
		local display_sc = AshitaCore:GetFontManager():Get('display_sc');
		display_ws:SetPositionX(exConfig.font.position[1]);
		display_ws:SetPositionY(exConfig.font.position[2]);
		
		display_ws:SetColor(exConfig.font.color);
		display_ws:SetFontFamily(exConfig.font.family);
		display_ws:SetFontHeight(exConfig.font.size);
		display_ws:SetBold(true);
		display_ws:GetBackground():SetColor(exConfig.font.bgcolor);
		display_ws:GetBackground():SetVisibility(exConfig.font.bgvisible);
		display_ws:SetVisibility(true);
		
		display_sc:SetPositionX(exConfig.font.position[1]);
		display_sc:SetPositionY(exConfig.font.position[2]);
		
		display_sc:SetColor(exConfig.font.color);
		display_sc:SetFontFamily(exConfig.font.family);
		display_sc:SetFontHeight(exConfig.font.size);
		display_sc:SetBold(true);
		display_sc:GetBackground():SetColor(exConfig.font.bgcolor);
		display_sc:GetBackground():SetVisibility(exConfig.font.bgvisible);
		display_sc:SetVisibility(false);
		
		

	
end);

ashita.register_event('render', function()
	seconds = os.time() - start_time;
	timer_start = os.date('!%H%M%S',seconds);
	if (tracked_skillchain[1] == nil) then
	timer_start2 = timer_start - 9;
	elseif (tracked_skillchain[1] ~= nil) then
	timer_start2 = timer_start - 9 + #tracked_skillchain;
	end
	
	timer = tostring(timer_start2);
	Time_Left = 'Time Remaining: '..-timer;
	
	--display_timer:text(Time_Left);
	--display_timer:show();
	
	if (timer_start2 > -1) then
		Time_Left = 'Time Remaining: 0'
		--display_timer:hide();
		SC = 'None';
		WS = 'None';
		ele1 = 'N/A';
		ele2 = 'N/A';
		ele3 = 'N/A';
		ele4 = 'N/A';
		propa = ' ';
		propb = ' ';
		propc = ' ';
		tracked_skillchain = {};
		display_sc:SetVisibility(false);
		display_ws:SetVisibility(true);
	end
	
end);

ashita.register_event('incoming_packet', function(id, size, packet)
	if (SC == nil) then
			SC = 'None';
			ele1 = 'N/A';
			ele2 = 'N/A';
			ele3 = 'N/A';
			ele4 = 'N/A';
		end
		if (WS == nil) then
			WS = 'None';
			propa = ' ';
			propb = ' ';
			propc = ' ';
			display_ws:SetVisibility(true);
			display_sc:SetVisibility(false);
		end
		display_sc:ShowText(Last_Skillchain);
		
		prev_SC = SC;
		Last_Skillchain = 'Last Skillchain: '..prev_SC..'\n'..'--------------------------------------'..'\n'..'Elements: '..'\n'..ele1..' | '..ele2..'\n'..ele3..' | '..ele4..'\n'..Time_Left;
		display_ws:ShowText(Last_WS);
		prev_WS = WS;
		Last_WS = 'Last Weaponskill: '..prev_WS..'\n'..'-----------------------------------'..'\n'..'Property A: '..propa..'\n'..'Property B: '..propb..'\n'..'Property C: '..propc..'\n'..Time_Left;

		
	if (id == 0x28) then
			local actor_id = struct.unpack('I', packet, 0x05 + 1);
			--print(AshitaCore:GetDataManager():GetEntity():GetName(actor_id))
			
				
			local target_count = struct.unpack('b', packet, 0x09 + 1);
			
			-- holds the bitOffset for unpacking bits
			local bitOffset = 82;

			-- unpack the action type
			-- 82 bits in. 0x0A:0x02 = 82
			-- action type is 4 bits wide
			local action_type = ashita.bits.unpack_be(packet, bitOffset, 4);
			-- adjust the offset
			bitOffset = bitOffset + 4;

			-- adjust the bitOffset
			bitOffset = bitOffset + 64;
			
			-- get the spell id
			local action_used = ashita.bits.unpack_be(packet, 86, 10);
			
			-- create our targets table, empty
			local targets = { };

			-- loop through how many targets there are
			for x = 1, target_count do
				-- empty target
				targets[x] = { };

				-- get the id of the target
				targets[x].id = ashita.bits.unpack_be(packet, bitOffset, 32);
				-- adjust the offset
				bitOffset = bitOffset + 32;


				-- get the action count
				targets[x].action_count = ashita.bits.unpack_be(packet, bitOffset, 4) + 1;
				-- adjust the offset
				bitOffset = bitOffset + 4;
				
				-- empty actions table
				targets[x].actions = { };
				
			--	for index = 1, 1024, 1 do
			--		local entity_manager = AshitaCore:GetDataManager():GetEntity();
			--		if entity_manager:GetServerId(index) == targets[x].id then
				--	print('we did it')
			--		end
			--	end

				-- loop through the action count
				for i = 1, targets[x].action_count do
					targets[x].actions[i] = { };
					-- get the targets reaction
					targets[x].actions[i].reaction = ashita.bits.unpack_be(packet, bitOffset, 5);
					-- adjust the offset
					bitOffset = bitOffset + 5;

					-- get the targets animation
					targets[x].actions[i].animation = ashita.bits.unpack_be(packet, bitOffset, 12);
					-- adjust the offset
					bitOffset = bitOffset + 12;

					-- get the targets special effect
					targets[x].actions[i].effect = ashita.bits.unpack_be(packet, bitOffset, 7);
					-- adjust the offset
					bitOffset = bitOffset + 7;

					-- get the targets knockback
					targets[x].actions[i].knockback = ashita.bits.unpack_be(packet, bitOffset, 3);
					-- adjust the offset
					bitOffset = bitOffset + 3;

					-- get the targets param
					-- use for damage debuffs (dia, bio, helix, blue magic)
					targets[x].actions[i].param = ashita.bits.unpack_be(packet, bitOffset, 17);
					-- adjust the offset
					bitOffset = bitOffset + 17;
					-- simplify name
					act_param = targets[x].actions[i].param
					scid = targets[x].actions[i].add_effect
					-- get the targets message id
					-- use for all normal debuffs (paralyze, slow, silence)
					targets[x].actions[i].message_id = ashita.bits.unpack_be(packet, bitOffset, 10);
					-- adjust the offset
					bitOffset = bitOffset + 10;

					-- adjust the offset manually
					bitOffset = bitOffset + 31;
					actmsg = targets[x].actions[i].message_id
					-- get if there is a subeffect. 0 = false 1 = true
					targets[x].actions[i].subeffect = ashita.bits.unpack_be(packet, bitOffset, 1);
					-- adjust the offset
					bitOffset = bitOffset + 1;
					subeffect = targets[x].actions[i].subeffect
					-- check if there's a sub effect
					-- use this for SC
					if (targets[x].actions[i].subeffect == 1) then
						-- get the targets add_effect
						targets[x].actions[i].add_effect = ashita.bits.unpack_be(packet, bitOffset, 10);
						-- adjust the offset
						bitOffset = bitOffset + 10;
					
						-- get the targets add_effect_param
						targets[x].actions[i].add_effect_param = ashita.bits.unpack_be(packet, bitOffset, 17);
						-- adjust the offset
						bitOffset = bitOffset + 17;

						-- get the targets add_effect_message
						targets[x].actions[i].add_effect_message = ashita.bits.unpack_be(packet, bitOffset, 10);
						-- adjust the offset
						bitOffset = bitOffset + 10;
					end

					-- get if there is a spikes. 0 = false 1 = true
					targets[x].actions[i].spikes = ashita.bits.unpack_be(packet, bitOffset, 1);
					-- adjust the offset
					bitOffset = bitOffset + 1;

					-- check if there's spikes
					if (targets[x].actions[i].spikes == 1) then
						-- get the targets spikes_effect
						targets[x].actions[i].spikes_effect = ashita.bits.unpack_be(packet, bitOffset, 10);
						-- adjust the offset
						bitOffset = bitOffset + 10;

						-- get the targets spikes_param
						targets[x].actions[i].spikes_param = ashita.bits.unpack_be(packet, bitOffset, 14);
						-- adjust the offset
						bitOffset = bitOffset + 17;

						-- get the targets spikes_message
						targets[x].actions[i].spikes_message = ashita.bits.unpack_be(packet, bitOffset, 10);
						-- adjust the offset
						bitOffset = bitOffset + 10;
					end
				end
			end
		if (actmsg == 185) then
			if (act_param < 255) then
				WS = tostring(weapon_skills[skill_id].en);
				propa = tostring(weapon_skills[skill_id].skillchain_a);
				propb = tostring(weapon_skills[skill_id].skillchain_b);
				propc = tostring(weapon_skills[skill_id].skillchain_c);
				start_time = os.time();
				display_ws:SetVisibility(true);
				display_sc:SetVisibility(false);
			end
			if (subeffect == 1) then
				if (scid >= 1 and scid <= 16) then
					SC = tostring(skillchains[scid].name);
					ele1 = tostring(skillchains[scid].element1);
					ele2 = tostring(skillchains[scid].element2);
					ele3 = tostring(skillchains[scid].element3);
					ele4 = tostring(skillchains[scid].element4);
					display_sc:SetVisibility(true);
					display_ws:SetVisibility(false);
					if (tracked_skillchain == nil) then
						tracked_skillchain[1] = SC;
					else
					tracked_skillchain[#tracked_skillchain + 1] = SC;
					end
					start_time = os.time();
				end
			end
		elseif (subeffect == 1) then
			if (scid >= 1 and scid <= 16) then
			SC = tostring(skillchains[scid].name);
			ele1 = tostring(skillchains[scid].element1);
			ele2 = tostring(skillchains[scid].element2);
			ele3 = tostring(skillchains[scid].element3);
			ele4 = tostring(skillchains[scid].element4);
			display_sc:SetVisibility(true);
			display_ws:SetVisibility(false);
			if (tracked_skillchain[1] == nil) then
				tracked_skillchain[1] = SC;
			else
				tracked_skillchain[#tracked_skillchain + 1] = SC;
			end
			start_time = os.time();
		end
		end
	end
end);

skillchains = 
{
[1] = {id=1,name='Light',element1='Light',element2='Fire',element3='Thunder',element4='Wind'},
[2] = {id=2,name='Darkness',element1='Dark',element2='Earth',element3='Ice',element4='Water'},
[3] = {id=3,name='Gravitation',element1='Dark',element2='Earth',element3='N/A',element4='N/A'},
[4] = {id=4,name='Fragmentation',element1='Thunder',element2='Wind',element3='N/A',element4='N/A'},
[5] = {id=5,name='Distortion',element1='Ice',element2='Water',element3='N/A',element4='N/A'},
[6] = {id=6,name='Fusion',element1='Light',element2='Fire',element3='N/A',element4='N/A'},
[7] = {id=7,name='Compression',element1='Dark',element2='N/A',element3='N/A',element4='N/A'},
[8] = {id=8,name='Liquefaction',element1='Fire',element2='N/A',element3='N/A',element4='N/A'},
[9] = {id=9,name='Induration',element1='Ice',element2='N/A',element3='N/A',element4='N/A'},
[10] = {id=10,name='Reverberation',element1='Water',element2='N/A',element3='N/A',element4='N/A'},
[11] = {id=11,name='Transfixion',element1='Light',element2='N/A',element3='N/A',element4='N/A'},
[12] = {id=12,name='Scission',element1='Earth',element2='N/A',element3='N/A',element4='N/A'},
[13] = {id=13,name='Detonation',element1='Wind',element2='N/A',element3='N/A',element4='N/A'},
[14] = {id=14,name='Impaction',element1='Thunder',element2='N/A',element3='N/A',element4='N/A'},
[15] = {id=15,name='Radiance',element1='Light',element2='Fire',element3='Thunder',element4='Wind'},
[16] = {id=16,name='Umbra',element1='Dark',element2='Earth',element3='Ice',element4='Water'},
};

monsterskill_properties = 
{
	
};

magic_spell_properties =
{
	[144] = {id=144,en="Fire",skillchain_a="Liquefaction",skillchain_b="",skillchain_c=""},
    [145] = {id=145,en="Fire II",skillchain_a="Liquefaction",skillchain_b="",skillchain_c=""},
    [146] = {id=146,en="Fire III",skillchain_a="Liquefaction",skillchain_b="",skillchain_c=""},
    [147] = {id=147,en="Fire IV",skillchain_a="Liquefaction",skillchain_b="",skillchain_c=""},
    [148] = {id=148,en="Fire V",skillchain_a="Liquefaction",skillchain_b="",skillchain_c=""},
    [149] = {id=149,en="Blizzard",skillchain_a="Induration",skillchain_b="",skillchain_c=""},
    [150] = {id=150,en="Blizzard II",skillchain_a="Induration",skillchain_b="",skillchain_c=""},
    [151] = {id=151,en="Blizzard III",skillchain_a="Induration",skillchain_b="",skillchain_c=""},
    [152] = {id=152,en="Blizzard IV",skillchain_a="Induration",skillchain_b="",skillchain_c=""},
    [153] = {id=153,en="Blizzard V",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [154] = {id=154,en="Aero",skillchain_a="Detonation",skillchain_b="",skillchain_c=""},
    [155] = {id=155,en="Aero II",skillchain_a="Detonation",skillchain_b="",skillchain_c=""},
    [156] = {id=156,en="Aero III",skillchain_a="Detonation",skillchain_b="",skillchain_c=""},
    [157] = {id=157,en="Aero IV",skillchain_a="Detonation",skillchain_b="",skillchain_c=""},
    [158] = {id=158,en="Aero V",skillchain_a="Detonation",skillchain_b="",skillchain_c=""},
    [159] = {id=159,en="Stone",skillchain_a="Scission",skillchain_b="",skillchain_c=""},
    [160] = {id=160,en="Stone II",skillchain_a="Scission",skillchain_b="",skillchain_c=""},
    [161] = {id=161,en="Stone III",skillchain_a="Scission",skillchain_b="",skillchain_c=""},
    [162] = {id=162,en="Stone IV",skillchain_a="Scission",skillchain_b="",skillchain_c=""},
    [163] = {id=163,en="Stone V",skillchain_a="Scission",skillchain_b="",skillchain_c=""},
    [164] = {id=164,en="Thunder",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [165] = {id=165,en="Thunder II",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [166] = {id=166,en="Thunder III",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [167] = {id=167,en="Thunder IV",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [168] = {id=168,en="Thunder V",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [169] = {id=169,en="Water",skillchain_a="Reverberation",skillchain_b="",skillchain_c=""},
    [170] = {id=170,en="Water II",skillchain_a="Reverberation",skillchain_b="",skillchain_c=""},
    [171] = {id=171,en="Water III",skillchain_a="Reverberation",skillchain_b="",skillchain_c=""},
    [172] = {id=172,en="Water IV",skillchain_a="Reverberation",skillchain_b="",skillchain_c=""},
    [173] = {id=173,en="Water V",skillchain_a="Reverberation",skillchain_b="",skillchain_c=""},
	[278] = {id=278,en="Geohelix",skillchain_a="Scission",skillchain_b="",skillchain_c=""},
    [279] = {id=279,en="Hydrohelix",skillchain_a="Reverberation",skillchain_b="",skillchain_c=""},
    [280] = {id=280,en="Anemohelix",skillchain_a="Detonation",skillchain_b="",skillchain_c=""},
    [281] = {id=281,en="Pyrohelix",skillchain_a="Liquefaction",skillchain_b="",skillchain_c=""},
    [282] = {id=282,en="Cryohelix",skillchain_a="Induration",skillchain_b="",skillchain_c=""},
    [283] = {id=283,en="Ionohelix",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [284] = {id=284,en="Noctohelix",skillchain_a="Compression",skillchain_b="",skillchain_c=""},
    [285] = {id=285,en="Luminohelix",skillchain_a="Transfixion",skillchain_b="",skillchain_c=""},
    [503] = {id=503,en="Impact",skillchain_a="Compression",skillchain_b="",skillchain_c=""},
	[665] = {id=665,en="Final Sting",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [666] = {id=666,en="Goblin Rush",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [667] = {id=667,en="Vanity Dive",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[669] = {id=669,en="Whirl of Rage",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[670] = {id=670,en="Benthic Typhoon",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[673] = {id=673,en="Quad. Continuum",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[682] = {id=682,en="Delta Thrust",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[688] = {id=688,en="Heavy Strike",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[692] = {id=692,en="Sudden Lunge",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[693] = {id=693,en="Quadrastrike",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[697] = {id=697,en="Amorphic Spikes",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[699] = {id=699,en="Barbed Crescent",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[704] = {id=704,en="Paralyzing Triad",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[709] = {id=709,en="Thrashing Assault",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[714] = {id=714,en="Sinker Drill",skillchain_a="Gravitation",skillchain_b="",skillchain_c=""},
	[723] = {id=723,en="Saurian Slide",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
	[740] = {id=740,en="Tourbillion",skillchain_a="Light",skillchain_b="",skillchain_c=""},
	[742] = {id=742,en="Bilgestorm",skillchain_a="Darkness",skillchain_b="",skillchain_c=""},
	[743] = {id=743,en="Bloodrake",skillchain_a="Darkness",skillchain_b="",skillchain_c=""},
	[885] = {id=885,en="Geohelix II",skillchain_a="Scission",skillchain_b="",skillchain_c=""},
    [886] = {id=886,en="Hydrohelix II",skillchain_a="Reverberation",skillchain_b="",skillchain_c=""},
    [887] = {id=887,en="Anemohelix II",skillchain_a="Detonation",skillchain_b="",skillchain_c=""},
    [888] = {id=888,en="Pyrohelix II",skillchain_a="Liquefaction",skillchain_b="",skillchain_c=""},
    [889] = {id=889,en="Cryohelix II",skillchain_a="Induration",skillchain_b="",skillchain_c=""},
    [890] = {id=890,en="Ionohelix II",skillchain_a="Impaction",skillchain_b="",skillchain_c=""},
    [891] = {id=891,en="Noctohelix II",skillchain_a="Compression",skillchain_b="",skillchain_c=""},
    [892] = {id=892,en="Luminohelix II",skillchain_a="Transfixion",skillchain_b="",skillchain_c=""}
};
