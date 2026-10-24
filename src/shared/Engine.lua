-- Pure Luau: no Roblox services. The server alone owns this state.
local Engine = {}
Engine.__index = Engine

function Engine.new(config, randomInteger)
    local self = setmetatable({}, Engine)
    self.config = config
    self.random = randomInteger or math.random
    self.state = { status = "lobby", players = {}, properties = {}, logs = {}, turn = 0,
        turnCount = 0, phase = "roll", pendingTile = false, dice = { 0, 0 }, winnerId = false }
    for i = 1, #config.tiles do
        self.state.properties[i] = { ownerId = false, level = 0 }
    end
    return self
end

function Engine:player(id)
    for _, player in ipairs(self.state.players) do
        if player.id == id then return player end
    end
    return nil
end

function Engine:current()
    return self.state.players[self.state.turn]
end

function Engine:log(message)
    table.insert(self.state.logs, 1, message)
    if #self.state.logs > 6 then table.remove(self.state.logs) end
    self.state.notice = message
end

function Engine:start(roster)
    if self.state.status == "playing" then return false, "A match is already running." end
    if #roster < 2 or #roster > self.config.maxPlayers then return false, "A match needs 2–6 players." end
    local seen = {}
    for _, entry in ipairs(roster) do
        if seen[entry.id] then return false, "Duplicate player." end
        seen[entry.id] = true
    end
    self.state.players = {}
    for index, entry in ipairs(roster) do
        table.insert(self.state.players, { id = entry.id, name = entry.name, bot = entry.bot == true,
            cash = self.config.startingCash, position = 1, alive = true, detained = false, colorIndex = index })
    end
    for _, property in ipairs(self.state.properties) do
        property.ownerId, property.level = false, 0
    end
    self.state.status, self.state.turn, self.state.turnCount = "playing", 1, 1
    self.state.phase, self.state.pendingTile, self.state.winnerId = "roll", false, false
    self.state.dice, self.state.logs = { 0, 0 }, {}
    self:log("Welcome to Citymoney! " .. self:current().name .. " goes first.")
    return true
end

function Engine:ownsGroup(id, group)
    for index, tile in ipairs(self.config.tiles) do
        if tile.group == group and self.state.properties[index].ownerId ~= id then return false end
    end
    return self.config.groups[group] ~= nil
end

function Engine:rent(index)
    local tile, property = self.config.tiles[index], self.state.properties[index]
    if tile.kind ~= "property" then return 0 end
    local amount = tile.rent * self.config.rentMultipliers[property.level + 1]
    if property.level == 0 and property.ownerId and self:ownsGroup(property.ownerId, tile.group) then
        amount = amount * 2
    end
    return amount
end

function Engine:wealth(player)
    local total = player.cash
    for index, property in ipairs(self.state.properties) do
        if property.ownerId == player.id then
            local tile = self.config.tiles[index]
            total = total + tile.price + property.level * tile.upgrade
        end
    end
    return total
end

function Engine:checkWinner()
    local survivors = {}
    for _, player in ipairs(self.state.players) do
        if player.alive then table.insert(survivors, player) end
    end
    if #survivors <= 1 or self.state.turnCount > self.config.maxTurns then
        local winner = survivors[1]
        for _, player in ipairs(survivors) do
            if not winner or self:wealth(player) > self:wealth(winner) then winner = player end
        end
        self.state.status, self.state.winnerId = "finished", winner and winner.id or false
        self.state.pendingTile = false
        self:log(winner and (winner.name .. " wins Citymoney with $" .. self:wealth(winner) .. " net worth!") or "The city is empty. Start a new match!")
        return true
    end
    return false
end

function Engine:liquidate(player, index)
    local property, tile = self.state.properties[index], self.config.tiles[index]
    local value = math.floor((tile.price + property.level * tile.upgrade) / 2)
    property.ownerId, property.level = false, 0
    player.cash = player.cash + value
    self:log(player.name .. " sold " .. tile.name .. " for $" .. value .. ".")
end

function Engine:pay(player, amount, recipient)
    -- Cash shortfalls sell deeds back to the city, in board order, at half cost.
    for index, property in ipairs(self.state.properties) do
        if player.cash >= amount then break end
        if property.ownerId == player.id then self:liquidate(player, index) end
    end
    local paid = math.min(player.cash, amount)
    player.cash = player.cash - paid
    if recipient then recipient.cash = recipient.cash + paid end
    if paid < amount then
        player.alive = false
        self:log(player.name .. " went bankrupt.")
        self:checkWinner()
    end
end

function Engine:sendToDetention(player)
    player.position, player.detained = 7, true
    self:log(player.name .. " is detained and will miss their next move.")
end

function Engine:land(player)
    local index = player.position
    local tile, property = self.config.tiles[index], self.state.properties[index]
    self.state.phase, self.state.pendingTile = "end", false
    self:log(player.name .. " landed on " .. tile.name .. ".")
    if tile.kind == "property" then
        if not property.ownerId then
            self.state.phase, self.state.pendingTile = "buy", index
        elseif property.ownerId ~= player.id then
            local owner = self:player(property.ownerId)
            local rent = self:rent(index)
            self:log(player.name .. " owes " .. owner.name .. " $" .. rent .. " rent.")
            self:pay(player, rent, owner)
        end
    elseif tile.kind == "tax" then
        self:log(player.name .. " owes $" .. tile.amount .. " city tax.")
        self:pay(player, tile.amount)
    elseif tile.kind == "detention" then
        self:sendToDetention(player)
    elseif tile.kind == "event" then
        local card = self.config.events[self.random(1, #self.config.events)]
        self:log(player.name .. ": " .. card.text)
        if card.detention then
            self:sendToDetention(player)
        elseif card.start then
            player.position = 1
            player.cash = player.cash + self.config.startBonus
        elseif card.amount < 0 then
            self:pay(player, -card.amount)
        else
            player.cash = player.cash + card.amount
        end
    elseif tile.kind == "park" then
        self:log(player.name .. " is relaxing in Central Park.")
    end
end

function Engine:nextTurn()
    self.state.turnCount = self.state.turnCount + 1
    if self:checkWinner() then return end
    repeat
        self.state.turn = self.state.turn % #self.state.players + 1
    until self:current().alive
    self.state.phase, self.state.pendingTile, self.state.dice = "roll", false, { 0, 0 }
    self:log("It's " .. self:current().name .. "'s turn.")
end

function Engine:remove(id)
    local player = self:player(id)
    if not player or not player.alive or self.state.status ~= "playing" then return end
    player.alive, player.cash = false, 0
    for _, property in ipairs(self.state.properties) do
        if property.ownerId == id then property.ownerId, property.level = false, 0 end
    end
    self:log(player.name .. " left the match. Their deeds return to the city.")
    if not self:checkWinner() and self:current().id == id then self:nextTurn() end
end

function Engine:act(id, action, tileIndex: any)
    if self.state.status ~= "playing" then return false, "Start a match first." end
    local player = self:current()
    if not player or player.id ~= id then return false, "Wait for your turn." end
    if not player.alive and action ~= "End" then return false, "You are bankrupt. End your turn." end
    local phase = self.state.phase
    if action == "Roll" and phase == "roll" then
        if player.detained then
            player.detained, self.state.phase = false, "end"
            self:log(player.name .. " served their detention and can move next turn.")
        else
            local first, second = self.random(1, 6), self.random(1, 6)
            self.state.dice = { first, second }
            local destination = player.position + first + second
            if destination > #self.config.tiles then
                player.cash = player.cash + self.config.startBonus
                self:log(player.name .. " passed City Gate and collected $" .. self.config.startBonus .. ".")
            end
            player.position = (destination - 1) % #self.config.tiles + 1
            self:land(player)
        end
    elseif action == "Buy" and phase == "buy" then
        local index = self.state.pendingTile
        local tile, property = self.config.tiles[index], self.state.properties[index]
        if property.ownerId then return false, "This property is already owned." end
        if player.cash < tile.price then return false, "You need $" .. tile.price .. " to buy this property." end
        player.cash, property.ownerId = player.cash - tile.price, id
        self.state.phase, self.state.pendingTile = "end", false
        self:log(player.name .. " bought " .. tile.name .. " for $" .. tile.price .. "!")
    elseif action == "Skip" and phase == "buy" then
        self.state.phase, self.state.pendingTile = "end", false
        self:log(player.name .. " passed on the property.")
    elseif action == "End" and phase == "end" then
        self:nextTurn()
    elseif action == "Upgrade" or action == "Sell" then
        if type(tileIndex) ~= "number" or tileIndex ~= math.floor(tileIndex) then return false, "Select a property." end
        local tile, property = self.config.tiles[tileIndex], self.state.properties[tileIndex]
        if not tile or tile.kind ~= "property" or not property or property.ownerId ~= id then return false, "You don't own this property." end
        if action == "Sell" then
            self:liquidate(player, tileIndex)
        else
            if not self:ownsGroup(id, tile.group) then return false, "Own both properties in this district to build." end
            if property.level >= self.config.maxLevel then return false, "This property is fully upgraded." end
            if player.cash < tile.upgrade then return false, "Not enough cash to build." end
            player.cash, property.level = player.cash - tile.upgrade, property.level + 1
            self:log(player.name .. " upgraded " .. tile.name .. " to level " .. property.level .. ".")
        end
    else
        return false, "That action is unavailable right now."
    end
    return true
end

return Engine
