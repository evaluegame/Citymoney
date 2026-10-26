local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Citymoney")
local Config = require(shared.Config)
local Engine = require(shared.Engine)
local Parties = require(shared.Parties)
local Tactics = require(shared.Tactics)
local Matchmaker = require(script.Matchmaker)
local World = require(script.World)
local random = Random.new()
local engine = Engine.new(Config, function(low, high) return random:NextInteger(low, high) end)
local world = World.new(Config)
local parties = Parties.new(Config)
local matcher

local remotes = Instance.new("Folder")
remotes.Name, remotes.Parent = "Remotes", shared
local action = Instance.new("RemoteEvent")
action.Name, action.Parent = "Action", remotes
local snapshot = Instance.new("RemoteEvent")
snapshot.Name, snapshot.Parent = "Snapshot", remotes
local feedback = Instance.new("RemoteEvent")
feedback.Name, feedback.Parent = "Feedback", remotes

local lastRequest = {}
local deadline = 0
local revision = 0
local botReadyAt = 0
local function payload(id)
    local party=parties:get(id)
    local lobby=party and party.members or {}
    local settings=party and party:snapshot() or {seats=2,fillBots=true,attackMode="destroy",hostId=false,members={}}
    return { game = engine:view(id), lobby = lobby, lobbyConfig=settings,hostId = party and party:hostId() or false,
        matchmaking=matcher and matcher:status(id) or nil,
        deadline = deadline, serverTime = workspace:GetServerTimeNow(), revision = revision, visitors = world:visitorList() }
end

local function publish(resetTimer)
    revision = revision + 1
    if resetTimer then deadline = workspace:GetServerTimeNow() + Config.turnSeconds end
    if resetTimer or botReadyAt == 0 then botReadyAt = workspace:GetServerTimeNow() + 2.1 end
    world:sync(engine.state)
    for _,recipient in ipairs(Players:GetPlayers()) do snapshot:FireClient(recipient,payload(recipient.UserId)) end
end

local function perform(id, command, index, level, expectedTurn)
    local previousTurn = engine.state.turnCount
    local previousPhase = engine.state.phase
    local ok, message = engine:act(id, command, index, level, expectedTurn)
    if ok then
        if command == "Roll" or command == "End" then world:endVisit(id) end
        local changedTurn = previousTurn ~= engine.state.turnCount
        publish(changedTurn or previousPhase ~= engine.state.phase)
    end
    return ok, message
end

matcher=Matchmaker.new(Config,{
    changed=function() publish(false) end,
    canStart=function() return engine.state.status~="playing" end,
    canQueue=function(id)
        local player=engine:player(id)
        return not (engine.state.status=="playing" and player and player.alive)
    end,
    start=function(roster,rules)
        local ok,message=engine:start(roster,rules)
        if ok then
            parties:combine(roster)
            for id in pairs(world.visiting) do world:endVisit(id) end
            publish(true)
        end
        return ok,message
    end,
    joinParty=function(id,leader)
        if matcher:isQueued(id) or matcher:isQueued(leader) then return false,"Your friend is already queued." end
        local ok,message=parties:join(id,leader)
        if ok then publish(false) end
        return ok,message
    end,
})

local function addPlayer(player)
    if parties:get(player.UserId) then return end
    parties:add(player.UserId,player.DisplayName)
    player.CharacterAdded:Connect(function(character) task.spawn(function() world:prepareCharacter(player, character) end) end)
    if player.Character then task.spawn(function() world:prepareCharacter(player, player.Character) end) end
    publish(false)
    task.spawn(function() matcher:playerAdded(player) end)
end
Players.PlayerAdded:Connect(addPlayer)
for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end

Players.PlayerRemoving:Connect(function(player)
    matcher:remove(player.UserId)
    parties:remove(player.UserId)
    lastRequest[player] = nil
    engine:remove(player.UserId)
    local remaining=0
    for _,other in ipairs(Players:GetPlayers()) do if other~=player then remaining=remaining+1 end end
    if remaining == 0 then
        engine = Engine.new(Config, function(low, high) return random:NextInteger(low, high) end)
    end
    publish(true)
end)

action.OnServerEvent:Connect(function(player, command, index, level, expectedTurn)
    if type(command) ~= "string" or #command > 16 then return end
    local now = os.clock()
    if lastRequest[player] and now - lastRequest[player] < 0.18 then return end
    lastRequest[player] = now
    if command == "Sync" then snapshot:FireClient(player, payload(player.UserId)); return end
    local party=parties:get(player.UserId)
    if not party then return end
    if command=="Queue" then
        local active=engine:player(player.UserId)
        if engine.state.status=="playing" and active and active.alive then feedback:FireClient(player,"Finish this match or leave it before queuing.");return end
        local ok,message=matcher:enqueue(player.UserId,party)
        if not ok then feedback:FireClient(player,message) end
        return
    elseif command=="QueueCancel" then
        local ok,message=matcher:cancel(player.UserId,false)
        if not ok then feedback:FireClient(player,message) end
        return
    elseif command=="BackLobby" then
        local ok,message=matcher:backToLobby(player)
        if not ok then feedback:FireClient(player,message) end
        return
    elseif command=="LeaveParty" then
        if matcher.reserved then
            local ok,message=matcher:backToLobby(player)
            if not ok then feedback:FireClient(player,message) end
            return
        end
        local ok,message=matcher:cancel(player.UserId,false)
        if ok then ok,message=parties:leave(player.UserId) end
        if ok then publish(false) else feedback:FireClient(player,message) end
        return
    elseif command=="JoinParty" then
        if type(index)~="number" or matcher:isQueued(player.UserId) or matcher:isQueued(index) then feedback:FireClient(player,"Choose an available party leader.");return end
        local ok,message=parties:join(player.UserId,index)
        if ok then publish(false) else feedback:FireClient(player,message) end
        return
    end
    if command=="Seats" or command=="Bots" or command=="AttackRule" or command=="Color" or command=="Ready" then
        local ok,message
        local active=engine:player(player.UserId)
        if matcher:isQueued(player.UserId) then ok,message=false,"Cancel matchmaking before changing party settings."
        elseif matcher.reserved then ok,message=false,"Return to the lobby to change the party."
        elseif command=="Ready" then ok,message=party:setReady(player.UserId,index)
        elseif engine.state.status=="playing" and active and active.alive then ok,message=false,"Change match settings and colors between games."
        elseif command=="Color" then ok,message=party:setColor(player.UserId,index)
        else
            local field=command=="Seats" and "seats" or (command=="Bots" and "bots" or "attack")
            ok,message=party:configure(player.UserId,field,index)
        end
        if ok then publish(false) else feedback:FireClient(player,message) end
        return
    end
    if command=="Card" then
        if type(index)~="table" then feedback:FireClient(player,"Choose a tactical card and its targets.");return end
        local ok,message=engine:playCard(player.UserId,index.kind,index.tile,index.targetId,index.turn)
        if ok then publish(false) else feedback:FireClient(player,message) end
        return
    end
    if command == "Return" then
        if world.visiting[player.UserId] then world:endVisit(player.UserId); publish(false) end
        return
    end
    if command == "Start" then
        if matcher.reserved then feedback:FireClient(player,"Return to the lobby to queue another online match.");return end
        if matcher:isQueued(player.UserId) then feedback:FireClient(player,"Cancel matchmaking before starting practice.");return end
        local lobby,message=party:buildRoster(player.UserId)
        if not lobby then feedback:FireClient(player,message);return end
        local ok
        ok, message = engine:start(lobby,{attackMode=party.attackMode})
        if ok then
            for id in pairs(world.visiting) do world:endVisit(id) end
            publish(true)
        else feedback:FireClient(player, message) end
        return
    end
    if index ~= nil and (type(index) ~= "number" or index ~= index or index % 1 ~= 0 or index < 1 or index > #Config.tiles) then return end
    if command=="Buy" or command=="Upgrade" then
        if level~=nil and (type(level)~="number" or level~=level or level%1~=0 or level<0 or level>Config.maxLevel) then
            feedback:FireClient(player,"Choose a valid home level."); return
        end
        if expectedTurn~=nil and expectedTurn~=engine.state.turnCount then
            feedback:FireClient(player,"That home selection expired. Open the options again."); return
        end
    end
    if command == "Visit" then
        local ok, message = engine:canVisit(player.UserId, index)
        if ok then ok, message = world:visit(player, index) end
        if ok then publish(false) else feedback:FireClient(player, message) end
        return
    end
    local ok, message = perform(player.UserId, command, index, level, expectedTurn)
    if not ok then feedback:FireClient(player, message) end
end)

-- A short server-owned clock prevents an AFK player from blocking the table.
task.spawn(function()
    while true do
        task.wait(0.5)
        if engine.state.status == "playing" then
            local current = engine:current()
            local now = workspace:GetServerTimeNow()
            if (current.bot and now >= botReadyAt) or now >= deadline then
                local handled=false
                if current.bot and current.alive then
                    if current.challenge.ready and not engine.state.challengeClaimed then
                        handled=perform(current.id,"Claim",nil,nil,engine.state.turnCount)
                    elseif not engine.state.actionUsed then
                        local move=Tactics.botMove(engine,current.id)
                        if move then
                            handled=engine:playCard(current.id,move.kind,move.tile,move.targetId,move.turn)
                            if handled then publish(false) end
                        end
                    end
                    if handled then botReadyAt=now+1.2 end
                end
                local phase = engine.state.phase
                if handled then
                    -- The next tick resumes the normal decision after its card/goal animation.
                elseif phase == "roll" then
                    perform(current.id, "Roll")
                elseif phase == "buy" then
                    local tile = Config.tiles[engine.state.pendingTile]
                    local buy = current.bot and current.cash >= tile.price + 180
                    local level=current.bot and current.cash>=tile.price+tile.upgrade+350 and 1 or 0
                    perform(current.id, buy and "Buy" or "Skip",nil,level)
                else
                    if current.bot then
                        for index, property in ipairs(engine.state.properties) do
                            local tile = Config.tiles[index]
                            if property.ownerId == current.id and property.level < Config.maxLevel
                                and current.cash >= tile.upgrade + 250 then
                                engine:act(current.id, "Upgrade", index)
                            end
                        end
                    end
                    perform(current.id, "End")
                end
            end
        end
    end
end)

matcher:start()

print("[Citymoney] Board ready. Open the client lobby to start a match.")
