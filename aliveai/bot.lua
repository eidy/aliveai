aliveai.bot=function(self, dtime)
	self.timer=self.timer+dtime
	self.timerfalling=self.timerfalling+dtime
	if self.timerfalling>0.2 then aliveai.falling(self) end
	if self.timer<=self.time then return self end
	self.timer=0

	if aliveai.regulate_prestandard>0 and math.random(1,aliveai.regulate_prestandard)==1 then return self end
--betweens
	if not aliveai.dmgbynode(self) then return self end
	if self.step(self,dtime) then return self end
	aliveai.jumping(self)-- if need to jump
	if aliveai.fight(self) then return self end
	if aliveai.fly(self) then return self end
	if aliveai.come(self) then return self end
	if aliveai.need_helper(self) then return self end	-- give stuff
	if aliveai.light(self) then return self end
	if aliveai.timer(self) then return self end		-- remove monsters
	aliveai.msghandler(self)
	
	aliveai.pickup(self)-- if can pick up items

--betweens helpers
	if self.isrnd and self.pickupgoto then return self end
--events
	if self.mine then
		aliveai.mine(self)
		return self
	end
	if self.findspace then
		aliveai.findspace(self)
		return self
	end
	if self.build then
		aliveai.build(self)
		return self
	end
--tasks
	if self.task=="build" then
		aliveai.task_build(self)
		return self
	end
--task create
	if aliveai.enable_build==true and self.building==1 and self.task=="" and not self.home then			--setting up for build a home
		aliveai.showstatus(self,"set up for build a home")
		self.build_step=1
		self.build_pos=""
		self.task="build"
		self.ignoremineitem=""
		self.ignoreminetime=0
		self.ignoreminetimer=200
		self.ignoreminechange=0
		self.taskstep=0
		aliveai.rndwalk(self,false)				-- stop rnd walking
		return self
	end

	if self.task=="" then
		aliveai.rndwalk(self)
	end
	return self
end


aliveai.do_nothing=function(self)
	return
end

aliveai.create_bot=function(def)
	if not def then def={} end
	def.name=def.name or "bot"
	def.mod_name=minetest.get_current_modname()
	def.spawn_y=def.spawn_y or 0
	if aliveai.smartshop and def.on_step==nil then def.on_step=aliveai.use_smartshop end
	if not def.on_click then def.on_click=aliveai.give_to_bot end

	def.texture=def.texture or "character.png"

	local itemtexture=def.texture
	if type(def.texture)=="table" and type(def.texture[1])=="string" then itemtexture=def.texture[1] end

	if aliveai.use3d_armor_model and not def.visual and not def.texture[2] then
		def.texture={def.texture,"aliveai_air.png","aliveai_air.png"}
	elseif type(def.texture)~="table" then
		def.texture={def.texture}
	end

	aliveai.registered_bots[def.name]={
				name=def.name,
				type=def.type or "npc",
				bot=def.mod_name ..":" .. def.name,
				item=def.mod_name ..":" .. def.name .. "_spawner",
				dead="",
				spawn_y=def.spawn_y
				}

minetest.register_craftitem(def.mod_name ..":" .. def.name .."_spawner", {
	description = def.name .." spawner",
	inventory_image = itemtexture or "character.png",
		on_place = function(itemstack, user, pointed_thing)
			if pointed_thing.type=="node" then
				local pos=aliveai.roundpos(pointed_thing.above)
				pos.y=pos.y+0.5 + def.spawn_y
				minetest.add_entity(pos, def.mod_name ..":" .. def.name):setyaw(math.random(0,6.28))
				itemstack:take_item()
			end
			return itemstack
		end,
	})
	def.drop_dead_body=def.drop_dead_body or 1
	if def.texture~=nil and type(def.texture)=="string" then def.texture={def.texture} end

if def.drop_dead_body==1 then
aliveai.registered_bots[def.name].dead=def.mod_name ..":" .. def.name .."_dead"
minetest.register_entity(def.mod_name ..":" .. def.name .."_dead",{
	hp_max = def.hp or 20,
	physical = true,
	weight = 5,
	collisionbox = def.collisionbox or {-0.35,-1.0,-0.35,0.35,0.8,0.35},
	visual = def.visual or "mesh",
	visual_size = def.visual_size or {x=1,y=1},
	mesh = aliveai.character_model,
	textures = def.texture,
	colors = {},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,
	on_activate=function(self, staticdata)
		aliveai.anim(self,"lay")
		self.object:setacceleration({x=0,y=-10,z =0})
		self.object:setvelocity({x=0,y=-3,z =0})
		return self
	end,
	on_step=function(self, dtime)
		self.time=self.time+dtime
		if self.time<5 then return self end
		local pos=self.object:getpos()
		pos.y=pos.y-1
		local node=minetest.get_node(pos)
		aliveai.punch(self,self.object,self.object:get_hp()*2)
		if node and minetest.get_item_group(node.name, "igniter")>0 then
		minetest.add_particlespawner({
			amount = 10,
			time =0.2,
			minpos = {x=pos.x-1, y=pos.y, z=pos.z-1},
			maxpos = {x=pos.x+1, y=pos.y, z=pos.z+1},
			minvel = {x=0, y=0, z=0},
			maxvel = {x=0, y=math.random(3,6), z=0},
			minacc = {x=0, y=2, z=0},
			maxacc = {x=0, y=0, z=0},
			minexptime = 1,
			maxexptime = 3,
			minsize = 3,
			maxsize = 8,
			texture = "default_item_smoke.png",
			collisiondetection = true,
		})
		end
		return self
	end,
	time=0,
	type="",
	anim=""
})
end


minetest.register_entity(def.mod_name ..":" .. def.name,{
	hp_max = def.hp or 20,
	physical = true,
	weight = 5,
	collisionbox = def.collisionbox or {-0.35,-1.0,-0.35,0.35,0.8,0.35},
	visual = def.visual or "mesh",
	visual_size = def.visual_size or {x=1,y=1},
	mesh = aliveai.character_model,
	textures = def.texture,
	colors = {},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = true,
	automatic_rotate = false,
	visual=def.visual or "mesh",
on_rightclick=function(self, clicker,name)
		self.on_click(self,clicker)
	end,
on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if dir~=nil then
			self.object:setvelocity({x = dir.x*3,y = self.object:getvelocity().y,z = dir.z*3})
		end

		if tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.fleshy then
			self.hp=self.hp-tool_capabilities.damage_groups.fleshy
			self.object:set_hp(self.hp)
		end

		aliveai.showhp(self)

		if self.object:get_hp()<=0 then
			local pos=self.object:getpos()
			aliveai.invdropall(self)
			if self.drop_dead_body==1 then
				aliveai.showstatus(self,"drop dead body")
				minetest.add_entity(pos, def.mod_name ..":" .. def.name .."_dead"):setyaw(self.object:getyaw())
			end
			self.on_death(self,puncher,pos)
			aliveai.max(self,true)
			return self
		end

		self.punched(self,puncher)

		aliveai.showhp(self)
		if aliveai.armor and self.armor then aliveai.armor(self,{dmg=true}) end

		if self.path then
			aliveai.exitpath(self)
		end
		minetest.after(2, function(self)
			aliveai.eat(self,"")
		end,self)
		if not (puncher:get_luaentity() and puncher:get_luaentity().aliveai and puncher:get_luaentity().botname==self.botname) then
			local known=aliveai.getknown(self,puncher)
			if known=="member" then
				aliveai.known(self,puncher,"")
				if math.random(1,3)==1 then aliveai.say(self,"I dont like you anymore") end
				return self
			elseif self.escape==1 and known=="fly" or self.fighting~=1 then
				if self.temper>-5 then
					self.temper=self.temper-0.3
				end
				if math.random(1,3)==1 then aliveai.sayrnd(self,"ahh") end
				self.fly=puncher
			elseif self.fighting==1 then
				if self.temper<5 then
					self.temper=self.temper+1
				end
				self.fight=puncher
				if math.random(1,3)==1 then aliveai.sayrnd(self,"ouch") end
			end
			return self
		end
		if math.random(1,3)==1 then aliveai.sayrnd(self,"ouch") end
		return self
	end,
on_activate=function(self, staticdata)
		if staticdata~="" then
			local r=aliveai.convertdata(staticdata)
			self.inv={}
			self.ignore_item={}
			self.ignore_nodes={}
			self.known={}
			self.old=r.old
			self.known=r.known
			self.inv=r.inv
			self.ignore_item=r.ignore_item
			self.ignore_nodes=r.ignore_ingnore_nodes
			self.task=r.task
			self.taskstep=r.taskstep
			self.botname=r.botname
			self.start_with_items=""
			self.dmg=r.dmg 
			if r.savetool then self.tools=r.tools self.savetool=1 self.tool_near=1 end
			if r.home then self.home=r.home end
			if r.resources then self.resources=r.resources end

			if r.hp then self.object:set_hp(r.hp) end

			for i, s in pairs(aliveai.loaddata) do
				s(self,r)
			end

			aliveai.showstatus(self,"loaded")
		end
		if self.inv==nil then self.inv={} end
		if self.ignore_item==nil  then self.ignore_item={} end

		self.move={x=0,y=0,z=0,speed=1}
		aliveai.anim(self,"stand")
		self.object:setacceleration({x=0,y=-10,z =0})
		self.object:setvelocity({x=0,y=-5,z =0})
		if self.botname=="" then self.botname=aliveai.genname() end
		if self.namecolor~="" then self.object:set_properties({nametag=self.botname,nametag_color="#" .. self.namecolor}) end
		if self.start_with_items~="" and type(self.start_with_items)=="table" then
			for i, s in pairs(self.start_with_items) do
				aliveai.invadd(self,i,s,true)
			end
			self.start_with_items=""
		end

		if self.old~=1 then
			aliveai.max(self)
			self.on_spawn(self)
			aliveai.showstatus(self,"new bot spawned")
		else
			aliveai.max(self)
			self.on_load(self)
			aliveai.showstatus(self,"bot loaded")
		end
		self.hp=self.object:get_hp()
		return self
	end,
get_staticdata = function(self)
		aliveai.max(self)
		local r={inv=self.inv,old=1,hp=self.object:get_hp(),
			task=self.task,
			taskstep=self.taskstep,
			ignore_item=self.ignore_item,
			known=self.known,
			ignore_nodes=self.ignore_ingnore_nodes,
			botname=self.botname,
			dmg=self.dmg,
			}
		if self.home then r.home=self.home end
		if self.resources then r.resources=self.resources end
		if self.savetool then r.tools=self.tools r.savetool=1 end
		if self.start_with_items then r.start_with_items="" end

		for i, s in pairs(aliveai.savedata) do
			local rr=s(self,r)
			if rr then
				for i1, s2 in pairs(rr) do
					r[i1]=s2
				end
			end
		end

		return aliveai.convertdata(r)
	end,
on_step=aliveai.bot,
	on_spoken_to= def.on_spoken_to or aliveai.on_spoken_to,
	visual= def.visual or "mesh",
	basey= def.basey or 0.7,
	old= 0,
	botname=def.botname or "",
	dmg= def.dmg or 4,
	namecolor= def.name_color or "ffffff",
	temper= 0,
	rnd= 0,
	isrnd= false,
	arm= def.arm or 5,
	done="",
	avoidy= def.avoid_height or 6,
	taskstep= 0,
	task= "",
	house=def.house or "",
	pathn= 1,
	anim= "",
	timer= 0,
	time= 1,
	otime= 1,
	timer3= 0,
	timerfalling= 0,
	aliveai= true,
	drop_dead_body=def.drop_dead_body or 1,
	team= def.team or "Sam",
	type= def.type or "npc",
	distance= def.distance or 15,
	tools= def.tools or "",
	tool_index=def.tool_index or 1,
	tool_reuse=def.tool_reuse or 0,
	tool_chance= def.tool_chance or 5,
	tool_see= def.tool_see or 1,
	tool_near= def.tool_near or 0,
	escape= def.escape or 1,
	fighting= def.fighting or 1,
	attack_players= def.attack_players or 0,
	attack_chance= def.attack_chance or 10,
	smartfight= def.smartfight or 1,
	building= def.building or 1,
	pickuping= def.pickuping or 1,
	attacking= def.attacking or 0,
	coming= def.coming or 1,
	work_helper= def.work_helper or 0,
	coming_players= def.coming_players or 1,
	talking= def.talking or 1,
	stealing= def.stealing or 0,
	steal_chance= def.steal_chance or 0,
	start_with_items= def.start_with_items or "",
	light= def.light or 1,
	lowestlight= def.lowest_light or 10,
	lightdamage=def.hurts_by_light or 1,
	annoyed_by_staring= def.annoyed_by_staring or 1,
	drowning= def.drowning or 1,
	on_fighting= def.on_fighting or aliveai.do_nothing,
	on_escaping= def.on_escaping or aliveai.do_nothing,
	on_punching= def.on_punching or aliveai.do_nothing,
	on_detect_enemy= def.on_detect_enemy or aliveai.do_nothing,
	on_detecting_enemy= def.on_detecting_enemy or aliveai.do_nothing,
	on_death= def.on_death or aliveai.do_nothing,
	on_spawn= def.on_spawn or aliveai.do_nothing,
	on_load= def.on_load or aliveai.do_nothing,
	on_random_walk= def.on_random_walk or aliveai.do_nothing,
	on_click= def.on_click or aliveai.do_nothing,
	punched= def.on_punched or aliveai.do_nothing,
	on_meet= def.on_meet or aliveai.do_nothing,
	step= def.on_step or aliveai.do_nothing,
	on_dig= def.on_dig or aliveai.do_nothing,
})

def.spawn_in= def.spawn_in or "air"
def.spawn_chance= def.spawn_chance or 1000

if def.light==nil then def.light=1 end
if def.lowest_light==nil then def.lowest_light=10 end
 
minetest.register_abm({
	nodenames = def.spawn_on or {"default:dirt_with_grass","default:dirt_with_dry_grass","group:sand","default:snow"},
	interval = def.spawn_interval or 30,
	chance = def.spawn_chance,
	action = function(pos)
		local pos1={x=pos.x,y=pos.y+1,z=pos.z}
		local pos2={x=pos.x,y=pos.y+2,z=pos.z}
		local l=minetest.get_node_light(pos1)
		if l==nil then return true end
		if math.random(1,def.spawn_chance)==1
		and (def.light==0 
		or (def.light>0 and l>=def.lowest_light) 
		or (def.light<0 and l<=def.lowest_light)) then
			if aliveai.check_spawn_space==false or (minetest.get_node(pos1).name==def.spawn_in and minetest.get_node(pos2).name==def.spawn_in) then
				aliveai.newbot=true
				pos1.y=pos1.y+def.spawn_y
				minetest.add_entity(pos1, def.mod_name ..":" .. def.name):setyaw(math.random(0,6.28))
			end
		end
	end,
})
print("[aliveai] loaded: " .. def.mod_name ..":" .. def.name)
end