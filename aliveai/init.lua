aliveai={
	character_model="character.b3d",	--character model
	default_team="Sam",
	check_spawn_space=true,
	enable_build=true,
	status=false,			--show bot status
	tools=1,				--hide bot tools
	get_everything_to_build_chance=50,
	get_random_stuff_chance=50,	-- get random stuff on spawn
	max_delay=100,			-- max run / bot delay
	bots_delay=0,
	bots_delay2=0,
	max_new_bots=10,
	team_fight=true,
	lifetimer=60,			--remove unbehavior none nps's
	max_paths_per_s={timer=0,times=10,checked=0},
	msg={},				--messages to bots
	registered_bots={},		--registered_bots
	active={},			--active bots
	active_num=0,			--active bots count
	smartshop=minetest.get_modpath("smartshop")~=nil,
	mesecons=minetest.get_modpath("mesecons")~=nil,
	loaddata={},			--functions
	savedata={},			--functions
	team_player={},
				--staplefood database, add eatable stuff to the list, then can all other bots check if them have something like that to eat when they gets hurted
	staplefood=		{["default:apple"]=2,["farming:bread"]=5,["mobs:meat"]=8,["mobs:meat_raw"]=3,["mobs:chicken_raw"]=2,["mobs:chicken_cooked"]=6,["mobs:chicken_egg_fried"]=2,["mobs:chicken_raw"]=2},
	furnishings=		{"default:torch","default:chest","default:furnace","default:chest_locked","default:sign_wall_wood","default:sign_wall_steel","vessels:steel_bottle","vessels:drinking_glass","vessels:glass_bottle"},
	basics=			{"default:desert_stone","default:sandstonebrick","default:sandstone","default:snowblock","default:ice","default:dirt","default:sand","default:desert_sand","default:silver_sand","default:stone","default:leaves"},
	windows=		{"default:glass"},
	ladders=			{"default:ladder_wood","default:ladder_steel"},
	tools_handler={		-- see extras.lua for use
		["default"]={
			try_to_craft=true,
			use=false,
			tools={"pick_wood","pick_stone","steel_steel","pick_mese","pick_diamond","sword_steel","sword_mese","sword_diamond"},
		}
	},
	nodes_handler={ --dig, mesecon_on, mesecon_off, punch, function
		["default:apple"]="dig",["aliveai_ants:antbase"]="dig",["tnt:tnt"]="dig",["tnt:tnt_burning"]="dig",["fire:basic_flame"]="dig",
	},
}

minetest.after(5, function()
	aliveai.team_load()
end)

minetest.register_globalstep(function(dtime)
	aliveai.max_paths_per_s.timer=aliveai.max_paths_per_s.timer+dtime
	if aliveai.max_paths_per_s.timer>1 then
		aliveai.max_paths_per_s.timer=0
		aliveai.max_paths_per_s.checked=0
		aliveai.bots_delay2=aliveai.bots_delay
		aliveai.bots_delay=0
	end
end)

dofile(minetest.get_modpath("aliveai") .. "/base.lua")
dofile(minetest.get_modpath("aliveai") .. "/event.lua")
dofile(minetest.get_modpath("aliveai") .. "/other.lua")
dofile(minetest.get_modpath("aliveai") .. "/items.lua")
dofile(minetest.get_modpath("aliveai") .. "/tasks.lua")
dofile(minetest.get_modpath("aliveai") .. "/chat.lua")
dofile(minetest.get_modpath("aliveai") .. "/bot.lua")
dofile(minetest.get_modpath("aliveai") .. "/extras.lua")
dofile(minetest.get_modpath("aliveai") .. "/handlers.lua")

dofile(minetest.get_modpath("aliveai") .. "/settings.lua")

print("[aliveai] api Loaded")