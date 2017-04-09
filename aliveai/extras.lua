﻿--print(debug.getinfo(2).name)				-- get name from calling function

if io.open(minetest.get_modpath("default") .. "/models/character.b3d","r") then
	print("[aliveai] default/character.b3d is used as default model")
elseif io.open(minetest.get_modpath("default") .. "/models/character.x","r") then
	aliveai.character_model="character.x"
	print("[aliveai] default/character.x is used as default model")
elseif io.open(minetest.get_modpath("3d_armor") .. "/models/3d_armor_character.b3d","r") then
	aliveai.character_model="3d_armor_character.b3d"
	print("[aliveai] 3d_armor/3d_armor_character.b3d is used as default model")
	aliveai.use3d_armor_model=true
else
	print("[aliveai] error: no model found")
end

if aliveai.mesecons then
	aliveai.nodes_handler["mesecons_switch:mesecon_switch_off"]="punch"
	aliveai.nodes_handler["mesecons_switch:mesecon_switch_on"]="punch"
	aliveai.nodes_handler["mesecons_button:button_off"]="punch"
end

if minetest.get_modpath("farming") then
	for i=1,5,8 do
		aliveai.nodes_handler["farming:wheat_" .. i]="dig"
	end
end

if minetest.get_modpath("wieldview") then
	aliveai.wieldviewr=function(self,item)
		if self.usearmor~=1 or self.visual~="mesh" or not (item and ItemStack(item) and ItemStack(item):get_definition()) then return end

		if self.addedarmor then self.addedarmor=nil return self end

		local def=ItemStack(item):get_definition()
		local texture=def.inventory_image or ""

		if texture=="" and def.tiles and def.tiles[1]~="" then
			texture=def.tiles[1]
		end

		if texture=="" then return end

		if not self.skin_texture then self.skin_texture=self.object:get_properties().textures[1] end
		self.item_texture=texture

		if self.armor then
			self.object:set_properties({
				mesh="3d_armor_character.b3d",
				textures={
					self.skin_texture,
					self.armor_textures[1] .."^" .. self.armor_textures[2] .."^" .. self.armor_textures[3] .."^" .. self.armor_textures[4] .."^" .. self.armor_textures[5].."^" .. self.armor_textures[6],
					self.item_texture,
					}
			})
		else
			self.object:set_properties({
				mesh="3d_armor_character.b3d",
				textures={
					self.skin_texture,
					"3d_armor_trans.png",
					self.item_texture,
					}
			})
		end
		return self
	end
end

if minetest.get_modpath("3d_armor") then
	aliveai.tools_handler["3d_armor"]={try_to_craft=true,use=false,tools={}}
	for i, v in pairs(minetest.registered_tools) do
		if v.groups and v.groups.armor_use and v.groups.armor_use>0 then --if minetest.get_item_group(i, "armor_use")~=0 then
			table.insert(aliveai.tools_handler["3d_armor"].tools,i)
		end
	end
	aliveai.loaddata.armor=function(self,r)
		if r.armor then
			self.skin_texture=r.skin_texture or self.object:get_properties().textures[1]
			self.armor_textures=r.armor_textures
			self.armor=r.armor
			self.item_texture=r.item_texture
			self.ohp_max=r.ohp_max
			self.hp_max=r.hp_max
			self.object:set_properties({
				mesh="3d_armor_character.b3d",
				textures={
					self.skin_texture,
					self.armor_textures[1] .."^" .. self.armor_textures[2] .."^" .. self.armor_textures[3] .."^" .. self.armor_textures[4] .."^" .. self.armor_textures[5].."^" .. self.armor_textures[6],
					self.item_texture,
					}
			})
		elseif r.item_texture then
			self.skin_texture=self.object:get_properties().textures[1]
			self.item_texture=r.item_texture
			self.object:set_properties({
				mesh="3d_armor_character.b3d",
				textures={
					self.object:get_properties().textures[1],
					"3d_armor_trans.png",
					self.item_texture,
					}
			})
		end
		return self
	end

	aliveai.savedata.armors=function(self)
		if self.armor then
			return {
				skin_texture=self.skin_texture,
				armor_textures=self.armor_textures,
				armor=self.armor,
				item_texture=self.item_texture or "3d_armor_trans.png",
				ohp_max=self.ohp_max,
				hp_max=self.hp_max,

			}
		elseif self.item_texture then
			return {item_texture=self.item_texture}
		end

	end

	aliveai.armor=function(self,a)
		if self.usearmor~=1 then return self end
		if a.dmg and self.armor and self.object:get_hp()>0 and self.armor.heal>0 then
			local hp=self.object:get_hp()
			local l_hp=math.floor(((self.armor.hp-hp)*(self.armor.heal*0.05))+0.5)
			if hp+l_hp<self.armor.hp then
				hp=hp+l_hp
			else
				hp=self.armor.hp
			end
			self.hp=hp
			self.object:set_hp(hp)
			self.armor.hp=hp
			aliveai.showhp(self,true)
		end

		if a.item and self.visual=="mesh" then
			if not ItemStack(a.item):get_definition() then return end
			local d=ItemStack(a.item):get_definition().groups
			local n
			if d.armor_head then
				n=1
			elseif d.armor_torso then
				n=2
			elseif d.armor_legs then
				n=3
			elseif d.armor_feet then
				n=4
			elseif d.armor_shield then
				n=5
			elseif d.armor_heal then
			else
				return
			end

			if not self.armor then
				self.armor={
					level=0,
					head=0,
					torso=0,
					legs=0,
					feet=0,
					shield=0,
					heal=0,
					hp=self.object:get_hp(),
				}
				self.armor_textures={"3d_armor_trans.png","3d_armor_trans.png","3d_armor_trans.png","3d_armor_trans.png","3d_armor_trans.png","3d_armor_trans.png"}
				if not self.skin_texture then self.skin_texture=self.object:get_properties().textures[1] end
				self.ohp_max=self.hp_max
			end
			if not self.ohp_max then self.ohp_max=self.hp_max end

			if d.armor_head and d.armor_head<self.armor.head then return end
			if d.armor_torso and d.armor_torso<self.armor.torso then return end
			if d.armor_legs and d.armor_legs<self.armor.legs then return end
			if d.armor_feet and d.armor_feet<self.armor.feet then return end
			if d.armor_shield and d.armor_shield<self.armor.shield then return end

			self.armor.head= d.armor_head or self.armor.head
			self.armor.torso= d.armor_torso or self.armor.torso
			self.armor.legs= d.armor_legs or self.armor.legs
			self.armor.feet= d.armor_feet or self.armor.feet
			self.armor.shield= d.armor_shield or self.armor.shield

			if d.armor_heal and d.armor_heal>self.armor.heal then self.armor.heal=d.armor_heal end

			self.armor.level=self.armor.head+self.armor.torso+self.armor.legs+self.armor.feet+self.armor.shield
			self.hp_max=self.ohp_max+self.armor.level
			self.armor.hp=self.hp_max

			--self.object:set_armor_groups({radiation=self.armor.level*0.1}) -- messing up

			if self.hp_max>self.object:get_hp() then self.object:set_hp(self.hp_max) end
			self.addedarmor=true
			local texture=d.texture or a.item:gsub("%:", "_")
			self.armor_textures[n]=texture ..".png"
			self.object:set_properties({
				mesh="3d_armor_character.b3d",
				textures={
					self.skin_texture,
					self.armor_textures[1] .."^" .. self.armor_textures[2] .."^" .. self.armor_textures[3] .."^" .. self.armor_textures[4] .."^" .. self.armor_textures[5].."^" .. self.armor_textures[6],
					self.item_texture or "3d_armor_trans.png",
					}
			})
			aliveai.showhp(self,true)
		end
	end
end


if minetest.get_modpath("bows") then
	aliveai.tools_handler.bows={--mod name
			try_to_craft=false, -- because its very unsure if they ever will be able to craft them
			use=true,
			tool_group="bow", -- item/node groups
			--tools={"bow_wood","bow_stone","bow_steel","bow_bronze","bow_obsidian","bow_mese","bow_diamond","bow_rainbow","bow_admin"},
			--amo="bows:arrow",
			amo_group="arrow", -- item/node groups
			amo_index=1,
			tool_index=2,
			tool_reuse=1,
			tool_near=0,
			tool_see=1,
			tool_chance=3,
		}
end

minetest.register_chatcommand("aliveai", {
	params = "",
	description = "aliveai settings",
	privs = {server=true},
	func = function(name, param)
		if string.find(param,"status=true")~=nil then
			aliveai.status=true
			minetest.chat_send_player(name, "<aliveai> bot status on")
		elseif string.find(param,"status=false")~=nil then
			aliveai.status=false
			minetest.chat_send_player(name, "<aliveai> bot status off")
		elseif string.find(param,"count")~=nil then
			minetest.chat_send_player(name, "<aliveai> max:".. aliveai.max_num .." by self:" .. aliveai.max_num_by_self .." monsters by self:" .. aliveai.max_num_by_self_monsters .." bots: " .. aliveai.active_num)
		end
	end
})