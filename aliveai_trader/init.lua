aliveai_trader={}

aliveai.savedata.trader=function(self)
	if self.trader then
		return {
			trader_inventory=self.trader_inventory,
			trader=self.trader,
			trader_select=self.trader_select,
		}
	end
end

aliveai.loaddata.trade=function(self,r)
	if r.trader then
		self.trader_inventory=r.trader_inventory
		self.trader=r.trader
		self.trader_select=r.trader_select
	end
	return self
end



aliveai.create_bot({
		name="trader",
		texture="aliveai_trader.png",
		building=0,
		annoyed_by_staring=0,
		hp=40,
	on_step=function(self,dtime)
		if self.offering then
			aliveai.rndwalk(self,false)
			aliveai.stand(self)
			return self
		end
	end,
	on_click=function(self,clicker)
		if not self.trader then
			aliveai.say(self,"sorry, have no offer... try again")
			self.on_spawn(self)
		end
		self.offering=true
		aliveai.lookat(self,clicker:getpos())
		aliveai_trader.form(self,clicker)
	end,
	on_spawn=function(self)
			self.botname="Trader: " .. self.botname
			self.object:set_properties({nametag=self.botname,nametag_color="#ffffff"})
			self.trader_inventory={}
			self.trader={}
			self.trader_select=1
			local count=0
			local c=1
			aliveai.showstatus(self,"creating offer")
			for i=0,20,1 do
				for i, v in pairs(minetest.registered_items) do
					if math.random(1,10)==1 and not self.trader_inventory[i] and minetest.get_item_group(i, "not_in_creative_inventory")==0 and minetest.get_all_craft_recipes(i) then
						count=count+1
						self.trader_inventory[i]=1
						if count>=20 then break end
					end
				end
				if count>=20 then break end
			end
			if count<1 then
				self.trader_inventory=nil 
				aliveai.showstatus(self,"failed to create offer")
				return self
			end
			count=0
			for i=0,20,1 do
				for i, v in pairs(minetest.registered_items) do
					if math.random(1,20)==1 and not self.trader_inventory[i] and minetest.get_item_group(i, "not_in_creative_inventory")==0 and minetest.get_all_craft_recipes(i) then
						count=count+1
						c=math.random(5,20)
						if v.stack_max<10 then c=math.random(1,v.stack_max) end
						self.trader[i]=c
						if count>=10 then return self end
					end
				end
			end
			if count<1 then
				self.trader_inventory=nil
				self.trader=nil
				aliveai.showstatus(self,"failed to create prices")
				return self
			end
	end,
})
aliveai_trader.form=function(self,player)
	local c=0
	local gui=""
	local but=""
	local but2=""
	local x=0
	local y=0
	local name=player:get_player_name()
	if not aliveai_trader.user then aliveai_trader.user={} end
	aliveai_trader.user[name]=self
	for i, v in pairs(self.trader_inventory) do
		c=c+1
		but=but .. "item_image_button[" .. x.. "," .. y.. ";1,1;".. i ..";buy" .. c ..";]"
		x=x+1
		if x>=10 then x=0 y=y+1 end
	end
	x=-1
	c=0
	for i, v in pairs(self.trader) do
		c=c+1
		x=x+1
		but2=but2 .. "item_image_button[" .. x.. ",3;1,1;".. i ..";pay" .. c ..";\n\n\b\b\b\b".. v .. "]"
	end
	gui=""
	.."size[10,4]"
	.. but
	.."label[0,2;Pay with:]"
	.."label[" .. (self.trader_select-1.2) ..",2.5;(Selected)]"
	.. but2
	minetest.after((0.1), function(gui)
		return minetest.show_formspec(player:get_player_name(), "aliveai_trader.form",gui)
	end, gui)
end

minetest.register_on_player_receive_fields(function(player, form, pressed)
	if form=="aliveai_trader.form" then
		local name=player:get_player_name()
		local self=aliveai_trader.user[name]

		if pressed.quit or not (self and self.object) then
			if self and self.offering then self.offering=nil end
			aliveai_trader.user[name]=nil
			return self
		end

		for i=1,10,1 do
			if pressed["pay" .. i] then
				self.trader_select=i
				aliveai_trader.form(self,player)
				return self
			end
		end

		for ii=1,20,1 do
			if pressed["buy" .. ii] then
				local c=0
				for i, v in pairs(self.trader_inventory) do
					c=c+1
					if c==ii then
						local cc=0
						local inv=player:get_inventory()
						if not inv:room_for_item("main", i) then minetest.chat_send_player(name, "Your inventory are full") return end
						for iii, vv in pairs(self.trader) do
							cc=cc+1
							if cc==self.trader_select then
								if not inv:contains_item("main",  iii .. " "  .. vv) then minetest.chat_send_player(name, "You dont have enough to buy") return end
								inv:remove_item("main", iii .. " "  .. vv)
								aliveai.showstatus(self,"selling: " .. i .." for " .. iii .. " "  .. vv)
							end
						end
						inv:add_item("main", i)
						return self
					end

				end
				return self
			end
		end
		aliveai_trader.user[name]=nil
		return self
	end
end)