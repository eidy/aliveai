aliveai_nitroglycerine={}
aliveai_nitroglycerine.explode=function(pos,node)
	if not node then node={} end

	node.radius= node.radius or 3
	node.set= node.set or ""
	node.place= node.place or {"fire:basic_flame","air","air","air","air"}
	node.place_chance=node.place_chance or 5
	node.user_name=node.user_name or ""
	node.drops=node.drops or 1
	node.velocity=node.velocity or 1
	node.hurt=node.hurt or 1

	local nodes={}
	if node.set~="" then node.set=minetest.get_content_id(node.set) end

	local nodes_n=0
	for i, v in pairs(node.place) do
		nodes_n=i
		nodes[i]=minetest.get_content_id(v)
	end

	local air=minetest.get_content_id("air")
	pos=vector.round(pos)
	local pos1 = vector.subtract(pos, node.radius)
	local pos2 = vector.add(pos, node.radius)
	local vox = minetest.get_voxel_manip()
	local min, max = vox:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge = min, MaxEdge = max})
	local data = vox:get_data()
	for z = -node.radius, node.radius do
	for y = -node.radius, node.radius do
	for x = -node.radius, node.radius do
		local rad = vector.length(vector.new(x,y,z))
		local v = area:index(pos.x+x,pos.y+y,pos.z+z)
		local p={x=pos.x+x,y=pos.y+y,z=pos.z+z}
		if data[v]~=air and node.radius/rad>=1 and minetest.is_protected(p, node.user_name)==false then
			if node.set~="" then
				data[v]=node.set
			end

			if aliveai.random(1,node.place_chance)==1 then
				data[v]=nodes[aliveai.random(1,nodes_n)]
			end

			if node.drops==1 and data[v]==air and math.random(1,4)==1 then
				local n=minetest.get_node(p)
				for _, item in pairs(minetest.get_node_drops(n.name, "")) do
					if p and item then minetest.add_item(p, item) end
				end
			end
		end
	end
	end
	end
	vox:set_data(data)
	vox:write_to_map()
	vox:update_map()
	vox:update_liquids()


if node.hurt==1 then
	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, node.radius*2)) do
		if not (ob:get_luaentity() and ob:get_luaentity().itemstring) then
			local pos2=ob:getpos()
			local d=math.max(1,vector.distance(pos,pos2))
			local dmg=(8/d)*node.radius
			ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=dmg}},nil)
		else
			ob:get_luaentity().age=890
		end
	end
end
if node.velocity==1 then
	for _, ob in ipairs(minetest.get_objects_inside_radius(pos, node.radius*2)) do
		local pos2=ob:getpos()
		local d=math.max(1,vector.distance(pos,pos2))
		local dmg=(8/d)*node.radius
		if ob:get_luaentity() then
			ob:setvelocity({x=(pos2.x-pos.x)*dmg, y=(pos2.y-pos.y)*dmg, z=(pos2.z-pos.z)*dmg})
		elseif ob:is_player() then
			local d=dmg/4
			local pos3={x=(pos2.x-pos.x)*d, y=(pos2.y-pos.y)*d, z=(pos2.z-pos.z)*d}
			ob:setpos({x=pos.x+pos3.x,y=pos.y+pos3.y,z=pos.z+pos3.z,})
		end
	end
end
	minetest.sound_play("aliveai_nitroglycerine_explode", {pos=pos, gain = 0.5, max_hear_distance = node.radius*8})
	if node.radius>15 then
		minetest.sound_play("aliveai_nitroglycerine_nuke", {pos=pos, gain = 0.5, max_hear_distance = node.radius*30})
	end
end


aliveai_nitroglycerine.freeze=function(ob)
	local p=ob:get_properties()
	local pos=ob:getpos()
	if ob:is_player() then
		pos=vector.round(pos)
		local node=minetest.get_node(pos)
		if node==nil or node.name==nil or minetest.registered_nodes[node.name].buildable_to==false then return end
		minetest.set_node(pos, {name = "aliveai_nitroglycerine:icebox"})
		minetest.after(0.5, function(pos, ob) 
			pos.y=pos.y-0.5
			ob:moveto(pos,false)
		end, pos, ob)
		return
	end
	if not ob:get_luaentity() then return end
	if p.visual=="mesh" and p.mesh~="" and p.mesh~=nil and ob:get_luaentity().name~="aliveai_nitroglycerine:ice" then
		aliveai_nitroglycerine.newice=true
		local m=minetest.add_entity(pos, "aliveai_nitroglycerine:ice")
		m:setyaw(ob:getyaw())
		m:set_properties({
			visual_size=p.visual_size,
			visual="mesh",
			mesh=p.mesh,
			textures={"default_ice.png","default_ice.png","default_ice.png","default_ice.png","default_ice.png","default_ice.png"},
			collisionbox=p.collisionbox
		})
	elseif ob:get_luaentity().name~="aliveai_nitroglycerine:ice" then
		minetest.add_item(pos,"default:ice")
	end
	local hp=ob:get_hp()+1
	ob:punch(ob,1,{full_punch_interval=1,damage_groups={fleshy=hp}})
	if ob:get_luaentity().aliveai then
		for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
			if ob:get_luaentity() and ob:get_luaentity().type and ob:get_luaentity().type=="" then
			ob:remove()
			end
		end
	end
end


minetest.register_entity("aliveai_nitroglycerine:ice",{
	hp_max = 1,
	physical = true,
	weight = 5,
	collisionbox = {-0.3,-0.3,-0.3, 0.3,0.3,0.3},
	visual = "sprite",
	visual_size = {x=0.7, y=0.7},
	textures = {}, 
	colors = {}, 
	spritediv = {x=1, y=1},
	initial_sprite_basepos = {x=0, y=0},
	is_visible = true,
	makes_footstep_sound = true,
	automatic_rotate = false,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
			local pos=self.object:getpos()
			minetest.sound_play("default_break_glass", {pos=pos, gain = 1.0, max_hear_distance = 10,})
			aliveai_nitroglycerine.crush(pos)
	end,
	on_activate=function(self, staticdata)
		if aliveai_nitroglycerine.newice then
			aliveai_nitroglycerine.newice=nil
		else
			self.object:remove()
		end
		self.object:setacceleration({x = 0, y = -10, z = 0})
		self.object:setvelocity({x = 0, y = -10, z = 0})
	end,
	on_step = function(self, dtime)
		self.timer=self.timer+dtime
		if self.timer<1 then return true end
		self.timer=0
		self.timer2=self.timer2+dtime
		if self.timer2>0.8 then
			minetest.sound_play("default_break_glass", {pos=self.object:getpos(), gain = 1.0, max_hear_distance = 10,})
			self.object:remove()
			aliveai_nitroglycerine.crush(self.object:getpos())
			return true
		end
	end,
	timer = 0,
	timer2 = 0,

})


minetest.register_node("aliveai_nitroglycerine:icebox", {
	description = "Ice box",
	wield_scale = {x=2, y=2, z=2},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
			{-0.5, -0.5, -0.5, 0.5, 1.5, -0.4375},
			{-0.5, -0.5, 0.4375, 0.5, 1.5, 0.5},
			{0.4375, -0.5, -0.4375, 0.5, 1.5, 0.4375},
			{-0.5, -0.5, -0.4375, -0.4375, 1.5, 0.4375},
			{-0.5, 1.5, -0.5, 0.5, 1.4375, 0.5},
		}
	},
	drop="default:ice",
	tiles = {"default_ice.png"},
	groups = {cracky = 1, level = 2, not_in_creative_inventory=1},
	sounds = default.node_sound_glass_defaults(),
	paramtype = "light",
	sunlight_propagates = true,
	alpha = 30,
	is_ground_content = false,
	drowning = 1,
	damage_per_second = 2,
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(20)
	end,
	on_timer = function (pos, elapsed)
		for i, ob in pairs(minetest.get_objects_inside_radius(pos, 1)) do
			return true
		end
		minetest.sound_play("default_break_glass", {pos=pos, gain = 1.0, max_hear_distance = 10,})
		minetest.set_node(pos, {name = "air"})
		aliveai_nitroglycerine.crush(pos)
		return false
	end,
	type="",
})

aliveai_nitroglycerine.crush=function(pos)
minetest.add_particlespawner({
	amount = 15,
	time =0.1,
	minpos = pos,
	maxpos = pos,
	minvel = {x=-2, y=-2, z=-2},
	maxvel = {x=2, y=2, z=2},
	minacc = {x=0, y=-8, z=0},
	maxacc = {x=0, y=-10, z=0},
	minexptime = 2,
	maxexptime = 1,
	minsize = 0.1,
	maxsize = 3,
	texture = "default_ice.png",
	collisiondetection = true,
})
end