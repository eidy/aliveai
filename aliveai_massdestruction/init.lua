aliveai_massdestruction={}
minetest.register_craft({
	output = "aliveai_massdestruction:walking_bomb 3",
	recipe = {
		{"default:mese_crystal_fragment","default:coal_lump"},
	}
})


minetest.register_abm({
	nodenames = {"group:sand","default:snow"},
	interval = 30,
	chance = 1000,
	action = function(pos)
		local pos1={x=pos.x,y=pos.y+1,z=pos.z}
		local pos2={x=pos.x,y=pos.y+2,z=pos.z}
		if aliveai.random(1,1000)==1 and minetest.get_node(pos1).name=="air" and minetest.get_node(pos2).name=="air" then
			minetest.add_entity(pos1, "aliveai_massdestruction:bomb2")
		end
	end,
})

minetest.register_craftitem("aliveai_massdestruction:walking_bomb", {
	description = "Walking bomb",
	inventory_image = "aliveai_massdestruction_bomb.png",
	on_use=function(itemstack, user, pointed_thing)
		local dir = user:get_look_dir()
		local pos=user:getpos()
		local pos2={x=pos.x+(dir.x*2),y=pos.y+1.5+(dir.y*2),z=pos.z+dir.z*2}
		minetest.add_entity(pos2, "aliveai_massdestruction:bomb2"):setvelocity({x=dir.x*10,y=dir.y*10,z=dir.z*10})
		itemstack:take_item()
		return itemstack
	end,
})

if aliveai_threat_eletric then

minetest.register_tool("aliveai_massdestruction:core", {
	description = "Uranium core",
	inventory_image = "aliveai_massdestruction_core.png",
	range = 15,
	on_use=function(itemstack, user, pointed_thing)
		if user:get_luaentity() then user=user:get_luaentity() end
		local typ=pointed_thing.type
		local pos1=user:getpos()
		pos1.y=pos1.y+1.5
		local pos2
		if typ=="object" then
			pos2=pointed_thing.ref:getpos()
		elseif typ=="node" then
			pos2=pointed_thing.under
		elseif typ=="nothing" then
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
		local d=math.floor(aliveai.distance(pos1,pos2)+0.5)
		local dir={x=(pos1.x-pos2.x)/-d,y=(pos1.y-pos2.y)/-d,z=(pos1.z-pos2.z)/-d}
		local p1=pos1
		for i=0,d,1 do
			p1={x=pos1.x+(dir.x*i),y=pos1.y+(dir.y*i),z=pos1.z+(dir.z*i)}
			if minetest.registered_nodes[minetest.get_node(p1).name] and minetest.registered_nodes[minetest.get_node(p1).name].walkable then
				break
			end
		end

		if p1.x~=p1.x or p1.y~=p1.y or p1.z~=p1.z then
			return itemstack
		end

		aliveai_massdestruction.uran_explode(p1,4)
		return itemstack
	end,
})


aliveai.create_bot({
		drop_dead_body=0,
		attack_players=1,
		name="uranium",
		team="nuke",
		texture="aliveai_massdestruction_uranium.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		escape=0,
		type="monster",
		dmg=19,
		hp=1000,
		name_color="",
		coming=0,
		smartfight=0,
		visual_size={x=2,y=1.5},
		collisionbox={-0.7,-1.5,-0.7,0.7,1.2,0.7},
		start_with_items={["default:mese_crystal"]=4,["aliveai_massdestruction:core"]=1},
		spawn_on={"group:sand","default:dirt_with_grass","default:dirt_with_dry_grass","default:gravel"},
		attack_chance=5,
		on_spawn=function(self)
			self.hp2=self.object:get_hp()
		end,
		on_load=function(self)
			self.hp2=self.object:get_hp()
		end,
	on_step=function(self,dtime)
		if math.random(1,20)==1 then
			local np=minetest.find_node_near(self.object:getpos(), 3,{"group:flammable"})
			if np and not minetest.is_protected(np,"") then
				minetest.place_node(np,{name="aliveai_massdestruction:fire"})
			end
		end


		if self.fight then
			if math.random(1,20)==1 and aliveai.distance(self,self.fight)>self.arm then
				self.blowing=1
				aliveai_nitroglycerine.explode(self.fight:getpos(),{
					radius=3,
					set="air",
					place={"aliveai_massdestruction:fire","aliveai_massdestruction:fire","air","air","air"}
				})
			elseif math.random(1,10)==1 then
				for _, ob in ipairs(minetest.get_objects_inside_radius(self.object:getpos(), self.distance)) do
					if not (aliveai.same_bot(self,ob) and aliveai.team(ob)=="nuke") then
						local pos=ob:getpos()
						aliveai_threat_eletric.lighthit(2,ob)
						local node=minetest.get_node(ob:getpos()).name
						if minetest.registered_nodes[node] and minetest.registered_nodes[node].walkable==false and not minetest.is_protected(np,"") then
							minetest.set_node(pos,{name="aliveai_massdestruction:fire"})
						end
					end
				end
			end

		end
	end,
	on_punched=function(self,puncher,h)
		if self.blowing or self.hp2-self.hp<10 then
			self.object:set_hp(self.hp2)
			self.hp=self.hp2
			self.blowing=nil
			if aliveai.team(puncher)~="nuke" then
				local p=puncher:getpos()
				local node=minetest.get_node(p).name
				if minetest.registered_nodes[node] and minetest.registered_nodes[node].walkable==false and not minetest.is_protected(p,"") then
					minetest.set_node(p,{name="aliveai_massdestruction:fire"})
				end
				aliveai_threat_eletric.lighthit(2,puncher)
			end
			return self
		end
		self.hp2=self.hp
	end,
	on_death=function(self)
		if not self.ex then
			self.ex=1
			local pos=self.object:getpos()
			if not pos then return end
			aliveai_massdestruction.uran_explode(pos,10,self)
			minetest.set_node(pos,{name="aliveai_massdestruction:source"})
		end
		return self
	end,
})
end

aliveai.create_bot({
		drop_dead_body=0,
		attack_players=1,
		name="nuker",
		team="nuke",
		texture="aliveai_massdestruction_nuker.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		escape=0,
		type="monster",
		dmg=0,
		hp=20,
		name_color="",
		arm=2,
		coming=0,
		smartfight=0,
		spawn_on={"group:sand","default:dirt_with_grass","default:dirt_with_dry_grass","default:gravel"},
		attack_chance=5,
	on_fighting=function(self,target)
		if not self.ti then self.ti=99 end
		self.temper=1
		self.ti=self.ti-1
		if self.ti<0 then
			self.on_death(self)
		else
			self.object:set_properties({nametag=self.ti,nametag_color="#ff0000aa"})
		end
	end,
	on_death=function(self)
		if not self.aliveaibomb then
			local pos=self.object:getpos()
			self.aliveaibomb=1
			self.hp=0
			self.object:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.object:get_hp()*2}})
			for i=1,50,1 do
				minetest.add_entity({x=pos.x+math.random(-5,5),y=pos.y+math.random(2,5),z=pos.z+math.random(-5,5)}, "aliveai_massdestruction:bomb")
			end
			aliveai_nitroglycerine.explode(pos,{
				radius=2,
				set="air",
				drops=0,
				place={"air","air"}
			})
		end
		return self
	end,
})


minetest.register_entity("aliveai_massdestruction:bomb",{
	hp_max = 9000,
	physical =true,
	weight = 1,
	collisionbox = {-0.15,-0.15,-0.15,0.15,0.15,0.15},
	visual = "sprite",
	visual_size = {x=0.5,y=0.5},
	textures ={"aliveai_massdestruction_bomb.png"},
	colors = {},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,
	on_activate=function(self, staticdata)
		self.time2=math.random(1,20)
		self.object:setacceleration({x =0, y =-10, z =0})
		self.object:setvelocity({x=math.random(-15,15),y=math.random(10,15),z=math.random(-15,15)})
		return self
	end,
	on_step=function(self, dtime)
		self.time=self.time+dtime
		self.time2=self.time2-dtime
		local v=self.object:getvelocity()
		if self.time2>1 and v.y==0 and self.last_y<0 then
			self.time2=0
			self.expl=math.random(1,10)
		end
		if self.time<0.1 then return self end
		self.last_y=v.y
		self.time=0
		if not self.expl then
			for _, ob in ipairs(minetest.get_objects_inside_radius(self.object:getpos(), 2)) do
				local en=ob:get_luaentity()
				if not (en and en.aliveaibomb) then
					self.time2=-1
					return self
				end
			end
		end
		if self.time2<0 then
			if self.expl and math.random(1,self.expl)==1 then
				aliveai_nitroglycerine.explode(self.object:getpos(),{radius=3,set="air",drops=0,place={"air","air"}})
				self.object:remove()
			elseif not self.expl then
				self.expl=math.random(1,10)
			else
				self.time2=0.5
			end
		end
		return self
	end,
	time=0,
	time2=10,
	type="",
	last_y=0,
	aliveaibomb=1
})

minetest.register_entity("aliveai_massdestruction:bomb2",{
	hp_max = 10,
	physical =true,
	weight = 1,
	collisionbox = {-0.2,-0.2,-0.2,0.2,0.2,0.2},
	visual = "sprite",
	visual_size = {x=0.5,y=0.5},
	textures ={"aliveai_massdestruction_bomb.png"},
	colors = {},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = true,
	automatic_rotate = false,
	namecolor="",
	expl=function(self,pos)
		minetest.add_particlespawner({
			amount = 20,
			time =0.2,
			minpos = {x=pos.x-1, y=pos.y, z=pos.z-1},
			maxpos = {x=pos.x+1, y=pos.y, z=pos.z+1},
			minvel = {x=-5, y=0, z=-5},
			maxvel = {x=5, y=5, z=5},
			minacc = {x=0, y=2, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 1,
			maxexptime = 2,
			minsize = 5,
			maxsize = 10,
			texture = "default_item_smoke.png",
			collisiondetection = true,
		})
		self.exp=1
		aliveai_nitroglycerine.explode(pos,{radius=2,set="air",place={"air","air"}})
		self.object:setvelocity({x=math.random(-5,5),y=math.random(5,10),z=math.random(-5,5)})
		self.object:remove()
	end,
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		local en=puncher:get_luaentity()
		if not self.exp and tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.fleshy then
			self.hp=self.hp-tool_capabilities.damage_groups.fleshy
			self.object:set_hp(self.hp)
			if dir~=nil then
				local v={x = dir.x*5,y = self.object:getvelocity().y,z = dir.z*5}
				self.object:setvelocity(v)
			end
		end
		if self.hp<1 and not self.exp then
			self.expl(self,self.object:getpos())
		end

	end,
	on_activate=function(self, staticdata)
		self.object:setacceleration({x =0, y =-10, z =0})
		self.hp=self.object:get_hp()
		return self
	end,
	on_step=function(self, dtime)
		self.time=self.time+dtime
		if self.object:getvelocity().y==0 then
			if self.fight then
				local pos=self.object:getpos()
				local pos2=self.fight:getpos()
				if aliveai.visiable(pos,pos2) then
					self.object:setvelocity({x=(pos.x-pos2.x)*-1,y=math.random(5,10),z=(pos.z-pos2.z)*-1})
				end
			else
				self.object:setvelocity({x=math.random(-5,5),y=math.random(5,10),z=math.random(-5,5)})
			end
			local y=self.object:getvelocity().y
			if y==0 or y==-0 then self.object:setvelocity({x=0,y=math.random(5,10),z=0}) end
		end
		if self.time<1 then return self end
		self.time=0
		local pos=self.object:getpos()
		local ob1
		for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 15)) do
			local en=ob:get_luaentity()
			if not (en and en.aliveaibomb) and aliveai.visiable(pos,ob:getpos()) then ob1=ob end
			if ob1 and math.random(1,3)==1 then break end
		end
		if not ob1 then self.fight=nil return end
		local pos2=ob1:getpos()
		local vis=aliveai.visiable(pos,pos2)
		if self.fight and aliveai.visiable(pos,self.fight:getpos()) then
			ob1=self.fight
			pos2=self.fight:getpos()
			vis=aliveai.visiable(pos,pos2)
		end
		if aliveai.distance(pos,pos2)<3 and vis then
			self.expl(self,pos)
		else
			self.fight=ob1
		end
		return self
	end,
	time=0,
	type="monster",
	aliveaibomb=1,
	team="bomb"
})



minetest.register_node("aliveai_massdestruction:source", {
	description = "Uranium source",
	drawtype = "liquid",
	tiles = {
		{name = "aliveai_massdestruction_uran.png",
			animation = {type = "vertical_frames",aspect_w = 16,aspect_h = 16,length = 2.0,},
		},
	},
	special_tiles = {
		{
			name = "aliveai_massdestruction_uran.png",
			animation = {type = "vertical_frames",aspect_w = 16,aspect_h = 16,length = 2.0,},
			backface_culling = false,
		},},
	alpha = 220,
	paramtype = "light",
	light_source = 15,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "source",
	liquid_alternative_flowing = "aliveai_massdestruction:flowing",
	liquid_alternative_source = "aliveai_massdestruction:source",
	liquid_viscosity = 0,
	damage_per_second = 19,
	post_effect_color = {a = 150, r = 150, g = 50, b = 190},
	groups = {aileuran=1,igniter=1, liquid = 3, puts_out_fire = 1,not_in_creative_inventory=1},
})

minetest.register_node("aliveai_massdestruction:flowing", {
	description = "Uranium flowing",
	drawtype = "flowingliquid",
	tiles = {"aliveai_massdestruction_uran.png"},
	special_tiles = {
		{
			name = "aliveai_massdestruction_uran.png",
			backface_culling = false,
			animation = {type = "vertical_frames",aspect_w = 16,aspect_h = 16,length = 2.0}
		},
		{
			name = "aliveai_massdestruction_uran.png",
			backface_culling = true,
			animation = {type = "vertical_frames",aspect_w = 16,aspect_h = 16,length = 2.0}
		}
	},
	alpha = 190,
	paramtype = "light",
	light_source = 15,
	paramtype2 = "flowingliquid",
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	is_ground_content = false,
	drop = "",
	drowning = 1,
	liquidtype = "flowing",
	liquid_alternative_flowing = "aliveai_massdestruction:flowing",
	liquid_alternative_source = "aliveai_massdestruction:source",
	liquid_viscosity = 2,
	damage_per_second = 19,
	post_effect_color = {a = 150, r = 150, g = 50, b = 190},
	groups = {aileuran=1,igniter=1, liquid = 3, puts_out_fire = 1,not_in_creative_inventory = 1},
})




if aliveai_threat_eletric then

minetest.register_abm({
	nodenames = {"group:soil","group:sand","group:flammable","group:dig_immediate","group:water","group:flowers","group:oddly_breakable_by_hand"},
	neighbors = {"group:aileuran"},
	interval = 10,
	chance = 4,
	action = function(pos)
		if minetest.is_protected(pos,"")==false then
			minetest.set_node(pos, {name ="aliveai_massdestruction:fire"})
		end
	end,
})

minetest.register_abm({
	nodenames = {"aliveai_massdestruction:fire","aliveai_massdestruction:source"},
	interval = 10,
	chance = 4,
	action = function(pos)
		if minetest.is_protected(pos,"")==false then
			minetest.set_node(pos, {name ="air"})
		end
	end,
})

minetest.register_abm({
	nodenames = {"group:aileuran"},
	interval = 10,
	chance = 10,
	action = function(pos)
		if math.random(1,10)~=1 then return end
		for i, ob in pairs(minetest.get_objects_inside_radius(pos, 15)) do
			local node=minetest.get_node(ob:getpos()).name
			if aliveai.team(ob)~="nuke" and node~="aliveai_massdestruction:fire" and minetest.registered_nodes[node] and minetest.registered_nodes[node].walkable==false then
				aliveai_threat_eletric.lighthit(2,ob)
				minetest.set_node(ob:getpos(), {name ="aliveai_massdestruction:fire"})
			end
		end
		local np=minetest.find_node_near(pos,15,{"group:soil","group:sand","group:flammable","group:dig_immediate","group:flowers","group:oddly_breakable_by_hand"})
		if np~=nil then
			minetest.set_node(np, {name ="aliveai_massdestruction:fire"})
		end
	end,
})

minetest.register_node("aliveai_massdestruction:fire", {
	description = "Uranium fire",
	inventory_image = "fire_basic_flame.png^[colorize:#aaff00aa",
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png^[colorize:#aaff00aa",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	paramtype = "light",
	light_source = 15,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 7,
	groups = {dig_immediate = 2,igniter=1,puts_out_fire = 1},
	drop="",
	on_construct=function(pos)
		minetest.get_node_timer(pos):start(5)
	end,
	on_punch=function(pos, node, puncher, pointed_thing)
		local p=puncher:getpos()
		p={x=p.x,y=p.y+1,z=p.z}
		local node=minetest.get_node(p).name
		if minetest.registered_nodes[node] and minetest.registered_nodes[node].walkable==false then minetest.set_node(p, {name ="aliveai_massdestruction:fire"}) end
	end,

	on_timer=function (pos, elapsed)
		for i, ob in pairs(minetest.get_objects_inside_radius(pos, 4)) do
			local p=ob:getpos()
			local node=minetest.get_node(p).name
			if aliveai.team(ob)~="nuke" then 
				if minetest.is_protected(p,"")==false and node~="aliveai_massdestruction:fire"
				and minetest.registered_nodes[node] and minetest.registered_nodes[node].walkable==false then
					minetest.set_node(p, {name ="aliveai_massdestruction:fire"})
				end
				aliveai_threat_eletric.lighthit(2,ob)
			end
		end

		if math.random(3)==1 then
			minetest.set_node(pos, {name ="air"})
		else
			minetest.sound_play("fire_small", {pos=pos, gain = 1.0, max_hear_distance = 5,})
		end
		return true
	end
})
end



aliveai_massdestruction.uran_explode=function(pos,d,self)
	aliveai_nitroglycerine.explode(pos,{
		radius=d,
		set="air",
		drops=0,
		place={"aliveai_massdestruction:fire","aliveai_massdestruction:fire","air","air","air"}
	})
	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, d*2)) do
		if not ((self and aliveai.same_bot(self,ob)) and aliveai.team(ob)=="nuke") then
			aliveai_threat_eletric.lighthit(2,ob)
			local node=minetest.get_node(ob:getpos()).name
			if minetest.registered_nodes[node] and minetest.registered_nodes[node].walkable==false then
				minetest.set_node(pos,{name="aliveai_massdestruction:fire"})
			end
		end
	end
end