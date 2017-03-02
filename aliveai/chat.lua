aliveai.on_spoken_to=function(self,name,speaker,msg)
	aliveai.showstatus(self,"spoken too: " .. msg)
	local player=minetest.get_player_by_name(speaker)

	if player==nil or self.coming_players==0 then
		player=aliveai.get_bot_by_name(speaker)
	end
	if player==nil then return self end
	local known=aliveai.getknown(self,player)

	if self.temper==0 and known~="fight" and known~="fly" and string.find(msg,"come")~=nil then
		if self.team=="Jezy" and player:is_player() then aliveai.sayrnd(self,"no") return self end

		local pos=player:getpos()
		if aliveai.distance(self,pos)>self.distance*2 then
			aliveai.sayrnd(self,"no, too far")
			return self
		end
		if player:get_luaentity() then
			if player:get_luaentity().fly then
				self.fight=player:get_luaentity().fly
				self.temper=2
				return self
			elseif player:get_luaentity().fight then
				self.fight=player:get_luaentity().fight
				self.temper=2
				return self
			end
		end
		if not self.zeal then self.zeal=1 end
		self.zeal=self.zeal+1
		self.come=player
		aliveai.known(self,player,"come")
		aliveai.sayrnd(self,"coming")

	end
	return self
end

aliveai.sayrnd=function(self,t,t2)
	if t==nil then return self end
	local a
	if t=="coming" then
		a={"ok","what?","ok, but then?"}
	elseif t=="ahh" then
		a={"nooo","help!","HELP MEEE","ohh no","that again","hey be cool!","need something?","i dont have enough"}
	elseif t=="ouch" then
		a={"ow","ah","ahhh","ohha","it hurts"}
	elseif t=="come here" then
		a={"ohh your litle","hey you, come here","please come here... i will give you a surprise!","wait","stay","you are dead","i want to talk to you","one by one","i will kick your"," ya r stinking"}
	elseif t=="thanks" then
		a={"thx ".. t2,"thanks i needed that ".. t2,"do you have some more? ","thats nice ".. t2,"cool ".. t2,"thanks a lot","nice"}
	elseif t=="got you" then
		a={"eliminated","feel good, and stay there!","HA HA!","XD","I got him","Got ya!", "c ya","see ya","loser","u r 2 bad","lol","yeah"}
	elseif t=="no" then
		a={"no way!"}
	elseif t=="what are you staring at?" then
		a={"what are you looking for?","waiting for something??","you are disgust me","you are interferes me","turn away your face!","???","?","-_-"}
	end

	if not a then
		aliveai.say(self,t)
		return self
	end
	table.insert(a, t)
	local l=aliveai.getlength(a)
	aliveai.say(self,a[math.random(1,l)])	
end



aliveai.say=function(self,text)
	if self.talking==0 then return self end
	minetest.chat_send_all("<" .. self.botname .."> " .. text)
end

aliveai.msghandler=function(self)
	if self.talking==1 and aliveai.msg[self.botname] then
		local name=aliveai.msg[self.botname].name
		local msg=aliveai.msg[self.botname].msg
		aliveai.msg[self.botname]=nil
		msg=string.sub(msg,string.len(self.botname)+2)
		self.on_spoken_to(self,self.botname,name,msg)
	end
	return self
end

minetest.register_on_chat_message(function(name, message)
	for i,v in pairs(aliveai.active) do
		if v:get_luaentity() and string.find(message,v:get_luaentity().botname .." ",1)~=nil then
			local p=minetest.get_player_by_name(name)
			aliveai.msg[v:get_luaentity().botname]={name=name,msg=message}
			return
		elseif v:get_luaentity() and string.find(message,v:get_luaentity().team .." ",1)~=nil then
			local p=minetest.get_player_by_name(name)
			local na,na2=string.find(message," ")
			local ms=string.sub(message,na)
			local ms2=v:get_luaentity().botname .. ms
			aliveai.msg[v:get_luaentity().botname]={name=name,msg=ms2}
			if math.random(1,3)==1 then return end
		end
	end
	return
end)

aliveai.get_bot_by_name=function(name)
	for i,v in pairs(aliveai.active) do
		if v:get_luaentity() and v:get_luaentity().botname==name then
			return v
		end
	end
	return
end