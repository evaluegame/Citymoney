-- Cross-server party queues. Studio uses a local adapter; live games use
-- MemoryStore claims and reserved servers, never client-supplied match rosters.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Teleport=game:GetService("TeleportService")
local MemoryStore=game:GetService("MemoryStoreService")
local Http=game:GetService("HttpService")
local Queue=require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").QueuePlanner)
local Protocol=require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").MatchProtocol)
local Matchmaker={}
Matchmaker.__index=Matchmaker
function Matchmaker.new(config,callbacks)
    local self=setmetatable({config=config,callbacks=callbacks,groups={},byPlayer={},errors={},ticket=nil,arrivalDeadline=nil,matchStarted=false},Matchmaker)
    self.localMode=RunService:IsStudio() or game.PlaceId==0
    self.reserved=not self.localMode and game.PrivateServerId~="" and game.PrivateServerOwnerId==0
    if not self.localMode then
        self.maps={ [2]=MemoryStore:GetSortedMap("CitymoneyQueue2_v1"),[4]=MemoryStore:GetSortedMap("CitymoneyQueue4_v1") }
        self.tickets=MemoryStore:GetSortedMap("CitymoneyMatches_v1")
        Teleport.TeleportInitFailed:Connect(function(player)
            local group=self.groups[self.byPlayer[player.UserId]]
            if group then
                group.teleporting=false;group.retryAt=os.clock()+3
                group.failed=(group.attempts or 0)>=3
                group.status=group.failed and "Teleport failed. Cancel and queue again." or "Roblox could not connect yet. Retrying the reserved match."
                callbacks.changed()
            end
        end)
    end
    return self
end
function Matchmaker:isQueued(id) return self.byPlayer[id]~=nil end
function Matchmaker:status(id)
    local group=self.groups[self.byPlayer[id]]
    if group then return {mode="lobby",queued=true,seats=group.seats,count=#group.users,status=group.status or "Searching for a match…",connecting=group.teleporting==true} end
    if self.reserved then return {mode="match",queued=false,status=self.matchStarted and "Online match" or "Waiting for the matched players to arrive…",seats=self.ticket and self.ticket.seats or 0} end
    return {mode="lobby",queued=false,status=self.errors[id] or (self.localMode and "Studio local matchmaking" or "Online matchmaking ready"),studio=self.localMode}
end
function Matchmaker:clear(group)
    for _,user in ipairs(group.users) do if self.byPlayer[user.id]==group.id then self.byPlayer[user.id]=nil end end
    self.groups[group.id]=nil
end
function Matchmaker:enqueue(id,party)
    if self.reserved then return false,"Return to the public lobby before joining a new queue." end
    if party:hostId()~=id then return false,"Your party leader joins the queue for everyone." end
    if #party.members>party.seats then return false,"Choose 4 players, or leave the larger party first." end
    local users={}
    for _,member in ipairs(party.members) do
        if not Players:GetPlayerByUserId(member.id) then return false,"A party member has left this server." end
        if self.callbacks.canQueue and not self.callbacks.canQueue(member.id) then return false,member.name.." must finish the current match first." end
        if not member.ready then return false,member.name.." must be ready before your party queues." end
        if self.byPlayer[member.id] then return false,"Someone in your party is already queued." end
        table.insert(users,{id=member.id,name=member.name,colorIndex=member.colorIndex})
    end
    for _,member in ipairs(party.members) do self.errors[member.id]=nil end
    local group={id=Http:GenerateGUID(false),users=users,seats=party.seats,job=game.JobId,updated=os.time(),joined=os.time(),status="Searching for a "..party.seats.."-player match…"}
    self.groups[group.id]=group
    for _,user in ipairs(users) do self.byPlayer[user.id]=group.id end
    if not self.localMode then
        local ok=pcall(function() self.maps[group.seats]:SetAsync(group.id,group,90,group.joined) end)
        if not ok then self:clear(group);return false,"Roblox matchmaking is temporarily unavailable. Please try again." end
        if group.cancelled then pcall(function() self.maps[group.seats]:RemoveAsync(group.id) end);return false,"Queue entry was cancelled." end
    end
    self.callbacks.changed()
    return true
end
function Matchmaker:cancel(id,force)
    local group=self.groups[self.byPlayer[id]]
    if not group then return true end
    if group.teleporting and force then return true end -- Normal departure into the reserved match.
    if not self.localMode then
        local ok,record=pcall(function() return self.maps[group.seats]:GetAsync(group.id) end)
        if not ok and not force then return false,"Could not reach the queue. Try cancel again." end
        if record and (record.matchId or ((record.claimUntil or 0)>os.time())) and not force and not group.failed then
            return false,"Your match is connecting. Please wait for the teleport."
        end
        pcall(function()
            self.maps[group.seats]:UpdateAsync(group.id,function(current,sort)
                if current then current.cancelled=true;return current,sort end
                return nil
            end,10)
        end)
    end
    group.cancelled=true;self:clear(group);self.callbacks.changed();return true
end
function Matchmaker:remove(id)
    local group=self.groups[self.byPlayer[id]]
    if not group then return end
    if group.teleporting then
        self.byPlayer[id]=nil
        local present=false
        for _,user in ipairs(group.users) do if user.id~=id and Players:GetPlayerByUserId(user.id) then present=true end end
        if not present then
            self.groups[group.id]=nil
            if not self.localMode then pcall(function() self.maps[group.seats]:RemoveAsync(group.id) end) end
        end
    else self:cancel(id,true) end
end
function Matchmaker:matchLive(seats)
    local map=self.maps[seats]
    local entries=map:GetRangeAsync(Enum.SortDirection.Ascending,50)
    local selected=Queue.select(entries,seats,os.time())
    if selected then
        Protocol.create(self.config,selected,map,self.tickets,{
            now=os.time,guid=function() return Http:GenerateGUID(false) end,
            reserve=function() return Teleport:ReserveServerAsync(game.PlaceId) end,
        })
    end
end
function Matchmaker:teleportGroup(group,ticket)
    if group.teleporting or group.failed or (group.retryAt and os.clock()<group.retryAt) then return end
    local members={}
    for _,user in ipairs(group.users) do
        local player=Players:GetPlayerByUserId(user.id)
        if player then table.insert(members,player) end
    end
    if #members==0 then self:clear(group);return end
    group.teleporting=true;group.attempts=(group.attempts or 0)+1
    group.status="Match found! Connecting "..#members.." player(s)…"
    self.callbacks.changed()
    local options=Instance.new("TeleportOptions")
    options.ReservedServerAccessCode=ticket.code
    options:SetTeleportData({citymoneyMatch=ticket.id})
    local ok=pcall(function() Teleport:TeleportAsync(game.PlaceId,members,options) end)
    if not ok then
        group.teleporting=false;group.retryAt=os.clock()+3;group.failed=group.attempts>=3
        group.status=group.failed and "Could not connect. Cancel the queue and try again." or "Connecting failed. Retrying your match…"
        self.callbacks.changed()
    end
end
function Matchmaker:tickLive()
    for id,group in pairs(self.groups) do
        if not group.cancelled and not group.teleporting then
            local record=self.maps[group.seats]:GetAsync(id)
            if record and record.matchId then
                local ticket=self.tickets:GetAsync(record.matchId)
                if ticket and ticket.status=="ready" then self:teleportGroup(group,ticket)
                else Protocol.recover(self.maps[group.seats],id,record,ticket,os.time()) end
            elseif record and not record.cancelled then
                if os.time()-(group.heartbeat or 0)>15 then
                    group.heartbeat=os.time()
                    self.maps[group.seats]:UpdateAsync(id,function(current,sort)
                        if current and not current.cancelled and not current.matchId then current.updated=os.time();return current,sort end
                        return nil
                    end,90)
                end
            else
                group.status="Queue entry expired. Please queue again."
                self:clear(group);self.callbacks.changed()
            end
        end
    end
    self:matchLive(2);self:matchLive(4)
end
function Matchmaker:tickLocal()
    if not self.callbacks.canStart() then return end
    local entries={}
    for id,group in pairs(self.groups) do group.updated=os.time();table.insert(entries,{key=id,value=group}) end
    table.sort(entries,function(a,b) return a.value.joined<b.value.joined or (a.value.joined==b.value.joined and a.key<b.key) end)
    for _,seats in ipairs({2,4}) do
        local selected=Queue.select(entries,seats,os.time())
        if selected then
            local roster=Queue.roster(selected,#self.config.playerColors)
            local ok=self.callbacks.start(roster,{attackMode="destroy"})
            if ok then for _,entry in ipairs(selected) do self:clear(entry.value) end;self.callbacks.changed() end
            return
        end
    end
end
function Matchmaker:backToLobby(player)
    if self.localMode then return false,"This is a Studio local test. Stop/restart Play to return to the test lobby." end
    local options=Instance.new("TeleportOptions")
    options:SetTeleportData({citymoneyReturn=true})
    local ok=pcall(function() Teleport:TeleportAsync(game.PlaceId,{player},options) end)
    return ok,if ok then nil else "Could not return to the lobby. Please try again."
end
function Matchmaker:playerAdded(player)
    local ok,join=pcall(function() return player:GetJoinData() end)
    if not ok then join={} end
    local transfer=type(join.TeleportData)=="table" and join.TeleportData or {}
    if self.reserved then
        local id=transfer.citymoneyMatch
        if type(id)~="string" then self:backToLobby(player);return end
        local success,ticket=pcall(function() return self.tickets:GetAsync(id) end)
        local admitted=false
        if success and ticket and ticket.privateId==game.PrivateServerId and ticket.status=="ready" then
            for _,user in ipairs(ticket.users) do if user.id==player.UserId then admitted=true end end
        end
        if not admitted then self:backToLobby(player);return end
        self.ticket=ticket;self.arrivalDeadline=self.arrivalDeadline or os.clock()+60
        self.callbacks.changed()
        return
    end
    local invite
    if type(join.LaunchData)=="string" and #join.LaunchData<2000 then
        pcall(function() invite=Http:JSONDecode(join.LaunchData) end)
    end
    if type(invite)=="table" and type(invite.citymoneyJob)=="string" and type(invite.leaderId)=="number" then
        if invite.citymoneyJob~=game.JobId and not self.localMode then
            local options=Instance.new("TeleportOptions");options.ServerInstanceId=invite.citymoneyJob
            options:SetTeleportData({citymoneyPartyLeader=invite.leaderId})
            local moved=pcall(function() Teleport:TeleportAsync(game.PlaceId,{player},options) end)
            if moved then return end
        else transfer.citymoneyPartyLeader=invite.leaderId end
    end
    if type(transfer.citymoneyPartyLeader)=="number" then
        local joined,message
        for _=1,6 do
            joined,message=self.callbacks.joinParty(player.UserId,transfer.citymoneyPartyLeader)
            if joined then break end
            task.wait(0.5)
        end
        if not joined then self.errors[player.UserId]=message or "Your friend is no longer available in this lobby.";self.callbacks.changed() end
    end
end
function Matchmaker:tickReserved()
    if self.matchStarted or not self.ticket then return end
    local complete=true
    for _,user in ipairs(self.ticket.users) do if not Players:GetPlayerByUserId(user.id) then complete=false end end
    if complete then
        local ok=self.callbacks.start(self.ticket.users,{attackMode="destroy"})
        if ok then self.matchStarted=true;self.callbacks.changed() end
    elseif self.arrivalDeadline and os.clock()>self.arrivalDeadline then
        self.arrivalDeadline=nil
        for _,player in ipairs(Players:GetPlayers()) do self:backToLobby(player) end
    end
end
function Matchmaker:start()
    task.spawn(function()
        while true do
            task.wait(2)
            local ok=pcall(function()
                if self.reserved then self:tickReserved()
                elseif self.localMode then self:tickLocal()
                else self:tickLive() end
            end)
            if not ok then
                -- Do not print reserved access codes or raw backend errors.
                for _,group in pairs(self.groups) do group.status="Matchmaking service is retrying. Your place in the queue is kept." end
                self.callbacks.changed()
            end
        end
    end)
    game:BindToClose(function()
        for _,group in pairs(self.groups) do
            if not group.teleporting then
                group.cancelled=true
                if not self.localMode then task.spawn(function() pcall(function() self.maps[group.seats]:RemoveAsync(group.id) end) end) end
            end
        end
    end)
end
return Matchmaker
