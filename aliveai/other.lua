aliveai.generate_house=function(self)
	local gen=true
	if self.x and self.y and self.z and not self.aliveai then
		gen=false
	else
		aliveai.showstatus(self,"generate house")
	end
--materials

		local base_matreals={"default:wood","default:stone"}

		local build_able=aliveai.random(1,aliveai.get_everything_to_build_chance)==1
		local wall=base_matreals[math.random(1,#base_matreals)]
		local floor=base_matreals[math.random(1,#base_matreals)]
		local window=aliveai.windows[aliveai.random(1,#aliveai.windows)]
		local furn_len=#aliveai.furnishings
-- random materials from near stuff
		if math.random(1,2)==1 then
			local pos
			if gen then
				pos=self.object:getpos()
			else
				pos=self
				self.distance=15
			end
			for i, name in pairs(aliveai.basics) do
				local np=minetest.find_node_near(pos, self.distance,{name})
				if np~=nil then
					wall=name
					floor=name
					break
				end
			end
		end
-- basic
		local rx=math.random(5,10) 
		local ry=math.random(3,5) 
		local rz=math.random(5,10)
		local rnd={}
-- door hole
		local doorrnd=math.random(1,2)
		local doorholex,doorholez,doorpx,doorpz,doorp
		if doorrnd==1 then
			rnd[1]=0
			rnd[2]=rx
			doorholez=aliveai.random(1,rz-1)
			doorholex=rnd[math.random(1,2)]
			if doorholex==0 then doorp=1 else doorp=-1 end -- used with furn
		else
			rnd[1]=0
			rnd[2]=rz
			doorholex=aliveai.random(1,rx-1)
			doorholez=rnd[math.random(1,2)]
			if doorholez==0 then doorp=1 else doorp=-1 end -- used with furn
		end
-- stair
		local stairrnd=math.random(1,4)
		if doorrnd==2 and doorholez==0 then
			stairrnd=2
		elseif doorrnd==2 and doorholez==rz then
			stairrnd=1
		end
		rnd[1]=1
		rnd[2]=rz-1
		local stair=2
		local stair2x=2
		local stairy=1
		local stair2z=rnd[stairrnd]
		local stairz=rnd[stairrnd]
-- windows
		local wy=math.random(1,3)
		local wx1=math.random(1,7)
		local wx1s=aliveai.random(1,rx-1)
		local wx2=math.random(1,7)
		local wx2s=aliveai.random(1,rx-1)
		local wz1=math.random(1,7)
		local wz1s=aliveai.random(1,rz-1)
		local wz2=math.random(1,7)
		local wz2s=aliveai.random(1,rz-1)

		local last=""
		local node=""
		local nodes=""
		local count=0
		local need={}
		for y=0,ry,1 do
			for x=0,rx,1 do
				for z=0,rz,1 do
					if ry>3 and x<=y and x==stair2x and z==stair2z and y==ry then			-- hole stair
						node="air"
						stair2x=stair2x+1
					elseif (y==1 or y==2) and z==doorholez and x==doorholex then			-- door hole
						node="air"
					elseif z==0  and y>1 and wy>1 and y<=wy and y<ry and x>=wx1s and x<=rx-1 then	-- window 1
						node=window
					elseif z==rz  and y>1 and wy>1 and y<=wy and y<ry and x>=wx2s and x<=rx-1 then	-- window 2
						node=window
					elseif x==0  and y>1 and wy>1 and y<=wy and y<ry and z>=wz1s and z<=rz-1 then	-- window 3
						node=window
					elseif x==0  and y>1 and wy>1 and y<=wy and y<ry and z>=wz2s and z<=rz-1 then	-- window 4
						node=window
					elseif x==0 or x==rx or z==0 or z==rz or y==ry then				-- walls
						node=wall
					elseif ry>3 and x==stair and z==stairz and y==stairy then				-- stair
						node=wall
						stair=stair+1
						stairy=stairy+1
					elseif y==0 then								-- floor
						node=floor
					elseif y==1 and (z==1 or z==rz-1 or x==1 or x==rx-1)				 -- furnishings
					and not ((x==doorholex+doorp and z==doorholez) or (z==doorholez+doorp and x==doorholex)) then -- no furnishings front of door holes 
						local furn_rnd=aliveai.random(1,furn_len*4)
						if furn_rnd<=furn_len then 
							node=aliveai.furnishings[furn_rnd]
						else
							node="air"
						end
					else
						node="air"
					end
					if not node then node="" end
					if not gen then
						nodes=""
						minetest.set_node({x=self.x+x,y=self.y+y,z=self.z+z},{name=node})
					end
					if last=="" then last=node end
					if node~="air" then
						if not need[node] then need[node]=0 end
						need[node]=need[node]+1	
					end
					if node~=last then
						nodes=nodes ..last .." " .. count .. "!"
						if build_able and gen then aliveai.invadd(self,last,count,true) end
						count=0
					end
					last=node
					count=count+1
					if y==ry and x==rx and z==rz and last~="a" then
						nodes=nodes ..last .." " .. count .. "!"
						if build_able and gen then aliveai.invadd(self,last,count,true) end
						count=0
					end
				end
			end
		end
		local t=""
		for n, v in pairs(need) do
			t=t .. n.." " ..v .."!"
		end
		nodes=t.."+" .. nodes
	self.house=nodes
	self.build_x=rx
	self.build_y=ry
	self.build_z=rz

	if not (self.build_x and self.build_y and self.build_z) or  self.house==nil or self.house=="" then
		aliveai.showstatus(self,"Error: failed to generate build instructions")
		print(self.botname,"Failed to generate build instructions")
		aliveai.punch(self,self.object,self.object:get_hp()*2)
		return nil
	end

	return self
end

aliveai.crafttoneed=function(self,a,group_only,neednum)-- needed craft stuff to search or groups
-- search group
	if self.crafting~=1 then return end
	if string.find(a,"group:",1)~=nil then
		local g=a.split(a,":")
		for i, v in pairs(minetest.registered_items) do
 			if minetest.get_item_group(i,g[2])>0 then
				return i
			end
		end
		for i, v in pairs(minetest.registered_nodes) do
 			if minetest.get_item_group(i,g[2])>0 then
				return i
			end
		end
	end
	if group_only then return a end
--  search mineable, it need help to find uncraftable/ find generated stuff.
	if minetest.registered_nodes[a] and minetest.registered_nodes[a].is_ground_content then
		neednum=neednum or 1
		aliveai.newneed(self,a,neednum,a,"node")
		return nil
	end
--search dropable
	local b=a
	if a=="default:steel_ingot"			then a="default:iron_lump" end
	if a=="default:copper_ingot"			then a="default:copper_lump" end
	if a=="default:gold_ingot"			then a="default:gold_lump" end
	if a=="default:mese_crystal_fragement"	then a="default:mese_crystal" end
	for i, v in pairs(minetest.registered_nodes) do
 		if v.drop and type(v.drop)=="string" and v.drop==a and v.is_ground_content then
			aliveai.newneed(self,b,neednum,i,"node")
			return nil
		end
	end
	return a
end

aliveai.showpath=function(pos,i,table)
	if aliveai.status==false or pos==nil or not (table or (pos.x and pos.y and pos.z)) then return end
	local a={"path1","path2","path3"}
	if a[i] and table then
		for _, s in pairs(pos) do
			minetest.add_entity(s, "aliveai:" ..a[i])
		end
		return
	end
	if a[i] then minetest.add_entity(pos, "aliveai:" ..a[i]) end
	return
end

aliveai.showstatus=function(self,t,c)
	if not aliveai.status then return self end
	local color={"ff0000","0000ff","00ff00","ffff00"}
	c=c or 2
	t=t or ""
	if color[c] and t then
		self.object:set_properties({nametag=t,nametag_color="#" .. color[c]})
		print(self.botname ..": " .. t)
		self.delstatus=math.random(0,50) 
		local del=self.delstatus
		minetest.after(2, function(self,del)
			if self and self.object then
				if self.delstatus==del then
					if self.namecolor=="" then
						self.object:set_properties({nametag="",nametag_color=""})
					else
						self.object:set_properties({nametag=self.botname,nametag_color="#" .. self.namecolor})
					end
				end
			end
		end, self,del)
	end
	return self
end

aliveai.form=function(name,text)
	if not text then
		local gui=""
		.."size[3.5,0.2]"
		.."tooltip[size;size: <x> <y> <z>]"
		.."field[0,0;3,1;size;;]"
		.."button_exit[2.5,-0.3;1.3,1;set;set]"
		minetest.after((0.1), function(gui)
			return minetest.show_formspec(name, "aliveai.buildxy",gui)
		end, gui)
	else
		local gui=""
		.."size[5,7]"
		.."tooltip[text;Copy the data (CTRL+A, CTRL+C)\nDo not change the code, its exactly calculated]"
		.."textarea[0.2,0.2;5,8;text;;" .. text .."]"
		minetest.after((0.1), function(gui)
			return minetest.show_formspec(name, "aliveai.buildxyX",gui)
		end, gui)
	end
end

minetest.register_on_player_receive_fields(function(player, form, pressed)
	if form=="aliveai.buildxy" and pressed.set then
		local name=player:get_player_name()
		local t=pressed.size
		local t1=t.split(t," ")
		if not (t1 and t1[2] and t1[3]) then
			minetest.chat_send_player(name, "set area size: <x> <y> <z>")
			return false
		end
		local x=tonumber(t1[1])
		local y=tonumber(t1[2])
		local z=tonumber(t1[3])
		if not (x and y and z) then
			minetest.chat_send_player(name, "set area size: <x> <y> <z>")
			return false
		end
		aliveai.buildingtool={x=x,y=y,z=z}
		minetest.chat_send_player(name, "area size set, now place the tool")
		return true
	end
	if form=="aliveai.spawnerform" then
		local pos=aliveai.spawneruser[player:get_player_name()]
		local meta=minetest.get_meta(pos)
		if pressed.quit then
			if pressed.n then
				local n=tonumber(pressed.n)
				if n==nil then n=1 end
				meta:set_int("n",n)
			end
			if pressed.team then
				meta:set_string("team",pressed.team)
			end
			if pressed.color then
				meta:set_string("color",pressed.color)
			end
			if pressed.time then
				local t=tonumber(pressed.time)
				if t==nil or t<2 then t=2 end
				if t>999 then t=999 end
				meta:set_int("t",t)
			end

			if aliveai.mesecons and meta:get_int("mese")==3 then
				minetest.get_node_timer(pos):stop()
			else
				minetest.get_node_timer(pos):start(meta:get_int("t"))
			end
			aliveai.spawneruser[player:get_player_name()]=nil
		else
		if pressed.bot then
			meta:set_string("bot",pressed.bot)
			meta:set_string("infotext", "Spawner by " ..meta:get_string("owner") .. " (".. pressed.bot ..")")
		end
		if pressed.mese then
			local n=1
			if pressed.mese=="send_on_spawn" then n=2
			elseif pressed.mese=="spawn_on_send" then n=3
			elseif pressed.mese=="send_on_reach_number" then n=4
			elseif pressed.mese=="send_on_reach_no_spawn" then n=5
			end
			meta:set_string("mese",n)
		end
			aliveai.spawnerform(player,pos)
		end
	end
end)

aliveai.spawnerform=function(player,pos)
	local meta=minetest.get_meta(pos)
	local n=meta:get_int("n")
	local bot=meta:get_string("bot")
	local time=meta:get_string("t")
	local team=meta:get_string("team")
	local color=meta:get_string("color")

	if not aliveai.spawneruser then aliveai.spawneruser={} end
	aliveai.spawneruser[player:get_player_name()]=pos

	local gui=""
	local nn=1
	local nn_n=0
	local list="random_npc"
	local c=""

	local but="item_image_button[2.7,0.5;1,1;;show;]"
		if bot=="" then
			bot=""
			n=1
		elseif bot=="random_npc" then
			nn_n=1
		end
	for i, v in pairs(aliveai.registered_bots) do
		nn=nn+1
		list=list .. "," .. v.name
		if v.name==bot then
			nn_n=nn
			but="item_image_button[2.7,0.5;1,1;".. v.item ..";imgbut;]"
		end
	end

	gui=""
	.."size[3.5,2.5]"
	.."tooltip[n;Spawn when there are less bots then...]"
	.."field[0,0;1.5,1;n;;" .. n .."]"
	.."tooltip[time;Timer]"
	.."field[1.5,0;1.5,1;time;;" .. time .."]"
	.."dropdown[-0.2,0.5;3,1;bot;" .. list.. ";" .. nn_n .."]"
	.. but
	.."button_exit[2.5,-0.3;1.3,1;set;Set]"
	.."tooltip[team;Team: set team name, or leave empty for default teams]"
	.."field[0,1.5;1.5,1;team;;" .. team .."]"
	.."tooltip[color;Nametag color (e.g c50032) (RedGreenBlue (RRGGBB)]"
	.."field[1.5,1.5;1.5,1;color;;" .. color .."]"
	if aliveai.mesecons then
		local mese=meta:get_int("mese")
		gui=gui .."dropdown[-0.2,2;4,1;mese;Mesecons...,send_on_spawn,spawn_on_send,send_on_reach_number,send_on_reach_no_spawn;" .. mese .."]"
	end
	minetest.after((0.1), function(gui)
		return minetest.show_formspec(player:get_player_name(), "aliveai.spawnerform",gui)
	end, gui)
end

minetest.register_node("aliveai:spawner", {
	description = "aliveai spawner",
	tiles = {"default_steel_block.png"},
	groups = {cracky = 2},
	drawtype="nodebox",
	paramtype="light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
		}
	},
	can_dig = function(pos, player)
		local meta=minetest.get_meta(pos)
		local name=player:get_player_name() or ""
		if meta:get_string("owner")==name or minetest.check_player_privs(name, {protection_bypass=true}) then
			return true
		end
	end,
	mesecons = {receptor = {state = "off"}},
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local name=placer:get_player_name() or ""
		meta:set_string("owner",name)
		meta:set_string("team",aliveai.default_team)
		meta:set_string("color","ffffff")
		meta:set_string("infotext", "Spawner by " .. name)
		local meta=minetest.get_meta(pos)
		meta:set_int("n",1)
		meta:set_string("bot",1)
		meta:set_int("mese",1)
		meta:set_int("reach",0)
		meta:set_int("t",120)
	end,
	on_timer = function (pos, elapsed)
		local meta=minetest.get_meta(pos)
		local n=meta:get_int("n")
		local bot=meta:get_string("bot")
		local mese=meta:get_int("mese")
		local team=meta:get_string("team")
		local color=meta:get_string("color")
		if bot=="random_npc" then
			local a=true
			local y=0
			for i, v in pairs(aliveai.registered_bots) do
			if v.type=="npc" and (a or math.random(1,4)==1) then
					bot=v.name
					y=v.spawn_y
					a=false
				end
			end
			pos.y=pos.y+y
		end
		if not aliveai.registered_bots[bot] then minetest.get_node_timer(pos):stop() return false end
		if n>aliveai.active_num then
			meta:set_int("reach",0) 
			if aliveai.mesecons and mese==5 then return true end
			local b=minetest.add_entity({x=pos.x,y=pos.y+1,z=pos.z}, aliveai.registered_bots[bot].bot)
			b:setyaw(math.random(0,6.28))
			if team~="" then b:get_luaentity().team=meta:get_string("team") end
			b:set_properties({nametag=b:get_luaentity().botname,nametag_color="#" ..  color})
			b:get_luaentity().namecolor=color
			if aliveai.mesecons and mese==2 then mesecon.receptor_on(pos) end
		elseif aliveai.mesecons and mese==4 and meta:get_int("reach")==0 then
			meta:set_int("reach",1)
			mesecon.receptor_on(pos)
		end
		if aliveai.mesecons then
			minetest.after(1.5, function(pos)
				mesecon.receptor_off(pos)
			end, pos)
		end
		return true
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		local meta=minetest.get_meta(pos)
		local name=player:get_player_name() or ""
		if meta:get_string("owner")==name or minetest.check_player_privs(name, {protection_bypass=true}) then
			aliveai.spawnerform(player,pos)
		end
	end,
	mesecons = {
		receptor = {state = "off"},
		effector = {
		action_on = function (pos, node)
			local meta=minetest.get_meta(pos)
			local mese=meta:get_int("mese")
			local bot=meta:get_string("bot")
			local n=meta:get_int("n")
			local team=meta:get_string("team")
			local color=meta:get_string("color")
			if bot=="random_npc" then
				local a=true
				local y=0
				for i, v in pairs(aliveai.registered_bots) do
				if v.type=="npc" and (a or math.random(1,4)==1) then
						bot=v.name
						y=v.spawn_y
						a=false
					end
				end
				pos.y=pos.y+y
			end
			if aliveai.registered_bots[bot] and n>aliveai.active_num and mese==3 then
				local b=minetest.add_entity({x=pos.x,y=pos.y+1,z=pos.z}, aliveai.registered_bots[bot].bot)
				b:setyaw(math.random(0,6.28))
				if team~="" then b:get_luaentity().team=meta:get_string("team") end
				b:set_properties({nametag=b:get_luaentity().botname,nametag_color="#" ..  color})
				b:get_luaentity().namecolor=color
			end
			return false
		end,
	}}
})

minetest.register_craftitem("aliveai:team_gift", {
	description = "Gift to team (punch a teammember to be changed to their team)",
	inventory_image = "aliveai_team_gift.png",
	on_use=function(itemstack, user, pointed_thing)
		if pointed_thing.type=="object" then
			local t=aliveai.team(pointed_thing.ref)
			aliveai.team(user,t)
			if aliveai.is_bot(pointed_thing.ref) then
				local name=user:get_player_name()
				local self=pointed_thing.ref:get_luaentity()
				if aliveai.getknown(self,user)=="fight" then
					self.temper=0
					self.fight=nil
					aliveai.known(self,user,"")
				end
			end
			itemstack:take_item()
			return itemstack
		end
	end,
})

local paths={
{0.2,"bubble.png^[colorize:#0000ffff"},
{0.2,"bubble.png^[colorize:#ffff00ff"},
{0.5,"bubble.png^[colorize:#00ff00ff"}}

for i=1,3,1 do
minetest.register_entity("aliveai:path" .. i,{
	hp_max = 1,
	physical = false,
	weight = 0,
	collisionbox = {-0.1,-0.1,-0.1, 0.1,0.1,0.1},
	visual = "sprite",
	visual_size = {x=paths[i][1], y=paths[i][1]},
	textures = {paths[i][2]}, 
	colors = {}, 
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = false,
	automatic_rotate = false,
	is_falling=0,
	on_step = function(self, dtime)
		self.timer=self.timer+dtime
		if self.timer<0.1 then return self end
		self.timer=0
		self.timer2=self.timer2+dtime
		if self.timer2>2 then
			self.object:remove()
			return self
		end
	end,
	timer=0,
	timer2=0,
	type="",
})
end
paths=nil