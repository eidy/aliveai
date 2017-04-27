aliveai.rnd_talk_to=function(self,ob)
	local bot=aliveai.is_bot(ob)
	local player=ob:is_player()
	if bot or player then
		local r=math.random(1,10)
		if r==1 then
			aliveai.say(self,"who are you?")
		elseif r==2 then
			aliveai.say(self,"what is your name?")
		elseif r==3 then
			aliveai.say(self,"what is your favorite color")
		elseif r==4 then
			aliveai.say(self,"do you have " .. self.lastitem_name)
		elseif r==5 then
			aliveai.say(self,"how are you")
		elseif r==6 and not (bot and ob:get_luaentity().type=="npc") then
			aliveai.say(self,"what is this?")
		elseif r==7 and aliveai.getknown(self,ob)=="" then
			aliveai.say(self,"friends?")
			minetest.after(1, function(self,ob)
				if aliveai.last_spoken_to=="ok" then
					aliveai.known(self,ob,"member")
					self.home=ob:get_luaentity().home
				end
			end, self,ob)
		elseif r==8 and bot and not self.home and ob:get_luaentity().home then
			aliveai.say(self,"can i live with you?")
			minetest.after(1, function(self,ob)
				if aliveai.last_spoken_to=="ok" then
					self.house=nil
					self.home=ob:get_luaentity().home
				end
			end, self,ob)
		elseif r==9 then
			aliveai.say(self,"whats up?")
		elseif r==10 then
			aliveai.say(self,"who want to mine with me?")
		end
	end
end


aliveai.on_spoken_to=function(self,name,speaker,msg)
	aliveai.showstatus(self,"spoken to: " .. msg)
	local player=minetest.get_player_by_name(speaker)
	if player==nil or self.coming_players==0 then
		player=aliveai.get_bot_by_name(speaker)
	end
	if player==nil then return self end
	local known=aliveai.getknown(self,player)

		if known~="member" and (known=="fight" or known=="fly" or self.temper>1 or self.mood<-4 or aliveai.team(player)~=self.team) then
			local name=""
			if aliveai.is_bot(player) then
				name=player:get_luaentity().botname
			elseif player:get_luaentity() then
				name=player:get_luaentity().name
			elseif player:is_player() then
				name=player:get_player_name()
			end
			self.temper=self.temper+0.5
			aliveai.sayrnd(self,"no",name,true)
			if self.temper>2 then
				self.fight=player
			elseif self.temper>1 then
				self.staring={name=name,step=1}
				aliveai.lookat(self,player:getpos(),true)
			end
			return self
		end
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
		local no_came

		if msg=="hi" then self.mood=self.mood-1 aliveai.say(self,"hi") end
		if aliveai.find(msg,{"?"}) then self.mood=self.mood-1 end
		aliveai.find(msg,{"him"},self,"who?")
		aliveai.find(msg,{"aaa"},self,"what?")
		aliveai.find(msg,{"hey"},self,"what?")
		aliveai.find(msg,{"did","hear","that"},self,"what?")
		aliveai.find(msg,{"who","are","you"},self,"a npc")
		aliveai.find(msg,{"who","made","you"},self,"AiTechEye")
		aliveai.find(msg,{"you","like","color"},self,self.namecolor)
		aliveai.find(msg,{"your","name"},self,self.botname)
		aliveai.find(msg,{"your","favorite","color"},self,self.namecolor)
		aliveai.find(msg,{"your","team"},self,self.team)
		aliveai.find(msg,{"what","you","doing"},self,self.task .." step " .. self.taskstep)
		aliveai.find(msg,{"where are you"},self,aliveai.strpos(self.object:getpos()))

		if msg=="can i live with you?" or msg=="friends?" then
			if self.mood>20 then aliveai.say(self,"ok")
			elseif self.mood>0 then aliveai.say(self,"not now")
			elseif self.mood<0 then aliveai.sayrnd(self,"no") end
			return
		end


		if aliveai.find(msg,{"do you","want"}) and aliveai.find_item(self,msg) then aliveai.say(self,"ok") msg="come" end

		if msg=="who?" and self.fight or self.fly then
			if self.fight and self.fight:is_player() then
				aliveai.say(self,self.fight:get_player_name())
			elseif self.fly and self.fly:is_player() then
				aliveai.say(self,self.fly:get_player_name())
			elseif self.fight and aliveai.is_bot(self.fight) then
				aliveai.say(self,aliveai.get_bot_name(self.fight))
			elseif self.fly and aliveai.is_bot(self.fly) then
				aliveai.say(self,aliveai.get_bot_name(self.fly))
			elseif self.fight and self.fight:get_luaentity() then
				aliveai.say(self,self.fight:get_luaentity().name)
			elseif self.fly and self.fly:get_luaentity() then
				aliveai.say(self,self.fly:get_luaentity().name)
			else
				aliveai.say(self,"that thing")
			end
			return
		end
		if aliveai.find(msg,{"do you","have"}) then
			local it,n=aliveai.find_item(self,msg,true)
			if it then
				aliveai.say(self,self.inv[it])
			else
				aliveai.say(self,"no")
			end
			return
		end

		if msg=="who want to mine with me?" then
			if self.mood>20 then aliveai.say(self,"me")
				aliveai.say(self,"where are you?")
				msg="come"
			elseif self.mood<0 then aliveai.sayrnd(self,"no") end
		end

		if self.mood>15 and aliveai.find(msg,{"give","me"}) or aliveai.find(msg,{"i","need"}) then
			local it,n=aliveai.find_item(self,msg,true)
			if it then
				if n>self.inv[it] then n= self.inv[it] aliveai.say(self,"you can get " .. self.inv[it]) no_came=true end
				self.come_give=it
				self.come_give_num=n
				msg="come"
			end
		elseif self.mood>1 and aliveai.find(msg,{"give","me"}) or aliveai.find(msg,{"i","need"}) then
			local it=aliveai.find_item(self,msg,true)
			if it then
				aliveai.say(self,"you can get 1")
				no_came=true
				self.come_give=it
				self.come_give_num=1
				msg="come"
			end
		elseif self.mood<0 and aliveai.find(msg,{"give","me"}) or aliveai.find(msg,{"i","need"}) then
			aliveai.say(self,"get your own stuff")
		end

		if aliveai.find(msg,{"how are you"}) or aliveai.find(msg,{"how do you feel"}) or aliveai.find(msg,{"whats up?"}) then
			if self.mood>20 then aliveai.say(self,"awesome")
			elseif self.temper<0 then aliveai.say(self,"keep me hidden")
			elseif self.mood>10 then aliveai.say(self,"good")
			elseif self.mood>0 then aliveai.say(self,"fine")
			elseif self.mood<1 then aliveai.say(self,"nothng")
			elseif self.mood<2 then aliveai.say(self,"...")
			end
		end

		if aliveai.find(msg,{"what is","this"}) then
			local name=""
			if minetest.get_player_by_name(speaker) then
				name=speaker
			end
			for _, ob in ipairs(minetest.get_objects_inside_radius(player:getpos(), 5)) do
				local en=ob:get_luaentity()
				if not (ob:is_player() and ob:get_player_name()==name)
				and not aliveai.same_bot(self,ob) then
					if ob:is_player() then aliveai.say(self,"a player, " .. name)
					elseif aliveai.is_bot(ob) then aliveai.say(self,"a aliveai bot, " .. en.name)
					elseif en.type and en.type~="" then aliveai.say(self,en.type)
					elseif en.itemstring and minetest.registered_items[en.itemstring] and minetest.registered_items[en.itemstring].description then aliveai.say(self,minetest.registered_items[en.itemstring].description)
					else aliveai.say(self,"idk, " .. en.name)
					end
					if aliveai.team(ob)==self.team then
						 aliveai.say(self,"team member")
					elseif (en and en.type=="monster" or aliveai.is_bot(ob)) or ob:is_player() then
						aliveai.say(self,"enemy")
						self.temper=2
						self.fight=ob
						self.on_detect_enemy(self,self.fight)
					end
					return
				end
			end
			local pp=player:getpos()
			local nn=minetest.get_node({x=pp.x,y=pp.y-1,z=pp.z}).name
			if minetest.registered_items[nn] then
				aliveai.say(self,minetest.registered_items[nn].description or nn)
			end
		end


		if aliveai.find(msg,{"come"}) or aliveai.find(msg,{"help"}) then
			if not self.zeal then self.zeal=1 end
			self.zeal=self.zeal+1
			self.mood=self.mood-1
			self.come=player
			aliveai.known(self,player,"come")
			if not no_came then aliveai.sayrnd(self,"coming") end
		end

	return self
end


aliveai.find_item=function(self,msg,inv)-- self, item exist, item in inventory
	local it=msg.split(msg," ")
	local n=1
	for i, s in pairs(it) do
		local ins=minetest.registered_items[s]
		if ins then
			if it[i+1] and tonumber(it[i+1])~=nil then n=tonumber(it[i+1]) end
			if inv and self.inv[s] then return s,n end
			if not inv then return true end
		end
	end
end



aliveai.find=function(msg,strs,self,say)
	if not (strs and msg) or type(strs)~="table" then
		return false
	end
	local tr=#strs
	local trs=0
	for i, s in pairs(strs) do
		if string.find(msg,s)~=nil then
			trs=trs+1
			if trs>=tr then
				if self and say then aliveai.say(self,say) end
				return true
			end 
		end
	end
	return false
end

aliveai.sayrnd=function(self,t,t2,nmood)
	if (self.mood<1 and not nmood) or t==nil or self.talking==0 then return self end
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
		a={"no way!","stop it!","go away","shut up","stop nagging"}
	elseif t=="what are you staring at?" then
		a={"what are you looking for?","waiting for something??","you are disgust me","you are interferes me","turn away your face!","???","?","-_-","what are you doing?","what you want?"}
	elseif t=="murder!" then
		a={"criminal!","stop him","get him!","killer","betrayer!","hey look that","what r u doing?"}
	elseif t=="its dead!" then
		a={"ohh a corpse","what happend here?","cool!","um?","something went wrong, please try again","hey look!","?","en of the life","Fail!","ugly","this is crazy!"}
	elseif t=="mine" then
		a={"this is hard!","borring","who are you","im hungry","what are you doing?","i need " .. self.lastitem_name,"cant find " .. self.lastitem_name,"plz give me","just 1 more","thats cool","what are your name","hey, can someone give me " .. self.lastitem_count .." " .. self.lastitem_name .."?","this is creepy",":D","how are you",":)",":@","...",":(","what are this",".","hey you","can you meet at " .. math.random(1,24) ..":" .. math.random(0,59) .." ?",aliveai.genname(),aliveai.genname() .." " ..aliveai.genname(),"i just have " .. self.lastitem_count,"do you want ".. self.lastitem_name .."?","k","no","zzz","did someone hear that?","i want a pet","lag","afk"}
	elseif t=="AHHH" then
		a={"aaaaaaaaa","ooooo","hhaaaaa","waaaaa","njaaaaa","?","?????","!??","DOH","Hey im flying!","WEEEE"}
	elseif t=="Hey, im flying!" then
		a={"Hej, hey im flying!","whoo!?","weeeee","look at me, im flying!","cool","help!","plz let me down!","aaaa"}
	elseif t=="its flying!" then
		a={"Hej, its flying!","i want to fly!","this guy is flying!","look","cool","plz let me down!","aaaa"}
	end
	if not a then
		aliveai.say(self,t)
		return self
	end
	table.insert(a, t)
	local say=a[aliveai.random(1,#a)]
	aliveai.say(self,say)
	aliveai.on_chat(self.object:getpos(),self.botname,say)	
end



aliveai.say=function(self,text)
	if self.talking==0 then return self end
	minetest.chat_send_all("<" .. self.botname .."> " .. text)
	aliveai.last_spoken_to=text
	aliveai.on_chat(self.object:getpos(),self.botname,text)
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
	local p=minetest.get_player_by_name(name):getpos()
	aliveai.on_chat(p,name,message)
end)

aliveai.on_chat=function(pos,name,message)
	local d1=25
	local en2
	for i,v in pairs(aliveai.active) do
		local en=v:get_luaentity()
		if en and aliveai.visiable(pos,v:getpos()) and aliveai.get_bot_name(en.object)~=name then
			local d2=aliveai.distance(en,pos)
			if d1>d2 then
				d1=d2
				en2=en
			end
			if string.find(message,en.botname .." ",1)~=nil then
				aliveai.msg[en.botname]={name=name,msg=message}
				return
			elseif string.find(message,en.team .." ",1)~=nil then
				local na,na2=string.find(message," ")
				local ms=string.sub(message,na)
				local ms2=en.botname .. ms
				aliveai.msg[en.botname]={name=name,msg=ms2}
				if math.random(1,3)==1 then return end
			end
		end
	end
	if en2 then
		aliveai.msg[en2.botname]={name=name,msg=en2.botname .." "..message}
	end
	return
end
