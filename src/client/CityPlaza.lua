local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Plaza=require(shared.Plaza)
local City={}
City.__index=City
function City.new(ui)
    local self=setmetatable({ui=ui,tab="festival",tile=nil,kind="shield",pending=nil,error=nil},City)
    local C=ui.colors
    self.shade,self.card=ui.overlay(520,628)
    ui.text(self.card,"THE CITY PLAZA",24,14,430,20,10,C.green,true)
    ui.text(self.card,"Something is happening.",24,39,440,34,25,C.ink,true)
    ui.button(self.card,"X",468,18,28,28,C.paper,function() self.shade.Visible=false end)
    self.tabs={}
    for index,tab in ipairs({"festival","market","contracts","news"}) do
        local label=({festival="Festival",market="Card market",contracts="Challenges",news="City news"})[tab]
        self.tabs[tab]=ui.button(self.card,label,24+(index-1)*120,87,112,36,C.paper,function() self:open(tab) end)
        self.tabs[tab].TextSize=12
    end
    self.title=ui.text(self.card,"",24,137,472,32,22,C.ink,true)
    self.description=ui.text(self.card,"",24,176,472,60,14,C.muted)
    self.period=ui.text(self.card,"",24,241,472,22,11,C.green,true)
    self.rows=Instance.new("ScrollingFrame")
    self.rows.Position,self.rows.Size=UDim2.fromOffset(24,274),UDim2.fromOffset(472,204)
    self.rows.BackgroundTransparency,self.rows.BorderSizePixel,self.rows.ScrollBarThickness,self.rows.Parent=1,0,3,self.card
    self.detail=ui.text(self.card,"",24,487,472,41,12,C.muted)
    self.status=ui.text(self.card,"",24,534,472,24,11,C.red)
    self.confirm=ui.button(self.card,"Choose an offer",24,572,332,40,C.green,function() self:confirmOffer() end)
    ui.button(self.card,"Back",368,572,128,40,C.paper,function() self.shade.Visible=false end)
    return self
end
function City:isOpen() return self.shade.Visible end
function City:open(tab)
    if tab=="contracts" then self.shade.Visible=false;self.ui.openGoals();return end
    self.tab=tab or "festival";self.shade.Visible=true;self.error=nil
    self:render(self.ui.data())
end
function City:feedback(message)
    if self.shade.Visible then self.pending=nil;self.error=message;self:render(self.ui.data()) end
end
function City:confirmOffer()
    local data=self.ui.data()
    if not data or self.pending then return end
    local festival=Plaza.festival(self.ui.config,data.game)
    local request={shop=self.tab,kind=self.kind,tile=self.tile,turn=data.game.turnCount,festivalId=festival.id}
    if self.ui.send("Plaza",request) then
        self.pending={turn=request.turn};self.error=nil
        local pending=self.pending
        task.delay(4,function()
            if self.pending==pending then self.pending=nil;self.error="Refreshing the plaza. Check the match before trying again.";self.ui.send("Sync");self:render(self.ui.data()) end
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
    local canBuy=myTurn and state.phase=="roll" and not state.plazaUsed and not self.pending
    if self.pending and self.pending.turn~=state.turnCount then self.pending=nil;self.error="Your turn changed. Review the current offer."
    elseif self.pending and state.plazaUsed then self.pending=nil;self.error=nil;ui.notify("Your city plaza purchase is ready.") end
    for tab,button in pairs(self.tabs) do button.BackgroundColor3=tab==self.tab and C.green or C.paper;button.TextColor3=tab==self.tab and C.white or C.ink end
    self.rows:ClearAllChildren()
    local festival,remaining=Plaza.festival(ui.config,state)
    local cost,valid=0,false
    local count=0
    if self.tab=="festival" then
        self.title.Text=festival.name;self.description.Text=festival.description
        self.period.Text=remaining.." total turns until the next festival · choose your property"
        for index,property in ipairs(state.properties) do
            if property.ownerId==ui.id then
                local chosen=self.tile==index
                local option=ui.button(self.rows,(chosen and "> " or "")..ui.config.tiles[index].name.." · Level "..property.level,2,count*42,464,36,chosen and C.green or C.paper,function() self.tile=index;self.error=nil;self:render(ui.data()) end)
                option.TextSize=13;count=count+1
            end
        end
        if count==0 then ui.text(self.rows,"Buy a home to take part in this festival.",12,20,440,48,15,C.muted) end
        cost=festival.cost
        local property=self.tile and state.properties[self.tile]
        valid=property and property.ownerId==ui.id or false
        self.detail.Text="Price: $"..cost.." in game cash · one plaza purchase per turn."
        if valid then
            if festival.kind=="boost" and (property.boost or 0)>0 then valid=false;self.detail.Text="This home already has an active rent boost."
            elseif festival.kind=="shield" and property.shield then valid=false;self.detail.Text="This home is already protected."
            elseif festival.kind=="repair" and property.level>=ui.config.maxLevel then valid=false;self.detail.Text="This home is already fully upgraded." end
        end
    elseif self.tab=="market" then
        self.title.Text="Choose your next move."
        self.description.Text="Buy a tactical card using game cash. Choose exactly what you receive, then play it through Cards & goals."
        self.period.Text="ONE PLAZA PURCHASE PER TURN · MAXIMUM THREE OF EACH CARD"
        for _,kind in ipairs(ui.config.cardTypes) do
            local definition=ui.config.cardDefinitions[kind]
            local chosen=self.kind==kind
            local owned=me and me.cards[kind] or 0
            local option=ui.button(self.rows,definition.name.." · $"..ui.config.cityMarket[kind].." · hand "..owned.." / 3",2,count*40,464,34,chosen and C.green or C.paper,function() self.kind=kind;self.error=nil;self:render(ui.data()) end)
            option.TextSize=12;count=count+1
        end
        self.detail.Text=ui.config.cardDefinitions[self.kind].description
        cost=ui.config.cityMarket[self.kind];valid=me and (me.cards[self.kind] or 0)<ui.config.cardLimit or false
    else
        self.title.Text="Around the table."
        self.description.Text="Current festival: "..festival.name..". "..festival.description
        self.period.Text="RECENT CITY BULLETIN"
        for _,message in ipairs(state.logs) do ui.text(self.rows,message,8,count*47,448,43,13,C.ink);count=count+1 end
        self.detail.Text="Click the plaza's market, festival pavilion or challenge hall to explore."
    end
    self.rows.CanvasSize=UDim2.fromOffset(0,count*(self.tab=="news" and 47 or 42))
    self.status.Text=self.error or (not myTurn and "Explore any time. Purchases open during your turn." or (state.phase~="roll" and "Visit the plaza before you roll on your next turn." or (state.plazaUsed and "Your plaza purchase is used for this turn." or "")))
    local enabled=canBuy and valid and me.cash>=cost and self.tab~="news"
    ui.available(self.confirm,enabled==true,C.green)
    self.confirm.Text=self.pending and "Confirming…" or (self.tab=="news" and "Festival & market tabs have offers" or (not canBuy and "Browse offers for your next turn" or (me.cash<cost and ("Need $"..(cost-me.cash).." more") or ("Confirm · $"..cost.." in game cash"))))
end
return City
