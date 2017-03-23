aliveai_threats={c4={},debris={}}

aliveai.savedata.clone=function(self)
	if self.clone then
		return {clone=1}
	end
	if self.natural_monster then
		return {t1=self.t1,t2=self.t2,t3=self.t3,natural_monster=1,consists=self.consists}
	end

	if self.killed and self.body then
		return {body=self.body,killed=self.killed,hp_max=self.hp_max}
	end


end

aliveai.loaddata.clone=function(self,r)
	if r.clone then
		self.clone=r.clone
	end
	if r.natural_monster then
		self.t1=r.t1
		self.t2=r.t2
		self.t3=r.t3
		self.natural_monster=1
		self.consists=r.consists
	end
	if r.killed and r.body then
		self.body=r.body
		self.killed=1
		self.hp_max=r.hp_max
	end
	return self
end

if minetest.get_modpath("aliveai_nitroglycerine")~=nil then

minetest.register_craft({
	output = "aliveai_threats:c4 2",
	recipe = {
		{"default:steel_ingot","default:coal_lump","default:steel_ingot"},
		{"default:steel_ingot","default:mese_crystal_fragment","default:steel_ingot"},
		{"default:steel_ingot","default:copper_ingot","default:steel_ingot"},

	}
})


minetest.register_craftitem("aliveai_threats:c4", {
	description = "C4 bomb",
	inventory_image = "aliveai_threats_c4.png",
		on_use = function(itemstack, user, pointed_thing)
			local name=user:get_player_name()
			local c=aliveai_threats.c4[name]
			if not c and pointed_thing.type=="object" then
				local ob=pointed_thing.ref
				aliveai_threats.c4[user:get_player_name()]=ob
				user:get_inventory():add_item("main","aliveai_threats:c4_controler")
				itemstack:take_item()
			elseif not c then
				aliveai_threats.c4[name]=nil
			end
			return itemstack
		end
})

minetest.register_craftitem("aliveai_threats:c4_controler", {
	description = "C4 controller",
	inventory_image = "aliveai_threats_c4_controller.png",
	groups = {not_in_creative_inventory=1},
		on_use = function(itemstack, user, pointed_thing)
			local name=user:get_player_name()
			local ob=aliveai_threats.c4[name]
			if ob and ob:getpos() and ob:getpos().x then
				local pos=ob:getpos()
				for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 3)) do
					ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=200}})
				end
				aliveai_nitroglycerine.explode(pos,{
					radius=3,
					set="air",
				})
			else
				user:get_inventory():add_item("main","aliveai_threats:c4")
			end
			aliveai_threats.c4[name]=nil
			itemstack:take_item()
			return itemstack
		end
})


aliveai.create_bot({
		drop_dead_body=0,
		attack_players=1,
		name="nitrogen",
		team="ice",
		texture="aliveai_threats_nitrogen.png",
		stealing=1,
		steal_chanse=2,
		attacking=1,
		talking=0,
		light=0,
		building=0,
		escape=0,
		start_with_items={["default:snowblock"]=1,["default:ice"]=4},
		type="monster",
		dmg=1,
		hp=40,
		name_color="",
		arm=2,
		spawn_on={"default:silver_sand","default:dirt_with_snow","default:snow","default:snowblock","default:ice"},
	on_step=function(self,dtime)
		local pos=self.object:getpos()
		pos.y=pos.y-1.5
		local node=minetest.get_node(pos)
		if node and node.name and minetest.is_protected(pos,"")==false then
			if minetest.get_item_group(node.name, "soil")>0 then
				minetest.set_node(pos,{name="default:dirt_with_snow"})
			elseif minetest.get_item_group(node.name, "sand")>0  and minetest.registered_nodes["default:silver_sand"] then
				minetest.set_node(pos,{name="default:silver_sand"})
			elseif minetest.get_item_group(node.name, "water")>0 then
				minetest.set_node(pos,{name="default:ice"})
				pos.y=pos.y+1
				if minetest.get_item_group(minetest.get_node(pos).name, "water")>1 then
					minetest.set_node(pos,{name="default:ice"})
				end
			elseif minetest.get_item_group(node.name, "lava")>0 then
				minetest.set_node(pos,{name="default:ice"})
				pos.y=pos.y+1
				if minetest.get_item_group(minetest.get_node(pos).name, "lava")>1 then
					minetest.set_node(pos,{name="default:ice"})
				end
			end
		end
	end,
	on_punching=function(self,target)
		if aliveai.gethp(target)<=self.dmg+5 then
			aliveai_nitroglycerine.freeze(target)
		else
			target:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.dmg}},nil)
		end
	end,
	on_death=function(self,puncher,pos)
		minetest.sound_play("default_break_glass", {pos=pos, gain = 1.0, max_hear_distance = 5,})
		aliveai_nitroglycerine.crush(pos)
	end,
})

aliveai.create_bot({
		drop_dead_body=0,
		attack_players=1,
		name="gassman",
		team="nuke",
		texture="aliveai_threats_gassman.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		escape=0,
		type="monster",
		dmg=0,
		hp=100,
		name_color="",
		arm=2,
		coming=0,
		smartfight=0,
		spawn_on={"group:sand","default:dirt_with_grass","default:dirt_with_dry_grass","default:gravel"},
		attack_chance=5,
	on_fighting=function(self,target)
		if not self.ti then self.ti={t=1,s=0} end
		self.temper=10
		self.ti.s=self.ti.s-1
		if self.ti.s<=0 then
			self.ti.t=self.ti.t-1
			if self.ti.t>=0 then
				self.ti.s=99
			end
		end
		if self.ti.t<0 then
			local pos=self.object:getpos()
			self.ex=true
			self.object:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.object:get_hp()*2}},nil)
			aliveai_nitroglycerine.explode(pos,{
				radius=10,
				set="air",
				drops=0,
			})
			return self
		end

		local tag=self.ti.t ..":" .. self.ti.s
		self.object:set_properties({nametag=tag,nametag_color="#ff0000aa"})
	end,
	on_death=function(self,puncher,pos)
			if not self.ex then
				self.hp=0
				self.ex=true
				aliveai_nitroglycerine.explode(pos,{
				radius=2,
				set="air",
				})
			end
			return self
	end,
})



aliveai.create_bot({
		drop_dead_body=0,
		attack_players=1,
		name="nitrogenblow",
		team="ice",
		texture="aliveai_threats_nitrogenblow.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		escape=0,
		start_with_items={["default:snowblock"]=10,["default:ice"]=2},
		spawn_on={"default:silver_sand","default:dirt_with_snow","default:snow","default:snowblock","default:ice"},
		type="monster",
		dmg=1,
		hp=30,
		name_color="",
		arm=2,
		coming=0,
		smartfight=0,
		spawn_on={"group:sand","default:dirt_with_grass","default:dirt_with_dry_grass","default:gravel"},
		attack_chance=5,
	on_fighting=function(self,target)
		if aliveai.gethp(target)<=self.dmg+5 then
			aliveai_nitroglycerine.freeze(target)
		elseif math.random(1,10)==1 then
			target:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.dmg}},nil)
		end
		if not self.ti then self.ti={t=5,s=9} end
		self.temper=10
		self.ti.s=self.ti.s-1
		if self.ti.s<=0 then
			self.ti.t=self.ti.t-1
			if self.ti.t>=0 then
				self.ti.s=9
			end
		end
		if self.ti.t<0 then
			self.ex=true
			if aliveai.gethp(target)<=11 then
				aliveai_nitroglycerine.freeze(target)
			else
				target:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=10}},nil)
			end
			aliveai_nitroglycerine.crush(self.object:getpos())
			self.object:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.object:get_hp()*2}},nil)
			return self
		end
		local tag=self.ti.t ..":" .. self.ti.s
		self.object:set_properties({nametag=tag,nametag_color="#ff0000aa"})
	end,
	on_death=function(self,puncher,pos)
			minetest.sound_play("default_break_glass", {pos=pos, gain = 1.0, max_hear_distance = 5,})
			if not self.ex then
				self.ex=true
				self.aliveai_ice=1
				local radius=10
				aliveai_nitroglycerine.explode(pos,{
					radius=radius,
					hurt=0,
					place={"default:snowblock","default:ice","default:snowblock"},
					place_chance=2,
				})
				for _, ob in ipairs(minetest.get_objects_inside_radius(pos, radius*2)) do
					local pos2=ob:getpos()
					local d=math.max(1,vector.distance(pos,pos2))
					local dmg=(8/d)*radius
					local en=ob:get_luaentity()
					if ob:is_player() or not (en and en.name=="aliveai_nitroglycerine:ice" or en.aliveai_ice) then
						if ob:get_hp()<=dmg+5 then
							aliveai_nitroglycerine.freeze(ob)
						else
							ob:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=dmg}})
						end
					end
				end
			end
			return self
	end,
})

aliveai.create_bot({
		drop_dead_body=0,
		attack_players=1,
		name="heavygassman",
		team="nuke",
		texture="aliveai_threats_gassman2.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		escape=0,
		start_with_items={["default:coal_lump"]=4},
		type="monster",
		dmg=0,
		hp=20,
		name_color="",
		arm=2,
		coming=1,
		smartfight=0,
		attack_chance=1,
	on_fighting=function(self,target)
		if not self.t then self.t=20 end
		self.temper=10
		self.t=self.t-1
		if self.t<0 then
			self.object:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.object:get_hp()*2}},nil)
			return self
		end
		self.object:set_properties({nametag=self.t,nametag_color="#ff0000aa"})
	end,
	on_death=function(self,puncher,pos)
		if not self.ex then
			self.ex=true
			local radius=10
			aliveai_nitroglycerine.explode(pos,{
				radius=radius,
				place={"aliveai_threats:gass","aliveai_threats:gass"},
				set="aliveai_threats:gass",
				place_chance=1,
			})
		end
		return self
	end,
})

minetest.register_node("aliveai_threats:gass", {
	description = "Gass",
	inventory_image = "bubble.png",
	tiles = {"aliveai_air.png"},
	walkable = false,
	pointable = false,
	drowning = 1,
	buildable_to = true,
	drawtype = "glasslike",
	groups = {not_in_creative_inventory=1},
	post_effect_color = {a = 248, r =0, g = 0, b = 0},
	damage_per_second = 1,
	paramtype = "light",
	liquid_viscosity = 15,
	liquidtype = "source",
	liquid_range = 0,
	liquid_alternative_flowing = "aliveai_threats:gass",
	liquid_alternative_source = "aliveai_threats:gass",
	groups = {liquid = 4,crumbly = 1}
})


end

aliveai.create_bot({
		attack_players=1,
		name="terminator",
		team="nuke",
		texture="aliveai_threats_terminator.png",
		attacking=1,
		talking=0,
		--light=0,
		building=0,
		escape=0,
		start_with_items={["default:steel_ingot"]=4,["default:steelblock"]=1},
		type="monster",
		dmg=0,
		hp=200,
		arm=3,
		name_color="",
		spawn_on={"group:sand","default:dirt_with_grass","default:dirt_with_dry_grass","default:gravel"},
		attack_chance=5,
	on_punching=function(self,target)
		local pos=self.object:getpos()
		pos.y=pos.y-0.5
		local radius=self.arm
		for _, ob in ipairs(minetest.get_objects_inside_radius(pos, radius)) do
			local pos2=ob:getpos()
			local d=math.max(1,vector.distance(pos,pos2))
			local dmg=(8/d)*radius
			local en=ob:get_luaentity()
			if ob:is_player() or not (en and en.team==self.team or ob.itemstring) then
				if en and en.object then
					if en.type~="" then ob:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=dmg}},nil) end
					dmg=dmg*2
					ob:setvelocity({x=(pos2.x-pos.x)*dmg, y=((pos2.y-pos.y)*dmg)+2, z=(pos2.z-pos.z)*dmg})
				elseif ob:is_player() then
					ob:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=dmg}},nil)
					local d=dmg/2
					local v=0
					local dd=0
					local p2={x=pos.x-pos2.x, y=pos.y-pos2.y, z=pos.z-pos2.z}
					local tmp
					for i=0,10,1 do
						dd=d*v
						tmp={x=pos.x+(p2.x*dd), y=pos.y+(p2.y*dd)+2, z=pos.z+(p2.z*dd)}
						local n=minetest.get_node(tmp)
						if n and n.name and minetest.registered_nodes[n.name].walkable then
							if minetest.is_protected(tmp,"")==false and minetest.dig_node(tmp) then
								for _, item in pairs(minetest.get_node_drops(n.name, "")) do
									if item then
										local it=minetest.add_item(tmp, item)
										it:get_luaentity().age=890
										it:setvelocity({x = math.random(-1, 1),y=math.random(-1, 1),z = math.random(-1, 1)})
									end
								end
							else
								break
							end
						end
						v=v-0.1
					end
					d=d*v
					ob:setpos({x=pos.x+(p2.x*d), y=pos.y+(p2.y*d)+2, z=pos.z+(p2.z*d)})
				end
			end
		end
	end,
	on_load=function(self)
		self.hp2=self.object:get_hp()
	end,
	on_punched=function(self,puncher)
		if self.hp2 and self.hp2-self.object:get_hp()<5 then
			self.object:set_hp(self.hp2)
			return self
		end
		local pos=self.object:getpos()
			minetest.add_particlespawner({
			amount = 5,
			time =0.05,
			minpos = pos,
			maxpos = pos,
			minvel = {x=-2, y=-2, z=-2},
			maxvel = {x=1, y=0.5, z=1},
			minacc = {x=0, y=-8, z=0},
			maxacc = {x=0, y=-10, z=0},
			minexptime = 2,
			maxexptime = 1,
			minsize = 0.1,
			maxsize = 2,
			texture = "default_steel_block.png",
			collisiondetection = true,
			spawn_chance=100,
		})
	end
})



aliveai.create_bot({
		attack_players=1,
		name="pull_monster",
		team="pull",
		texture="aliveai_threats_pull.png",
		visual_size={x=0.8,y=1.4},
		collisionbox={-0.33,-1.3,-0.33,0.33,1.5,0.33},
		attacking=1,
		talking=0,
		light=-1,
		lowest_light=9,
		building=0,
		smartfight=0,
		escape=0,
		type="monster",
		dmg=0,
		hp=80,
		arm=2,
		name_color="",
		spawn_on={"group:sand","default:dirt_with_grass","default:dirt_with_dry_grass","group:stone","default:snow"},
		attack_chance=3,
		spawn_chance=200,
		spawn_y=1,
	on_punching=function(self,target)
		if not self.pull_down then
			local pos=aliveai.roundpos(target:getpos())
			local n=minetest.get_node(pos)
			if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].walkable then return end
			pos.y=pos.y-1
			self.pull_down={pos={pos0=pos}}
			local p
			for i=1,3,1 do
				p={x=pos.x,y=pos.y-i,z=pos.z}
				n=minetest.get_node(p)
				self.pull_down.pos["pos" .. i]=p
				if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].walkable==false then
					self.pull_down=nil
					return
				end
			end
			self.pull_down.target=target
		end
	end,
	on_detect_enemy=function(self,target)
		self.object:set_properties({
			mesh = aliveai.character_model,
			textures = {"aliveai_threats_pull.png"},
		})
	end,
	on_load=function(self)
		self.move.speed=0.5
		local pos=aliveai.roundpos(self.object:getpos())
		local n=minetest.get_node(pos)
		if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].walkable then
			pos.y=pos.y+3
			local l=minetest.get_node_light(pos)
			if not l then return end
			local n=minetest.get_node(pos)
			if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].walkable then
				self.domovefromslp=true
				return self
			elseif l>9 then
				self.sleeping={ground=pos}
				return self
			else
				self.domovefromslp=true
				return self
			end
		end
	end,
	on_step=function(self,dtime)
		if self.movefromslp then
			aliveai.rndwalk(self,false)
			aliveai.stand(self)
			for i, v in pairs(self.movefromslp) do
				self.object:moveto(v)
				table.remove(self.movefromslp,i)
				return self
			end
			self.movefromslp=nil
			return self
		end
		if self.domovefromslp then
			self.domovefromslp=nil
			local pos=self.object:getpos()
			local gpos={x=pos.x,y=pos.y+3,z=pos.z}
			local n=minetest.get_node(gpos)
			if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].walkable then
				self.movefromslp={} -- move up from stuck sleep pos
				local p3=0
				for i=1,103,1 do
					p={x=gpos.x,y=gpos.y+i,z=gpos.z}
					local n=minetest.get_node(p)
					self.movefromslp[i]=p
					if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].walkable==false then
						p3=p3+1
						if p3>2 then
							self.sleeping=nil
							return self
						end
					else
						p3=0
					end
				end
				aliveai.punch(self,self.object,self.object:get_hp()*2)
				return self
			end
		end
		if self.sleeping then
			local pos=aliveai.roundpos(self.object:getpos())
			if self.sleeping.pos then
				if self.sleeping.pos.pos0 then
					self.object:moveto(self.sleeping.pos.pos0)
					self.sleeping.pos.pos0=nil
				elseif self.sleeping.pos.pos1 then
					self.object:moveto(self.sleeping.pos.pos1)
					self.sleeping.pos.pos1=nil
				elseif self.sleeping.pos.pos2 then
					self.object:moveto(self.sleeping.pos.pos2)
					self.sleeping.pos=nil
				end
				if not self.pull_down then return self end
			end
			if self.pull_down then
				if self.pull_down.target and self.pull_down.pos then
					if self.pull_down.pos.pos0 and not (self.sleeping.pos and self.sleeping.pos.pos2) then 
						self.pull_down=nil
						self.sleeping=nil
						return
					end
					if self.pull_down.pos.pos0 then
						self.pull_down.target:moveto(self.pull_down.pos.pos0)
						self.pull_down.pos.pos0=nil
					elseif self.pull_down.pos.pos1 then
						self.pull_down.target:moveto(self.pull_down.pos.pos1)
						self.pull_down.pos.pos1=nil
					elseif self.pull_down.pos.pos2 then
						self.pull_down.target:moveto(self.pull_down.pos.pos2)
						self.pull_down.pos=nil
					end
					return self
				end
				if self.pull_down.target and aliveai.gethp(self.pull_down.target)>0 and aliveai.distance(self,self.pull_down.target:getpos())<=self.arm+1 then
					aliveai.punch(self,self.pull_down.target,1)
					if aliveai.gethp(self.pull_down.target)<=0 then
						self.object:set_hp(self.hp_max)
						aliveai.showhp(self,true)
						self.domovefromslp=true
					end
					return self
				else
					self.sleeping=nil
					self.pull_down=nil
					return
				end
			end
			if self.hide then
				self.time=self.otime
				if math.random(1,2)==1 then
					if not self.abortsleep then
						for _, ob in ipairs(minetest.get_objects_inside_radius(self.sleeping.ground, 10)) do
							local en=ob:get_luaentity()
							if not (en and en.aliveai and en.team==self.team) then
								return self
							end
						end
					end
					self.hide=nil
					self.pull_down=nil
					self.domovefromslp=true
				end
				if self.hide then return self end
			end
			local l=minetest.get_node_light(self.sleeping.ground)
			if not l then
				aliveai.punch(self,self.object,self.object:get_hp()*2)
				self.sleeping=nil
				self.domovefromslp=true
				return self
			elseif l<=9 or self.abortsleep then
				self.domovefromslp=true
			else
				if math.random(1,10)==1 then
					for _, ob in ipairs(minetest.get_objects_inside_radius(self.sleeping.ground, self.distance)) do
						local en=ob:get_luaentity()
						if not (en and en.aliveai and en.team==self.team) then
							return self
						end
					end
					aliveai.punch(self,self.object,self.object:get_hp()*2)
				end
				return self
			end
		elseif math.random(1,10)==1 or self.pull_down or self.hide then
			local pos=aliveai.roundpos(self.object:getpos())
			pos.y=pos.y-1
			local l=minetest.get_node_light(pos)
			if not l then return end
			if l>9 or self.pull_down or self.hide then
				local p
				self.sleeping={ground=pos,pos={pos0=pos}}
				for i=1,3,1 do
					p={x=pos.x,y=pos.y-i,z=pos.z}
					local n=minetest.get_node(p)
					self.sleeping.pos["pos" .. i]=p
					if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].walkable==false then
						self.sleeping=nil
						self.pull_down=nil
						return
					end
				end
				aliveai.rndwalk(self,false)
				aliveai.stand(self)
				return self
			end
		elseif math.random(1,10)==1 then
			local pos=self.object:getpos()
			pos.y=pos.y-1.5
			local n=minetest.get_node(pos)
			if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].tiles then
				local tiles=minetest.registered_nodes[n.name].tiles
				if type(tiles)=="table" and type(tiles[1])=="string" then
				self.tex=tiles[1]
				self.object:set_properties({
					mesh = aliveai.character_model,
					textures = {tiles[1]},
				})
				end
			end 
		end
	end,
	on_punched=function(self,puncher)
		self.object:set_properties({
			mesh = aliveai.character_model,
			textures = {"aliveai_threats_pull.png"},
		})
		local pos=self.object:getpos()
			minetest.add_particlespawner({
			amount = 5,
			time =0.05,
			minpos = pos,
			maxpos = pos,
			minvel = {x=-2, y=-2, z=-2},
			maxvel = {x=1, y=0.5, z=1},
			minacc = {x=0, y=-8, z=0},
			maxacc = {x=0, y=-10, z=0},
			minexptime = 2,
			maxexptime = 1,
			minsize = 0.1,
			maxsize = 2,
			texture = self.tex or "default_dirt.png",
			collisiondetection = true,
		})
		self.tex=nil
		if self.sleeping or self.hide then self.abortsleep=true end
		if self.hide or not self.fight then return end
		if not self.ohp then self.ohp=self.object:get_hp()*0.8 return end
		if self.ohp>self.object:get_hp() then
			local pos=self.object:getpos()
			local n=minetest.get_node(pos)
			if minetest.registered_nodes[n.name] and minetest.registered_nodes[n.name].walkable then return end
			self.hide=true
			self.ohp=nil
			self.time=0.2
			self.pull_down=nil
			return self
		end
	end
})

minetest.register_craft({
	output = "aliveai_threats:mind_manipulator",
	recipe = {
		{"default:steel_ingot", "default:papyrus"},
		{"default:steel_ingot", "default:mese_crystal"},
		{"default:steel_ingot", "default:obsidian_glass"},
	}
})

minetest.register_tool("aliveai_threats:mind_manipulator", {
	description = "Mind manipulator",
	inventory_image = "aliveai_threats_mind_manipulator.png",
		on_use = function(itemstack, user, pointed_thing)
			if pointed_thing.type=="object" then
				local ob=pointed_thing.ref
				if ob:get_luaentity() and ob:get_luaentity().type and ob:get_luaentity().type=="monster" then
					ob:get_luaentity().team="mind_manipulator" .. math.random(1,100)
				elseif ob:get_luaentity() then
					ob:get_luaentity().type="monster"
					ob:get_luaentity().team="mind_manipulator" .. math.random(1,100)
					ob:get_luaentity().attack_players=1
					ob:get_luaentity().attacking=1
					ob:get_luaentity().talking=0
					ob:get_luaentity().light=0
					ob:get_luaentity().building=0
					ob:get_luaentity().fighting=1
					ob:get_luaentity().attack_chance=2
--support for other mobs
					ob:get_luaentity().attack_type="dogfight"
					ob:get_luaentity().reach=2
					ob:get_luaentity().damage=3
					ob:get_luaentity().view_range=10
					ob:get_luaentity().walk_velocity= ob:get_luaentity().walk_velocity or 2
					ob:get_luaentity().run_velocity= ob:get_luaentity().run_velocity or 2
				elseif ob:is_player() then
					ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=5}},nil)
						ob:set_properties({
							mesh = aliveai.character_model,
							textures = {"aliveai_threats_mind_manipulator.png"}
						})
					if ob:get_hp()<=0 and aliveai.registered_bots["bot"] and aliveai.registered_bots["bot"].bot=="aliveai:bot" then
						local tex=ob:get_properties().textures
						local pos=ob:getpos()
						local m=minetest.add_entity(pos, "aliveai:bot")
						m:get_luaentity().attack_chance=2
						m:get_luaentity().type="monster"
						m:get_luaentity().team="mind_manipulator" .. math.random(1,100)
						m:get_luaentity().attack_players=1
						m:get_luaentity().attacking=1
						m:get_luaentity().talking=0
						m:get_luaentity().light=0
						m:get_luaentity().building=0
						m:get_luaentity().fighting=1
						m:setyaw(math.random(0,6.28))
						m:set_properties({
							mesh = aliveai.character_model,
							textures = tex
						})
					end
				end
			end
		end
})



aliveai.create_bot({
		drop_dead_body=0,
		attack_players=1,
		name="cockroach",
		team="bug",
		texture={"aliveai_threats_cockroach.png","aliveai_threats_cockroach.png","aliveai_threats_cockroach.png","aliveai_threats_cockroach.png","aliveai_threats_cockroach.png","aliveai_threats_cockroach.png"},
		attacking=1,
		talking=0,
		light=0,
		building=0,
		escape=0,
		type="monster",
		dmg=1,
		hp=4,
		name_color="",
		arm=2,
		coming=0,
		smartfight=0,
		spawn_on={"group:sand","default:dirt_with_grass","default:dirt_with_dry_grass","default:gravel"},
		attack_chance=2,
		visual="cube",
		visual_size={x=0.4,y=0.001},
		collisionbox={-0.1,0,-0.1,0.2,0.1,0.2},
		basey=0,
		distance=10,
	on_load=function(self)
		if self.clone then
			self.object:remove()
		end
	end,
	on_step=function(self,dtime)
		if self.fight then
			local pos=aliveai.roundpos(self.object:getpos())
			local n=0
			for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 20)) do
				local en=ob:get_luaentity()
				if en and en.name=="aliveai_threats:cockroach" then
					n=n+1
				end
			end
			if n<10 then
				for y=-2,5,1 do
				for x=-2,2,1 do
				for z=-2,2,1 do
					local p1={x=pos.x+x,y=pos.y+y,z=pos.z+z}
					local p2={x=pos.x+x,y=pos.y+y-1,z=pos.z+z}
					local no1=minetest.get_node(p1).name
					local no2=minetest.get_node(p2).name
					if not (minetest.registered_nodes[no1] and minetest.registered_nodes[no2]) then return end
					if minetest.registered_nodes[no1].walkable==false and minetest.registered_nodes[no2].walkable
					and aliveai.visiable(pos,p1) then
						local e=minetest.add_entity(p1,"aliveai_threats:cockroach")
						e:get_luaentity().clone=1
						e:get_luaentity().fight=self.fight
						e:get_luaentity().temper=3
						e:setyaw(math.random(0,6.28))
						n=n+1
						if n>=10 then
							return
						end
					end
					end
					end
				end
			end
		elseif self.clone and not self.fight then
			self.object:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.object:get_hp()*2}},nil)
		end
	end,
	on_click=function(self,clicker)
		clicker:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.object:get_hp()*2}},nil)
	end,
	on_death=function(self,puncher,pos)
		local pos=self.object:getpos()
			minetest.add_particlespawner({
			amount = 5,
			time =0.05,
			minpos = pos,
			maxpos = pos,
			minvel = {x=-2, y=-2, z=-2},
			maxvel = {x=1, y=0.5, z=1},
			minacc = {x=0, y=-8, z=0},
			maxacc = {x=0, y=-10, z=0},
			minexptime = 2,
			maxexptime = 1,
			minsize = 0.1,
			maxsize = 1,
			texture = "default_dirt.png^[colorize:#000000cc",
			collisiondetection = true,
		})
		return self
	end,
})


aliveai.create_bot({
		attack_players=1,
		name="ninja",
		team="bug",
		texture="aliveai_threats_ninja.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		start_with_items={["default:sword_steel"]=1},
		type="",
		hp=30,
		name_color="",
		attack_chance=2,
	on_step=function(self,dtime)
		if not self.finvist and (self.fight or self.fly) then
			self.finvist=true
				self.object:set_properties({
					is_visible=false,
					makes_footstep_sound=false,
					textures={"aliveai_threats_i.png","aliveai_threats_i.png","aliveai_threats_i.png"}
				})
		elseif self.finvist and not (self.fight or self.fight) then
			self.finvist=nil
			self.object:set_properties({
				is_visible=true,
				makes_footstep_sound=true,
				textures={"aliveai_threats_ninja.png","aliveai_threats_i.png","aliveai_threats_i.png"}
			})
		elseif self.finvist and self.fight then
			if math.random(1,10)<3 then
				self.object:set_properties({is_visible=true})
			else
				self.object:set_properties({is_visible=false})

				if math.random(1,5)==1 then
					local pos=self.object:getpos()
					for _, ob in ipairs(minetest.get_objects_inside_radius(pos, self.distance/2)) do
						local en=ob:get_luaentity()
						if en and en.aliveai and en.fight and en.fight:get_luaentity() and en.fight:get_luaentity().aliveai and en.fight:get_luaentity().botname==self.botname then
							ob:get_luaentity().fight=nil
						end
					end
				end

			end
		end
	end,
	on_punched=function(self,puncher)
		local pos=self.object:getpos()
		if self.finvist then
			self.finvist=nil
			self.object:set_properties({
				is_visible=true,
				makes_footstep_sound=true,
				textures={"aliveai_threats_ninja.png","aliveai_threats_i.png","aliveai_threats_i.png"},
			})
		end
		minetest.add_particlespawner({
			amount = 5,
			time =0.05,
			minpos = pos,
			maxpos = pos,
			minvel = {x=-2, y=-2, z=-2},
			maxvel = {x=1, y=0.5, z=1},
			minacc = {x=0, y=-8, z=0},
			maxacc = {x=0, y=-10, z=0},
			minexptime = 2,
			maxexptime = 1,
			minsize = 0.1,
			maxsize = 2,
			texture = "default_dirt.png^[colorize:#000000cc",
			collisiondetection = true,
		})
	end
})

minetest.register_tool("aliveai_threats:quantumcore", {
	description = "Quantum core",
	inventory_image = "aliveai_threats_quantumcore.png",
	range = 15,
	on_use=function(itemstack, user, pointed_thing)
		if user:get_luaentity() then user=user:get_luaentity() end
		local type=pointed_thing.type
		if type=="node" or type=="object" then
			local pos=pointed_thing.above
			if type=="object" then
				pos=pointed_thing.ref:getpos()
			end
			local n1=minetest.registered_nodes[minetest.get_node(pos).name]
			pos.y=pos.y+1
			local n2=minetest.registered_nodes[minetest.get_node(pos).name]
			if n1 and n2 and not (n1.walkable and n2.walkable) then
				user:setpos(pos)
			end
		else
			aliveai_threats.quantumcoremove(user)	
		end

	end,
	on_place=function(itemstack, user, pointed_thing)
		aliveai_threats.quantumcoremove(user)	
	end
})

aliveai_threats.quantumcoremove=function(user)
			distance=15
			local pos=aliveai.roundpos(user:getpos())
			local tpto={x=pos.x,y=pos.y,z=pos.z}
			local tpto_d=0
			local opos={x=pos.x,y=pos.y,z=pos.z}

			local air=minetest.get_content_id("air")
			local pos1 = vector.subtract(pos, distance)
			local pos2 = vector.add(pos, distance)
			local vox = minetest.get_voxel_manip()
			local min, max = vox:read_from_map(pos1, pos2)
			local area = VoxelArea:new({MinEdge = min, MaxEdge = max})
			local data = vox:get_data()
			for z = -distance, distance do
			for y = -distance, distance do
			for x = -distance, distance do
				local v = area:index(pos.x+x,pos.y+y,pos.z+z)
				local p={x=pos.x+x,y=pos.y+y-1,z=pos.z+z}
				local n=minetest.registered_nodes[minetest.get_node(p).name]
				if data[v]==air and n and n.walkable and math.random(1,10)==1 then
					local a=true
					for i=1,3,1 do
						local p2={x=pos.x+x,y=pos.y+y+i,z=pos.z+z}
						local n=minetest.registered_nodes[minetest.get_node(p2).name]
						if not n or n.walkable then a=false end
					end
					if a and aliveai.distance(opos,p)>tpto_d then
						p.y=p.y+1
						tpto=p
						tpto_d=aliveai.distance(opos,p)
					end
				end
			end
			end
			end
			if tpto then
				user:setpos(tpto)
			end
end


aliveai.create_bot({
		attack_players=1,
		name="quantum_monster",
		team="bug",
		texture="aliveai_threats_quantum_monster.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		start_with_items={["aliveai_threats:quantumcore"]=1},
		type="",
		hp=40,
		name_color="",
		visual_size={x=1,y=1.4},
		collisionbox={-0.33,-1.3,-0.33,0.33,1.2,0.33},
		spawn_y=1,
	on_step=function(self,dtime)
		if self.fight and not self.fly and (math.random(1,5)==1 or self.epunched) then
			self.epunched=nil
			local p=aliveai.roundpos(self.fight:getpos())
			if not p then self.fight=nil return end
			local pos={x=p.x+math.random(-1,4),y=p.y,z=p.z+math.random(-1,4)}
			for i=-2,2,1 do
				local pos1={x=pos.x,y=pos.y+i,z=pos.z}
				local pos2={x=pos.x,y=pos.y+i+1,z=pos.z}
				local pos3={x=pos.x,y=pos.y+i+2,z=pos.z}
				local pos4={x=pos.x,y=pos.y+i+3,z=pos.z}

				local n1=minetest.registered_nodes[minetest.get_node(pos1).name]
				local n2=minetest.registered_nodes[minetest.get_node(pos2).name]
				local n3=minetest.registered_nodes[minetest.get_node(pos3).name]
				local n4=minetest.registered_nodes[minetest.get_node(pos4).name]

				if n2 and n2.walkable==false and n1 and n3 and n4 and n1.walkable and not (n3.walkable and n4.walkable) then
					pos2.y=pos2.y+1
					self.object:setpos(pos2)
				end
			end
		elseif self.fly and (self.epunched or aliveai.distance(self,self.fly:getpos())<self.distance) then
			self.epunched=nil
			local pos=aliveai.roundpos(self.object:getpos())
			local air=minetest.get_content_id("air")
			local pos1 = vector.subtract(pos, self.distance)
			local pos2 = vector.add(pos, self.distance)
			local vox = minetest.get_voxel_manip()
			local min, max = vox:read_from_map(pos1, pos2)
			local area = VoxelArea:new({MinEdge = min, MaxEdge = max})
			local data = vox:get_data()
			for z = -self.distance, self.distance do
			for y = -self.distance, self.distance do
			for x = -self.distance, self.distance do
				local v = area:index(pos.x+x,pos.y+y,pos.z+z)
				local p={x=pos.x+x,y=pos.y+y-1,z=pos.z+z}
				local n=minetest.registered_nodes[minetest.get_node(p).name]
				if data[v]==air and n and n.walkable and not (self.tpto_d and math.random(1,10)~=1) then
					local a=true
					for i=1,3,1 do
						local p2={x=pos.x+x,y=pos.y+y+i,z=pos.z+z}
						local n=minetest.registered_nodes[minetest.get_node(p2).name]
						if not n or n.walkable then a=false end
					end
					if a and (not self.tpto_d or aliveai.distance(self.fly:getpos(),p)>self.tpto_d) then
						p.y=p.y+2
						self.tpto=p
						self.tpto_d=aliveai.distance(self.fly:getpos(),p)
					end
				end
			end
			end
			end
			if self.tpto then
				self.object:setpos(self.tpto)
				self.tpto=nil
				self.tpto_d=nil
			end
		end

		local p=self.object:getpos()
		minetest.add_particlespawner({
			amount = 20,
			time =1,
			minpos = {x=p.x+1,y=p.y+1,z=p.z+1},
			maxpos = {x=p.x-1,y=p.y-1,z=p.z-1},
			minvel = {x=0, y=0, z=0},
			maxvel = {x=0, y=0, z=0},
			minacc = {x=0, y=0, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 0.5,
			maxexptime = 1,
			minsize = 0.4,
			maxsize = 0.8,
			glow=15,
			texture = "aliveai_threats_quantum_monster_lights.png",
		})

	end,
	on_punched=function(self,puncher)
		local pos=self.object:getpos()
		self.epunched=true
		minetest.add_particlespawner({
			amount = 5,
			time =0.05,
			minpos = pos,
			maxpos = pos,
			minvel = {x=-2, y=-2, z=-2},
			maxvel = {x=1, y=0.5, z=1},
			minacc = {x=0, y=-8, z=0},
			maxacc = {x=0, y=-10, z=0},
			minexptime = 2,
			maxexptime = 1,
			minsize = 0.1,
			maxsize = 2,
			texture = "default_dirt.png^[colorize:#000000cc",
			collisiondetection = true,
		})
	end
})

minetest.register_globalstep(function(dtime)
	for i, o in pairs(aliveai_threats.debris) do
		if o.ob and o.ob:get_luaentity() and o.ob:get_hp()>0 and o.ob:getvelocity().y~=0 then
			for ii, ob in pairs(minetest.get_objects_inside_radius(o.ob:getpos(), 1.5)) do
				local en=ob:get_luaentity()
				if not en or (en.name~="__builtin:item" and not (en.aliveai and en.botname==o.n) ) then
					ob:punch(o.ob,1,{full_punch_interval=1,damage_groups={fleshy=1}},nil)
					o.ob:setvelocity({x=0, y=0, z=0})
					table.remove(aliveai_threats.debris,i)
					break
				end
			end
		else
			table.remove(aliveai_threats.debris,i)
		end
	end
end)


aliveai.create_bot({
		attack_players=1,
		name="natural_monster",
		team="natural",
		texture="aliveai_threats_natural_monster.png",
		attacking=1,
		talking=0,
		light=0,
		building=0,
		type="monster",
		hp=10,
		name_color="",
		collisionbox={-0.5,-0.5,-0.5,0.5,0.5,0.5},
		visual="cube",
		basey=-0.5,
		drop_dead_body=0,
		escape=0,
		spawn_on={"group:sand","group:soil","default:snow","default:snowblock","default:ice","group:leaves","group:tree","group:stone","group:cracky","group:level","group:crumbly","group:choppy"},
		attack_chance=2,
		spawn_chance=100,
	on_spawn=function(self)
		local pos=self.object:getpos()
		pos.y=pos.y-1.5
		if minetest.get_node(pos).name=="aliveai:spawner" then pos.y=pos.y-1 end
		local drop=minetest.get_node_drops(minetest.get_node(pos).name)[1]
		local n=minetest.registered_nodes[minetest.get_node(pos).name]
		if not (n and n.walkable) or drop=="" or type(drop)~="string" then self.object:remove() return self end
		local t=n.tiles
		if not t[1] then self.object:remove() return self end
		local tx={}
		self.t1=t[1]
		self.t2=t[1]
		self.t3=t[1]
		self.natural_monster=1
		self.consists=drop
		self.team=self.consists
		if t[2] then self.t2=t[2] self.t3=t[2] end
		if t[3] and t[3].name then self.t3=t[3].name
		elseif t[3] then self.t3=t[3]
		end
		tx[1]=self.t1
		tx[2]=self.t2
		tx[3]=self.t3
		tx[4]=self.t3
		tx[5]=self.t3 .."^aliveai_threats_natural_monster.png"
		tx[6]=self.t3
		self.object:set_properties({textures=tx})
		self.cctime=0
	end,	
	on_load=function(self)
		if self.natural_monster then
			local tx={}
			tx[1]=self.t1
			tx[2]=self.t2
			tx[3]=self.t3
			tx[4]=self.t3
			tx[5]=self.t3 .."^aliveai_threats_natural_monster.png"
			tx[6]=self.t3
			self.object:set_properties({textures=tx})
			self.team=self.consists
			self.cctime=0
		else
			self.object:remove()
		end
	end,
	on_step=function(self,dtime)
		if self.fight and (self.cctime<1 or self.time==self.otime) then
			self.cctime=5
			local d=aliveai.distance(self,self.fight:getpos())
			if not (d>4 and d<self.distance and aliveai.viewfield(self,self.fight) and aliveai.visiable(self,self.fight:getpos())) then return end
			local pos=self.object:getpos()
			local ta=self.fight:getpos()
			if not (ta and pos) then return end
			aliveai.stand(self)
			aliveai.lookat(self,ta)

			local e=minetest.add_item({x=pos.x,y=pos.y,z=pos.z},self.consists)
			local dir=aliveai.get_dir(self,ta)
			local vc = {x = dir.x*30, y = dir.y*30, z = dir.z*30}
			e:setvelocity(vc)

			e:get_luaentity().age=(tonumber(minetest.setting_get("item_entity_ttl")) or 900)-2
			table.insert(aliveai_threats.debris,{ob=e,n=self.botname})
			return self
		elseif self.fight and self.cctime>1 then
			self.cctime=self.cctime-1
		end
	end,
	on_death=function(self,puncher,pos)
		aliveai.invadd(self,self.consists,math.random(1, 4),false)
	end,
	on_punched=function(self,puncher)
		local pos=self.object:getpos()
		aliveai.lookat(self,pos)
		minetest.add_particlespawner({
			amount = 5,
			time =0.05,
			minpos = pos,
			maxpos = pos,
			minvel = {x=-2, y=-2, z=-2},
			maxvel = {x=1, y=0.5, z=1},
			minacc = {x=0, y=-8, z=0},
			maxacc = {x=0, y=-10, z=0},
			minexptime = 2,
			maxexptime = 1,
			minsize = 0.2,
			maxsize = 4,
			texture = self.t1,
			collisiondetection = true,
		})
	end
})

aliveai.create_bot({
		type="npc",
		name="stubborn_monster",
		texture="aliveai_threats_stubborn_monster.png",
		hp=20,
		drop_dead_body=0,
		usearmor=0,
	on_load=function(self)
		if not self.body or self.killed then self.on_spawn(self) return self end
		local s={}
		local c=""
		local t=""
		for i,v in ipairs(self.body) do
			s["s"..v]=v
			if i>1 then c="^" end
			t=t .. c.. "aliveai_threats_stubborn_monster" .. v ..".png"
		end
		self.object:set_properties({
				mesh = aliveai.character_model,
				textures = {t,"aliveai_threats_i.png","aliveai_threats_i.png"},
		})
		if not s["s3"] then 
			self.object:set_properties({
				mesh = aliveai.character_model,
				collisionbox={-0.3,-0.3,-0.3,0.3,0.7,0.3},
			})
			self.basey=-0.5 
		end
		if not s["s4"] then self.nhead=true end
		self.on_spawn(self)
	end,
	on_spawn=function(self)
		if not self.body then
			self.body={1,2,3,4}
		end
		self.hp2=self.object:get_hp()
		self.deadtimer=10
		self.hurted=0
		if self.killed then
			self.attack_players=1
			self.attacking=1
			self.team="stubborn"
			self.talking=0
			self.light=0
			self.building=0
			self.type="monster"
			self.escape=0
			self.attack_chance=1
			self.smartfight=0
		end

	end,
	on_step=function(self,dtime)
		if self.dead1 then
			self.time=self.otime
			self.deadtimer=self.deadtimer-1
			if self.deadtimer<0 then 
				self.object:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=self.hp*2}},nil)
			end
			return self
		end

		if self.lay then
			self.time=self.otime
			if math.random(0,5)==1 then
				if self.basey==-0.5 then self.object:set_properties({mesh = aliveai.character_model,collisionbox={-0.3,-0.3,-0.3,0.3,0.7,0.3}}) end
				aliveai.anim(self,"stand")
				self.lay=nil
			end
			return self
		end
		if self.nhead then
			self.fight=nil
			self.fly=nil
			self.temper=0
			self.come=nil
		end
	end,
	on_punched=function(self,puncher,h) 
		self.hurted=h
	end,
	on_death=function(self,puncher,pos)
		local r=math.random(1,5)
		if r>4 then
			if self.basey==-0.5 then self.object:set_properties({mesh = aliveai.character_model,collisionbox={-0.35,-1.0,-0.35,0.35,0.8,0.35}}) local pos=self.object:getpos() self.object:setpos({x=pos.x,y=pos.y+1,z=pos.z}) end
			aliveai.anim(self,"lay")
			self.lay=true
		end

		if r<3 or not self.killed then
			r=math.random(1,4)
			table.remove(self.body,r)
			local t=""
			local c=""
			local col=self.object:get_properties().collisionbox
			local c2=0
			for i,v in ipairs(self.body) do
				if i>1 then c="^" end
				t=t .. c.. "aliveai_threats_stubborn_monster" .. v ..".png"
				c2=i
			end
			if r==3 then self.basey=-0.5 col={-0.3,-0.3,-0.3,0.3,0.7,0.3} end
			self.object:set_properties({
				mesh = aliveai.character_model,
				textures = {t,"aliveai_threats_i.png","aliveai_threats_i.png"},
				collisionbox=col,
			})
			if r==1 or c2==1 or self.hurted>self.hp_max then
				if self.basey==-0.5 then self.object:set_properties({mesh = aliveai.character_model,collisionbox={-0.35,-1.0,-0.35,0.35,0.8,0.35}}) local pos=self.object:getpos() self.object:setpos({x=pos.x,y=pos.y+1,z=pos.z}) end
				aliveai.anim(self,"lay")
				self.object:set_hp(self.hp_max)
				self.hp=self.hp_max
				self.dead1=true
				return self
			end
			if r==4 then self.nhead=true end
			if not self.killed then
				self.killed=1
				self.on_spawn(self)
			end
		end
		if not self.dead1 then
			self.hp_max=self.hp_max-2
			self.object:set_hp(self.hp_max)
			self.hp=self.hp_max
		end
	end
})

