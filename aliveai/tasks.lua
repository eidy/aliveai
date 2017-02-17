aliveai.savedata.task_build=function(self)
	if self.task=="build" then
		return {
			house=self.house,
			build_step=self.build_step,
			build_x=self.build_x,
			build_y=self.build_y,
			build_z=self.build_z,
			build_pos=self.build_pos,
			ignoremineitem=self.ignoremineitem,
			ignoreminechange=self.ignoreminechange,
			ignoreminetime=self.ignoreminetime,
			ignoreminetimer=self.ignoreminetimer,
		}
	end
end

aliveai.loaddata.task_build=function(self,r)
	if self.task=="build" then
		self.house=r.house
		self.build_step=r.build_step
		self.build_x=r.build_x
		self.build_y=r.build_y
		self.build_z=r.build_z
		self.build_pos=r.build_pos
		self.ignoremineitem=r.ignoremineitem
		self.ignoreminetime=tonumber(r.ignoreminetime)
		self.ignoreminetimer=tonumber(r.ignoreminetimer)
		self.ignoreminechange=tonumber(r.ignoreminechange)
	end
	return self
end



aliveai.task_build=function(self)
		if self.building~=1 then return self end
		if self.path and self.done=="" and self.tmpgoto then			-- path
			aliveai.path(self)
			self.tmpgoto=self.tmpgoto+1
			if self.tmpgoto>=20 then 
				aliveai.exitpath(self)
				aliveai.showstatus(self,"path failed, mine")
			end
		end
		if self.taskstep<1 then		--if need to dig
			aliveai.buildpath(self,true) -- get need info
			if aliveai.haveneed(self) then
				self.done=""
				if self.resources then
					local pos=self.object:getpos()
					pos.y=pos.y+1
					local p=aliveai.creatpath(self,pos,self.resources,20)
					if p then
						self.path=p
						aliveai.showstatus(self,"go to resources and mine",4)
						return self
					end

				end
				self.mine={target={},status="search"}
				aliveai.showstatus(self,"mine",4)
			else
				self.taskstep=1
			end
			return self
		end
		if self.taskstep==1 then			-- mine done: find space
			self.findspace=true
			self.done=""
			aliveai.showstatus(self,"findspace",4)
			return self
		end
		if self.taskstep==2 then		-- findspace done: build
			self.build={}
			self.done=""
			aliveai.showstatus(self,"build",4)
			return self
		end
		if self.taskstep==3 then			-- build building done, clear status
			if not self.home then		-- set home if it was a house
				local pos=self.object:getpos()
				pos.y=pos.y+1
				self.home=pos
				aliveai.showstatus(self,"home set, build done",3)
			else
				aliveai.showstatus(self,"status build done",3)
			end
			self.ignore_item={}
			self.done=""
			self.task=""
			self.build_step=nil
			self.build_x=nil
			self.build_y=nil
			self.build_z=nil
			self.build_pos=nil
			self.house=nil
			self.taskstep=0
			return self
		end
end