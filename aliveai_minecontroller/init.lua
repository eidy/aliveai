﻿aliveai_minecontroller={timer=0,users={}}

minetest.register_craft({
	output = "aliveai_minecontroller:controller",
	recipe = {
		{"default:steel_ingot","default:diamond","default:steel_ingot"},
		{"default:steel_ingot","default:mese","default:steel_ingot"},
		{"default:steel_ingot","default:obsidian_shard","default:steel_ingot"},
	}
})



minetest.register_tool("aliveai_minecontroller:controller", {
	description = "Mind manipulator",
	inventory_image = "aliveai_minecontroller.png",
	on_use = function(itemstack, user, pointed_thing)
		local username=user:get_player_name()
		if pointed_thing.type=="object" and not aliveai_minecontroller.users[username] then
			if not pointed_thing.ref:get_luaentity() then return end
			if user:get_luaentity() then
				pointed_thing.ref:get_luaentity().controlled=1
				return
			end
			local pos=user:getpos()
			local e={}
			e.username=username
			e.user=user
			e.pos=pos
			e.texture=e.user:get_properties().textures
			e.ob=pointed_thing.ref
			e.ob:get_luaentity().controlled=1
			e.hp=e.ob:get_luaentity().hp

			if mobs and mobs.spawning_mobs and mobs.spawning_mobs[e.ob:get_luaentity().name] then e.mobs=true else e.aliveai=true end
			if not (pointed_thing.ref:get_luaentity() and pointed_thing.ref:get_luaentity().aliveai or e.mobs) then return itemstack end

			aliveai_minecontroller.users[username]={}
			aliveai_minecontroller.users[username]=e
			aliveai_minecontroller.usersname=username
			if armor and armor.textures[username] then
				e.texture[1]=armor.textures[username].skin
				e.texture[2]=armor.textures[username].armor
				e.texture[3]=armor.textures[username].weilditem
			end
			local m=minetest.add_entity({x=pos.x,y=pos.y+1,z=pos.z}, "aliveai_minecontroller:standing_player")
			m:setyaw(user:get_look_yaw()-math.pi/2)
			user:set_nametag_attributes({color={a=0,r=255,g=255,b=255}})
			user:set_attach(e.ob, "",{x = 0, y = 0, z = 0}, {x = 0, y = -10, z = 0})
			user:set_look_horizontal(e.ob:getyaw())
			user:set_eye_offset({x = 0, y = -11, z = 5}, {x = 0, y = 0, z = 0})
			user:set_properties({visual_size = {x=0, y=0},visual="mesh"})
		elseif pointed_thing.type=="object" then
			local e=aliveai_minecontroller.users[username]
			if not (e.ob and e.ob:get_luaentity()) then return itemstack end
			if e.mobs then
				e.mob_restore={type=e.ob:get_luaentity().type,team=e.ob:get_luaentity().team}
				e.ob:get_luaentity().type="monster"
				e.ob:get_luaentity().team="mobs".. math.random(1,100)
				e.ob:get_luaentity().attack_type= e.ob:get_luaentity().attack_type or "dogfight"
				e.ob:get_luaentity().reach=2
				e.ob:get_luaentity().damage=e.ob:get_luaentity().damage or 3
				e.ob:get_luaentity().view_range=10
				e.ob:get_luaentity().walk_velocity= e.ob:get_luaentity().walk_velocity or 2
				e.ob:get_luaentity().run_velocity= e.ob:get_luaentity().run_velocity or 2
				do_attack(e.ob:get_luaentity(), pointed_thing.ref)
				return
			end
			if pointed_thing.ref:get_luaentity() and e.aliveai and pointed_thing.ref:get_luaentity().name=="__builtin:item" then
				aliveai.pickup(e.ob:get_luaentity(),true)
			end
			e.punch=true
			aliveai.punch(e.ob:get_luaentity(),pointed_thing.ref,e.ob:get_luaentity().dmg)
			e.ob:get_luaentity().fight=pointed_thing.ref
		elseif pointed_thing.type=="node" and aliveai_minecontroller.users[username] and aliveai_minecontroller.users[username].aliveai then
			local e=aliveai_minecontroller.users[username]
			if not (e.ob and e.ob:get_luaentity()) then return itemstack end
			aliveai.dig(e.ob:get_luaentity(),pointed_thing.under)
			e.punch=true
		elseif pointed_thing.type=="nothing" and aliveai_minecontroller.users[username] and aliveai_minecontroller.users[username].mobs then
			local e=aliveai_minecontroller.users[username]
			if e.mob_restore then
				e.ob:get_luaentity().type=e.mob_restore.type
				e.ob:get_luaentity().team=e.mob_restore.team
				e.ob:get_luaentity().state=""
				e.mob_restore=nil
			end
			minetest.sound_play(e.ob:get_luaentity().sounds.random, {
				object = e.ob,
				max_hear_distance = e.ob:get_luaentity().sounds.distance
			})
			if e.ob:get_luaentity().do_custom then e.ob:get_luaentity().do_custom(e.ob:get_luaentity()) end


		end
		return itemstack
	end,
	on_place = function(itemstack, user, pointed_thing)
		local username=user:get_player_name()
		if pointed_thing.type=="node" and aliveai_minecontroller.users[username] and aliveai_minecontroller.users[username].aliveai then
			local e=aliveai_minecontroller.users[username]
			if not (e.ob and e.ob:get_luaentity()) then return itemstack end
			local key=e.user:get_player_control()
			if not e.selected or (key.jump and key.RMB) then
				aliveai_minecontroller.show_inventory(e)
			else
				aliveai.place(e.ob:get_luaentity(),pointed_thing.above,e.selected)
			end
		end
		return itemstack
	end
})

aliveai_minecontroller.show_inventory=function(e)
	local c=0
	local gui=""
	local but=""
	local but2=""
	local x=0
	local y=0

	for i, v in pairs(e.ob:get_luaentity().inv) do
		c=c+1
		but=but .. "item_image_button[" .. x.. "," .. y .. ";1,1;".. i ..";use" .. c ..";\n".. v .. "]"
		x=x+1
		if x>=20 then
			x=0 y=y+1
			if y>9 then break end
		end
	end

	x=-1
	c=0
	gui=""
	.."size[20,10]"
	.. but
	minetest.after((0.1), function(gui)
		return minetest.show_formspec(e.username, "aliveai_minecontroller.form",gui)
	end, gui)
end

minetest.register_on_player_receive_fields(function(player, form, pressed)
	if form=="aliveai_minecontroller.form" then
		local e=aliveai_minecontroller.users[player:get_player_name()]
		if pressed.quit or not (e and e.ob) then
			return
		end
		local c=0
		local self=e.ob:get_luaentity()
		for i, v in pairs(self.inv) do
			c=c+1
			if pressed["use" .. c] then
				if minetest.registered_tools[i] and minetest.registered_tools[i].on_use then
					self.tools={i}
					self.tool_near=1
					self.savetool=1
					minetest.chat_send_player(e.username,"<".. self.botname.. "> " ..i .. " is used as tool")
				else
					if e.hp<self.hp_max and aliveai.eat(self,i) then
						minetest.chat_send_player(e.username,"<".. self.botname.. "> Health: " .. e.hp)
						return
					end
					minetest.chat_send_player(e.username,"<".. self.botname.. "> " ..i .. " is selected")
					e.selected=i
				end
				return
			end
		end
	end
end)


minetest.register_globalstep(function(dtime)
	aliveai_minecontroller.timer=aliveai_minecontroller.timer+dtime
	if aliveai_minecontroller.timer<0.2 then return end
	aliveai_minecontroller.timer=0
	for i, e in pairs(aliveai_minecontroller.users) do

		if not e.user or not e.user:get_attach() or not e.ob:get_luaentity() or e.ob:get_hp()<=0 then
			aliveai_minecontroller.exit(e)
			return
		end
		local self=e.ob:get_luaentity()
		
		local key=e.user:get_player_control()

		if e.hp~=self.hp then e.hp=self.hp minetest.chat_send_player(e.username,"<".. self.botname.. "> Health: " .. e.hp) end

		if key.left then
			if e.mobs then self.order="" end
			self.controlled=0
			e.user:set_eye_offset({x = 0, y = -11, z = 0}, {x = 0, y = 0, z = 0})
		elseif key.right then
			self.controlled=1
			e.user:set_eye_offset({x = 0, y = -11, z = 5}, {x = 0, y = 0, z = 0})
		elseif self.controlled==0 then
			e.user:set_look_horizontal(e.ob:getyaw())
		end
		if e.mobs and self.rotate and self.rotate~=0 then
			e.ob:setyaw(e.user:get_look_yaw() + self.rotate*4 or -1.57)
		else
			e.ob:setyaw(e.user:get_look_yaw()-1.57)
		end
		if key.up then
			if e.aliveai then
				aliveai.walk(self)
			elseif e.mobs then
				self.order=""
				set_velocity(self,self.walk_velocity)
			end

		elseif key.down then
			if e.aliveai then
				aliveai.walk(self,2)
			elseif e.mobs then
				self.order=""
				set_velocity(self,self.run_velocity)
			end
		else
			if e.aliveai then
				aliveai.stand(self)
			elseif e.mobs then
				self.order="stand"
				set_velocity(self, 0)
			end
		end
		if key.jump then
			local self=self
			if e.aliveai and key.down then
				aliveai.jump(self,{y=7})
			elseif e.aliveai then
				aliveai.jump(self)
			elseif e.mobs and self.jump then
				local p=e.ob:getpos()
				p.y=p.y-2
				local n=minetest.get_node(p).name
				if minetest.registered_nodes[n] and minetest.registered_nodes[n].walkable then
					local v = e.ob:getvelocity()
					v.y = self.jump_height
					e.ob:setvelocity(v)
					set_velocity(self, self.run_velocity)
				end
			end
		end
		if e.aliveai and math.random(1,3)==1 and key.LMB and not e.punch then
			aliveai.use(self,self.fight)
		elseif e.punch then
			e.punch=nil
		end
		if key.sneak then
			aliveai_minecontroller.exit(e)
		end
	end
end)

aliveai_minecontroller.exit=function(e)
	local username=e.user:get_player_name()
	e.user:set_detach()
	if e.ob and e.ob:get_luaentity() then
		e.ob:get_luaentity().controlled=nil
	end
	local user=e.user
	local poss={x=e.pos.x,y=e.pos.y,z=e.pos.z}
	minetest.after(0.1, function(user,poss)
		aliveai_minecontroller.users[e.username]=nil
		user:set_nametag_attributes({color={a=255,r=255,g=255,b=255}})
		user:set_eye_offset({x=0,y=0,z=0},{x=0,y=0,z=0})
		user:set_properties({visual_size = {x=1, y=1},visual="mesh"})
		user:setpos(poss)
	end,user,poss)
end

minetest.register_entity("aliveai_minecontroller:standing_player",{
	hp_max = 20,
	physical = true,
	weight = 5,
	collisionbox = {-0.35,-1.0,-0.35,0.35,0.8,0.35},
	visual =  "mesh",
	visual_size = {x=1,y=1},
	mesh = aliveai.character_model ,
	textures = "",
	colors = {},
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,
	on_punch=function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		if tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.fleshy then
			local e=aliveai_minecontroller.users[self.username]
			e.user:set_hp(e.user:get_hp()-tool_capabilities.damage_groups.fleshy)
			if e.user:get_hp()<=0 then
				aliveai_minecontroller.exit(e)
			else
				self.object:set_hp(e.user:get_hp())
			end
		end
		return self
	end,
	on_activate=function(self, staticdata)
		if staticdata~="" then
			self.username=staticdata
		elseif aliveai_minecontroller.usersname then
			self.username=aliveai_minecontroller.usersname
			aliveai_minecontroller.usersname=nil
		end
		local e=aliveai_minecontroller.users[self.username]
		if not (self.username and e ) then
			self.object:remove()
			return self
		end
		if minetest.check_player_privs(self.username, {fly=true})==false then
			self.object:setacceleration({x=0,y=-10,z =0})
			self.object:setvelocity({x=0,y=-3,z =0})
		end

		self.object:set_animation({ x=  0, y= 79, },30,0)
		self.object:set_properties({
			mesh=aliveai.character_model,
			textures=e.texture,
			nametag=self.username,
			nametag_color="#FFFFFF"
		})
		return self
	end,
	get_staticdata = function(self)
		return self.username
	end,
	on_step=function(self, dtime)
		local e=aliveai_minecontroller.users[self.username]
		if not e then self.object:remove() return self end
		self.time=self.time+dtime
		if self.time<1 then return self end
		self.time=0
		local pos=self.object:getpos()
		e.pos=pos
		local node2=minetest.get_node(pos)
		pos.y=pos.y-1
		local node1=minetest.get_node(pos)
		if node1 and minetest.registered_nodes[node1.name] and minetest.registered_nodes[node1.name].damage_per_second>0 then
			aliveai.punch(self,self.object,minetest.registered_nodes[node1.name].damage_per_second)
			return nil
		end
	end,
	type="npc",
	team="Sam",
	time=0,
})