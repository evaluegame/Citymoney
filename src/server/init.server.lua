local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Citymoney")
local Config = require(shared.Config)
local Engine = require(shared.Engine)
local World = require(script.World)
local random = Random.new()
local engine = Engine.new(Config, function(low, high) return random:NextInteger(low, high) end)
local world = World.new(Config)

local remotes = Instance.new("Folder")
remotes.Name, remotes.Parent = "Remotes", shared
local action = Instance.new("RemoteEvent")
action.Name, action.Parent = "Action", remotes
local snapshot = Instance.new("RemoteEvent")
snapshot.Name, snapshot.Parent = "Snapshot", remotes
local feedback = Instance.new("RemoteEvent")
feedback.Name, feedback.Parent = "Feedback", remotes

local joined, lastRequest = {}, {}
local deadline = 0
local revision = 0
local botReadyAt = 0
local function roster()
    local result = {}
    for _, player in ipairs(joined) do
        if player.Parent == Players then table.insert(result, { id = player.UserId, name = player.DisplayName }) end
    end
    return result
end

local function payload()
    local lobby = roster()
    return { game = engine.state, lobby = lobby, hostId = lobby[1] and lobby[1].id or false,
        deadline = deadline, serverTime = workspace:GetServerTimeNow(), revision = revision, visitors = world:visitorList() }
end

local function publish(resetTimer)
    revision = revision + 1
    if resetTimer then deadline = workspace:GetServerTimeNow() + Config.turnSeconds end
    if resetTimer or botReadyAt == 0 then botReadyAt = workspace:GetServerTimeNow() + 2.1 end
    world:sync(engine.state)
    snapshot:FireAllClients(payload())
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

local function addPlayer(player)
    if table.find(joined, player) then return end
    table.insert(joined, player)
    player.CharacterAdded:Connect(function(character) task.spawn(function() world:prepareCharacter(player, character) end) end)
    if player.Character then task.spawn(function() world:prepareCharacter(player, player.Character) end) end
    publish(false)
end
Players.PlayerAdded:Connect(addPlayer)
for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end

Players.PlayerRemoving:Connect(function(player)
    local index = table.find(joined, player)
    if index then table.remove(joined, index) end
    lastRequest[player] = nil
    engine:remove(player.UserId)
    if #roster() == 0 then
        engine = Engine.new(Config, function(low, high) return random:NextInteger(low, high) end)
    end
    publish(true)
end)

action.OnServerEvent:Connect(function(player, command, index, level, expectedTurn)
    if type(command) ~= "string" or #command > 16 then return end
    local now = os.clock()
    if lastRequest[player] and now - lastRequest[player] < 0.18 then return end
    lastRequest[player] = now
    if command == "Sync" then snapshot:FireClient(player, payload()); return end
    if command == "Return" then
        if world.visiting[player.UserId] then world:endVisit(player.UserId); publish(false) end
        return
    end
    if command == "Start" then
        local lobby = roster()
        if not lobby[1] or lobby[1].id ~= player.UserId then feedback:FireClient(player, "Only the host can start a match."); return end
        if #lobby > Config.maxPlayers then feedback:FireClient(player, "Set your server capacity to 6 players or fewer."); return end
        if #lobby == 1 then table.insert(lobby, { id = Config.botId, name = "City Bot", bot = true }) end
        local ok, message = engine:start(lobby)
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
                local phase = engine.state.phase
                if phase == "roll" then
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

print("[Citymoney] Board ready. Open the client lobby to start a match.")
