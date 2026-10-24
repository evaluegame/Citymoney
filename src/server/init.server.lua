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
        deadline = deadline, serverTime = workspace:GetServerTimeNow(), revision = revision }
end

local function publish(resetTimer)
    revision = revision + 1
    if resetTimer then deadline = workspace:GetServerTimeNow() + Config.turnSeconds end
    botReadyAt = workspace:GetServerTimeNow() + 2.1
    world:sync(engine.state)
    snapshot:FireAllClients(payload())
end

local function perform(id, command, index)
    local previousTurn = engine.state.turnCount
    local previousPhase = engine.state.phase
    local ok, message = engine:act(id, command, index)
    if ok then
        local changedTurn = previousTurn ~= engine.state.turnCount
        publish(changedTurn or previousPhase ~= engine.state.phase)
    end
    return ok, message
end

local function hideAvatar(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    if humanoid then
        humanoid.WalkSpeed, humanoid.JumpPower, humanoid.AutoRotate = 0, 0, false
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if root then root.Anchored = true end
    local function hide(object)
        if object:IsA("BasePart") then object.Transparency, object.CanCollide = 1, false end
        if object:IsA("Decal") then object.Transparency = 1 end
    end
    for _, object in ipairs(character:GetDescendants()) do hide(object) end
    character.DescendantAdded:Connect(hide)
end

local function addPlayer(player)
    if table.find(joined, player) then return end
    table.insert(joined, player)
    player.CharacterAdded:Connect(hideAvatar)
    if player.Character then task.spawn(hideAvatar, player.Character) end
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

action.OnServerEvent:Connect(function(player, command, index)
    if type(command) ~= "string" or #command > 16 then return end
    local now = os.clock()
    if lastRequest[player] and now - lastRequest[player] < 0.18 then return end
    lastRequest[player] = now
    if command == "Sync" then snapshot:FireClient(player, payload()); return end
    if command == "Start" then
        local lobby = roster()
        if not lobby[1] or lobby[1].id ~= player.UserId then feedback:FireClient(player, "Only the host can start a match."); return end
        if #lobby > Config.maxPlayers then feedback:FireClient(player, "Set your server capacity to 6 players or fewer."); return end
        if #lobby == 1 then table.insert(lobby, { id = Config.botId, name = "City Bot", bot = true }) end
        local ok, message = engine:start(lobby)
        if ok then publish(true) else feedback:FireClient(player, message) end
        return
    end
    if index ~= nil and (type(index) ~= "number" or index ~= index or index % 1 ~= 0 or index < 1 or index > #Config.tiles) then return end
    local ok, message = perform(player.UserId, command, index)
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
                    perform(current.id, buy and "Buy" or "Skip")
                else
                    if current.bot then
                        for index, property in ipairs(engine.state.properties) do
                            local tile = Config.tiles[index]
                            if property.ownerId == current.id and property.level < Config.maxLevel
                                and engine:ownsGroup(current.id, tile.group) and current.cash >= tile.upgrade + 250 then
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
