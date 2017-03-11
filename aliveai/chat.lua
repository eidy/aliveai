aliveai.on_spoken_to=function(self,name,speaker,msg)
	aliveai.showstatus(self,"spoken to: " .. msg)
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
	if t==nil or self.talking==0 then return self end
	local a
	if t=="coming" then
		a={"ok","what?","ok, but then?","so?"}
	elseif t=="ahh" then
		a={"AHH!!","nooo","help!","HELP MEEE","ohh no","you again","hey be cool!","need something?","i dont have enough","STOP HIM!!!","plz stop him!"}
	elseif t=="ouch" then
		a={"ow","ah","ahhh","ohha","it hurts","A","stop it!","aaaa"}
	elseif t=="come here" then
		a={"ohh your litle","hey you, come here","please come here... i will give you a surprise!","wait","stay","you are dead","i want to talk to you","one by one","i will kick your"," ya r stinking","ban","please ban him!","this is your end of life!"}
	elseif t=="thanks" then
		a={"thx ".. t2,"thanks i needed that ".. t2,"do you have some more? ","thats nice ".. t2,"cool ".. t2,"thanks a lot","nice"}
	elseif t=="got you" then
		a={"eliminated","feel good, and stay there!","HA HA!","XD","I got him","Got ya!", "c ya","see ya","loser","u r 2 bad","lol","yeah","..."}
	elseif t=="no" then
		a={"no way!"}
	elseif t=="what are you staring at?" then
		a={"what are you looking for?","waiting for something??","you are disgust me","you are interferes me","turn away your face!","???","?","-_-","what are you doing?","what you want?"}
	elseif t=="murder!" then
		a={"criminal!","stop him","get him!","killer","betrayer!","hey look that","what r u doing?"}
	elseif t=="its dead!" then
		a={"ohh a corpse","what happend here?","cool!","um?","something went wrong, please try again","hey look!","?","en of the life","Fail!","ugly","this is crazy!"}
	elseif t=="beautiful weather" then
		a={"this is hard!","borring","monster?","im hungry","i need a home","i need " .. self.lastitem_name,"cant find " .. self.lastitem_name,"just 1 more","thats cool","im alive","hey, can someone give me " .. self.lastitem_count .." " .. self.lastitem_name .."s?","this is creepy",":D","lol",":)",":@","...",":(",":/",".","hey you","can you meet at " .. math.random(1,24) ..":" .. math.random(0,59) .." ?",aliveai.genname(),aliveai.genname() .." " ..aliveai.genname(),"i just have " .. self.lastitem_count,"anyone have ".. self.lastitem_name .."?","k","no","zzz","did someone hear that?"}
	elseif t=="AHHH" then
		a={"aaaaaaaaa","ooooo","hhaaaaa","waaaaa","njaaaaa","?","?????","!??","DOH"}
	end
	if not a then
		aliveai.say(self,t)
		return self
	end
	table.insert(a, t)
	aliveai.say(self,a[aliveai.random(1,#a)])	
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