-- Large event choices and explicit prices; transactions remain server-validated.
local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Plaza=require(shared.Plaza)
local City={}
City.__index=City
local function eligible(config,offer,property,id)
    if not property or property.ownerId~=id then return false,"Choose one of your homes" end
    if offer.kind=="boost" and (property.boost or 0)>0 then return false,"Rent boost already active" end
    if offer.kind=="shield" and property.shield then return false,"Already protected" end
    if offer.kind=="repair" and property.level>=config.maxLevel then return false,"Already fully upgraded" end
    return true,offer.kind=="boost" and "+50% rent for 2 payments" or (offer.kind=="shield" and "Block the next demolition" or ("Upgrade to level "..(property.level+1)))
end
function City.new(ui)
    local self=setmetatable({ui=ui,tab="overview",tile=nil,kind="shield",pending=nil,error=nil},City)
    local C=ui.colors
    self.shade,self.card=ui.overlay(520,656)
    ui.text(self.card,"CITY EVENTS",24,15,380,22,13,C.green,true)
    self.heading=ui.text(self.card,"Choose an event.",24,45,425,38,27,C.ink,true)
    self.close=ui.button(self.card,"X",452,17,44,44,C.paper,function() self.shade.Visible=false end)
    self.back=ui.button(self.card,"< ALL EVENTS",24,96,168,46,C.paper,function() self:open("overview") end)
    self.title=ui.text(self.card,"",24,154,472,32,23,C.ink,true)
    self.description=ui.text(self.card,"",24,194,472,54,16,C.muted)
    self.period=ui.text(self.card,"",24,254,472,26,13,C.green,true)
    self.rows=Instance.new("ScrollingFrame")
    self.rows.Position,self.rows.Size=UDim2.fromOffset(24,292),UDim2.fromOffset(472,194)
    self.rows.BackgroundTransparency,self.rows.BorderSizePixel,self.rows.ScrollBarThickness,self.rows.Parent=1,0,6,self.card
    self.detail=ui.text(self.card,"",24,498,472,36,15,C.ink,true)
    self.status=ui.text(self.card,"",24,537,472,27,13,C.muted)
    self.confirm=ui.button(self.card,"Choose a home",24,574,332,64,C.gold,function() self:confirmOffer() end)
    self.done=ui.button(self.card,"CLOSE",368,574,128,64,C.paper,function() self.shade.Visible=false end)
    self.confirm.TextSize=17;self.done.TextSize=17
    self.overview=Instance.new("Frame")
    self.overview.Size,self.overview.Position,self.overview.BackgroundTransparency,self.overview.Parent=UDim2.fromOffset(472,452),UDim2.fromOffset(24,102),1,self.card
    self.options={}
    local destinations={
        {"festival","FESTIVAL","Improve one of your homes","FF9DCF"},
        {"market","CARD MARKET","Buy the card you choose","FFC34D"},
        {"contracts","CHALLENGES","Complete goals, collect rewards","AFACFF"},
        {"news","CITY NEWS","Read the city bulletin","75D9EC"},
    }
    for index,item in ipairs(destinations) do
        local x,y=((index-1)%2)*242,math.floor((index-1)/2)*172
        local button=ui.button(self.overview,"",x,y,230,158,C.paper,function() self:open(item[1]) end)
        ui.frame(button,16,16,38,7,Color3.fromHex(item[4]))
        ui.text(button,item[2],16,34,198,27,18,C.ink,true)
        ui.text(button,item[3],16,69,198,42,15,C.muted)
        local note=ui.text(button,"OPEN >",16,121,198,23,14,C.green,true)
        self.options[item[1]]={button=button,note=note}
    end
    ui.text(self.overview,"One paid city offer per turn, before rolling.\nAll prices use game cash.",0,354,472,66,16,C.muted)
    return self
end
function City:isOpen() return self.shade.Visible end
function City:open(tab)
    if tab=="contracts" then self.shade.Visible=false;self.ui.openGoals();return end
    if tab=="festival" and (self.tab~="festival" or not self.shade.Visible) then self.tile=nil end
    self.tab=tab or "overview";self.shade.Visible=true;self.error=nil
    self:render(self.ui.data())
end
function City:feedback(message)
    if self.shade.Visible then self.pending=nil;self.error=message;self:render(self.ui.data()) end
end
function City:confirmOffer()
    local data=self.ui.data()
    if not data or self.pending or (self.tab~="festival" and self.tab~="market") then return end
    local festival=Plaza.festival(self.ui.config,data.game)
    local request={shop=self.tab,kind=self.kind,tile=self.tile,turn=data.game.turnCount,festivalId=festival.id}
    if self.ui.send("Plaza",request) then
        self.pending={turn=request.turn,shop=self.tab};self.error=nil
        local pending=self.pending
        task.delay(4,function()
            if self.pending==pending then self.pending=nil;self.error="Checking your purchase. Please wait for the refreshed match.";self.ui.send("Sync");self:render(self.ui.data()) end
        end)
        self:render(data)
    end
end
function City:render(data)
    if not data or not self.shade.Visible then return end
    local state,ui,C=data.game,self.ui,self.ui.colors
    local me,current
    for _,player in ipairs(state.players) do if player.id==ui.id then me=player end end
    current=state.players[state.turn]
    local myTurn=state.status=="playing" and me and me.alive and current and current.id==ui.id
    if self.pending and self.pending.turn~=state.turnCount then self.pending=nil;self.error="Your turn changed. Review the current offer."
    elseif self.pending and state.plazaUsed then
        local message=self.pending.shop=="festival" and "Festival applied to your home!" or "Card added! Open Cards & Goals to play it."
        self.pending=nil;self.error=nil;self.shade.Visible=false;ui.notify(message);return
    end
    local canBuy=myTurn and state.phase=="roll" and not state.plazaUsed and not self.pending
    local overview=self.tab=="overview"
    self.overview.Visible=overview;self.back.Visible=not overview
    for _,object in ipairs({self.title,self.description,self.period,self.rows,self.detail,self.status,self.confirm}) do object.Visible=not overview end
    self.done.Position,self.done.Size=UDim2.fromOffset(overview and 24 or 368,574),UDim2.fromOffset(overview and 472 or 128,64)
    self.done.Text=overview and "BACK TO BOARD" or "CLOSE"
    self.heading.Text=overview and "Choose an event." or (self.tab=="market" and "Pick a card." or (self.tab=="news" and "Around the city." or "Join the festival."))
    local festival,remaining=Plaza.festival(ui.config,state)
    if overview then
        self.options.festival.note.Text=festival.name.." · $"..festival.cost
        local cheapest=math.huge
        for _,price in pairs(ui.config.cityMarket) do cheapest=math.min(cheapest,price) end
        self.options.market.note.Text="CARDS FROM $"..cheapest.." >"
        self.options.contracts.note.Text=me and me.challenge and me.challenge.ready and "REWARD READY >" or "VIEW YOUR GOAL >"
        self.options.news.note.Text="LATEST UPDATES >"
        return
    end
    self.rows:ClearAllChildren()
    self.detail.TextSize=15
    local cost,valid,count=0,false,0
    local function option(title,subtitle,right,chosen,enabled,callback)
        local button=ui.button(self.rows,"",2,count*70,460,64,chosen and C.mint or C.paper,callback)
        button.Active=enabled
        ui.text(button,title,14,5,324,28,17,enabled and C.ink or C.muted,true)
        ui.text(button,subtitle,14,35,382,23,14,C.muted)
        ui.text(button,right,350,9,96,24,16,C.green,true)
        count=count+1
    end
    if self.tab=="festival" then
        self.title.Text=festival.name;self.description.Text=festival.description
        self.period.Text=remaining.." turns left · choose your home below"
        local allowed={}
        for index,property in ipairs(state.properties) do if eligible(ui.config,festival,property,ui.id) then table.insert(allowed,index) end end
        -- A sole eligible home needs no unnecessary selection click. Multiple
        -- eligible homes always require the player's explicit choice.
        if self.tile and not table.find(allowed,self.tile) then self.tile=nil end
        if not self.tile and #allowed==1 then self.tile=allowed[1] end
        for index,property in ipairs(state.properties) do if property.ownerId==ui.id then
            local enabled,explanation=eligible(ui.config,festival,property,ui.id)
            local chosen=self.tile==index
            option(ui.config.tiles[index].name,explanation,chosen and "CHOSEN" or ("L"..property.level),chosen,enabled,function() self.tile=index;self.error=nil;self:render(ui.data()) end)
        end end
        if count==0 then ui.text(self.rows,"Buy a home first to join this festival.\nYou can still visit the Card Market.",12,22,440,100,18,C.muted) end
        cost=festival.cost;valid=self.tile~=nil
        self.detail.Text=valid and ("Cost $"..cost.." · Balance after $"..((me and me.cash or 0)-cost)) or ("Choose a home · festival costs $"..cost)
    elseif self.tab=="market" then
        self.title.Text="Choose exactly what you get."
        self.description.Text="Buy a card, then open Cards & Goals to choose its target and play it."
        self.period.Text="One purchase per turn · up to 3 of each card"
        for _,kind in ipairs(ui.config.cardTypes) do
            local definition=ui.config.cardDefinitions[kind]
            local owned=me and me.cards[kind] or 0
            local chosen=self.kind==kind
            local enabled=owned<ui.config.cardLimit
            option(definition.name,(chosen and "SELECTED · " or "")..owned.." / 3 in your hand","$"..ui.config.cityMarket[kind],chosen,enabled,function() self.kind=kind;self.error=nil;self:render(ui.data()) end)
        end
        self.detail.Text=ui.config.cardDefinitions[self.kind].description
        self.detail.TextSize=14
        cost=ui.config.cityMarket[self.kind];valid=me and (me.cards[self.kind] or 0)<ui.config.cardLimit or false
    else
        self.title.Text="Current festival: "..festival.name
        self.description.Text=festival.description
        self.period.Text="RECENT CITY NEWS"
        for _,message in ipairs(state.logs) do ui.text(self.rows,message,8,count*64,444,60,16,C.ink);count=count+1 end
        self.detail.Text="Events and offers change as the match progresses."
    end
    self.rows.CanvasSize=UDim2.fromOffset(0,count*(self.tab=="news" and 64 or 70))
    self.status.Text=self.error or (not myTurn and "Look around! Paid offers open on your turn." or (state.phase~="roll" and "Use city offers before rolling on your next turn." or (state.plazaUsed and "City offer used. Your next step is to roll." or "")))
    self.status.TextColor3=self.error and C.red or C.muted
    local enabled=canBuy and valid and me.cash>=cost and self.tab~="news"
    ui.available(self.confirm,enabled==true,C.gold)
    self.confirm.Visible=self.tab~="news"
    if self.pending then self.confirm.Text="CONFIRMING..."
    elseif not canBuy then self.confirm.Text="BROWSE FOR NEXT TURN"
    elseif not valid then self.confirm.Text=self.tab=="festival" and "CHOOSE A HOME" or "CARD LIMIT REACHED"
    elseif me.cash<cost then self.confirm.Text="NEED $"..(cost-me.cash).." MORE"
    else self.confirm.Text=(self.tab=="market" and "BUY CARD · $" or "JOIN FESTIVAL · $")..cost end
end
return City
