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
		self.object:setacceleration({x =0, y =-10, z =0})
		self.object:setvelocity({x=math.random(-15,15),y=math.random(10,15),z=math.random(-15,15)})
		return self
	end,
	on_step=function(self, dtime)
		self.time=self.time+dtime
		self.time2=self.time2-dtime
		local v=self.object:getvelocity()
		if self.time2>1 and (v.y==0) then
			self.time2=0.1
			return self
		end
		if self.time<0.1 then return self end
		self.time=0
		for _, ob in ipairs(minetest.get_objects_inside_radius(self.object:getpos(), 2)) do
			local en=ob:get_luaentity()
			if not (en and en.aliveaibomb) then
				self.time2=-1
				return self
			end
		end
		if self.time2<0 then
			aliveai_nitroglycerine.explode(self.object:getpos(),{radius=3,set="air",drops=0,place={"air","air"}})
			self.object:remove()
		end
		return self
	end,
	time=0,
	time2=10,
	type="",
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

		if self.hp<1 and not self.exp then self.expl(self,self.object:getpos()) end
		self.exp=nil
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