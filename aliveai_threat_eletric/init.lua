aliveai_threat_eletric={}

aliveai.create_bot({
		drop_dead_body=0,
		attack_players=1,
		name="eletric_terminator",
		team="nuke",
		texture="aliveai_threat_eletric_terminator.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		escape=0,
		start_with_items={["default:steel_ingot"]=4,["aliveai_threat_eletric:core"]=1},
		type="monster",
		dmg=9,
		hp=200,
		name_color="",
		attack_chance=3,
	on_step=function(self,dtime)
		if self.fight and math.random(1,3)==1 and aliveai.visiable(self,self.fight) and aliveai.viewfield(self,self.fight) then
			local pos=self.object:getpos()
			local ta=self.fight:getpos()
			aliveai.lookat(self,ta)
			aliveai_threat_eletric.lightning(pos,ta)
		end
	end,
	on_load=function(self)
		self.hp2=self.object:get_hp()
	end,
	on_spawn=function(self)
		self.hp2=self.object:get_hp()
	end,
	on_death=function(self,puncher,pos)
		if not self.exx then
			self.exx=1
			local pos=self.object:getpos()
			minetest.add_particlespawner({
				amount = 20,
				time =0.1,
				minpos = pos,
				maxpos = pos,
				minvel = {x=-10, y=10, z=-10},
				maxvel = {x=10, y=50, z=10},
				minacc = {x=0, y=-3, z=0},
				maxacc = {x=0, y=-8, z=0},
				minexptime = 3,
				maxexptime = 1,
				minsize = 1,
				maxsize = 8,
				texture = "default_steel_block.png",
				collisiondetection = true,
			})
			aliveai_threat_eletric.explode(pos,10)
			self.object:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.hp*2}})
		end
	end,
	on_punching=function(self,target)
		local pos=target:getpos()
		if math.random(1,3)==1 and minetest.registered_nodes[minetest.get_node(pos).name] and minetest.registered_nodes[minetest.get_node(pos).name].buildable_to then
			minetest.set_node(pos, {name="aliveai_threat_eletric:lightning"})
		end
	end,
	on_punched=function(self,puncher)
		if self.hp2-self.hp<5 then
			self.object:set_hp(self.hp2)
			self.hp=self.hp2
			local pos=puncher:getpos()
			if minetest.registered_nodes[minetest.get_node(pos).name] and minetest.registered_nodes[minetest.get_node(pos).name].buildable_to then
				minetest.set_node(pos, {name="aliveai_threat_eletric:lightning"})
			end
			return self
		end
		local pos=self.object:getpos()
		minetest.add_particlespawner({
			amount = 20,
			time=0.2,
			minpos = {x=pos.x+0.5,y=pos.y+0.5,z=pos.z+0.5},
			maxpos = {x=pos.x-0.5,y=pos.y-0.5,z=pos.z-0.5},
			minvel = {x=-0.1, y=-0.1, z=-0.1},
			maxvel = {x=0.1, y=0.1, z=0.1},
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 0.5,
			maxexptime = 1,
			minsize = 0.5,
			maxsize = 2,
			texture = "aliveai_threat_eletric_vol.png",
		})
	end
})


minetest.register_tool("aliveai_threat_eletric:core", {
	description = "High voltage core",
	inventory_image = "aliveai_threat_eletric_core.png",
	on_use=function(itemstack, user, pointed_thing)
		if user:get_luaentity() then user=user:get_luaentity() end
		local type=pointed_thing.type
		local pos1=user:getpos()
		pos1.y=pos1.y+1.5
		local pos2
		if type=="object" then
			pos2=pointed_thing.ref:getpos()
		elseif type=="node" then
			pos2=pointed_thing.above
		elseif type=="nothing" then
			local dir
			if user:get_luaentity() then
				if user:get_luaentity().aliveai and user:get_luaentity().fight then
					local dir=aliveai.get_dir(user:get_luaentity(),user:get_luaentity().fight)
					pos2={x=pos1.x+(dir.x*30),y=pos1.y+(dir.y*30),z=pos1.z+(dir.z*30)}
				else
					pos2=aliveai.pointat(user:get_luaentity(),30)
				end
			else
				local dir=user:get_look_dir()
				pos2={x=pos1.x+(dir.x*30),y=pos1.y+(dir.y*30),z=pos1.z+(dir.z*30)}
			end
		else
			return itemstack
		end
		aliveai_threat_eletric.lightning(pos1,pos2)

	end,
	on_place=function(itemstack, user, pointed_thing)
		itemstack:take_item()
		aliveai_threat_eletric.explode(user:getpos(),20)
		return itemstack
	end
})

aliveai_threat_eletric.lighthit=function(level,ob,user)
	local dmg=math.random(1,5)
	local hp=ob:get_hp()
	local en=0
	if ob:get_luaentity() then en=1 end
	for i=0,dmg,1 do
		if en==1 and ob then 
			ob:setvelocity({x=0, y=0, z=0})
		end
		hp=hp-level
		local time=math.random(1,10)*0.1
		if ob:get_hp()<=0 then return false end
		minetest.after((i*0.3)+time, function(ob,user)
		if ob==nil or ob:get_hp()<=0 then return false end
		ob:set_hp(ob:get_hp()-level)
		if ob then ob:punch(ob,1, {full_punch_interval=1,damage_groups={fleshy=4}}, "default:bronze_pick") end
		end, ob,user)
	if hp<=0 then return false end
	end
end

minetest.register_node("aliveai_threat_eletric:lightning", {
	description = "Lightning",
	groups = {not_in_creative_inventory=1},
	tiles = {
		{
			name = "aliveai_threat_eletric_an.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 0.4,
			},
		},
	},
	pointable=false,
	post_effect_color = {a = 210, r =10, g = 80, b = 230},
	sounds = default.node_sound_stone_defaults(),
	drawtype="plantlike",
	light_source = 8,
	paramtype = "light",
	alpha = 50,
	sunlight_propagates = true,
	liquid_viscosity = 8,
	liquid_renewable = false,
	liquid_range = 0,
	liquid_alternative_flowing="aliveai_threat_eletric:lightning",
	liquid_alternative_source="aliveai_threat_eletric:lightning",
	liquidtype = "source",
	is_ground_content = false,
on_construct=function(pos)
		minetest.get_node_timer(pos):start(1)
	end,
on_timer=function(pos, elapsed)
		local rnd=math.random(1,3)
		local sp=0
	for i, ob in pairs(minetest.get_objects_inside_radius(pos, 3)) do
		local p=ob:getpos()
		if ob:is_player() or not (ob:get_luaentity() and ob:get_luaentity().aliveai and ob:get_luaentity().team=="nuke") and minetest.registered_nodes[minetest.get_node(p).name] and minetest.registered_nodes[minetest.get_node(p).name].buildable_to then
		minetest.set_node(p, {name="aliveai_threat_eletric:lightning"})
		aliveai_threat_eletric.lighthit(1,ob)
		minetest.set_node(p, {name="aliveai_threat_eletric:lightning"})
		minetest.sound_play("aliveai_threat_eletric", {pos=pos, gain = 1, max_hear_distance = 10,})
		p.y=p.y+1
		if minetest.registered_nodes[minetest.get_node(p).name] and minetest.registered_nodes[minetest.get_node(p).name].buildable_to then
			minetest.set_node(p, {name="aliveai_threat_eletric:lightning"})
		end
		end
		sp=sp+1
		if sp>2 then break end
	end
	if rnd>=2 then
		minetest.set_node(pos, {name = "air"})
		return false
	else
		local np=minetest.find_node_near(pos, 2,{"air"})
		if np~=nil then
			minetest.set_node(np, {name="aliveai_threat_eletric:lightning"})
			minetest.sound_play("aliveai_threat_eletric", {pos=pos, gain = 1, max_hear_distance = 10,})
		end
	end
	return true
	end,

})


aliveai_threat_eletric.lightning=function(pos1,pos2)
	minetest.sound_play("aliveai_threat_eletric_lightning", {
		pos = pos1,
		max_hear_distance = 5,
		gain = 1,
	})
	minetest.sound_play("aliveai_threat_eletric_lightning", {
		pos = pos2,
		max_hear_distance = 5,
		gain = 1,
	})
	local d=math.floor(aliveai.distance(pos1,pos2)+0.5)
	local dir={x=(pos1.x-pos2.x)/-d,y=(pos1.y-pos2.y)/-d,z=(pos1.z-pos2.z)/-d}
	local p1=pos1
	local p2=p1
	local opos=p1
	for i=0,d,1 do
		opos=p1
		i=i-1
		p1={x=pos1.x+(dir.x*i-0.5),y=pos1.y+(dir.y*i-0.5),z=pos1.z+(dir.z*i-0.5)}
		i=i+1
		p2={x=pos1.x+(dir.x*i+0.5),y=pos1.y+(dir.y*i+0.5),z=pos1.z+(dir.z*i+0.5)}
		if minetest.registered_nodes[minetest.get_node(p1).name] and minetest.registered_nodes[minetest.get_node(p1).name].buildable_to==false then break end
		if math.random(1,2)==1 and i>3 then
			minetest.set_node(p1, {name="aliveai_threat_eletric:lightning"})
		end
		minetest.add_particlespawner({
			amount = 8,
			time =0.2,
			minpos = p1,
			maxpos = p2,
			minvel = {x=-0.1, y=-0.1, z=-0.1},
			maxvel = {x=0.1, y=0.1, z=0.1},
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 0.5,
			maxexptime = 1,
			minsize = 1,
			maxsize = 4,
			texture = "aliveai_threat_eletric_vol.png",
		})
	end
	if minetest.registered_nodes[minetest.get_node(opos).name] and minetest.registered_nodes[minetest.get_node(opos).name].buildable_to then
		minetest.set_node(opos, {name="aliveai_threat_eletric:lightning"})
	end
end

aliveai_threat_eletric.explode=function(pos,r)
	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, r*2)) do
		if not (ob:get_luaentity() and ob:get_luaentity().itemstring) then
			local pos2=ob:getpos()
			local d=math.max(1,vector.distance(pos,pos2))
			local dmg=(8/d)*r
			ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=dmg}},nil)
		else
			ob:get_luaentity().age=890
		end
		local pos2=ob:getpos()
		if minetest.registered_nodes[minetest.get_node(pos2).name] and minetest.registered_nodes[minetest.get_node(pos2).name].buildable_to then
			minetest.set_node(pos2, {name="aliveai_threat_eletric:lightning"})
		end
	end

	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, r*2)) do
		local pos2=ob:getpos()
		local d=math.max(1,vector.distance(pos,pos2))
		local dmg=(8/d)*r
		if ob:get_luaentity() then
			ob:setvelocity({x=(pos2.x-pos.x)*dmg, y=(pos2.y-pos.y)*dmg, z=(pos2.z-pos.z)*dmg})
		elseif ob:is_player() then
			local d=dmg/4
			local pos3={x=(pos2.x-pos.x)*d, y=(pos2.y-pos.y)*d, z=(pos2.z-pos.z)*d}
			ob:setpos({x=pos.x+pos3.x,y=pos.y+pos3.y,z=pos.z+pos3.z,})
		end
	end
	minetest.sound_play("aliveai_nitroglycerine_nuke", {pos=pos, gain = 0.5, max_hear_distance = r*4})
end