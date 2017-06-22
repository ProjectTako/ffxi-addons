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
        position    = { 1000, 500 },
        bgcolor     = 0x80000000,
        bgvisible   = true,
    }
};
start_time = os.time()
local exConfig = default_config;
local tracked_skillchain = 
{
	
};
-- Stores Physical Blue Magic that meets the requirements of SCing under CA or Azure Lure
local tracked_CA =
{
	
};
local tracked_AL =
{

};
-- Store Elemental  Maigc that were casted under Immamenence
local tracked_Immanence = 
{

};
ashita.register_event('load', function()
	-- load the config
	exConfig = ashita.settings.load_merged(_addon.path .. 'settings/settings.json', exConfig);

	-- create our test on screen objects
		 display_ws = AshitaCore:GetFontManager():Create('display_ws');
		 display_sc = AshitaCore:GetFontManager():Create('display_sc');

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
ashita.register_event('unload', function()
	-- Get the font object..

	AshitaCore:GetFontManager():Delete('display_ws');
	AshitaCore:GetFontManager():Delete('display_sc');
	
end);
ashita.register_event('prerender', function()
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

		
		prev_SC = SC;
		Last_Skillchain = 'Last Skillchain: '..prev_SC..'\n'..'--------------------------------------'..'\n'..'Elements: '..'\n'..ele1..' | '..ele2..'\n'..ele3..' | '..ele4..'\n'..Time_Left;
		
		prev_WS = WS;
		Last_WS = 'Last Weaponskill: '..prev_WS..'\n'..'-----------------------------------'..'\n'..'Property A: '..propa..'\n'..'Property B: '..propb..'\n'..'Property C: '..propc..'\n'..Time_Left;
		
		display_ws = AshitaCore:GetFontManager():Get('display_ws');
		display_sc = AshitaCore:GetFontManager():Get('display_sc');
		display_sc:SetText(Last_Skillchain);
		display_ws:SetText(Last_WS);
end);

ashita.register_event('incoming_packet', function(id, size, packet)

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
		local spell_id = ashita.bits.unpack_be(packet, 86, 10);
		
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
				-- get the targets message id
				-- use for all normal debuffs (paralyze, slow, silence)
				targets[x].actions[i].message_id = ashita.bits.unpack_be(packet, bitOffset, 10);
				-- adjust the offset
				bitOffset = bitOffset + 10;

				-- adjust the offset manually
				bitOffset = bitOffset + 31;

				-- get if there is a subeffect. 0 = false 1 = true
				targets[x].actions[i].subeffect = ashita.bits.unpack_be(packet, bitOffset, 1);
				-- adjust the offset
				bitOffset = bitOffset + 1;
				
				-- check if there's a sub effect
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
		--or index,value in pairs(targets) do
			for index, value in pairs(targets) do
			if (action_type == 3 or action_type == 4) then
			local scid = value.actions[1].add_effect
			if (value.actions[1].message_id == 185) then
			if (spell_id < 255) then
				WS = tostring(weapon_skills[spell_id].en);
				propa = tostring(weapon_skills[spell_id].skillchain_a);
				propb = tostring(weapon_skills[spell_id].skillchain_b);
				propc = tostring(weapon_skills[spell_id].skillchain_c);
				start_time = os.time();
				display_ws:SetVisibility(true);
				display_sc:SetVisibility(false);
			end
			if (value.actions[1].subeffect == 1) then
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
			elseif (value.actions[1].subeffect == 1) then
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
	--end
	end
	end
	end
	return false;
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
weapon_skills =   
{
	[1] = {id=1,en="Combo",ja="コンボ",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [2] = {id=2,en="Shoulder Tackle",ja="タックル",element=4,icon_id=591,prefix="/weaponskill",range=2,skill=1,skillchain_a="Impaction",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [3] = {id=3,en="One Inch Punch",ja="短勁",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Compression",skillchain_b="",skillchain_c="",targets=32},
    [4] = {id=4,en="Backhand Blow",ja="バックハンドブロー",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Detonation",skillchain_b="",skillchain_c="",targets=32},
    [5] = {id=5,en="Raging Fists",ja="乱撃",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [6] = {id=6,en="Spinning Attack",ja="スピンアタック",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Liquefaction",skillchain_b="Impaction",skillchain_c="",targets=32},
    [7] = {id=7,en="Howling Fist",ja="空鳴拳",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Transfixion",skillchain_b="Impaction",skillchain_c="",targets=32},
    [8] = {id=8,en="Dragon Kick",ja="双竜脚",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Fragmentation",skillchain_b="",skillchain_c="",targets=32},
    [9] = {id=9,en="Asuran Fists",ja="夢想阿修羅拳",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Gravitation",skillchain_b="Liquefaction",skillchain_c="",targets=32},
    [10] = {id=10,en="Final Heaven",ja="ファイナルヘヴン",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Light",skillchain_b="Fusion",skillchain_c="",targets=32},
    [11] = {id=11,en="Ascetic's Fury",ja="アスケーテンツォルン",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Fusion",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [12] = {id=12,en="Stringing Pummel",ja="連環六合圏",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Gravitation",skillchain_b="Liquefaction",skillchain_c="",targets=32},
    [13] = {id=13,en="Tornado Kick",ja="闘魂旋風脚",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Induration",skillchain_b="Impaction",skillchain_c="Detonation",targets=32},
    [14] = {id=14,en="Victory Smite",ja="ビクトリースマイト",element=6,icon_id=590,prefix="/weaponskill",range=2,skill=1,skillchain_a="Light",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [15] = {id=15,en="Shijin Spiral",ja="四神円舞",element=0,icon_id=592,prefix="/weaponskill",range=2,skill=1,skillchain_a="Fusion",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [16] = {id=16,en="Wasp Sting",ja="ワスプスティング",element=5,icon_id=593,prefix="/weaponskill",range=2,skill=2,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [17] = {id=17,en="Viper Bite",ja="バイパーバイト",element=5,icon_id=593,prefix="/weaponskill",range=2,skill=2,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [18] = {id=18,en="Shadowstitch",ja="シャドーステッチ",element=1,icon_id=594,prefix="/weaponskill",range=2,skill=2,skillchain_a="Reverberation",skillchain_b="",skillchain_c="",targets=32},
    [19] = {id=19,en="Gust Slash",ja="ガストスラッシュ",element=2,icon_id=595,prefix="/weaponskill",range=10,skill=2,skillchain_a="Detonation",skillchain_b="",skillchain_c="",targets=32},
    [20] = {id=20,en="Cyclone",ja="サイクロン",element=2,icon_id=595,prefix="/weaponskill",range=10,skill=2,skillchain_a="Detonation",skillchain_b="Impaction",skillchain_c="",targets=32},
    [21] = {id=21,en="Energy Steal",ja="エナジースティール",element=7,icon_id=596,prefix="/weaponskill",range=2,skill=2,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [22] = {id=22,en="Energy Drain",ja="エナジードレイン",element=7,icon_id=596,prefix="/weaponskill",range=2,skill=2,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [23] = {id=23,en="Dancing Edge",ja="ダンシングエッジ",element=6,icon_id=597,prefix="/weaponskill",range=2,skill=2,skillchain_a="Scission",skillchain_b="Detonation",skillchain_c="",targets=32},
    [24] = {id=24,en="Shark Bite",ja="シャークバイト",element=6,icon_id=597,prefix="/weaponskill",range=2,skill=2,skillchain_a="Fragmentation",skillchain_b="",skillchain_c="",targets=32},
    [25] = {id=25,en="Evisceration",ja="エヴィサレーション",element=6,icon_id=597,prefix="/weaponskill",range=2,skill=2,skillchain_a="Gravitation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [26] = {id=26,en="Mercy Stroke",ja="マーシーストローク",element=6,icon_id=597,prefix="/weaponskill",range=2,skill=2,skillchain_a="Darkness",skillchain_b="Gravitation",skillchain_c="",targets=32},
    [27] = {id=27,en="Mandalic Stab",ja="マンダリクスタッブ",element=6,icon_id=597,prefix="/weaponskill",range=2,skill=2,skillchain_a="Fusion",skillchain_b="Compression",skillchain_c="",targets=32},
    [28] = {id=28,en="Mordant Rime",ja="モーダントライム",element=2,icon_id=595,prefix="/weaponskill",range=2,skill=2,skillchain_a="Fragmentation",skillchain_b="Distortion",skillchain_c="",targets=32},
    [29] = {id=29,en="Pyrrhic Kleos",ja="ピリッククレオス",element=1,icon_id=594,prefix="/weaponskill",range=2,skill=2,skillchain_a="Distortion",skillchain_b="Scission",skillchain_c="",targets=32},
    [30] = {id=30,en="Aeolian Edge",ja="イオリアンエッジ",element=2,icon_id=595,prefix="/weaponskill",range=2,skill=2,skillchain_a="Impaction",skillchain_b="Scission",skillchain_c="Detonation",targets=32},
    [31] = {id=31,en="Rudra's Storm",ja="ルドラストーム",element=2,icon_id=595,prefix="/weaponskill",range=2,skill=2,skillchain_a="Darkness",skillchain_b="Distortion",skillchain_c="",targets=32},
    [32] = {id=32,en="Fast Blade",ja="ファストブレード",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [33] = {id=33,en="Burning Blade",ja="バーニングブレード",element=0,icon_id=599,prefix="/weaponskill",range=2,skill=3,skillchain_a="Liquefaction",skillchain_b="",skillchain_c="",targets=32},
    [34] = {id=34,en="Red Lotus Blade",ja="レッドロータス",element=0,icon_id=599,prefix="/weaponskill",range=2,skill=3,skillchain_a="Liquefaction",skillchain_b="Detonation",skillchain_c="",targets=32},
    [35] = {id=35,en="Flat Blade",ja="フラットブレード",element=4,icon_id=600,prefix="/weaponskill",range=2,skill=3,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [36] = {id=36,en="Shining Blade",ja="シャインブレード",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [37] = {id=37,en="Seraph Blade",ja="セラフブレード",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [38] = {id=38,en="Circle Blade",ja="サークルブレード",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Reverberation",skillchain_b="Impaction",skillchain_c="",targets=32},
    [39] = {id=39,en="Spirits Within",ja="スピリッツウィズイン",element=15,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [40] = {id=40,en="Vorpal Blade",ja="ボーパルブレード",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Scission",skillchain_b="Impaction",skillchain_c="",targets=32},
    [41] = {id=41,en="Swift Blade",ja="スウィフトブレード",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Gravitation",skillchain_b="",skillchain_c="",targets=32},
    [42] = {id=42,en="Savage Blade",ja="サベッジブレード",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Fragmentation",skillchain_b="Scission",skillchain_c="",targets=32},
    [43] = {id=43,en="Knights of Round",ja="ナイツオブラウンド",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Light",skillchain_b="Fusion",skillchain_c="",targets=32},
    [44] = {id=44,en="Death Blossom",ja="ロズレーファタール",element=4,icon_id=600,prefix="/weaponskill",range=2,skill=3,skillchain_a="Fragmentation",skillchain_b="Distortion",skillchain_c="",targets=32},
    [45] = {id=45,en="Atonement",ja="ロイエ",element=15,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Fusion",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [46] = {id=46,en="Expiacion",ja="エクスピアシオン",element=6,icon_id=598,prefix="/weaponskill",range=2,skill=3,skillchain_a="Distortion",skillchain_b="Scission",skillchain_c="",targets=32},
    [47] = {id=47,en="Sanguine Blade",ja="サンギンブレード",element=7,icon_id=601,prefix="/weaponskill",range=2,skill=3,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [48] = {id=48,en="Hard Slash",ja="ハードスラッシュ",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [49] = {id=49,en="Power Slash",ja="パワースラッシュ",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Transfixion",skillchain_b="",skillchain_c="",targets=32},
    [50] = {id=50,en="Frostbite",ja="フロストバイト",element=1,icon_id=603,prefix="/weaponskill",range=2,skill=4,skillchain_a="Induration",skillchain_b="",skillchain_c="",targets=32},
    [51] = {id=51,en="Freezebite",ja="フリーズバイト",element=1,icon_id=603,prefix="/weaponskill",range=2,skill=4,skillchain_a="Induration",skillchain_b="Detonation",skillchain_c="",targets=32},
    [52] = {id=52,en="Shockwave",ja="ショックウェーブ",element=7,icon_id=604,prefix="/weaponskill",range=2,skill=4,skillchain_a="Reverberation",skillchain_b="",skillchain_c="",targets=32},
    [53] = {id=53,en="Crescent Moon",ja="クレセントムーン",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [54] = {id=54,en="Sickle Moon",ja="シックルムーン",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Scission",skillchain_b="Impaction",skillchain_c="",targets=32},
    [55] = {id=55,en="Spinning Slash",ja="スピンスラッシュ",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Fragmentation",skillchain_b="",skillchain_c="",targets=32},
    [56] = {id=56,en="Ground Strike",ja="グラウンドストライク",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Fragmentation",skillchain_b="Distortion",skillchain_c="",targets=32},
    [57] = {id=57,en="Scourge",ja="スカージ",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Light",skillchain_b="Fusion",skillchain_c="",targets=32},
    [58] = {id=58,en="Herculean Slash",ja="ヘラクレススラッシュ",element=1,icon_id=603,prefix="/weaponskill",range=2,skill=4,skillchain_a="Induration",skillchain_b="Impaction",skillchain_c="Detonation",targets=32},
    [59] = {id=59,en="Torcleaver",ja="トアクリーバー",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Light",skillchain_b="Distortion",skillchain_c="",targets=32},
    [60] = {id=60,en="Resolution",ja="レゾルーション",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Fragmentation",skillchain_b="Scission",skillchain_c="",targets=32},
    [61] = {id=61,en="Dimidiation",ja="デミディエーション",element=6,icon_id=602,prefix="/weaponskill",range=2,skill=4,skillchain_a="Light",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [64] = {id=64,en="Raging Axe",ja="レイジングアクス",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Detonation",skillchain_b="Impaction",skillchain_c="",targets=32},
    [65] = {id=65,en="Smash Axe",ja="スマッシュ",element=4,icon_id=606,prefix="/weaponskill",range=2,skill=5,skillchain_a="Impaction",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [66] = {id=66,en="Gale Axe",ja="ラファールアクス",element=2,icon_id=607,prefix="/weaponskill",range=2,skill=5,skillchain_a="Detonation",skillchain_b="",skillchain_c="",targets=32},
    [67] = {id=67,en="Avalanche Axe",ja="アバランチアクス",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Scission",skillchain_b="Impaction",skillchain_c="",targets=32},
    [68] = {id=68,en="Spinning Axe",ja="スピニングアクス",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Liquefaction",skillchain_b="Scission",skillchain_c="Impaction",targets=32},
    [69] = {id=69,en="Rampage",ja="ランページ",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [70] = {id=70,en="Calamity",ja="カラミティ",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Scission",skillchain_b="Impaction",skillchain_c="",targets=32},
    [71] = {id=71,en="Mistral Axe",ja="ミストラルアクス",element=6,icon_id=605,prefix="/weaponskill",range=10,skill=5,skillchain_a="Fusion",skillchain_b="",skillchain_c="",targets=32},
    [72] = {id=72,en="Decimation",ja="デシメーション",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Fusion",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [73] = {id=73,en="Onslaught",ja="オンスロート",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Darkness",skillchain_b="Gravitation",skillchain_c="",targets=32},
    [74] = {id=74,en="Primal Rend",ja="プライマルレンド",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Gravitation",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [75] = {id=75,en="Bora Axe",ja="ボーラアクス",element=1,icon_id=608,prefix="/weaponskill",range=10,skill=5,skillchain_a="Scission",skillchain_b="Detonation",skillchain_c="",targets=32},
    [76] = {id=76,en="Cloudsplitter",ja="クラウドスプリッタ",element=4,icon_id=606,prefix="/weaponskill",range=2,skill=5,skillchain_a="Darkness",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [77] = {id=77,en="Ruinator",ja="ルイネーター",element=6,icon_id=605,prefix="/weaponskill",range=2,skill=5,skillchain_a="Distortion",skillchain_b="Detonation",skillchain_c="",targets=32},
    [80] = {id=80,en="Shield Break",ja="シールドブレイク",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [81] = {id=81,en="Iron Tempest",ja="アイアンテンペスト",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [82] = {id=82,en="Sturmwind",ja="シュトルムヴィント",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Reverberation",skillchain_b="Scission",skillchain_c="",targets=32},
    [83] = {id=83,en="Armor Break",ja="アーマーブレイク",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [84] = {id=84,en="Keen Edge",ja="キーンエッジ",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Compression",skillchain_b="",skillchain_c="",targets=32},
    [85] = {id=85,en="Weapon Break",ja="ウェポンブレイク",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [86] = {id=86,en="Raging Rush",ja="レイジングラッシュ",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Induration",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [87] = {id=87,en="Full Break",ja="フルブレイク",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Distortion",skillchain_b="",skillchain_c="",targets=32},
    [88] = {id=88,en="Steel Cyclone",ja="スチールサイクロン",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Distortion",skillchain_b="Detonation",skillchain_c="",targets=32},
    [89] = {id=89,en="Metatron Torment",ja="メタトロントーメント",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Light",skillchain_b="Fusion",skillchain_c="",targets=32},
    [90] = {id=90,en="King's Justice",ja="キングズジャスティス",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Fragmentation",skillchain_b="Scission",skillchain_c="",targets=32},
    [91] = {id=91,en="Fell Cleave",ja="フェルクリーヴ",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Scission",skillchain_b="Detonation",skillchain_c="",targets=32},
    [92] = {id=92,en="Ukko's Fury",ja="ウッコフューリー",element=3,icon_id=610,prefix="/weaponskill",range=2,skill=6,skillchain_a="Light",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [93] = {id=93,en="Upheaval",ja="アップヒーバル",element=6,icon_id=609,prefix="/weaponskill",range=2,skill=6,skillchain_a="Fusion",skillchain_b="Compression",skillchain_c="",targets=32},
    [96] = {id=96,en="Slice",ja="スライス",element=6,icon_id=611,prefix="/weaponskill",range=2,skill=7,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [97] = {id=97,en="Dark Harvest",ja="ダークハーベスト",element=7,icon_id=612,prefix="/weaponskill",range=2,skill=7,skillchain_a="Reverberation",skillchain_b="",skillchain_c="",targets=32},
    [98] = {id=98,en="Shadow of Death",ja="シャドーオブデス",element=7,icon_id=612,prefix="/weaponskill",range=2,skill=7,skillchain_a="Induration",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [99] = {id=99,en="Nightmare Scythe",ja="ナイトメアサイス",element=7,icon_id=612,prefix="/weaponskill",range=2,skill=7,skillchain_a="Compression",skillchain_b="Scission",skillchain_c="",targets=32},
    [100] = {id=100,en="Spinning Scythe",ja="スピニングサイス",element=6,icon_id=611,prefix="/weaponskill",range=2,skill=7,skillchain_a="Reverberation",skillchain_b="Scission",skillchain_c="",targets=32},
    [101] = {id=101,en="Vorpal Scythe",ja="ボーパルサイス",element=6,icon_id=611,prefix="/weaponskill",range=2,skill=7,skillchain_a="Transfixion",skillchain_b="Scission",skillchain_c="",targets=32},
    [102] = {id=102,en="Guillotine",ja="ギロティン",element=2,icon_id=613,prefix="/weaponskill",range=2,skill=7,skillchain_a="Induration",skillchain_b="",skillchain_c="",targets=32},
    [103] = {id=103,en="Cross Reaper",ja="クロスリーパー",element=6,icon_id=611,prefix="/weaponskill",range=2,skill=7,skillchain_a="Distortion",skillchain_b="",skillchain_c="",targets=32},
    [104] = {id=104,en="Spiral Hell",ja="スパイラルヘル",element=6,icon_id=611,prefix="/weaponskill",range=2,skill=7,skillchain_a="Distortion",skillchain_b="Scission",skillchain_c="",targets=32},
    [105] = {id=105,en="Catastrophe",ja="カタストロフィ",element=6,icon_id=611,prefix="/weaponskill",range=2,skill=7,skillchain_a="Darkness",skillchain_b="Gravitation",skillchain_c="",targets=32},
    [106] = {id=106,en="Insurgency",ja="インサージェンシー",element=6,icon_id=611,prefix="/weaponskill",range=2,skill=7,skillchain_a="Fusion",skillchain_b="Compression",skillchain_c="",targets=32},
    [107] = {id=107,en="Infernal Scythe",ja="インファナルサイズ",element=7,icon_id=612,prefix="/weaponskill",range=2,skill=7,skillchain_a="Compression",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [108] = {id=108,en="Quietus",ja="クワイタス",element=7,icon_id=612,prefix="/weaponskill",range=2,skill=7,skillchain_a="Darkness",skillchain_b="Distortion",skillchain_c="",targets=32},
    [109] = {id=109,en="Entropy",ja="エントロピー",element=7,icon_id=612,prefix="/weaponskill",range=2,skill=7,skillchain_a="Gravitation",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [112] = {id=112,en="Double Thrust",ja="ダブルスラスト",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Transfixion",skillchain_b="",skillchain_c="",targets=32},
    [113] = {id=113,en="Thunder Thrust",ja="サンダースラスト",element=4,icon_id=615,prefix="/weaponskill",range=2,skill=8,skillchain_a="Transfixion",skillchain_b="Impaction",skillchain_c="",targets=32},
    [114] = {id=114,en="Raiden Thrust",ja="ライデンスラスト",element=4,icon_id=615,prefix="/weaponskill",range=2,skill=8,skillchain_a="Transfixion",skillchain_b="Impaction",skillchain_c="",targets=32},
    [115] = {id=115,en="Leg Sweep",ja="足払い",element=4,icon_id=615,prefix="/weaponskill",range=2,skill=8,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [116] = {id=116,en="Penta Thrust",ja="ペンタスラスト",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Compression",skillchain_b="",skillchain_c="",targets=32},
    [117] = {id=117,en="Vorpal Thrust",ja="ボーパルスラスト",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Reverberation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [118] = {id=118,en="Skewer",ja="スキュアー",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Transfixion",skillchain_b="Impaction",skillchain_c="",targets=32},
    [119] = {id=119,en="Wheeling Thrust",ja="大車輪",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Fusion",skillchain_b="",skillchain_c="",targets=32},
    [120] = {id=120,en="Impulse Drive",ja="インパルスドライヴ",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Gravitation",skillchain_b="Induration",skillchain_c="",targets=32},
    [121] = {id=121,en="Geirskogul",ja="ゲイルスコグル",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Light",skillchain_b="Distortion",skillchain_c="",targets=32},
    [122] = {id=122,en="Drakesbane",ja="雲蒸竜変",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Fusion",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [123] = {id=123,en="Sonic Thrust",ja="ソニックスラスト",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Transfixion",skillchain_b="Scission",skillchain_c="",targets=32},
    [124] = {id=124,en="Camlann's Torment",ja="カムラン",element=6,icon_id=614,prefix="/weaponskill",range=2,skill=8,skillchain_a="Light",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [125] = {id=125,en="Stardiver",ja="スターダイバー",element=3,icon_id=616,prefix="/weaponskill",range=2,skill=8,skillchain_a="Gravitation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [128] = {id=128,en="Blade: Rin",ja="臨",element=6,icon_id=617,prefix="/weaponskill",range=2,skill=9,skillchain_a="Transfixion",skillchain_b="",skillchain_c="",targets=32},
    [129] = {id=129,en="Blade: Retsu",ja="烈",element=1,icon_id=618,prefix="/weaponskill",range=2,skill=9,skillchain_a="Scission",skillchain_b="",skillchain_c="",targets=32},
    [130] = {id=130,en="Blade: Teki",ja="滴",element=5,icon_id=619,prefix="/weaponskill",range=2,skill=9,skillchain_a="Reverberation",skillchain_b="",skillchain_c="",targets=32},
    [131] = {id=131,en="Blade: To",ja="凍",element=1,icon_id=618,prefix="/weaponskill",range=2,skill=9,skillchain_a="Induration",skillchain_b="Detonation",skillchain_c="",targets=32},
    [132] = {id=132,en="Blade: Chi",ja="地",element=3,icon_id=620,prefix="/weaponskill",range=2,skill=9,skillchain_a="Impaction",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [133] = {id=133,en="Blade: Ei",ja="影",element=7,icon_id=621,prefix="/weaponskill",range=2,skill=9,skillchain_a="Compression",skillchain_b="",skillchain_c="",targets=32},
    [134] = {id=134,en="Blade: Jin",ja="迅",element=6,icon_id=617,prefix="/weaponskill",range=2,skill=9,skillchain_a="Impaction",skillchain_b="Detonation",skillchain_c="",targets=32},
    [135] = {id=135,en="Blade: Ten",ja="天",element=6,icon_id=617,prefix="/weaponskill",range=2,skill=9,skillchain_a="Gravitation",skillchain_b="",skillchain_c="",targets=32},
    [136] = {id=136,en="Blade: Ku",ja="空",element=6,icon_id=617,prefix="/weaponskill",range=2,skill=9,skillchain_a="Gravitation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [137] = {id=137,en="Blade: Metsu",ja="生者必滅",element=6,icon_id=617,prefix="/weaponskill",range=2,skill=9,skillchain_a="Darkness",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [138] = {id=138,en="Blade: Kamu",ja="カムハブリ",element=3,icon_id=620,prefix="/weaponskill",range=2,skill=9,skillchain_a="Fragmentation",skillchain_b="Compression",skillchain_c="",targets=32},
    [139] = {id=139,en="Blade: Yu",ja="湧",element=5,icon_id=619,prefix="/weaponskill",range=2,skill=9,skillchain_a="Reverberation",skillchain_b="Scission",skillchain_c="",targets=32},
    [140] = {id=140,en="Blade: Hi",ja="秘",element=6,icon_id=617,prefix="/weaponskill",range=2,skill=9,skillchain_a="Darkness",skillchain_b="Gravitation",skillchain_c="",targets=32},
    [141] = {id=141,en="Blade: Shun",ja="瞬",element=6,icon_id=617,prefix="/weaponskill",range=2,skill=9,skillchain_a="Fusion",skillchain_b="Impaction",skillchain_c="",targets=32},
    [144] = {id=144,en="Tachi: Enpi",ja="壱之太刀・燕飛",element=6,icon_id=622,prefix="/weaponskill",range=2,skill=10,skillchain_a="Transfixion",skillchain_b="Scission",skillchain_c="",targets=32},
    [145] = {id=145,en="Tachi: Hobaku",ja="弐之太刀・鋒縛",element=4,icon_id=623,prefix="/weaponskill",range=2,skill=10,skillchain_a="Induration",skillchain_b="",skillchain_c="",targets=32},
    [146] = {id=146,en="Tachi: Goten",ja="参之太刀・轟天",element=4,icon_id=623,prefix="/weaponskill",range=2,skill=10,skillchain_a="Transfixion",skillchain_b="Impaction",skillchain_c="",targets=32},
    [147] = {id=147,en="Tachi: Kagero",ja="四之太刀・陽炎",element=0,icon_id=624,prefix="/weaponskill",range=2,skill=10,skillchain_a="Liquefaction",skillchain_b="",skillchain_c="",targets=32},
    [148] = {id=148,en="Tachi: Jinpu",ja="五之太刀・陣風",element=2,icon_id=625,prefix="/weaponskill",range=2,skill=10,skillchain_a="Scission",skillchain_b="Detonation",skillchain_c="",targets=32},
    [149] = {id=149,en="Tachi: Koki",ja="六之太刀・光輝",element=6,icon_id=622,prefix="/weaponskill",range=2,skill=10,skillchain_a="Reverberation",skillchain_b="Impaction",skillchain_c="",targets=32},
    [150] = {id=150,en="Tachi: Yukikaze",ja="七之太刀・雪風",element=7,icon_id=626,prefix="/weaponskill",range=2,skill=10,skillchain_a="Induration",skillchain_b="Detonation",skillchain_c="",targets=32},
    [151] = {id=151,en="Tachi: Gekko",ja="八之太刀・月光",element=2,icon_id=625,prefix="/weaponskill",range=2,skill=10,skillchain_a="Distortion",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [152] = {id=152,en="Tachi: Kasha",ja="九之太刀・花車",element=1,icon_id=627,prefix="/weaponskill",range=2,skill=10,skillchain_a="Fusion",skillchain_b="Compression",skillchain_c="",targets=32},
    [153] = {id=153,en="Tachi: Kaiten",ja="零之太刀・回天",element=6,icon_id=622,prefix="/weaponskill",range=2,skill=10,skillchain_a="Light",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [154] = {id=154,en="Tachi: Rana",ja="十之太刀・乱鴉",element=6,icon_id=622,prefix="/weaponskill",range=2,skill=10,skillchain_a="Gravitation",skillchain_b="Induration",skillchain_c="",targets=32},
    [155] = {id=155,en="Tachi: Ageha",ja="十一之太刀・鳳蝶",element=2,icon_id=625,prefix="/weaponskill",range=2,skill=10,skillchain_a="Compression",skillchain_b="Scission",skillchain_c="",targets=32},
    [156] = {id=156,en="Tachi: Fudo",ja="祖之太刀・不動",element=6,icon_id=622,prefix="/weaponskill",range=2,skill=10,skillchain_a="Light",skillchain_b="Distortion",skillchain_c="",targets=32},
    [157] = {id=157,en="Tachi: Shoha",ja="十二之太刀・照破",element=6,icon_id=622,prefix="/weaponskill",range=2,skill=10,skillchain_a="Fragmentation",skillchain_b="Compression",skillchain_c="",targets=32},
    [160] = {id=160,en="Shining Strike",ja="シャインストライク",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [161] = {id=161,en="Seraph Strike",ja="セラフストライク",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [162] = {id=162,en="Brainshaker",ja="ブレインシェイカー",element=4,icon_id=629,prefix="/weaponskill",range=2,skill=11,skillchain_a="Reverberation",skillchain_b="",skillchain_c="",targets=32},
    [163] = {id=163,en="Starlight",ja="スターライト",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="",skillchain_b="",skillchain_c="",targets=1},
    [164] = {id=164,en="Moonlight",ja="ムーンライト",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="",skillchain_b="",skillchain_c="",targets=1},
    [165] = {id=165,en="Skullbreaker",ja="スカルブレイカー",element=0,icon_id=630,prefix="/weaponskill",range=2,skill=11,skillchain_a="Induration",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [166] = {id=166,en="True Strike",ja="トゥルーストライク",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Detonation",skillchain_b="Impaction",skillchain_c="",targets=32},
    [167] = {id=167,en="Judgment",ja="ジャッジメント",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [168] = {id=168,en="Hexa Strike",ja="ヘキサストライク",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Fusion",skillchain_b="",skillchain_c="",targets=32},
    [169] = {id=169,en="Black Halo",ja="ブラックヘイロー",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Fragmentation",skillchain_b="Compression",skillchain_c="",targets=32},
    [170] = {id=170,en="Randgrith",ja="ランドグリース",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Light",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [171] = {id=171,en="Mystic Boon",ja="ミスティックブーン",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [172] = {id=172,en="Flash Nova",ja="フラッシュノヴァ",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Induration",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [173] = {id=173,en="Dagan",ja="ダガン",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="",skillchain_b="",skillchain_c="",targets=1},
    [174] = {id=174,en="Realmrazer",ja="レルムレイザー",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Fusion",skillchain_b="Impaction",skillchain_c="",targets=32},
    [175] = {id=175,en="Exudation",ja="エクズデーション",element=6,icon_id=628,prefix="/weaponskill",range=2,skill=11,skillchain_a="Darkness",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [176] = {id=176,en="Heavy Swing",ja="ヘヴィスイング",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [177] = {id=177,en="Rock Crusher",ja="ロッククラッシャー",element=3,icon_id=632,prefix="/weaponskill",range=2,skill=12,skillchain_a="Impaction",skillchain_b="",skillchain_c="",targets=32},
    [178] = {id=178,en="Earth Crusher",ja="アースクラッシャー",element=3,icon_id=632,prefix="/weaponskill",range=2,skill=12,skillchain_a="Detonation",skillchain_b="Impaction",skillchain_c="",targets=32},
    [179] = {id=179,en="Starburst",ja="スターバースト",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="Compression",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [180] = {id=180,en="Sunburst",ja="サンバースト",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="Compression",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [181] = {id=181,en="Shell Crusher",ja="シェルクラッシャー",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="Detonation",skillchain_b="",skillchain_c="",targets=32},
    [182] = {id=182,en="Full Swing",ja="フルスイング",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="Liquefaction",skillchain_b="Impaction",skillchain_c="",targets=32},
    [183] = {id=183,en="Spirit Taker",ja="スピリットテーカー",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [184] = {id=184,en="Retribution",ja="レトリビューション",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="Gravitation",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [185] = {id=185,en="Gate of Tartarus",ja="タルタロスゲート",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="Darkness",skillchain_b="Distortion",skillchain_c="",targets=32},
    [186] = {id=186,en="Vidohunir",ja="ヴィゾフニル",element=7,icon_id=633,prefix="/weaponskill",range=2,skill=12,skillchain_a="Fragmentation",skillchain_b="Distortion",skillchain_c="",targets=32},
    [187] = {id=187,en="Garland of Bliss",ja="ガーランドオブブリス",element=6,icon_id=631,prefix="/weaponskill",range=2,skill=12,skillchain_a="Fusion",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [188] = {id=188,en="Omniscience",ja="オムニシエンス",element=7,icon_id=633,prefix="/weaponskill",range=2,skill=12,skillchain_a="Gravitation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [189] = {id=189,en="Cataclysm",ja="カタクリスム",element=7,icon_id=633,prefix="/weaponskill",range=2,skill=12,skillchain_a="Compression",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [190] = {id=190,en="Myrkr",ja="ミルキル",element=7,icon_id=633,prefix="/weaponskill",range=2,skill=12,skillchain_a="",skillchain_b="",skillchain_c="",targets=1},
    [191] = {id=191,en="Shattersoul",ja="シャッターソウル",element=4,icon_id=634,prefix="/weaponskill",range=2,skill=12,skillchain_a="Gravitation",skillchain_b="Induration",skillchain_c="",targets=32},
    [192] = {id=192,en="Flaming Arrow",ja="フレイミングアロー",element=0,icon_id=635,prefix="/weaponskill",range=12,skill=25,skillchain_a="Liquefaction",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [193] = {id=193,en="Piercing Arrow",ja="ピアシングアロー",element=2,icon_id=636,prefix="/weaponskill",range=12,skill=25,skillchain_a="Reverberation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [194] = {id=194,en="Dulling Arrow",ja="ダリングアロー",element=0,icon_id=635,prefix="/weaponskill",range=12,skill=25,skillchain_a="Liquefaction",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [196] = {id=196,en="Sidewinder",ja="サイドワインダー",element=6,icon_id=637,prefix="/weaponskill",range=12,skill=25,skillchain_a="Reverberation",skillchain_b="Transfixion",skillchain_c="Detonation",targets=32},
    [197] = {id=197,en="Blast Arrow",ja="ブラストアロー",element=6,icon_id=637,prefix="/weaponskill",range=4,skill=25,skillchain_a="Induration",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [198] = {id=198,en="Arching Arrow",ja="アーチングアロー",element=6,icon_id=637,prefix="/weaponskill",range=12,skill=25,skillchain_a="Fusion",skillchain_b="",skillchain_c="",targets=32},
    [199] = {id=199,en="Empyreal Arrow",ja="エンピリアルアロー",element=6,icon_id=637,prefix="/weaponskill",range=12,skill=25,skillchain_a="Fusion",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [200] = {id=200,en="Namas Arrow",ja="南無八幡",element=6,icon_id=637,prefix="/weaponskill",range=12,skill=25,skillchain_a="Light",skillchain_b="Distortion",skillchain_c="",targets=32},
    [201] = {id=201,en="Refulgent Arrow",ja="リフルジェントアロー",element=6,icon_id=637,prefix="/weaponskill",range=12,skill=25,skillchain_a="Reverberation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [202] = {id=202,en="Jishnu's Radiance",ja="ジシュヌの光輝",element=6,icon_id=637,prefix="/weaponskill",range=12,skill=25,skillchain_a="Light",skillchain_b="Fusion",skillchain_c="",targets=32},
    [203] = {id=203,en="Apex Arrow",ja="エイペクスアロー",element=6,icon_id=637,prefix="/weaponskill",range=12,skill=25,skillchain_a="Fragmentation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [208] = {id=208,en="Hot Shot",ja="ホットショット",element=0,icon_id=638,prefix="/weaponskill",range=12,skill=26,skillchain_a="Reverberation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [209] = {id=209,en="Split Shot",ja="スプリットショット",element=2,icon_id=639,prefix="/weaponskill",range=12,skill=26,skillchain_a="Reverberation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [210] = {id=210,en="Sniper Shot",ja="スナイパーショット",element=0,icon_id=638,prefix="/weaponskill",range=12,skill=26,skillchain_a="Liquefaction",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [212] = {id=212,en="Slug Shot",ja="スラッグショット",element=6,icon_id=640,prefix="/weaponskill",range=12,skill=26,skillchain_a="Reverberation",skillchain_b="Transfixion",skillchain_c="Detonation",targets=32},
    [213] = {id=213,en="Blast Shot",ja="ブラストショット",element=6,icon_id=640,prefix="/weaponskill",range=4,skill=26,skillchain_a="Induration",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [214] = {id=214,en="Heavy Shot",ja="ヘヴィショット",element=6,icon_id=640,prefix="/weaponskill",range=12,skill=26,skillchain_a="Fusion",skillchain_b="",skillchain_c="",targets=32},
    [215] = {id=215,en="Detonator",ja="デトネーター",element=6,icon_id=640,prefix="/weaponskill",range=12,skill=26,skillchain_a="Fusion",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [216] = {id=216,en="Coronach",ja="カラナック",element=6,icon_id=640,prefix="/weaponskill",range=12,skill=26,skillchain_a="Darkness",skillchain_b="Fragmentation",skillchain_c="",targets=32},
    [217] = {id=217,en="Trueflight",ja="トゥルーフライト",element=6,icon_id=640,prefix="/weaponskill",range=12,skill=26,skillchain_a="Fragmentation",skillchain_b="Scission",skillchain_c="",targets=32},
    [218] = {id=218,en="Leaden Salute",ja="レデンサリュート",element=7,icon_id=641,prefix="/weaponskill",range=12,skill=26,skillchain_a="Gravitation",skillchain_b="Transfixion",skillchain_c="",targets=32},
    [219] = {id=219,en="Numbing Shot",ja="ナビングショット",element=1,icon_id=642,prefix="/weaponskill",range=4,skill=26,skillchain_a="Induration",skillchain_b="Impaction",skillchain_c="Detonation",targets=32},
    [220] = {id=220,en="Wildfire",ja="ワイルドファイア",element=0,icon_id=638,prefix="/weaponskill",range=12,skill=26,skillchain_a="Darkness",skillchain_b="Gravitation",skillchain_c="",targets=32},
    [221] = {id=221,en="Last Stand",ja="ラストスタンド",element=6,icon_id=640,prefix="/weaponskill",range=12,skill=26,skillchain_a="Fusion",skillchain_b="Reverberation",skillchain_c="",targets=32},
    [224] = {id=224,en="Exenterator",ja="エクゼンテレター",element=3,icon_id=643,prefix="/weaponskill",range=2,skill=2,skillchain_a="Fragmentation",skillchain_b="Scission",skillchain_c="",targets=32},
    [225] = {id=225,en="Chant du Cygne",ja="シャンデュシニュ",element=6,icon_id=644,prefix="/weaponskill",range=2,skill=3,skillchain_a="Light",skillchain_b="Distortion",skillchain_c="",targets=32},
    [226] = {id=226,en="Requiescat",ja="レクイエスカット",element=6,icon_id=644,prefix="/weaponskill",range=2,skill=3,skillchain_a="Gravitation",skillchain_b="Scission",skillchain_c="",targets=32},
    [227] = {id=227,en="Knights of Rotund",ja="ナイスオブラウンド",element=6,icon_id=598,prefix="/weaponskill",range=2,targets=32},
    [238] = {id=238,en="Uriel Blade",ja="ウリエルブレード",element=6,icon_id=645,prefix="/weaponskill",range=2,skill=2,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [239] = {id=239,en="Glory Slash",ja="グローリースラッシュ",element=4,icon_id=646,prefix="/weaponskill",range=2,skill=2,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [240] = {id=240,en="Tartarus Torpor",ja="タルタロストーパー",element=7,icon_id=647,prefix="/weaponskill",range=2,skill=12,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [241] = {id=241,en="Netherspikes",ja="剣山獄",element=6,icon_id=46,prefix="/weaponskill",range=7,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [242] = {id=242,en="Carnal Nightmare",ja="白昼夢",element=6,icon_id=46,prefix="/weaponskill",range=7,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [243] = {id=243,en="Aegis Schism",ja="破鎧陣",element=6,icon_id=46,prefix="/weaponskill",range=7,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [244] = {id=244,en="Dancing Chains",ja="舞空鎖",element=6,icon_id=46,prefix="/weaponskill",range=7,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [245] = {id=245,en="Barbed Crescent",ja="偃月刃",element=6,icon_id=46,prefix="/weaponskill",range=11,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [246] = {id=246,en="Shackled Fists",ja="連環拳",element=6,icon_id=46,prefix="/weaponskill",range=2,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [247] = {id=247,en="Foxfire",ja="跳狐斬",element=6,icon_id=46,prefix="/weaponskill",range=2,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [248] = {id=248,en="Grim Halo",ja="輪天殺",element=6,icon_id=46,prefix="/weaponskill",range=2,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [249] = {id=249,en="Netherspikes",ja="剣山獄",element=6,icon_id=46,prefix="/weaponskill",range=7,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [250] = {id=250,en="Carnal Nightmare",ja="白昼夢",element=6,icon_id=46,prefix="/weaponskill",range=7,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [251] = {id=251,en="Aegis Schism",ja="破鎧陣",element=6,icon_id=46,prefix="/weaponskill",range=7,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [252] = {id=252,en="Dancing Chains",ja="舞空鎖",element=6,icon_id=46,prefix="/weaponskill",range=7,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [253] = {id=253,en="Barbed Crescent",ja="偃月刃",element=6,icon_id=46,prefix="/weaponskill",range=11,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [254] = {id=254,en="Vulcan Shot",ja="バルカンショット",element=6,icon_id=46,prefix="/weaponskill",range=12,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
    [255] = {id=255,en="Dimensional Death",ja="次元殺",element=6,icon_id=46,prefix="/weaponskill",range=2,skillchain_a="",skillchain_b="",skillchain_c="",targets=32},
}, {"id", "en", "ja", "element", "icon_id", "prefix", "range", "skill", "skillchain_a", "skillchain_b", "skillchain_c", "targets"}
