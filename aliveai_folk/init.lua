aliveai.create_bot({
		name="folk1",
		texture="aliveai_folk1.png",
		arm=3,
})
aliveai.create_bot({
		name="folk2",
		texture="aliveai_folk2.png",
})
aliveai.create_bot({
		name="folk3",
		texture="aliveai_folk3.png",
})
aliveai.create_bot({
		name="folk4",
		texture="aliveai_folk4.png",
		work_helper=1,
})
aliveai.create_bot({
		name="folk5",
		texture="aliveai_folk5.png",
		light=-1,
		stealing=1,
		steal_chanse=2,
		talking=0,
		smartfight=0,
		fighting=0,
		lowest_light=9,
})
aliveai.create_bot({
		name="folk6",
		texture="aliveai_folk6.png",
})
aliveai.create_bot({
		name="folk7",
		texture="aliveai_folk7.png",
})
aliveai.create_bot({
		name="folk8",
		texture="aliveai_folk8.png",
})
aliveai.create_bot({
		name="folk9",
		texture="aliveai_folk9.png",
		hp=30,
		light=-1,
		stealing=1,
		steal_chanse=5,
		lowest_light=5,
})
aliveai.create_bot({
		name="folk10",
		texture="aliveai_folk10.png",
})
aliveai.create_bot({
		name="folk11",
		texture="aliveai_folk11.png",
})
aliveai.create_bot({
		name="folk12",
		texture="aliveai_folk12.png",
})
aliveai.create_bot({
		name="folk13",
		texture="aliveai_folk13.png",
		hp=30,
})
aliveai.create_bot({
		name="folk14",
		texture="aliveai_folk14.png",
		hp=50,
		dmg=8,
		work_helper=1,
})
aliveai.create_bot({
		name="folk15",
		texture="aliveai_folk15.png",
		hp=15,
})

aliveai.create_bot({
		name="folk17",
		texture="aliveai_folk17.png",
		hp=21,
		on_step=function(self,dtime)
			if not self.juggling and self.isrnd and math.random(1,40)==1 then
				for name, s in pairs(self.inv) do
					if s>30 then
						self.juggle_with=name
						break
					end
				end
				if not self.juggle_with then return end
				aliveai.stand(self)
				self.juggle=math.random(3,10)
				self.juggling=math.random(50,100)
			end
			if not self.juggling then return end
			self.juggling=self.juggling-1
			if self.juggling<0 or self.inv[self.juggle_with]==nil or self.inv[self.juggle_with]<1 then self.juggling=nil self.time=self.otime return end
			self.time=1 -((self.juggle*0.1)*0.9)
			local y=5 + self.juggle
			local pos=self.object:getpos()
			local yaw=self.object:getyaw()
			if not self.jside then self.jside=1
			elseif self.jside==0.2 then self.jside=-0.2
			else self.jside=0.2 end
			local x =math.sin(yaw) * self.jside
			local z =math.cos(yaw) * self.jside
			pos.y=pos.y-0.1
			for _, ob in ipairs(minetest.get_objects_inside_radius(pos, 2)) do
				local en=ob:get_luaentity()
				if en and en.name=="__builtin:item" and en.itemstring==self.juggle_with and not en.jtokken then
					en.jtokken=1
					ob:punch(self.object,1,{full_punch_interval=1,damage_groups={fleshy=1}})
					self.inv[self.juggle_with]=self.inv[self.juggle_with]+1
				end
			end
			self.inv[self.juggle_with]=self.inv[self.juggle_with]-1
			local e=minetest.add_item(aliveai.pointat(self,0.5), self.juggle_with)
			e:setvelocity({x=x,y=y,z=z})
			return self
		end
})