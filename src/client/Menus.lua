-- Lobby, tactical targeting and challenge menus share the main HUD's controls.
local SocialService=game:GetService("SocialService")
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Menus={}
Menus.__index=Menus
function Menus.new(ui)
    local self=setmetatable({ui=ui,kind="demolish",tile=nil,targetId=nil,pending=nil,error=nil},Menus)
    local C,config=ui.colors,ui.config
    local frame,text,button,overlay=ui.frame,ui.text,ui.button,ui.overlay
    self.lobby,self.lobbyCard=overlay(520,632)
    text(self.lobbyCard,"Play together",24,16,436,36,26,C.ink,true)
    text(self.lobbyCard,"Choose your match, player color and readiness.",24,55,472,30,13,C.muted)
    self.leaveParty=button(self.lobbyCard,"Leave party",338,18,120,28,C.paper,function() ui.send("LeaveParty") end)
    button(self.lobbyCard,"×",468,18,28,28,C.paper,function() self.lobby.Visible=false end)
    self.two=button(self.lobbyCard,"2 players",24,100,230,44,C.green,function() ui.send("Seats",2) end)
    self.four=button(self.lobbyCard,"4 players",266,100,230,44,C.paper,function() ui.send("Seats",4) end)
    self.bots=button(self.lobbyCard,"Fill empty seats with bots",24,154,472,38,C.paper,function()
        local data=ui.data();if data then ui.send("Bots",not data.lobbyConfig.fillBots) end
    end)
    text(self.lobbyCard,"PRACTICE DEMOLITION RULE · ONLINE ALWAYS DESTROYS THE HOUSE",24,204,472,20,10,C.muted,true)
    self.downgrade=button(self.lobbyCard,"Remove one level",24,232,230,36,C.paper,function() ui.send("AttackRule","downgrade") end)
    self.destroy=button(self.lobbyCard,"Destroy whole house",266,232,230,36,C.paper,function() ui.send("AttackRule","destroy") end)
    self.members=Instance.new("ScrollingFrame")
    self.members.Position,self.members.Size=UDim2.fromOffset(24,286),UDim2.fromOffset(472,118)
    self.members.BackgroundTransparency,self.members.BorderSizePixel,self.members.ScrollBarThickness,self.members.Parent=1,0,3,self.lobbyCard
    text(self.lobbyCard,"YOUR PLAYER COLOR · colors already taken are locked",24,414,472,20,10,C.muted,true)
    self.colorButtons={}
    for index,hex in ipairs(config.playerColors) do
        local choose=button(self.lobbyCard,tostring(index),24+(index-1)*78,442,66,32,Color3.fromHex(hex),function() ui.send("Color",index) end)
        choose.TextColor3=C.ink;table.insert(self.colorButtons,choose)
    end
    self.ready=button(self.lobbyCard,"Ready",24,490,230,40,C.green,function() self:toggleReady() end)
    self.invite=button(self.lobbyCard,"Invite friends",266,490,230,40,C.paper,function()
        task.spawn(function()
            if RunService:IsStudio() or game.PlaceId==0 then self.error="Publish the place, then invite friends from a live Roblox server.";self:render(ui.data());return end
            local data=ui.data()
            if not data then return end
            if data and data.matchmaking and (data.matchmaking.mode=="match" or data.matchmaking.queued) then self.error="Invite friends from the lobby before your party joins a queue.";self:render(ui.data());return end
            local ok,canInvite=pcall(function() return SocialService:CanSendGameInviteAsync(Players.LocalPlayer) end)
            if not ok or not canInvite then self.error="Roblox cannot open invites here. Friends can use the experience's Join button.";self:render(ui.data());return end
            local options=Instance.new("ExperienceInviteOptions")
            options.LaunchData=Http:JSONEncode({citymoneyJob=game.JobId,leaderId=data.hostId})
            local opened=pcall(function() SocialService:PromptGameInvite(Players.LocalPlayer,options) end)
            if not opened then self.error="The invite prompt could not open. Try the Roblox experience page.";self:render(ui.data()) end
        end)
    end)
    self.lobbyStatus=text(self.lobbyCard,"",24,536,472,29,12,C.muted)
    self.queue=button(self.lobbyCard,"Join online queue",24,576,230,40,C.green,function()
        local data=ui.data()
        if data and data.matchmaking and data.matchmaking.mode=="match" then ui.send("BackLobby")
        elseif data and data.matchmaking and data.matchmaking.queued then ui.send("QueueCancel")
        else ui.send("Queue") end
    end)
    self.start=button(self.lobbyCard,"Practice",266,576,230,40,C.paper,function() ui.send("Start") end)
    self.actions,self.actionCard=overlay(520,660)
    text(self.actionCard,"Cards & challenges",24,16,436,36,25,C.ink,true)
    button(self.actionCard,"×",468,18,28,28,C.paper,function() self.actions.Visible=false end)
    local challenge=frame(self.actionCard,24,66,472,101,C.mint)
    self.goalName=text(challenge,"Your challenge",12,7,310,24,15,C.ink,true)
    self.goalText=text(challenge,"",12,34,310,40,12,C.muted)
    self.goalProgress=text(challenge,"",12,78,310,15,10,C.green,true)
    self.claim=button(challenge,"Claim reward",338,12,122,34,C.green,function()
        local data=ui.data();if data then ui.send("Claim",nil,nil,data.game.turnCount) end
    end);self.claim.TextSize=11
    self.newGoal=button(challenge,"New goal $50",338,55,122,30,C.paper,function()
        local data=ui.data();if data then ui.send("NewGoal",nil,nil,data.game.turnCount) end
    end);self.newGoal.TextSize=10
    self.cardStatus=text(self.actionCard,"ONE TACTICAL CARD PER TURN",24,178,472,18,10,C.muted,true)
    self.cardButtons={}
    local short={demolish="Demolish",collect="Demand rent",boost="Rent boost",shield="Shield",repair="Renovate"}
    for index,kind in ipairs(config.cardTypes) do
        local select=button(self.actionCard,short[kind],24+((index-1)%3)*160,202+math.floor((index-1)/3)*44,152,36,C.paper,function()
            if not self.pending then self.kind=kind;self.tile=nil;self.targetId=nil;self.error=nil;self:render(ui.data()) end
        end)
        select.TextSize=11;self.cardButtons[kind]=select
    end
    self.description=text(self.actionCard,"",24,293,472,42,12,C.muted)
    text(self.actionCard,"CHOOSE THE PROPERTY",24,339,472,18,10,C.muted,true)
    self.properties=Instance.new("ScrollingFrame")
    self.properties.Position,self.properties.Size=UDim2.fromOffset(24,365),UDim2.fromOffset(472,112)
    self.properties.BackgroundTransparency,self.properties.BorderSizePixel,self.properties.ScrollBarThickness,self.properties.Parent=1,0,3,self.actionCard
    self.targetCaption=text(self.actionCard,"",24,483,472,18,10,C.muted,true)
    self.opponents=Instance.new("Frame")
    self.opponents.Position,self.opponents.Size,self.opponents.BackgroundTransparency,self.opponents.Parent=UDim2.fromOffset(24,507),UDim2.fromOffset(472,32),1,self.actionCard
    self.effect=text(self.actionCard,"",24,544,472,25,13,C.ink,true)
    self.play=button(self.actionCard,"Choose a property",24,580,332,42,C.green,function() self:playCard() end)
    button(self.actionCard,"Back",368,580,128,42,C.paper,function() self.actions.Visible=false end)
    self.actionStatus=text(self.actionCard,"",24,629,472,20,10,C.red)
    self.shortNames=short
    return self
end
function Menus:isOpen() return self.lobby.Visible or self.actions.Visible end
function Menus:openLobby() self.lobby.Visible=true;self.actions.Visible=false;self.error=nil;self:render(self.ui.data()) end
function Menus:toggleReady()
    local data=self.ui.data()
    if not data then return end
    for _,entry in ipairs(data.lobby) do if entry.id==self.ui.id then self.ui.send("Ready",not entry.ready);return end end
end
function Menus:feedback(message)
    self.pending=nil;self.error=message
    self:render(self.ui.data())
end
function Menus:resize(layout,_rosterHeight)
    if not self.ui.cameraBar then return end
    local bar=self.ui.cameraBar
    local r=layout.camera
    bar.Position,bar.Size=UDim2.fromOffset(r[1],r[2]),UDim2.fromOffset(r[3],r[4])
    local specs={{"TableView",4,100},{"Fit",108,60},{"ZoomOut",172,36},{"ZoomIn",212,36}}
    for _,spec in ipairs(specs) do
        local object=bar:FindFirstChild(spec[1])
        object.Position,object.Size=UDim2.fromOffset(spec[2],2),UDim2.fromOffset(spec[3],30)
    end
end
function Menus:playCard()
    local data=self.ui.data()
    if not data or self.pending or not self.tile then return end
    local request={kind=self.kind,tile=self.tile,targetId=self.targetId,turn=data.game.turnCount}
    if self.ui.send("Card",request) then
        self.pending={turn=request.turn,seq=data.game.lastAction and data.game.lastAction.seq or 0,tile=self.tile}
        local pending=self.pending
        self.error=nil;self:render(data)
        task.delay(4,function()
            if self.pending==pending then
                self.pending=nil;self.error="No confirmation yet. Refreshing the match before you retry."
                self.ui.send("Sync");self:render(self.ui.data())
            end
        end)
    end
end
function Menus:render(data)
    if not data then return end
    local ui,C,config=self.ui,self.ui.colors,self.ui.config
    if self.revision~=data.revision then self.error=nil;self.revision=data.revision end
    local state,settings=data.game,data.lobbyConfig
    if state.status=="playing" and self.lastStatus~="playing" then
        self.lobby.Visible=false;self.actions.Visible=false;self.pending=nil
    end
    self.lastStatus=state.status
    local me,current
    for _,entry in ipairs(state.players) do if entry.id==ui.id then me=entry end end
    current=state.players[state.turn]
    local myTurn=state.status=="playing" and current and current.id==ui.id and current.alive
    local host=data.hostId==ui.id
    local queue=data.matchmaking or {mode="lobby",queued=false,status=""}
    local active=state.status=="playing" and me and me.alive
    local editable=host and not active and not queue.queued and queue.mode~="match"
    local mine,readyCount=nil,0
    for _,entry in ipairs(data.lobby) do
        if entry.id==ui.id then mine=entry end
        if entry.ready then readyCount=readyCount+1 end
    end
    if not settings then return end
    ui.available(self.two,editable,settings.seats==2 and C.green or C.paper)
    ui.available(self.four,editable,settings.seats==4 and C.green or C.paper)
    ui.available(self.bots,editable,C.paper)
    self.bots.Text="Practice fills empty seats with bots: "..(settings.fillBots and "ON" or "OFF")
    ui.available(self.downgrade,editable,settings.attackMode=="downgrade" and C.green or C.paper)
    ui.available(self.destroy,editable,settings.attackMode=="destroy" and C.green or C.paper)
    self.members:ClearAllChildren()
    for index,entry in ipairs(data.lobby) do
        local name=ui.text(self.members,(entry.ready and "✓ " or "○ ")..entry.name..(entry.id==data.hostId and " · host" or ""),8,(index-1)*28,450,26,13,Color3.fromHex(config.playerColors[entry.colorIndex] or "798579"),entry.id==ui.id)
        name.TextWrapped,name.TextTruncate=false,Enum.TextTruncate.AtEnd
    end
    self.members.CanvasSize=UDim2.fromOffset(0,#data.lobby*28)
    for index,button in ipairs(self.colorButtons) do
        local taken=false
        for _,entry in ipairs(data.lobby) do if entry.id~=ui.id and entry.colorIndex==index then taken=true end end
        button.Active=not active and not queue.queued and queue.mode~="match" and not taken
        button.BackgroundTransparency=taken and 0.6 or 0
        button.Text=mine and mine.colorIndex==index and "✓" or tostring(index)
    end
    self.ready.Text=mine and mine.ready and "Ready ✓ · click to unready" or "I'm ready to play"
    ui.available(self.ready,mine~=nil and not queue.queued and queue.mode~="match",mine and mine.ready and C.green or C.paper)
    local enough=readyCount>=settings.seats or settings.fillBots
    self.lobbyStatus.Text=self.error or ((queue.queued or queue.mode=="match") and queue.status or (queue.status.." · "..#data.lobby.." in party · "..readyCount.." ready"))
    self.lobbyStatus.TextColor3=self.error and C.red or C.muted
    ui.available(self.start,editable and state.status~="playing" and mine~=nil and mine.ready and enough,C.paper)
    self.start.Text="Practice with "..settings.seats.." players"
    local partyReady=readyCount==#data.lobby and #data.lobby<=settings.seats
    ui.available(self.queue,queue.mode=="match" or (queue.queued and not queue.connecting) or (host and not active and mine~=nil and mine.ready and partyReady),C.green)
    self.queue.Text=queue.mode=="match" and "Return to lobby" or (queue.queued and (queue.connecting and "Connecting…" or "Cancel queue") or ("Join "..settings.seats.."-player queue"))
    self.leaveParty.Text=queue.mode=="match" and "Leave match" or "Leave party"
    ui.available(self.leaveParty,not queue.connecting,C.paper)
    if not self.actions.Visible then return end
    if not me or not me.alive or state.status~="playing" then self.actions.Visible=false;self.pending=nil;return end
    if self.pending then
        local event=state.lastAction
        if event and event.seq>self.pending.seq and event.actorId==ui.id then
            local tile=self.pending.tile
            self.pending=nil;self.actions.Visible=false;ui.focus(tile);return
        elseif self.pending.turn~=state.turnCount then self.pending=nil;self.error="Your turn changed. Choose your action again." end
    end
    local goal=me.challenge
    self.goalName.Text=goal.name
    self.goalText.Text=goal.description
    self.goalProgress.Text=goal.progress.." / "..goal.target.." · reward $"..goal.reward.." + card"
    self.claim.Text="Claim $"..goal.reward
    ui.available(self.claim,myTurn and goal.ready and not state.challengeClaimed,C.green)
    ui.available(self.newGoal,myTurn and not state.challengeSwapped and me.cash>=config.challengeSwapCost,C.paper)
    self.cardStatus.Text=state.actionUsed and "YOUR TACTICAL CARD HAS BEEN USED THIS TURN" or "ONE TACTICAL CARD PER TURN · CHOOSE YOUR TARGETS"
    for kind,button in pairs(self.cardButtons) do
        button.Text=self.shortNames[kind].." ×"..(me.cards[kind] or 0)
        button.Active=not self.pending
        button.BackgroundColor3=kind==self.kind and C.green or C.paper
        button.TextColor3=kind==self.kind and C.white or C.ink
    end
    local definition=config.cardDefinitions[self.kind]
    self.description.Text=definition.description
    self.properties:ClearAllChildren();self.opponents:ClearAllChildren()
    local candidates={}
    for index,property in ipairs(state.properties) do
        if property.ownerId and ((definition.target=="rival" and property.ownerId~=ui.id) or (definition.target~="rival" and property.ownerId==ui.id)) then table.insert(candidates,index) end
    end
    if self.tile and not table.find(candidates,self.tile) then self.tile=nil end
    for row,index in ipairs(candidates) do
        local property=state.properties[index]
        local owner
        for _,entry in ipairs(state.players) do if entry.id==property.ownerId then owner=entry end end
        local select=ui.button(self.properties,config.tiles[index].name.." · "..(owner and owner.name or "").." · L"..property.level,2,(row-1)*33,466,28,self.tile==index and C.green or C.paper,function()
            if not self.pending then self.tile=index;self.error=nil;self:render(ui.data()) end
        end)
        select.TextSize=11
    end
    if #candidates==0 then ui.text(self.properties,definition.target=="rival" and "No opponent owns a house yet." or "Buy a property before using this card.",8,8,450,45,13,C.muted) end
    self.properties.CanvasSize=UDim2.fromOffset(0,#candidates*33)
    self.targetCaption.Text=definition.target=="demand" and "CHOOSE WHO MUST PAY" or (settings.attackMode=="destroy" and "ATTACK RULE: FULL HOUSE DEMOLITION" or "ATTACK RULE: REMOVE ONE LEVEL; L0 HOMES ARE DEMOLISHED")
    local activeOpponent=false
    if definition.target=="demand" then
        local row=0
        for _,entry in ipairs(state.players) do
            if entry.alive and entry.id~=ui.id then
                if entry.id==self.targetId then activeOpponent=true end
                local select=ui.button(self.opponents,entry.name, row*157,0,150,30,entry.id==self.targetId and C.green or C.paper,function() self.targetId=entry.id;self.error=nil;self:render(ui.data()) end)
                select.TextSize=11;row=row+1
            end
        end
    end
    local property=self.tile and state.properties[self.tile]
    local canPlay=myTurn and not state.actionUsed and not self.pending and (me.cards[self.kind] or 0)>0 and property~=nil
    local message="Select a property to see the effect."
    if property then
        if self.kind=="collect" then
            local amount=math.min(config.demandCap,ui.rent(state,self.tile)*config.demandMultiplier)
            message="Demand $"..amount.." now using "..config.tiles[self.tile].name.."."
            canPlay=canPlay and activeOpponent
        elseif self.kind=="demolish" then
            message=property.shield and "A shield will block this attack; both cards are used." or (settings.attackMode=="destroy" or property.level==0) and "Demolish this house. The lot returns to the city." or ("Remove one level: L"..property.level.." → L"..(property.level-1))
        elseif self.kind=="boost" then
            message="Rent +50% for the next two payments.";canPlay=canPlay and (property.boost or 0)==0
        elseif self.kind=="shield" then message="Block the next demolition attempt.";canPlay=canPlay and not property.shield
        elseif self.kind=="repair" then message="Free upgrade: L"..property.level.." → L"..math.min(config.maxLevel,property.level+1);canPlay=canPlay and property.level<config.maxLevel end
    end
    self.effect.Text=message
    ui.available(self.play,canPlay==true,C.green)
    self.play.Text=self.pending and "Playing card…" or (canPlay and "Play "..definition.name or (not myTurn and "Wait for your turn" or (state.actionUsed and "Card already used this turn" or "Choose valid targets")))
    self.actionStatus.Text=self.error or ((me.cards[self.kind] or 0)==0 and "You have no copies. Earn cards at City Gate, City News, the park or challenges." or "")
end
return Menus
