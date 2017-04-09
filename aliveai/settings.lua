-- add / change settings in here


--aliveai.character_model="character.b3d"	-- character model, will be automatically choose model depends on what mod is used.


aliveai.constant_node_testing=false		-- constantly checks if bots can use nodes / vehicles, usefull for test vehilces

aliveai.check_spawn_space=true		-- e.g.g check if the bot spawns in air, and not in the ground
aliveai.enable_build=true			-- makes bots can build
aliveai.status=false				-- show bot status/dev mode (using more cpy)  /aliveai status=true /aliveai status=false
aliveai.tools=1				-- hide bot tools
aliveai.get_everything_to_build_chance=50	-- get everything bots need to build chance
aliveai.max_delay=100			-- max bot delay/lag
aliveai.max_new_bots=10			-- max spawning new bots, will be called old if they has been inactive
aliveai.lifetimer=60				-- remove unbehavior none nps

aliveai.team_player["singleplayer"]="sam"	--the default team player(s) will be within

aliveai.staplefood=				{["default:apple"]=2,["farming:bread"]=5,["mobs:meat"]=8,["mobs:meat_raw"]=3,["mobs:chicken_raw"]=2,["mobs:chicken_cooked"]=6,["mobs:chicken_egg_fried"]=2,["mobs:chicken_raw"]=2}
aliveai.furnishings=				{"default:torch","default:chest","default:furnace","default:chest_locked","default:sign_wall_wood","default:sign_wall_steel","vessels:steel_bottle","vessels:drinking_glass","vessels:glass_bottle"}
aliveai.basics=				{"default:desert_stone","default:sandstonebrick","default:sandstone","default:snowblock","default:ice","default:dirt","default:sand","default:desert_sand","default:silver_sand","default:stone","default:leaves"}
aliveai.windows=				{"default:glass"}
aliveai.ladders=				{"default:ladder_wood","default:ladder_steel"}
aliveai.tools_handler["default"]={			-- see extras.lua for use
		try_to_craft=true,
		use=false,
		tools={"pick_wood","pick_stone","steel_steel","pick_mese","pick_diamond","sword_steel","sword_mese","sword_diamond"},
}
aliveai.nodes_handler={			-- dig, mesecon_on, mesecon_off, punch, function
	["default:apple"]="dig",["aliveai_ants:antbase"]="dig",["tnt:tnt"]="dig",["tnt:tnt_burning"]="dig",["fire:basic_flame"]="dig",
}


aliveai.create_bot()				-- create a standard bot
aliveai.create_bot({			-- create standard bot 2
		attack_players=1,
		name="bot2",
		team="Jezy",
		texture="aliveai_skin2.png",
		stealing=1,
		steal_chanse=5,
})

minetest.register_craft({			--punch bot from another team to become their member
	output = "aliveai:team_gift",
	recipe = {
		{"","default:bronze_ingot",""},
		{"default:mese_crystal","default:diamond","default:steel_ingot"},
		{"","default:gold_ingot",""},
	}
})


if minetest.get_modpath("kpgmobs") then
	aliveai.nodes_handler["default:grass_1"]={func=aliveai.drive_vehicle,item="kpgmobs:horseh1",pos={x=0,y=20,z=0}}
	aliveai.nodes_handler["default:grass_2"]={func=aliveai.drive_vehicle,item="kpgmobs:horsearah1",pos={x=0,y=20,z=0}}
	aliveai.nodes_handler["default:grass_3"]={func=aliveai.drive_vehicle,item="kpgmobs:horsepegh1",pos={x=0,y=20,z=0}}
end