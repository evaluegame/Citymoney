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
    self.lobby,self.lobbyCard=overlay(520,676)
    text(self.lobbyCard,"Play together",24,16,436,36,26,C.ink,true)
    text(self.lobbyCard,"Choose 2 or 4 players, then start playing.",24,58,472,28,16,C.muted)
    self.leaveParty=button(self.lobbyCard,"Leave party",334,18,108,36,C.paper,function() ui.send("LeaveParty") end)
    button(self.lobbyCard,"×",452,17,44,44,C.paper,function() self.lobby.Visible=false end)
    self.two=button(self.lobbyCard,"2 PLAYERS",24,101,230,56,C.green,function() ui.send("Seats",2) end)
    self.four=button(self.lobbyCard,"4 PLAYERS",266,101,230,56,C.paper,function() ui.send("Seats",4) end)
    self.practiceSettings,self.settingsCard=overlay(480,340)
    text(self.settingsCard,"Practice settings",24,20,386,36,25,C.ink,true)
    button(self.settingsCard,"×",412,17,44,44,C.paper,function() self.practiceSettings.Visible=false;self.lobby.Visible=true end)
    self.bots=button(self.settingsCard,"Fill empty seats with bots",24,83,432,58,C.paper,function()
        local data=ui.data();if data then ui.send("Bots",not data.lobbyConfig.fillBots) end
    end)
    text(self.settingsCard,"DEMOLITION RULE",24,157,432,20,13,C.muted,true)
    self.downgrade=button(self.settingsCard,"Remove one level",24,190,210,54,C.paper,function() ui.send("AttackRule","downgrade") end)
    self.destroy=button(self.settingsCard,"Destroy whole house",246,190,210,54,C.paper,function() ui.send("AttackRule","destroy") end)
    text(self.settingsCard,"Online matches always use full-house demolition.",24,264,432,48,15,C.muted)
    text(self.lobbyCard,"YOUR COLOR · pick one if you like",24,173,472,23,13,C.muted,true)
    text(self.lobbyCard,"YOUR PARTY",24,260,472,22,13,C.muted,true)
    self.members=Instance.new("ScrollingFrame")
    self.members.Position,self.members.Size=UDim2.fromOffset(24,290),UDim2.fromOffset(472,96)
    self.members.BackgroundTransparency,self.members.BorderSizePixel,self.members.ScrollBarThickness,self.members.Parent=1,0,3,self.lobbyCard
    self.colorButtons={}
    for index,hex in ipairs(config.playerColors) do
        local choose=button(self.lobbyCard,tostring(index),24+(index-1)*78,205,66,42,Color3.fromHex(hex),function() ui.send("Color",index) end)
        choose.TextColor3=C.ink;table.insert(self.colorButtons,choose)
    end
    self.ready=button(self.lobbyCard,"Ready",24,404,230,48,C.green,function() self:toggleReady() end)
    self.invite=button(self.lobbyCard,"INVITE FRIENDS",266,404,230,48,C.paper,function()
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
    self.lobbyStatus=text(self.lobbyCard,"",24,465,472,36,15,C.muted)
    self.queue=button(self.lobbyCard,"PLAY ONLINE",24,514,472,64,C.green,function()
        local data=ui.data()
        if data and data.matchmaking and data.matchmaking.mode=="match" then ui.send("BackLobby")
        elseif data and data.matchmaking and data.matchmaking.queued then ui.send("QueueCancel")
        else ui.send("Queue") end
    end)
    self.start=button(self.lobbyCard,"PRACTICE WITH BOTS",24,592,302,64,C.paper,function() ui.send("Start") end)
    self.settings=button(self.lobbyCard,"SETTINGS",338,592,158,64,C.paper,function() self.lobby.Visible=false;self.practiceSettings.Visible=true end)
    self.queue.TextSize=18;self.start.TextSize=16
    self.actions,self.actionCard=overlay(520,700)
    text(self.actionCard,"Cards & challenges",24,16,436,36,25,C.ink,true)
    button(self.actionCard,"×",468,18,28,28,C.paper,function() self.actions.Visible=false end)
    local challenge=frame(self.actionCard,24,66,472,101,C.mint)
    self.goalName=text(challenge,"Your challenge",12,7,310,24,15,C.ink,true)
    self.goalText=text(challenge,"",12,34,310,40,12,C.muted)
    self.goalProgress=text(challenge,"",12,78,310,15,10,C.green,true)
    self.claim=button(challenge,"Claim reward",338,12,122,44,C.green,function()
        local data=ui.data();if data then ui.send("Claim",nil,nil,data.game.turnCount) end
    end);self.claim.TextSize=14
    self.newGoal=button(challenge,"New goal $50",338,63,122,30,C.paper,function()
        local data=ui.data();if data then ui.send("NewGoal",nil,nil,data.game.turnCount) end
    end);self.newGoal.TextSize=10
    self.cardStatus=text(self.actionCard,"ONE TACTICAL CARD PER TURN",24,178,472,18,10,C.muted,true)
    self.cardButtons={}
    local short={demolish="Demolish",collect="Demand rent",boost="Rent boost",shield="Shield",repair="Renovate"}
    for index,kind in ipairs(config.cardTypes) do
        local select=button(self.actionCard,short[kind],24+((index-1)%3)*160,194+math.floor((index-1)/3)*52,152,44,C.paper,function()
            if not self.pending then self.kind=kind;self.tile=nil;self.targetId=nil;self.error=nil;self:render(ui.data()) end
        end)
        select.TextSize=14;self.cardButtons[kind]=select
    end
    self.description=text(self.actionCard,"",24,298,472,42,15,C.muted)
    text(self.actionCard,"CHOOSE THE PROPERTY",24,339,472,18,12,C.muted,true)
    self.properties=Instance.new("ScrollingFrame")
    self.properties.Position,self.properties.Size=UDim2.fromOffset(24,365),UDim2.fromOffset(472,112)
    self.properties.BackgroundTransparency,self.properties.BorderSizePixel,self.properties.ScrollBarThickness,self.properties.Parent=1,0,3,self.actionCard
    self.targetCaption=text(self.actionCard,"",24,483,472,18,10,C.muted,true)
    self.opponents=Instance.new("Frame")
    self.opponents.Position,self.opponents.Size,self.opponents.BackgroundTransparency,self.opponents.Parent=UDim2.fromOffset(24,507),UDim2.fromOffset(472,52),1,self.actionCard
    self.effect=text(self.actionCard,"",24,566,472,32,15,C.ink,true)
    self.play=button(self.actionCard,"Choose a property",24,606,332,64,C.green,function() self:playCard() end)
    self.play.TextSize=17
    button(self.actionCard,"Back",368,606,128,64,C.paper,function() self.actions.Visible=false end)
    self.actionStatus=text(self.actionCard,"",24,675,472,20,12,C.red)
    self.shortNames=short
    return self
end
function Menus:isOpen() return self.lobby.Visible or self.actions.Visible or self.practiceSettings.Visible end
function Menus:openLobby() self.lobby.Visible=true;self.actions.Visible=false;self.practiceSettings.Visible=false;self.error=nil;self:render(self.ui.data()) end
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
    local specs={{"TableView",4,100},{"Fit",108,60}}
    if layout.compact then specs={{"TableView",4,232},{"Fit",244,136}} end
    for _,spec in ipairs(specs) do
        local object=bar:FindFirstChild(spec[1])
        object.Position,object.Size=UDim2.fromOffset(spec[2],2),UDim2.fromOffset(spec[3],layout.compact and 64 or 30)
        object.TextSize=layout.compact and 18 or 14
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
        self.lobby.Visible=false;self.actions.Visible=false;self.practiceSettings.Visible=false;self.pending=nil
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
    self.bots.Text="Fill empty seats with bots: "..(settings.fillBots and "ON" or "OFF")
    ui.available(self.downgrade,editable,settings.attackMode=="downgrade" and C.green or C.paper)
    ui.available(self.destroy,editable,settings.attackMode=="destroy" and C.green or C.paper)
    self.members:ClearAllChildren()
    for index,entry in ipairs(data.lobby) do
        local name=ui.text(self.members,(entry.ready and "READY · " or "WAITING · ")..entry.name..(entry.id==data.hostId and " · host" or ""),8,(index-1)*32,450,30,16,C.ink,entry.id==ui.id)
        name.TextWrapped,name.TextTruncate=false,Enum.TextTruncate.AtEnd
    end
    self.members.CanvasSize=UDim2.fromOffset(0,#data.lobby*32)
    for index,button in ipairs(self.colorButtons) do
        local taken=false
        for _,entry in ipairs(data.lobby) do if entry.id~=ui.id and entry.colorIndex==index then taken=true end end
        button.Active=not active and not queue.queued and queue.mode~="match" and not taken
        button.BackgroundTransparency=taken and 0.6 or 0
        button.Text=mine and mine.colorIndex==index and "✓" or tostring(index)
    end
    self.ready.Text=mine and mine.ready and "READY · tap to unready" or "I'M READY TO PLAY"
    self.ready.Visible=#data.lobby>1 or not (mine and mine.ready)
    self.invite.Position,self.invite.Size=UDim2.fromOffset(self.ready.Visible and 266 or 24,404),UDim2.fromOffset(self.ready.Visible and 230 or 472,48)
    ui.available(self.ready,mine~=nil and not queue.queued and queue.mode~="match",mine and mine.ready and C.green or C.paper)
    local enough=readyCount>=settings.seats or settings.fillBots
    self.lobbyStatus.Text=self.error or ((queue.queued or queue.mode=="match") and queue.status or (readyCount<#data.lobby and "Waiting for your friends to tap Ready." or (#data.lobby==1 and "Play online, or try a quick practice game." or "Everyone is ready. The host can start!")))
    self.lobbyStatus.TextColor3=self.error and C.red or C.muted
    ui.available(self.start,editable and state.status~="playing" and mine~=nil and mine.ready and enough,C.paper)
    self.start.Text=settings.fillBots and "PRACTICE WITH BOTS" or "PRACTICE WITH PARTY"
    local partyReady=readyCount==#data.lobby and #data.lobby<=settings.seats
    ui.available(self.queue,queue.mode=="match" or (queue.queued and not queue.connecting) or (host and not active and mine~=nil and mine.ready and partyReady),C.green)
    self.queue.Text=queue.mode=="match" and "RETURN TO LOBBY" or (queue.queued and (queue.connecting and "CONNECTING..." or "CANCEL SEARCH") or ("PLAY ONLINE · "..settings.seats.." PLAYERS"))
    self.leaveParty.Visible=#data.lobby>1 or queue.mode=="match"
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
    local cardSpace=false
    for _,kind in ipairs(config.cardTypes) do if (me.cards[kind] or 0)<config.cardLimit then cardSpace=true end end
    self.goalProgress.Text=goal.progress.." / "..goal.target.." · reward $"..goal.reward..(cardSpace and " + card" or " · hand full")
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
        local select=ui.button(self.properties,config.tiles[index].name.." · "..(owner and owner.name or "").." · L"..property.level,2,(row-1)*70,466,64,self.tile==index and C.green or C.paper,function()
            if not self.pending then self.tile=index;self.error=nil;self:render(ui.data()) end
        end)
        select.TextSize=17
    end
    if #candidates==0 then ui.text(self.properties,definition.target=="rival" and "No opponent owns a house yet." or "Buy a property before using this card.",8,8,450,45,13,C.muted) end
    self.properties.CanvasSize=UDim2.fromOffset(0,#candidates*70)
    self.targetCaption.Text=definition.target=="demand" and "CHOOSE WHO MUST PAY" or (settings.attackMode=="destroy" and "ATTACK RULE: FULL HOUSE DEMOLITION" or "ATTACK RULE: REMOVE ONE LEVEL; L0 HOMES ARE DEMOLISHED")
    local activeOpponent=false
    if definition.target=="demand" then
        local row=0
        for _,entry in ipairs(state.players) do
            if entry.alive and entry.id~=ui.id then
                if entry.id==self.targetId then activeOpponent=true end
                local select=ui.button(self.opponents,entry.name, row*157,0,150,52,entry.id==self.targetId and C.green or C.paper,function() self.targetId=entry.id;self.error=nil;self:render(ui.data()) end)
                select.TextSize=15;row=row+1
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
