local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local shared = ReplicatedStorage:WaitForChild("Citymoney")
local Config = require(shared:WaitForChild("Config"))
local remotes = shared:WaitForChild("Remotes")
local action = remotes:WaitForChild("Action")
local snapshot = remotes:WaitForChild("Snapshot")
local feedback = remotes:WaitForChild("Feedback")

local C = {
    ink = Color3.fromHex("17383E"), panel = Color3.fromHex("15333A"), cream = Color3.fromHex("FFF1D7"),
    muted = Color3.fromHex("ABC3C1"), gold = Color3.fromHex("F6C66F"), green = Color3.fromHex("83DBBD"),
    dark = Color3.fromHex("102A30"), line = Color3.fromHex("37565A"), red = Color3.fromHex("FF9E9E"),
}
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "Citymoney", false, false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name, root.Size, root.Position, root.AnchorPoint = "HUD", UDim2.fromOffset(1120, 740), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
root.BackgroundTransparency, root.Parent = 1, gui
local scale = Instance.new("UIScale")
scale.Parent = root

local function corner(object, radius)
    local value = Instance.new("UICorner")
    value.CornerRadius, value.Parent = UDim.new(0, radius or 14), object
end
local function panel(parent, x, y, width, height, tint)
    local frame = Instance.new("Frame")
    frame.Position, frame.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
    frame.BackgroundColor3, frame.BorderSizePixel = tint or C.panel, 0
    frame.Parent = parent
    corner(frame)
    local stroke = Instance.new("UIStroke")
    stroke.Color, stroke.Transparency, stroke.Parent = C.line, 0.35, frame
    return frame
end
local function label(parent, text, x, y, width, height, size, tint, bold)
    local object = Instance.new("TextLabel")
    object.Position, object.Size, object.BackgroundTransparency = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height), 1
    object.Text, object.TextSize, object.TextColor3 = text, size or 16, tint or C.cream
    object.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    object.TextXAlignment, object.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
    object.TextWrapped, object.Parent = true, parent
    return object
end
local function button(parent, text, x, y, width, height, tint, callback)
    local object = Instance.new("TextButton")
    object.Position, object.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
    object.BackgroundColor3, object.BorderSizePixel, object.AutoButtonColor = tint or C.gold, 0, true
    object.Font, object.TextSize, object.TextColor3, object.Text = Enum.Font.GothamBold, 15, C.ink, text
    object.Parent = parent
    corner(object, 10)
    if callback then object.Activated:Connect(callback) end
    return object
end
local data, selected, mainCommand, requestSale
local rolling = false
local clickLocked = false
local function send(command, index)
    if clickLocked or rolling then return end
    clickLocked = true
    action:FireServer(command, index)
    task.delay(0.22, function() clickLocked = false end)
end

local header = panel(root, 20, 16, 1080, 84)
label(header, "C I T Y M O N E Y", 24, 10, 360, 38, 28, C.cream, true)
label(header, "A LITTLE CITY. A BIG OPPORTUNITY.", 25, 49, 420, 20, 11, C.muted, true)
local roundLabel = label(header, "THE CITY IS OPEN", 440, 16, 250, 25, 14, C.gold, true)
local timerLabel = label(header, "Waiting for a match", 440, 43, 250, 22, 12, C.muted)
local wealthLabel = label(header, "$0 NET WORTH", 710, 16, 190, 25, 15, C.green, true)
local portfolioLabel = label(header, "YOUR CITY STARTS HERE", 710, 44, 190, 20, 10, C.muted, true)
local helpButton = button(header, "How to play", 910, 23, 146, 38, C.cream)

local tablePanel = panel(root, 20, 118, 224, 358)
label(tablePanel, "AT THE TABLE", 18, 14, 190, 24, 12, C.muted, true)
local seats = Instance.new("Frame")
seats.Position, seats.Size, seats.BackgroundTransparency, seats.Parent = UDim2.fromOffset(12, 48), UDim2.fromOffset(200, 300), 1, tablePanel

local newsPanel = panel(root, 20, 490, 224, 228)
label(newsPanel, "CITY BULLETIN", 18, 12, 188, 24, 12, C.muted, true)
local newsText = label(newsPanel, "Welcome! The host can start a match.", 18, 45, 188, 168, 13, C.cream)
newsText.TextYAlignment = Enum.TextYAlignment.Top

local detail = panel(root, 856, 118, 244, 294)
local districtStrip = panel(detail, 16, 16, 212, 6, C.gold)
local districtName = label(detail, "CITY EXPLORER", 18, 34, 208, 20, 11, C.muted, true)
local tileName = label(detail, "Your next big move", 18, 60, 208, 60, 23, C.cream, true)
local tileInfo = label(detail, "Roll the dice to find a place in the city.", 18, 124, 208, 87, 14, C.muted)
tileInfo.TextYAlignment = Enum.TextYAlignment.Top
local upgradeButton = button(detail, "Build", 16, 226, 102, 44, C.green, function() if selected then send("Upgrade", selected) end end)
local sellButton = button(detail, "Sell", 126, 226, 102, 44, C.cream, function() if selected and requestSale then requestSale(selected) end end)
upgradeButton.Visible, sellButton.Visible = false, false

local deedsPanel = panel(root, 856, 426, 244, 292)
label(deedsPanel, "YOUR CITY", 18, 12, 160, 25, 12, C.muted, true)
local deedsCount = label(deedsPanel, "0 deeds", 160, 12, 66, 25, 11, C.gold)
local deeds = Instance.new("ScrollingFrame")
deeds.Position, deeds.Size = UDim2.fromOffset(12, 47), UDim2.fromOffset(220, 230)
deeds.BackgroundTransparency, deeds.BorderSizePixel, deeds.ScrollBarThickness = 1, 0, 3
deeds.ScrollBarImageColor3, deeds.CanvasSize, deeds.Parent = C.gold, UDim2.fromOffset(0, 0), deedsPanel
local noDeeds = label(deedsPanel, "Buy your first property.\nOwn a matching pair to build!", 22, 100, 200, 90, 14, C.muted)

local statusPill = panel(root, 300, 118, 520, 48)
local statusText = label(statusPill, "WELCOME TO YOUR NEXT EMPIRE", 18, 5, 484, 38, 14, C.cream, true)
statusText.TextXAlignment = Enum.TextXAlignment.Center

local control = panel(root, 268, 584, 564, 134)
local turnTitle = label(control, "Welcome to Citymoney", 20, 14, 350, 28, 21, C.cream, true)
local turnSubtitle = label(control, "Play with friends, or start solo against City Bot.", 20, 45, 516, 22, 13, C.muted)
local mainButton = button(control, "Connecting…", 20, 78, 348, 40, C.gold, function() if mainCommand then send(mainCommand) end end)
local skipButton = button(control, "Pass", 380, 78, 164, 40, C.cream, function() send("Skip") end)
skipButton.Visible = false
local diceA = label(control, "–", 426, 6, 50, 44, 32, C.gold, true)
local diceB = label(control, "–", 484, 6, 50, 44, 32, C.gold, true)
for _, die in ipairs({ diceA, diceB }) do
    die.BackgroundTransparency, die.BackgroundColor3, die.TextColor3 = 0, C.cream, C.ink
    die.Size, die.TextXAlignment = UDim2.fromOffset(44, 44), Enum.TextXAlignment.Center
    corner(die, 10)
end
local timerTrack = panel(control, 20, 126, 524, 3, C.line)
local timerFill = Instance.new("Frame")
timerFill.Size, timerFill.BorderSizePixel, timerFill.BackgroundColor3, timerFill.Parent = UDim2.fromScale(1, 1), 0, C.green, timerTrack
local viewButton = button(root, "Rotate view", 469, 524, 160, 36, C.cream)
local zoomOut = button(root, "−", 429, 524, 32, 36, C.cream)
local zoomIn = button(root, "+", 637, 524, 32, 36, C.cream)

local toast = panel(root, 300, 181, 520, 58, C.ink)
local toastText = label(toast, "", 16, 8, 488, 42, 15, C.gold, true)
toast.Visible = false
local toastVersion = 0
local function notify(message)
    toastVersion = toastVersion + 1
    local version = toastVersion
    toastText.Text, toast.Visible = message, true
    task.delay(4, function() if toastVersion == version then toast.Visible = false end end)
end

local help = panel(root, 270, 152, 580, 422)
help.ZIndex = 10
for _, item in ipairs(help:GetChildren()) do if item:IsA("GuiObject") then item.ZIndex = 11 end end
label(help, "Own a piece of the city.", 28, 22, 520, 42, 28, C.gold, true).ZIndex = 11
local rules = label(help,
    "1   Roll two dice and move around the city.\n\n2   Buy empty properties. Visitors pay you rent.\n\n3   Own both deeds in a district to double base rent.\n     Build up to 3 levels to increase rent further.\n\n4   Passing City Gate earns $200. City News can\n     help or hurt; detention costs your next move.\n\n5   Last player standing wins. After 120 turns,\n     the highest net worth wins (ties: first seat).",
    28, 82, 520, 260, 16, C.cream)
rules.ZIndex, rules.TextYAlignment = 11, Enum.TextYAlignment.Top
local closeHelp = button(help, "Let's build a city", 28, 358, 524, 42, C.gold, function() help.Visible = false end)
closeHelp.ZIndex = 11
help.Visible = false
helpButton.Activated:Connect(function() help.Visible = not help.Visible end)

local function overlay(width, height)
    local shade = Instance.new("Frame")
    shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency = UDim2.fromScale(1, 1), C.dark, 0.22
    shade.Active, shade.ZIndex, shade.Visible, shade.Parent = true, 20, false, root
    local card = panel(shade, (1120 - width) / 2, (740 - height) / 2, width, height)
    card.ZIndex = 21
    card.DescendantAdded:Connect(function(object) if object:IsA("GuiObject") then object.ZIndex = 22 end end)
    return shade, card
end
local saleModal, saleCard = overlay(480, 270)
label(saleCard, "Sell this property?", 28, 22, 424, 40, 25, C.cream, true)
local saleDescription = label(saleCard, "", 28, 80, 424, 100, 16, C.muted)
local saleIndex, saleTurn
button(saleCard, "Keep it", 28, 196, 200, 44, C.cream, function() saleModal.Visible = false end)
button(saleCard, "Confirm sale", 240, 196, 212, 44, C.gold, function()
    saleModal.Visible = false
    if data and data.game.status == "playing" and data.game.turnCount == saleTurn then send("Sell", saleIndex) end
end)
requestSale = function(index)
    if not data then return end
    local tile, property = Config.tiles[index], data.game.properties[index]
    saleIndex, saleTurn = index, data.game.turnCount
    saleDescription.Text = tile.name .. " returns to the city. You receive $" .. math.floor((tile.price + property.level * tile.upgrade) / 2)
        .. ".\n\nSelling a district partner removes your matching-pair bonus."
    saleModal.Visible = true
end

local resultModal, resultCard = overlay(560, 430)
local resultTitle = label(resultCard, "A new city champion", 28, 22, 504, 42, 26, C.gold, true)
local resultSubtitle = label(resultCard, "", 28, 69, 504, 28, 14, C.muted)
local resultRows = Instance.new("Frame")
resultRows.Position, resultRows.Size, resultRows.BackgroundTransparency = UDim2.fromOffset(28, 112), UDim2.fromOffset(504, 224), 1
resultRows.ZIndex, resultRows.Parent = 22, resultCard
local replayButton = button(resultCard, "Play again", 28, 357, 316, 44, C.gold, function() resultModal.Visible = false; send("Start") end)
button(resultCard, "View board", 356, 357, 176, 44, C.cream, function() resultModal.Visible = false end)

local welcomeModal, welcomeCard = overlay(560, 360)
label(welcomeCard, "Your city starts here.", 28, 22, 504, 44, 29, C.gold, true)
label(welcomeCard, "A quick guide for your first game", 28, 73, 504, 26, 15, C.muted)
label(welcomeCard, "01   Roll, then buy the property you land on.\n\n02   Collect a matching pair, then build for more rent.\n\n03   Click any board tile to inspect it. Watch your cash!", 28, 120, 504, 147, 17, C.cream)
button(welcomeCard, "Got it — let's play", 28, 288, 504, 44, C.gold, function() welcomeModal.Visible = false end)

local tileHighlight = Instance.new("Highlight")
tileHighlight.Name, tileHighlight.FillTransparency, tileHighlight.OutlineColor = "InspectedProperty", 0.88, C.gold
tileHighlight.FillColor, tileHighlight.DepthMode, tileHighlight.Parent = C.gold, Enum.HighlightDepthMode.AlwaysOnTop, workspace

local angle, distance, cameraAngle, cameraDistance = math.rad(44), 115, math.rad(44), 115
local camera = workspace.CurrentCamera
local function updateCamera(deltaTime)
    camera = workspace.CurrentCamera
    if not camera then return end
    camera.CameraType, camera.FieldOfView = Enum.CameraType.Scriptable, 45
    local smoothing = 1 - math.exp(-8 * math.min(deltaTime, 0.1))
    cameraAngle = cameraAngle + (angle - cameraAngle) * smoothing
    cameraDistance = cameraDistance + (distance - cameraDistance) * smoothing
    local position = Vector3.new(math.sin(cameraAngle) * cameraDistance, cameraDistance * 1.12, math.cos(cameraAngle) * cameraDistance)
    camera.CFrame = CFrame.lookAt(position, Vector3.new(0, 1, 0))
    local viewport = camera.ViewportSize
    scale.Scale = math.min(viewport.X / 1120, math.max(1, viewport.Y - 12) / 740)
end
viewButton.Activated:Connect(function() angle = angle + math.pi / 2 end)
zoomOut.Activated:Connect(function() distance = math.min(150, distance + 10) end)
zoomIn.Activated:Connect(function() distance = math.max(85, distance - 10) end)
UserInputService.InputChanged:Connect(function(input, processed)
    if not processed and input.UserInputType == Enum.UserInputType.MouseWheel then
        distance = math.clamp(distance - input.Position.Z * 5, 85, 150)
    end
end)

local function playerById(state, id)
    for _, entry in ipairs(state.players) do if entry.id == id then return entry end end
    return nil
end
local function ownsGroup(state, id, group)
    for index, tile in ipairs(Config.tiles) do
        if tile.group == group and state.properties[index].ownerId ~= id then return false end
    end
    return true
end
local function propertyRent(state, index)
    local tile, property = Config.tiles[index], state.properties[index]
    local amount = tile.rent * Config.rentMultipliers[property.level + 1]
    if property.ownerId and property.level == 0 and ownsGroup(state, property.ownerId, tile.group) then amount = amount * 2 end
    return amount
end
local function netWorth(state, resident)
    local amount = resident.cash
    for index, property in ipairs(state.properties) do
        if property.ownerId == resident.id then
            local tile = Config.tiles[index]
            amount = amount + tile.price + property.level * tile.upgrade
        end
    end
    return amount
end

local function enabled(object, available, tint)
    object.Active, object.AutoButtonColor = available, available
    object.BackgroundColor3, object.TextColor3 = available and tint or C.line, available and C.ink or C.muted
end

local render
render = function()
    if not data then return end
    local state = data.game
    local current = state.players[state.turn]
    local mine = playerById(state, player.UserId)
    local myTurn = state.status == "playing" and current and current.id == player.UserId and current.alive
    local isHost = data.hostId == player.UserId
    if saleModal.Visible and (state.status ~= "playing" or saleTurn ~= state.turnCount or not myTurn) then saleModal.Visible = false end
    local ownedCount, districtCount = 0, 0
    for _, property in ipairs(state.properties) do if property.ownerId == player.UserId then ownedCount = ownedCount + 1 end end
    for group in pairs(Config.groups) do if mine and ownsGroup(state, player.UserId, group) then districtCount = districtCount + 1 end end
    wealthLabel.Text = mine and ("$" .. netWorth(state, mine) .. " NET WORTH") or "BUILD YOUR FORTUNE"
    portfolioLabel.Text = ownedCount .. " DEEDS  ·  " .. districtCount .. " DISTRICTS"
    seats:ClearAllChildren()
    local entries = state.status == "lobby" and data.lobby or state.players
    for seat, entry in ipairs(entries) do
        local active = state.status == "playing" and current and current.id == entry.id
        local row = panel(seats, 0, (seat - 1) * 49, 200, 43, active and C.line or C.dark)
        local tint = Color3.fromHex(Config.playerColors[entry.colorIndex or seat] or "FFFFFF")
        panel(row, 8, 11, 5, 21, tint)
        local name = label(row, entry.name .. (entry.alive == false and " · OUT" or ""), 22, 4, 112, 18, 12, entry.alive == false and C.muted or C.cream, true)
        name.TextTruncate, name.TextWrapped = Enum.TextTruncate.AtEnd, false
        label(row, active and (entry.id == player.UserId and "YOUR MOVE" or "TAKING A TURN") or (entry.bot and "CITY BOT" or "CITY RESIDENT"), 22, 23, 112, 13, 8, active and C.gold or C.muted, true)
        label(row, entry.cash and ("$" .. entry.cash) or "Ready", 138, 8, 58, 26, 12, tint, true)
    end
    newsText.Text = #state.logs > 0 and table.concat(state.logs, "\n\n", 1, math.min(4, #state.logs)) or "Invite friends, or start solo to play against City Bot. No purchases or Robux required."
    roundLabel.Text = state.status == "playing" and ("TURN " .. state.turnCount .. " / " .. Config.maxTurns) or "THE CITY IS OPEN"
    diceA.Text, diceB.Text = state.dice[1] > 0 and tostring(state.dice[1]) or "–", state.dice[2] > 0 and tostring(state.dice[2]) or "–"
    skipButton.Visible = false
    mainButton.Active, mainButton.BackgroundColor3 = true, C.gold
    mainCommand = nil
    if state.status == "lobby" or state.status == "finished" then
        local finished = state.status == "finished"
        local winner = playerById(state, state.winnerId)
        turnTitle.Text = finished and (winner and (winner.name .. " wins!") or "Match complete") or "Welcome to Citymoney"
        turnSubtitle.Text = #data.lobby == 1 and "Start solo to play against City Bot." or (#data.lobby .. " residents ready. The host can start.")
        mainButton.Text = isHost and (finished and "Play again" or "Start the city") or "Waiting for host…"
        mainCommand = isHost and "Start" or nil
        statusText.Text = finished and "A NEW CITY STORY STARTS HERE" or "BUY. BUILD. MAKE YOUR FORTUNE."
    else
        statusText.Text = myTurn and "YOUR CITY. YOUR MOVE." or ((current and current.name or "A resident") .. " IS MAKING A MOVE")
        turnTitle.Text = myTurn and "It's your turn" or ((current and current.name or "A resident") .. "'s turn")
        if not mine then
            turnSubtitle.Text = "You're watching this match. You'll join the next one."
        elseif not mine.alive then
            turnSubtitle.Text = "You're out this round. Watch who wins the city!"
        else
            turnSubtitle.Text = state.notice or "Build your city."
        end
        if myTurn then
            if state.phase == "roll" then
                mainCommand, mainButton.Text = "Roll", mine.detained and "Serve detention" or "Roll the dice  [R]"
            elseif state.phase == "buy" then
                local tile = Config.tiles[state.pendingTile]
                mainCommand, mainButton.Text = "Buy", "Buy " .. tile.name .. " · $" .. tile.price
                skipButton.Visible = true
                if mine.cash < tile.price then
                    mainCommand, mainButton.Text = nil, "Need $" .. tile.price .. " · sell a deed or pass"
                end
            else
                mainCommand, mainButton.Text = "End", "End turn  [Space]"
            end
        elseif current and current.id == player.UserId and not current.alive and state.phase == "end" then
            mainCommand, mainButton.Text = "End", "End turn"
        else
            mainButton.Text = "Watching the city…"
        end
    end
    if rolling then mainCommand, mainButton.Text = nil, "Rolling…" end
    enabled(mainButton, mainCommand ~= nil, C.gold)

    local previousScroll = deeds.CanvasPosition
    deeds:ClearAllChildren()
    local count = 0
    for index, property in ipairs(state.properties) do
        if property.ownerId == player.UserId then
            local tile = Config.tiles[index]
            local matching = ownsGroup(state, player.UserId, tile.group)
            local row = button(deeds, tile.name .. (matching and "  ★ " or "  ·  ") .. "L" .. property.level, 2, count * 39, 208, 33, Color3.fromHex(Config.groups[tile.group].color), function()
                selected = index
                render()
            end)
            row.TextSize = 12
            count = count + 1
        end
    end
    deeds.CanvasSize, deedsCount.Text, noDeeds.Visible = UDim2.fromOffset(0, count * 39), count .. " deeds", count == 0
    deeds.CanvasPosition = Vector2.new(0, math.min(previousScroll.Y, math.max(0, count * 39 - 230)))
    if not selected and mine then selected = mine.position end
    local tile = selected and Config.tiles[selected]
    local board = workspace:FindFirstChild("CitymoneyBoard")
    tileHighlight.Adornee = board and selected and board:FindFirstChild("Tile" .. selected) or nil
    upgradeButton.Visible, sellButton.Visible = false, false
    if tile then
        local property = state.properties[selected]
        districtName.Text = tile.group and string.upper(Config.groups[tile.group].name) or "AROUND THE CITY"
        districtStrip.BackgroundColor3 = tile.group and Color3.fromHex(Config.groups[tile.group].color) or C.gold
        tileName.Text = tile.name
        if tile.kind == "property" then
            local owner = playerById(state, property.ownerId)
            tileInfo.Text = (owner and ("Owned by " .. owner.name) or ("Price  $" .. tile.price))
                .. "\nRent  $" .. propertyRent(state, selected) .. "  ·  Level " .. property.level .. "/3"
                .. "\nBuild cost  $" .. tile.upgrade
            local own = property.ownerId == player.UserId
            upgradeButton.Visible, sellButton.Visible = myTurn and own, myTurn and own
            if own then
                tileInfo.Text = tileInfo.Text .. "\nResale  $" .. math.floor((tile.price + property.level * tile.upgrade) / 2)
            end
            local pair = own and ownsGroup(state, player.UserId, tile.group)
            local canBuild = myTurn and own and pair and property.level < Config.maxLevel and mine.cash >= tile.upgrade
            upgradeButton.TextSize = 12
            upgradeButton.Text = property.level >= 3 and "Max level" or (not pair and "Need pair" or ("Build $" .. tile.upgrade))
            enabled(upgradeButton, canBuild == true, C.green)
        else
            local descriptions = { start = "Collect $200 whenever you pass City Gate.", visit = "Just visiting. Detained players miss their next move.",
                detention = "Go straight to detention. No City Gate bonus.", park = "Take a breath. Nothing to pay here.",
                event = "The city has news for you. A random event changes your fortune.", tax = "Pay $120 into the city budget." }
            tileInfo.Text = descriptions[tile.kind] or "Explore the city."
        end
    end
    replayButton.Visible = isHost
    if state.status == "finished" then
        local winner = playerById(state, state.winnerId)
        resultTitle.Text = winner and (winner.name .. " wins the city!") or "The match is over"
        resultSubtitle.Text = winner and ("$" .. netWorth(state, winner) .. " net worth · a city well built") or "Gather your friends for another round."
        resultRows:ClearAllChildren()
        local standings = table.clone(state.players)
        table.sort(standings, function(a, b)
            if a.alive ~= b.alive then return a.alive end
            local left, right = netWorth(state, a), netWorth(state, b)
            return left > right or (left == right and a.colorIndex < b.colorIndex)
        end)
        for rank, resident in ipairs(standings) do
            local row = label(resultRows, rank .. "   " .. resident.name .. "    $" .. netWorth(state, resident) .. (resident.alive and "" or "  · OUT"), 0, (rank - 1) * 34, 504, 30, 16,
                Color3.fromHex(Config.playerColors[resident.colorIndex]), rank == 1)
            row.ZIndex = 22
        end
    end
end

local diceAnimation = 0
local function animateDice(first, second)
    diceAnimation = diceAnimation + 1
    local version = diceAnimation
    rolling = true
    render()
    task.spawn(function()
        for frame = 1, 10 do
            if diceAnimation ~= version then return end
            diceA.Text, diceB.Text = tostring(math.random(1, 6)), tostring(math.random(1, 6))
            diceA.Rotation, diceB.Rotation = frame % 2 == 0 and 7 or -7, frame % 2 == 0 and -7 or 7
            task.wait(0.045 + frame * 0.003)
        end
        if diceAnimation ~= version then return end
        diceA.Text, diceB.Text, diceA.Rotation, diceB.Rotation = tostring(first), tostring(second), 0, 0
        rolling = false
        render()
    end)
end

local welcomeShown = false
snapshot.OnClientEvent:Connect(function(incoming)
    if data and incoming.revision < data.revision then return end
    local previous = data
    local before = data and playerById(data.game, player.UserId)
    local after = playerById(incoming.game, player.UserId)
    if after and (not before or before.position ~= after.position or incoming.game.turnCount < data.game.turnCount) then
        selected = after.position
    end
    data = incoming
    render()
    local state = data.game
    if not welcomeShown and state.status == "lobby" then
        welcomeShown, welcomeModal.Visible = true, true
    end
    if state.status ~= "lobby" then welcomeModal.Visible = false end
    if state.status ~= "finished" then resultModal.Visible = false end
    if before and after and before.cash ~= after.cash then
        local delta = after.cash - before.cash
        notify((delta > 0 and "+$" or "−$") .. math.abs(delta) .. "  ·  Cash $" .. after.cash)
    end
    local current = state.players[state.turn]
    if current and current.id == player.UserId and state.status == "playing" and state.phase == "roll"
        and (not previous or previous.game.turnCount ~= state.turnCount or previous.game.status ~= "playing") then
        notify(current.detained and "Your turn — serve detention, then end your turn." or "Your turn! Roll the dice to explore the city.")
    end
    if previous and previous.game.phase == "roll" and state.phase ~= "roll" and state.dice[1] > 0 and state.turnCount == previous.game.turnCount then
        animateDice(state.dice[1], state.dice[2])
    end
    if state.status == "finished" and (not previous or previous.game.status ~= "finished") then
        resultModal.Visible, help.Visible, saleModal.Visible = true, false, false
        for _ = 1, 30 do
            local confetti = Instance.new("Frame")
            confetti.Size, confetti.Position, confetti.Rotation = UDim2.fromOffset(7, 14), UDim2.fromOffset(math.random(0, 1120), -20), math.random(0, 180)
            confetti.BorderSizePixel, confetti.BackgroundColor3, confetti.ZIndex, confetti.Parent = 0, Color3.fromHex(Config.playerColors[math.random(1, 6)]), 19, root
            TweenService:Create(confetti, TweenInfo.new(2 + math.random(), Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Position = UDim2.fromOffset(math.random(0, 1120), 780), Rotation = math.random(-360, 360) }):Play()
            task.delay(3.2, function() confetti:Destroy() end)
        end
    end
end)
feedback.OnClientEvent:Connect(notify)
local function inspectAt(position)
    if help.Visible or welcomeModal.Visible or saleModal.Visible or resultModal.Visible then return end
    local board = workspace:FindFirstChild("CitymoneyBoard")
    local currentCamera = workspace.CurrentCamera
    if not board or not currentCamera then return end
    local ray = currentCamera:ScreenPointToRay(position.X, position.Y)
    local parameters = RaycastParams.new()
    parameters.FilterType, parameters.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { board }
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, parameters)
    local index = hit and hit.Instance:GetAttribute("TileIndex")
    if index and Config.tiles[index] then selected = index; render() end
end
UserInputService.TouchTapInWorld:Connect(function(position, processed) if not processed then inspectAt(position) end end)
UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.UserInputType == Enum.UserInputType.MouseButton1 then inspectAt(input.Position) end
    if processed or help.Visible or welcomeModal.Visible or saleModal.Visible or resultModal.Visible or not mainCommand then return end
    if (input.KeyCode == Enum.KeyCode.R and mainCommand == "Roll") or input.KeyCode == Enum.KeyCode.Space then send(mainCommand) end
end)
RunService.RenderStepped:Connect(function(deltaTime)
    updateCamera(deltaTime)
    if data and data.game.status == "playing" then
        local remaining = math.max(0, data.deadline - workspace:GetServerTimeNow())
        timerLabel.Text = math.ceil(remaining) .. "s left · auto-play on timeout"
        timerFill.Size = UDim2.fromScale(math.clamp(remaining / Config.turnSeconds, 0, 1), 1)
        timerFill.BackgroundColor3, timerLabel.TextColor3 = remaining <= 8 and C.red or C.green, remaining <= 8 and C.red or C.muted
    else
        timerLabel.Text = "1–6 players · cash stays in this match"
        timerFill.Size, timerLabel.TextColor3 = UDim2.fromScale(0, 1), C.muted
    end
end)
-- The listener is attached before requesting the first snapshot (including late joins).
action:FireServer("Sync")
