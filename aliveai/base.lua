aliveai.gethp=function(ob)		-- because some mods are remaking mobs health system, like mobs redo
	if not ob then return 0 end
	local h=ob:get_hp()
	if ob:get_luaentity() then
		if ob:get_luaentity().health then h=ob:get_luaentity().health end
		if ob:get_luaentity().hp then h=ob:get_luaentity().hp end
	elseif not ob:is_player() then
		h=0
	end
	return h
end

aliveai.showtext=function(self,text,color)
	self.delstatus=math.random(0,1000) 
	local del=self.delstatus
	color=color or "ff0000"
	self.object:set_properties({nametag=text,nametag_color="#" ..  color})
	minetest.after(1.5, function(self,del)
		if self and self.object and self.delstatus==del then
			if self.namecolor~="" then
				self.object:set_properties({nametag=self.botname,nametag_color="#ffffff"})
			else
				self.object:set_properties({nametag="",nametag_color=""})
			end
		end
	end, self,del)
	return self
end

aliveai.showhp=function(self,p)
	local color="ff0000"
	if p then color="00ff00" end
	aliveai.showtext(self,self.object:get_hp() .." / " .. self.hp_max,color)
	return self
end

aliveai.timer=function(self)
	if self.type=="npc" then return end
	if not self.lifetimer or self.fly or self.come or self.fight then self.lifetimer=aliveai.lifetimer end
	self.lifetimer=self.lifetimer-1
	if self.lifetimer>0 then return end
	for _, ob in ipairs(minetest.get_objects_inside_radius(self.object:getpos(), self.distance)) do
		local en=ob:get_luaentity() 
		if ob:is_player() or (en and en.type and en.type~="" and ((en.type~=self.type) or en.team and en.team~=self.team)) then
			self.lifetimer=nil
			return
		end
	end
	aliveai.showstatus(self," - removed")
	self.object:remove()
	return self
end



aliveai.creatpath=function(self,pos1,pos2,d,notadvanced)
	aliveai.max_paths_per_s.checked=aliveai.max_paths_per_s.checked+1
	if aliveai.max_paths_per_s.checked>aliveai.max_paths_per_s.times then return nil end
	pos1=aliveai.roundpos(pos1)
	pos2=aliveai.roundpos(pos2)
	d=d or self.distance
	local p=minetest.find_path(pos1,pos2, self.distance, 2, self.avoidy,"Dijkstra")
	p=p or aliveai.createpathbyladder(self,pos1,pos2,d)
	if not notadvanced then
		p=p or aliveai.createpathbytower(self,pos1,pos2)
		p=p or aliveai.createpathbybridge(self,pos1,pos2)
	end
	aliveai.showpath(p,1,true)
	return p
end

aliveai.createpathbybridge=function(self,pos1,pos2)
	local path
	if aliveai.visiable(pos1,pos2) then
		aliveai.showstatus(self,"bridge path")
		local n=0
		path={}
		local v = {x = pos1.x - pos2.x, y = pos1.y - pos2.y-1, z = pos1.z - pos2.z}
		v.y=v.y-1
		v=aliveai.roundpos(v)
		local amount = (v.x ^ 2 + v.y ^ 2 + v.z ^ 2) ^ 0.5
		local d=math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x) + (pos1.y-pos2.y)*(pos1.y-pos2.y)+(pos1.z-pos2.z)*(pos1.z-pos2.z))
		v.x = (v.x  / amount)*-1
		v.y = (v.y  / amount)*-1
		v.z = (v.z  / amount)*-1
		for i=0,d,1 do
			local p={x=pos1.x+(v.x*i),y=pos1.y+v.y-1,z=pos1.z+(v.z*i)}
			local node=minetest.get_node(p)
			if node and minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].walkable==false then
				p=aliveai.roundpos(p)
				table.insert(path,p)
				aliveai.showpath(p,1)
				n=n+1
			end
		end
		for i, v in pairs(aliveai.basics) do
			if aliveai.invhave(self,i,n) then
				self.path_bridge=i
				break
			end
		end
		if not self.path_bridge then
			for i, v in pairs(aliveai.standard) do
				if aliveai.invhave(self,i,n) then
					self.path_bridge=i
					break
				end
			end
		end
		if not self.path_bridge then
			local nn=0
			for i, v in pairs(self.inv) do
				if minetest.registered_nodes[i] and minetest.registered_nodes[i].walkable then
					nn=nn+v
					if nn>=n then
						self.path_bridge=""
						break
					end
				end
			end
		end
		if not self.path_bridge then return nil end
	end
	return path
end


aliveai.createpathbytower=function(self,pos1,pos2)
	local d=self.distance
	local tp
	local new_path
	local n=0
	local tmp=aliveai.neartarget(self,pos2,-1,-d)
	aliveai.showstatus(self,"tower path")
	if tmp and aliveai.visiable(self,tmp) then
		tp={}
		table.insert(tp,tmp)
		local tmp2=aliveai.neartarget(self,pos2,-1,2,1)
		if tmp2 then
			table.insert(tp,tmp2)
		end
		table.insert(tp,pos2)
	elseif tmp then
		local tp1=minetest.find_path(pos1,tmp, d, 2, self.avoidy,"Dijkstra")
		if tp1 then
			tp=tp1
			table.insert(tp,pos2)
		end
	else
		local tp1=minetest.find_path(pos1,pos2, d, d-1, self.avoidy,"Dijkstra")
		if tp1 then
			tp=tp1
			table.insert(tp,pos2)
		end
	end
	if tp then
		local p
		local po
		new_path={}
		for i, p in pairs(tp) do
			if po and po.y<p.y then
				for i=1, p.y-po.y-1,1 do
					n=n+1
					local po2={x=po.x,y=po.y+i,z=po.z}
					table.insert(new_path, po2)
					aliveai.showpath(po2,2)
				end
			else
				table.insert(new_path, p)
				aliveai.showpath(p,1)
			end
			po={x=p.x,y=p.y,z=p.z}
		end

		for i, v in pairs(aliveai.basics) do
			if aliveai.invhave(self,i,n) then
				self.path_tower=i
				break
			end
		end
		if not self.path_tower then
			for i, v in pairs(aliveai.standard) do
				if aliveai.invhave(self,i,n) then
					self.path_tower=i
					break
				end
			end
		end
		if not self.path_tower then
			local nn=0
			for i, v in pairs(self.inv) do
				if minetest.registered_nodes[i] and minetest.registered_nodes[i].walkable then
					nn=nn+v
					if nn>=n then
						self.path_tower=""
						break
					end
				end
			end
		end
	end
	return new_path
end


aliveai.createpathbyladder=function(self,pos1,pos2,d)
	if pos2.y<pos1.y or pos2.y-pos1.y<self.arm then return nil end
	d=d or self.distance
	local np=minetest.find_node_near(pos2, d,aliveai.ladders)
	if np then np=aliveai.neartarget(self,np,1,0) end
	if np then
		aliveai.showstatus(self,"ladder path")
		aliveai.showpath(np,3)
		local np2=minetest.find_node_near(pos1, d,aliveai.ladders)
		if np2 and aliveai.visiable(self,np2) then
			aliveai.showpath(np2,2)
			local np3=minetest.find_path(pos1,np2, d, 2, self.avoidy,"Dijkstra")
				aliveai.showpath(np3,1,true)
			if np3 then
				local y1=math.floor(pos1.y+0.5)
				for i=y1,np.y,1 do
					local pos3={x=np2.x,y=i,z=np2.z}
					aliveai.showpath(pos3,1)
					table.insert(np3, pos3)
				end
				table.insert(np3, np)
				return np3
			end
		end
	end
	return nil
end



aliveai.buildpath=function(self,need)
	if self.house=="" then
		aliveai.generate_house(self)
		if not (self.build_x and self.build_y and self.build_z) then
			aliveai.showstatus(self,"Error: void build instructions")
			aliveai.punch(self,self.object,self.object:get_hp()*2)
			return nil
		end
	elseif string.find(self.house,"+++")~=nil then
		local house1=self.house.split(self.house,"+++")
		self.house=house1[2]
		local v=house1[1].split(house1[1]," ")
		local vx=tonumber(v[1])
		local vy=tonumber(v[2])
		local vz=tonumber(v[3])
		if vx and vy and vz then
			self.build_x=vx
			self.build_y=vy
			self.build_z=vz
		else
			print("aliveai: buildpath failed missing vector(s)")
			self.need=nil
			self.build_x=1
			self.build_y=1
			self.build_z=1
			self.house=""
			self.task="."
			return self
		end
	end
	local building=self.house
	local bas=building.split(building,"+")
	if not bas or not bas[2] then
		print("aliveai: buildpath failed (no +)")
		return nil
	end
	if need then
		local need0={}
		local need1=bas[1].split(bas[1],"!")
		for _, s1 in ipairs(need1) do
			local s2=s1.split(s1," ")
			if s2[1]==nil or s2[2]==nil  then
				print("aliveai: need failed (node or number)")
				return nil
			end
			aliveai.newneed(self,s2[1],tonumber(s2[2]))
		end
		return self
	end
	local build={node={},x=self.build_x,y=self.build_y,z=self.build_z}
	build.node={}
	local path={}
	local n=1
	local d1=bas[2].split(bas[2],"!")
	for _, s1 in ipairs(d1) do
		local s2=s1.split(s1," ")
		if s2[1]==nil or s2[2]==nil  then
			print("aliveai: buildpath failed (node or number)")
			return nil
		end
		local s2n=tonumber(s2[2])
		for s3=1,s2n,1 do
			build.node[n]=s2[1]
			n=n+1
		end
	end
	local dx=(build.x/2)*-1
	local dz=(build.z/2)*-1
	n=0
	local nn=0
	local pos=self.object:getpos()
	pos.y=pos.y-1
	aliveai.showstatus(self,"create (home) build path")
	for y=0,build.y,1 do
		for x=0,build.x,1 do
			for z=0,build.z,1 do
				nn=nn+1
				if build.node[nn]~="a" and build.node[nn]~=nil then
					local p={x=pos.x+x+dx,y=pos.y+y,z=pos.z+z+dz}
					if not minetest.get_node(p) or minetest.is_protected(p,"") then
						return nil
					end
					n=n+1
					path[n]={}
					path[n].pos=aliveai.roundpos(p)
					path[n].node=build.node[nn]
					aliveai.showpath(p,2)
				end
			end
		end
	end
	return path
end

aliveai.lookforfreespace=function(pos,xzstartdis,xzdis,xz,y)
	for i=xzstartdis,xzdis,1 do
		local p1={x=pos.x+i,y=pos.y,z=pos.z}
		local p2={x=pos.x-i,y=pos.y,z=pos.z}
		local p3={x=pos.x,y=pos.y,z=pos.z+i}
		local p4={x=pos.x,y=pos.y,z=pos.z-i}
		aliveai.showpath({p1,p2,p3,p4},2,true)
		if minetest.get_node(p1) and minetest.get_node(p1).name=="air" then
			if aliveai.checkarea(p1,"air",3,1) and aliveai.checkarea(p1,"air",xz,y) then
				return p1
			end
		end
		if minetest.get_node(p2) and minetest.get_node(p2).name=="air" then
			if aliveai.checkarea(p2,"air",3,1) and aliveai.checkarea(p2,"air",xz,y) then
				return p2
			end
		end
		if minetest.get_node(p3) and minetest.get_node(p3).name=="air" then
			if aliveai.checkarea(p3,"air",3,1) and aliveai.checkarea(p3,"air",xz,y) then
				return p3
			end
		end
		if minetest.get_node(p4) and minetest.get_node(p4).name=="air" then
			if aliveai.checkarea(p4,"air",3,1) and aliveai.checkarea(p4,"air",xz,y) then
				return p4
			end
		end
	end
		return nil
end

aliveai.checkarea=function(pos,node_name,pxz,py)
	local pxz2=(pxz/2)*-1
	local air= "air"==node_name
	for y=0,py,1 do
		for x=0,pxz,1 do
			for z=0,pxz,1 do
				local p={x=pos.x+x+pxz2,y=pos.y+y,z=pos.z+z+pxz2}
				local node=minetest.get_node(p)
				if not node or (air and minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].buildable_to==false and node.name~=node_name) or minetest.is_protected(p,"") then
					return false
				end
			end
		end
	end
	return true

end

aliveai.getlength=function(a)
	if a==nil then return 0 end
	local n=0
	for _ in pairs(a) do
		n=n+1
	end
	return n
end

aliveai.rndwalk=function(self,toogle)
	if toogle==nil then toogle=true end
	self.isrnd=toogle
	if toogle==false then
		self.falllook=nil
		return self
	end
	self.on_random_walk(self)
	local rnd=math.random(0,5)
--falllook
	if self.falllook then
		self.falllook.times=self.falllook.times-1
		if not self.falllook.ignore then
			local r=math.random(1, self.falllook.n)
			if rnd<2 then
				local yaw=self.falllook[r]
				if type(yaw)~="number" then yaw=0 end
				self.object:setyaw(yaw)
				aliveai.stand(self)
			elseif rnd==2 then
				local pos=self.object:getpos()
				local rndpos
				for _, ob in ipairs(minetest.get_objects_inside_radius(pos, self.distance)) do
					if ob and ob:getpos() then
						rndpos=ob:getpos()
						if math.random(1,3)==1 then break end
					end
				end
				if rndpos then
					aliveai.lookat(self,rndpos)
					aliveai.stand(self)
				end
			else
				local yaw=self.falllook[r]
				if type(yaw)~="number" then yaw=0 end
				self.object:setyaw(yaw)
				aliveai.walk(self)
			end
			if self.falllook.times<=0 then
				self.falllook=nil
				aliveai.falling(self)
			end
			return self
		end
		if self.falllook.times<=0 then self.falllook=nil end
	end
-- normal rnd
	if rnd==0 then
		self.object:setyaw(math.random(0,6.28))
		aliveai.stand(self)
	elseif rnd==1 then
		aliveai.stand(self)
	elseif rnd==2 then
		local pos=self.object:getpos()
		if self.staring then
			for _, ob in ipairs(minetest.get_objects_inside_radius(pos, self.arm)) do
				if math.random(1,2)==1 and ob and ob:getpos() and aliveai.visiable(self,ob:getpos()) and ((ob:get_luaentity() and ob:get_luaentity().name==self.staring.name) or (ob:is_player() and self.staring.name==ob:get_player_name())) then
					if self.staring.step>2 then
						self.temper=1
						self.fight=ob
						aliveai.sayrnd(self,"come here")
						self.on_detect_enemy(self,self.fight)
						self.staring=nil
						return self
					end
					self.staring.step=self.staring.step+1
					aliveai.lookat(self,ob:getpos())
					aliveai.sayrnd(self,"what are you staring at?")
					return self
				end
			end
		elseif self.annoyed_by_staring==1 then
			for _, ob in ipairs(minetest.get_objects_inside_radius(pos, self.arm)) do
				if math.random(1,2)==1 and ob and ob:getpos() and aliveai.visiable(self,ob:getpos())  then
					if self.stealing==1 and math.random(1,self.steal_chance)==1 then aliveai.steal(self,ob) return self end
					if ob:get_luaentity() and not (ob:get_luaentity().name=="" or (ob:get_luaentity().aliveai and ob:get_luaentity().botname==self.botname)) then
						self.staring={}
						self.staring.name=ob:get_luaentity().name
						self.staring.step=1
						aliveai.lookat(self,ob:getpos())
						return self
					elseif ob:is_player() then
						self.staring={}
						self.staring.name=ob:get_player_name()
						self.staring.step=1
						aliveai.lookat(self,ob:getpos())
						return self
					end
				end
			end		
		end
		self.staring=nil
		local rndpos
		for _, ob in ipairs(minetest.get_objects_inside_radius(pos, self.distance)) do
			if ob and ob:getpos() then
				rndpos=ob:getpos()
				if math.random(1,3)==1 then break end
			end
		end
		if rndpos then
			aliveai.lookat(self,rndpos)
			aliveai.stand(self)
		end
	elseif rnd<4 then
		self.object:setyaw(math.random(0,6.28))
		aliveai.walk(self)
	end
end

aliveai.punch=function(self,ob,hp)
	hp=hp or 1
	if not ob then return end
	if ob:get_luaentity() and ob:get_luaentity().itemstring then ob:remove() return end
	ob:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=hp}},nil)
	if self.object:get_hp()<=0 then
		return nil
	end
	return self	
end


aliveai.dmgbynode=function(self)
	local pos=self.object:getpos()
	local node2=minetest.get_node(pos)
	pos.y=pos.y-1
	local node1=minetest.get_node(pos)
	if node1 and minetest.registered_nodes[node1.name] and minetest.registered_nodes[node1.name].damage_per_second>0 then
		if not aliveai.punch(self,self.object,minetest.registered_nodes[node1.name].damage_per_second) then
			return nil
		end
		self.object:setyaw(math.random(0,6.28))
		aliveai.walk(self,2)
		aliveai.showstatus(self,"hurts by " .. node1.name,1)
	elseif node2 and minetest.registered_nodes[node2.name] and minetest.registered_nodes[node2.name].damage_per_second>0 then
		if not aliveai.punch(self,self.object,minetest.registered_nodes[node2.name].damage_per_second) then
			return nil
		end
		self.object:setyaw(math.random(0,6.28))
		aliveai.walk(self)
		aliveai.showstatus(self,"hurts by " .. node2.name,1)
	end
	return self
end


aliveai.falling=function(self)
	self.timerfalling=0
	if aliveai.regulate_prestandard>0 and math.random(1,aliveai.regulate_prestandard)==1 then return self end

	if self.isrnd and self.path and self.floating==nil then aliveai.path(self) return self end
	if self.isrnd and self.done=="path" then self.timerfalling=0.2 self.done="" end

	local pos=self.object:getpos()
	local node2=minetest.get_node(pos)
	pos.y=pos.y-1
	local node=minetest.get_node(pos)
-- if unknown
	local test2=minetest.registered_nodes[node2.name]
	local test=minetest.registered_nodes[node.name]
	if not test or not test2 then return nil end
--water
	if test2.liquid_viscosity>0 then
		self.floating=true
		self.object:setacceleration({x =0, y =0.1, z =0})
		if self.object:getvelocity().y<-0.1 then
			local y=self.object:getvelocity().y
			self.object:setvelocity({x = self.move.x, y =y/2, z =self.move.z})
			return self
		end
			self.object:setvelocity({x = self.move.x, y =1 - (test2.liquid_viscosity*0.1), z =self.move.z})
		if test.drowning and not self.drown then
			self.drown=true
			self.air=0
		elseif self.air and self.air>=20 then
			aliveai.punch(self,self.object,1)
		elseif self.air then
			self.air=self.air+0.1

		end
		return self
-- ladder
	elseif test.climbable then
		self.floating=true
		if not self.air then
			self.air=0
		elseif self.air>=20 then
			aliveai.punch(self,self.object,1)
		elseif self.air>=5 then
			self.object:setyaw(math.random(0,6.28))
			aliveai.walk(self)
			self.object:setacceleration({x =0, y =-0.2, z =0})
			self.object:setvelocity({x = self.move.x, y =-2, z =self.move.z})
			return self
		end
		if self.climb==pos.y then self.air=self.air+0.1 end
		self.climb=pos.y
		self.object:setacceleration({x =0, y =0.1, z =0})
		if self.object:getvelocity().y<-0.1 then
			local y=self.object:getvelocity().y
			self.object:setvelocity({x = self.move.x, y =y/2, z =self.move.z})
			return self
		end
		self.object:setvelocity({x = self.move.x, y =1, z =self.move.z})
		aliveai.stand(self)
		return self
-- no water or ledder
	elseif self.floating then
		node=minetest.get_node({x=pos.x,y=pos.y-0.2,z=pos.z})
		local n=minetest.registered_nodes[node.name]
		self.air=nil
		self.climb=nil
		if n.liquid_viscosity>0 or n.climbable then
			self.object:setacceleration({x=0,y=0,z =0})
			self.object:setvelocity({x = self.move.x, y =0, z =self.move.z})
			return self
		end
		self.floating=nil
		self.object:setacceleration({x=0,y=-10,z =0})
	elseif test2.drowning>0 and self.drowning then
		if not self.air then
			self.drown=true
			self.air=0
		elseif self.air>=20 then
			aliveai.punch(self,self.object,1)
		end
		self.air=self.air+(test.drowning*0.1)
		return self
	elseif self.drown then
		self.floating=nil
		self.air=nil
		self.drown=nil
-- falling
	elseif self.object:getvelocity().y~=0 then --and (test.walkable==false or pos.y%1~=0.5) then
		if not self.fallingfrom or self.fallingfrom<pos.y then self.fallingfrom=pos.y end
	end
--and hit the ground
	if self.fallingfrom then
		pos.y=pos.y-1
		local node3=minetest.get_node(pos)
		if node3 and minetest.registered_nodes[node3.name] and minetest.registered_nodes[node3.name].walkable then
			local from=math.floor(self.fallingfrom+0.5)
			local hit=math.floor(pos.y+0.5)
			local d=from-hit
			self.fallingfrom=nil
			if d>=self.avoidy then
				aliveai.punch(self,self.object,d)
			end
		end
	end
-- return if not moving
	if self.move.x+self.move.z==0 then return self end
--disable rnd directions
	if not self.path then
		local j={}
		local dmg=false
		for i=1,self.avoidy*-1,-1 do
			local nnode=minetest.registered_nodes[minetest.get_node({x=pos.x+self.move.x,y=pos.y+i,z=pos.z+self.move.z}).name]
			if nnode and nnode.damage_per_second>0 then dmg=true break end
			if i<0 then j[2+(i*-1)]=nnode.walkable end
			if nnode.walkable then break end
		end

		if self.fight and aliveai.distance(self,self.fight:getpos())<=self.arm*1.5 then
			j[self.avoidy+2]=nil
			dmg=nil
		end


		if j[self.avoidy+2]==false or dmg then
			self.falllook={ignore=false}
			local canuse={4.71,1.57,0,3.14}
			local f={{x=1,z=0},{x=-1,z=0},{x=0,z=1},{x=0,z=-1}}
			local use=1
			j={}
			for i=1,4,1 do
				for i2=1,self.avoidy*-1,-1 do
					local nnode=minetest.registered_nodes[minetest.get_node({x=pos.x+f[i].x,y=pos.y+i2,z=pos.z+f[i].z}).name]

					if nnode.damage_per_second>0 then
						break
					end

					if nnode.walkable then
						self.falllook[use]=canuse[i]
						self.falllook.n=use
						use=use+1
						aliveai.showpath({x=pos.x+f[i].x,y=pos.y+i2+1,z=pos.z+f[i].z},2)
						break
					end
				end
			end
			if use==1 then
				self.falllook.ignore=true
				self.falllook.times=5
			else
				self.falllook.times=10
				local p=aliveai.creatpath(self,pos,aliveai.roundpos(pos))
				if p~=nil then
					self.path=p
					self.timerfalling=0.1
					aliveai.falling(self)
					return self
				end
			end
			self.falllook.times=10
			return self
		elseif j[4]==false and self.object:getvelocity().y==0 then
			self.object:setvelocity({x = self.move.x*2, y = 5.2, z =self.move.z*2})
		end
	end
	return self
end

aliveai.jump=function(self,v)
	if self.object:getvelocity().y==0 then
		v=v or {}
		v.y=v.y or 5.2
		v.x=v.x or self.move.x
		v.z=v.z or self.move.z
		self.object:setvelocity({x = self.move.x, y = v.y, z =self.move.z})
	end
end


aliveai.jumping=function(self)
	local pos=self.object:getpos()
	pos.y=pos.y-self.basey
	if minetest.get_node(pos)==nil then return end
	local test=minetest.registered_nodes[minetest.get_node(pos).name]
-- jump inside block
	if self.object:getvelocity().y==0 and test.walkable and test.drawtype~="nodebox" then
		aliveai.jump(self)
		aliveai.showstatus(self,"jump inside block")
		return self
	end
	if self.move.x+self.move.z~=0 and self.object:getvelocity().y==0 then
		local x=self.move.x
		local z=self.move.z
		local j={}
		for i=-2,3,1 do
			j[i+3]=minetest.registered_nodes[minetest.get_node({x=pos.x+x,y=pos.y+i,z=pos.z+z}).name].walkable
		end
-- jump x1
		if j[3] and j[4]==false and j[5]==false then
			aliveai.jump(self)
			minetest.after(0.5, function(self)
				if self and self.object and self.object:get_luaentity() and self.object:get_luaentity().name then
					self.object:setvelocity({x = self.move.x*2, y = self.object:getvelocity().y, z =self.move.z*2})

				end
			end, self)
			aliveai.showstatus(self,"jump")
			return self
--jump x2
		elseif j[4] and j[5]==false and j[6]==false then
			aliveai.jump(self,{y=7})
			minetest.after(0.5, function(self)
				if self and self.object and self.object:get_luaentity() and self.object:get_luaentity().name then
					self.object:setvelocity({x = self.move.x*2, y = self.object:getvelocity().y, z =self.move.z*2})
				end
			end, self)
			aliveai.showstatus(self,"jump x2")
			return self
--wall
		elseif not self.path and j[4] and j[6] then
			aliveai.showstatus(self,"wall")
			aliveai.stand(self)
		end
	end
	return self
end

aliveai.neartarget=function(self,p,starty,endy,stepy)
	aliveai.showstatus(self,"check neartarget")
	local a={
	{x=p.x-1,z=p.z},
	{x=p.x+1,z=p.z},
	{x=p.x,z=p.z+1},
	{x=p.x,z=p.z-1},
	{x=p.x+1,z=p.z+1},
	{x=p.x-1,z=p.z-1},
	{x=p.x-1,z=p.z+1},
	{x=p.x+1,z=p.z-1}}
	local n=8
	local o=aliveai.roundpos(self.object:getpos())
	local last_p=nil
	local last_able=nil
	starty=starty or 1
	endy=endy or -4
	stepy=stepy or -1
	for y=starty,endy,stepy do
		for i=1,8,1 do
			last_p={x=a[i].x,y=p.y+y,z=a[i].z}
			if minetest.registered_nodes[minetest.get_node(last_p).name].walkable==false then
				if minetest.registered_nodes[minetest.get_node({x=a[i].x,y=p.y+y-1,z=a[i].z}).name].walkable and
				minetest.registered_nodes[minetest.get_node({x=a[i].x,y=p.y+y+1,z=a[i].z}).name].walkable==false then
					last_able={x=a[i].x,y=p.y+y,z=a[i].z}
					if o.y==last_able.y then
						aliveai.showpath(last_able,3)
						return last_able
					end
				end
			else
				n=n-1
			end
		end
		if n==0 and y<=0 then
			break	
		end
		n=8
	end
		if last_able~=nil then
			aliveai.showpath(last_able,3)
			return last_able
		end
		return nil
end

aliveai.findnode=function(self,node_name,ignores)
	aliveai.showstatus(self,"find node")
	local pos=self.object:getpos()
	pos.y=pos.y-1
	local re={pos={},path={}}
	local np=minetest.find_node_near(pos, self.distance,{node_name})
	if ignores and np~=nil then -- ignore unable nodes
		for _, s in pairs(ignores) do
			if aliveai.samepos(np,s) then
				return ignores
			end
		end
	end
	if np~=nil and minetest.is_protected(np,"")==false then
	re.pos=np
		local np2=nil
		local near=aliveai.neartarget(self,np)
		if near~=nil then
			np2=near
		else
			np2=minetest.find_node_near(np, 2,{"air"})
		end
		if np2~=nil then
			local np3=np
			if minetest.registered_nodes[minetest.get_node({x=np2.x,y=np2.y-1,z=np2.z}).name].walkable==false
			or minetest.registered_nodes[minetest.get_node({x=np2.x,y=np2.y+1,z=np2.z}).name].walkable==false then
				np3=np2
				aliveai.showpath(np,3)
			end
			local pos1=aliveai.roundpos(pos)
			local p=aliveai.creatpath(self,pos1,np3)
			if p~=nil then
				re.path=p
				return re
			else
			if not ignores then ignores={} end -- ignore unable nodes
				table.insert(ignores, np)
				return ignores
			end
		end
	end
	return nil
end

aliveai.ignorenode=function(self,pos)
	if self.mine then
		if not self.mine.ignore then self.mine.ignore={} end -- ignore unable nodes
		table.insert(self.mine.ignore, pos)
		return self
	end
end

aliveai.samepos=function(pos1,pos2)
	return (pos1 and pos2 and pos1.x==pos2.x and pos1.y==pos2.y and pos1.z==pos2.z)
end

aliveai.roundpos=function(pos)
	if pos and pos.x and pos.y and pos.z then
		pos.x = math.floor(pos.x+0.5)
		pos.y = math.floor(pos.y+0.5)
		pos.z = math.floor(pos.z+0.5)
		return pos
	end
	return nil
end

aliveai.viewfield=function(self,ob)
	local pos1
	local pos2=ob:getpos()
	if not self.aliveai and self.x and self.y and self.z then
		pos1=self
	else
		pos1=self.object:getpos()
	end
	return aliveai.distance(pos1,pos2)>aliveai.distance(aliveai.pointat(self,1),pos2)
end

aliveai.pointat=function(self,d)
	local pos=self.object:getpos()
	local yaw=self.object:getyaw()
	if yaw ~= yaw or type(yaw)~="number" then
		yaw=0
	end
	d=d or 1
	local x =math.sin(yaw) * -d
	local z =math.cos(yaw) * d
	return {x=pos.x+x,y=pos.y,z=pos.z+z}
end

aliveai.distance=function(self,pos2)
	if pos2 and pos2.x and self then
		local pos1
		if not self.object and self.x and self.y and self.z then
			pos1=self
		else
			pos1=self.object:getpos()
		end
		return math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x) + (pos1.y-pos2.y)*(pos1.y-pos2.y)+(pos1.z-pos2.z)*(pos1.z-pos2.z))
	end
	return 99
end

aliveai.visiable=function(self,pos2)
	if not pos2 or not pos2.x then return nil end
	local pos1
	if self.x and self.y and self.z then
		pos1=self
	else
		pos1=self.object:getpos()
	end
	local v = {x = pos1.x - pos2.x, y = pos1.y - pos2.y-1, z = pos1.z - pos2.z}
	v.y=v.y-1
	local amount = (v.x ^ 2 + v.y ^ 2 + v.z ^ 2) ^ 0.5
	local d=math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x) + (pos1.y-pos2.y)*(pos1.y-pos2.y)+(pos1.z-pos2.z)*(pos1.z-pos2.z))
	v.x = (v.x  / amount)*-1
	v.y = (v.y  / amount)*-1
	v.z = (v.z  / amount)*-1
	for i=1,d,1 do
		local node=minetest.get_node({x=pos1.x+(v.x*i),y=pos1.y+(v.y*i),z=pos1.z+(v.z*i)})
		if node and node.name and minetest.registered_nodes[node.name] and minetest.registered_nodes[node.name].walkable then
			return false
		end
	end
	return true
end

aliveai.walk=function(self,sp)
	local pos=self.object:getpos()
	local yaw=self.object:getyaw()
	if yaw ~= yaw or type(yaw)~="number" then
		return nil
	end
	sp=sp or 1
	local x =math.sin(yaw) * -1
	local z =math.cos(yaw) * 1
	local s=(self.move.speed+1)*sp
	self.move.x=x*sp
	self.move.z=z*sp
	self.object:setvelocity({
		x = x*s,
		y = self.object:getvelocity().y,
		z = z*s})
	aliveai.anim(self,"walk")
	return self
end

aliveai.stand=function(self)
	self.move.x=0
	self.move.z=0
	self.object:setvelocity({
		x = 0,
		y = self.object:getvelocity().y,
		z = 0})
	aliveai.anim(self,"stand")
	return self
end

aliveai.lookat=function(self,pos2)
	if pos2==nil or pos2.x==nil then
		return nil
	end
	self.object:setyaw(0)
	local pos1=self.object:getpos()
	local vec = {x=pos1.x-pos2.x, y=pos1.y-pos2.y, z=pos1.z-pos2.z}
	local yaw = math.atan(vec.z/vec.x)-math.pi/2
	if type(yaw)~="number" then yaw=0 end
	if pos1.x >= pos2.x then yaw = yaw+math.pi end
	self.object:setyaw(yaw)
	return self
end

aliveai.anim=function(self,type)
	if self.visual~="mesh" then return end
	local curr=self.anim
	if curr==type or curr==nil then return self end
	if	type=="stand" then self.object:set_animation({ x=  0, y= 79, },30,0)
	elseif	type=="lay" then  self.object:set_animation({ x=162, y=166, },30,0)
	elseif	type=="walk" then  self.object:set_animation({ x=168, y=187, },30,0)
	elseif	type=="mine"  then  self.object:set_animation({ x=189, y=198, },30,0)
	elseif	type=="walk_mine" then  self.object:set_animation({ x=200, y=219, },30,0)
	elseif	type=="sit" then  self.object:set_animation({x= 81, y=160, },30,0)
	else return self
	end
	self.anim=type
	return self
end

aliveai.strpos=function(str,spl)
	if str==nil then return "" end
	if spl then
		local c=","
		if string.find(str," ") then c=" " end
		local s=str.split(str,c)
			if s[3]==nil then
				return nil
			else
				return {x=tonumber(s[1]),y=tonumber(s[2]),z=tonumber(s[3])}
			end
	else	if str.x and str.y and str.z then
			str=aliveai.roundpos(str)
			return str.x .."," .. str.y .."," .. str.z
		else
			return nil
		end
	end
end

aliveai.convertdata=function(str,spl)
	if type(str)=="string" then
		local s1=str.split(str,"?")
		local r={}
		for _, s in ipairs(s1) do
			local s2=s.split(s,"=")
			if s2[2]~=nil and string.find(s2[2],"*")~=nil then	-- tables
				local d1=s2[2].split(s2[2],"*")
				local inner={}
				for nn, ss in pairs(d1) do
					local d2=ss.split(ss," ")
					if d2 and d2[1] then
						if tonumber(d2[1])~=nil then d2[1]=tonumber(d2[1]) end -- table name n to n

						if tonumber(d2[2])~=nil then
							inner[d2[1]]=tonumber(d2[2])
						else
							inner[d2[1]]=d2[2]
						end
					end
				end
				r[s2[1]]=inner
			elseif s2[2]~=nil and string.find(s2[2],",")~=nil then	-- pos
				r[s2[1]]=aliveai.strpos(s2[2],true)
			else						-- else	
				local tnr=tonumber(s2[2])
				if tnr~=nil then s2[2]=tnr end
				r[s2[1]]=s2[2]
			end
		end
		return r
	elseif type(str)=="table" then
		local r=""
		for n, s in pairs(str) do
		r=r .. n .."="
			if s and type(s)=="table" and s.x and s.y and s.z then		-- pos
				r=r .. aliveai.strpos(s,false)
			elseif s and type(s)=="table" then				-- table
				for n1, s1 in pairs(s) do
				if n1==nil or type(n1)=="table" then n1="" s1="" end
					r=r .. n1 .. " " .. s1 .."*"
				end
			else							-- else
				r=r .. s
			end
			r=r .. "?"
		end
		return r
	end
	return ""
end

aliveai.genname=function(self)
	local r=math.random(3,15)
	local s=""
	local rnd
	for i=1, r do
		rnd=math.random(1, 4)
		if rnd==1 then
			s=s .. string.char(math.random(97, 122))
		elseif rnd==2 then
			s=s .. string.char(math.random(48, 57))
		else
			s=s .. string.char(math.random(65, 90))
		end
	end
	return s
end

function aliveai.max(self,update)
	local c=0
	for i in pairs(aliveai.active) do
		c=c+1
		if not aliveai.active[i] or not aliveai.active[i]:get_luaentity() or not aliveai.active[i]:get_hp() or aliveai.active[i]:get_hp()<=0 then
			table.remove(aliveai.active,c)
			c=c-1
		end
	end
	aliveai.active_num=c+1
	if c==0 then aliveai.active_num=0 end
	if c>aliveai.max_num_by_self then
		aliveai.regulate_prestandard=aliveai.max_num-c+2
	else
		aliveai.regulate_prestandard=0
	end
	local new=aliveai.newbot
	aliveai.newbot=nil
	if update then
		return self
	elseif self.old==0 and (c+1>aliveai.max_num or (new and ((self.type=="monster" and c+1>aliveai.max_num_by_self_monsters) or c+1>aliveai.max_num_by_self))) then
		self.object:remove()
		return self
	end
	table.insert(aliveai.active,self.object)
end