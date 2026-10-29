-- Pure Luau: no Roblox services. The server alone owns this state.
local runtimeScript = getfenv().script
local Plans = runtimeScript and require(runtimeScript.Parent.PropertyPlans) or require("./PropertyPlans")
local Tactics = runtimeScript and require(runtimeScript.Parent.Tactics) or require("./Tactics")
local Plaza = runtimeScript and require(runtimeScript.Parent.Plaza) or require("./Plaza")
local Engine = {}
Engine.__index = Engine

function Engine.new(config, randomInteger)
    local self = setmetatable({}, Engine)
    self.config = config
    self.random = randomInteger or math.random
    self.state = { status = "lobby", players = {}, properties = {}, logs = {}, turn = 0,
        turnCount = 0, phase = "roll", pendingTile = false, dice = { 0, 0 }, winnerId = false }
    for i = 1, #config.tiles do
        self.state.properties[i] = {}
        Tactics.resetProperty(self.state.properties[i])
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

function Engine:start(roster, rules)
    if self.state.status == "playing" then return false, "A match is already running." end
    if #roster < 2 or #roster > self.config.maxPlayers then return false, "A match needs 2–6 players." end
    local seen,colors = {},{}
    for index, entry in ipairs(roster) do
        if seen[entry.id] then return false, "Duplicate player." end
        local color=entry.colorIndex or index
        if type(color)~="number" or color%1~=0 or color<1 or color>#self.config.playerColors or colors[color] then return false,"Each resident needs a different color." end
        colors[color]=true
        seen[entry.id] = true
    end
    self.state.players = {}
    for index, entry in ipairs(roster) do
        local resident={ id = entry.id, name = entry.name, bot = entry.bot == true,
            cash = self.config.startingCash, position = 1, alive = true, detained = false, colorIndex = entry.colorIndex or index }
        Tactics.initialize(self.config,resident,index)
        table.insert(self.state.players,resident)
    end
    for _, property in ipairs(self.state.properties) do
        Tactics.resetProperty(property)
    end
    self.state.status, self.state.turn, self.state.turnCount = "playing", 1, 1
    self.state.phase, self.state.pendingTile, self.state.winnerId = "roll", false, false
    self.state.dice, self.state.logs = { 0, 0 }, {}
    self.state.rules={attackMode=rules and rules.attackMode=="downgrade" and "downgrade" or "destroy"}
    self.state.actionUsed,self.state.challengeClaimed,self.state.challengeSwapped=false,false,false
    self.state.lastAction=false
    self.state.lastRoll=false
    self.state.plazaUsed=false
    Tactics.refresh(self)
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
    return Plans.projectedRent(self.config,self.state,property.ownerId,index,property.level)
end

function Engine:wealth(player)
    local total = player.cash
    for index, property in ipairs(self.state.properties) do
        if property.ownerId == player.id then
            total = total + Plans.investment(self.config,index,property.level,property.rentTier)
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
    local value = math.floor(Plans.investment(self.config,index,property.level,property.rentTier) / 2)
    Tactics.resetProperty(property)
    player.cash = player.cash + value
    self:log(player.name .. " sold " .. tile.name .. " for $" .. value .. ".")
end

function Engine:pay(player, amount, recipient, category)
    -- Cash shortfalls sell deeds back to the city, in board order, at half cost.
    for index, property in ipairs(self.state.properties) do
        if player.cash >= amount then break end
        if property.ownerId == player.id then self:liquidate(player, index) end
    end
    local paid = math.min(player.cash, amount)
    player.cash = player.cash - paid
    if recipient then recipient.cash = recipient.cash + paid end
    if recipient and category=="rent" then recipient.stats.rent=recipient.stats.rent+paid end
    if paid < amount then
        player.alive = false
        self:log(player.name .. " went bankrupt.")
        self:checkWinner()
    end
    return paid
end

function Engine:awardGate(player)
    player.cash=player.cash+self.config.startBonus
    player.stats.passes=player.stats.passes+1
    Tactics.draw(self,player,1)
end

function Engine:playCard(id,kind,index,targetId,turn)
    return Tactics.play(self,id,kind,index,targetId,turn)
end

function Engine:view(id)
    local result=table.clone(self.state)
    result.players={}
    for _,player in ipairs(self.state.players) do
        local copy=table.clone(player)
        if player.id~=id then copy.cards={} end
        table.insert(result.players,copy)
    end
    return result
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
            local paid=self:pay(player, rent, owner,"rent")
            if paid>0 and (property.boost or 0)>0 then property.boost=property.boost-1 end
        end
    elseif tile.kind == "tax" then
        self:log(player.name .. " owes $" .. tile.amount .. " city tax.")
        self:pay(player, tile.amount)
    elseif tile.kind == "detention" then
        self:sendToDetention(player)
    elseif tile.kind == "event" then
        player.stats.news=player.stats.news+1
        local card = self.config.events[self.random(1, #self.config.events)]
        self:log(player.name .. ": " .. card.text)
        if card.detention then
            self:sendToDetention(player)
        elseif card.start then
            player.position = 1
            self:awardGate(player)
        elseif card.card then Tactics.grant(self,player,card.card,1)
        elseif card.draw then Tactics.draw(self,player,card.draw)
        elseif card.communityGift then
            for _,resident in ipairs(self.state.players) do if resident.alive then resident.cash=resident.cash+card.communityGift end end
        elseif card.maintenance or card.levelMaintenance or card.dividend then
            local homes,levels=0,0
            for _,asset in ipairs(self.state.properties) do if asset.ownerId==player.id then homes=homes+1;levels=levels+asset.level end end
            if card.dividend then player.cash=player.cash+homes*card.dividend
            else self:pay(player,homes*(card.maintenance or 0)+levels*(card.levelMaintenance or 0)) end
        elseif card.amount and card.amount < 0 then
            self:pay(player, -card.amount)
        else
            player.cash = player.cash + (card.amount or 0)
        end
    elseif tile.kind == "park" then
        Tactics.draw(self,player,1)
        self:log(player.name .. " found a tactical card in Central Park.")
    end
end

function Engine:nextTurn()
    self.state.turnCount = self.state.turnCount + 1
    if self:checkWinner() then return end
    repeat
        self.state.turn = self.state.turn % #self.state.players + 1
    until self:current().alive
    self.state.phase, self.state.pendingTile, self.state.dice = "roll", false, { 0, 0 }
    self.state.actionUsed,self.state.challengeClaimed,self.state.challengeSwapped=false,false,false
    self.state.plazaUsed=false
    self:log("It's " .. self:current().name .. "'s turn.")
end

function Engine:remove(id)
    local player = self:player(id)
    if not player or not player.alive or self.state.status ~= "playing" then return end
    player.alive, player.cash = false, 0
    for _, property in ipairs(self.state.properties) do
        if property.ownerId == id then Tactics.resetProperty(property) end
    end
    self:log(player.name .. " left the match. Their deeds return to the city.")
    if not self:checkWinner() and self:current().id == id then self:nextTurn() end
end

function Engine:canVisit(id, tileIndex: any)
    if self.state.status ~= "playing" then return false, "Start a match first." end
    local player = self:player(id)
    if not player or not player.alive then return false, "Only active residents can visit a home." end
    if type(tileIndex) ~= "number" or tileIndex ~= math.floor(tileIndex) then return false, "Select a property." end
    local property = self.state.properties[tileIndex]
    if not property or property.ownerId ~= id then return false, "You can walk through homes you own." end
    return true
end

function Engine:act(id, action, tileIndex: any, targetLevel: any, expectedTurn: any)
    if self.state.status ~= "playing" then return false, "Start a match first." end
    local player = self:current()
    if not player or player.id ~= id then return false, "Wait for your turn." end
    if not player.alive and action ~= "End" then return false, "You are bankrupt. End your turn." end
    if (action=="Buy" or action=="Upgrade" or action=="SetRent" or action=="Claim" or action=="NewGoal") and expectedTurn~=nil and expectedTurn~=self.state.turnCount then
        return false, "That home selection expired. Open the options again."
    end
    local phase = self.state.phase
    if action=="Plaza" then
        return Plaza.act(self,id,tileIndex)
    elseif action=="Claim" then
        local ok,message=Tactics.claim(self,player)
        if not ok then return false,message end
    elseif action=="NewGoal" then
        local ok,message=Tactics.swap(self,player)
        if not ok then return false,message end
    elseif action == "Roll" and phase == "roll" then
        if player.detained then
            player.detained, self.state.phase = false, "end"
            self:log(player.name .. " served their detention and can move next turn.")
        else
            local first, second = self.random(1, 6), self.random(1, 6)
            self.state.dice = { first, second }
            local destination = player.position + first + second
            if destination > #self.config.tiles then
                self:awardGate(player)
                self:log(player.name .. " passed City Gate and collected $" .. self.config.startBonus .. ".")
            end
            player.position = (destination - 1) % #self.config.tiles + 1
            self:land(player)
            self.state.lastRoll={seq=(self.state.lastRoll and self.state.lastRoll.seq or 0)+1,turn=self.state.turnCount,actorId=id,values={first,second},steps=first+second}
        end
    elseif action == "Buy" and phase == "buy" then
        local index = self.state.pendingTile
        local tile, property = self.config.tiles[index], self.state.properties[index]
        if tileIndex~=nil and tileIndex~=index then return false, "This is a different property. Open its options again." end
        if property.ownerId then return false, "This property is already owned." end
        local level = targetLevel==nil and 0 or targetLevel
        local cost = Plans.purchaseCost(self.config,index,level)
        if not cost then return false, "Choose a home level from 0 to "..self.config.maxLevel.."." end
        if player.cash < cost then return false, "You need $" .. cost .. " for this home and its land." end
        player.cash, property.ownerId, property.level = player.cash - cost, id, level
        player.stats.upgrades=player.stats.upgrades+level
        self.state.phase, self.state.pendingTile = "end", false
        self:log(player.name .. " bought " .. tile.name .. " as a level "..level.." "..self.config.homeNames[level+1].." for $" .. cost .. "!")
    elseif action == "Skip" and phase == "buy" then
        self.state.phase, self.state.pendingTile = "end", false
        self:log(player.name .. " passed on the property.")
    elseif action == "End" and phase == "end" then
        self:nextTurn()
    elseif action == "Upgrade" or action == "Sell" or action == "Paint" or action=="SetRent" then
        if type(tileIndex) ~= "number" or tileIndex ~= math.floor(tileIndex) then return false, "Select a property." end
        local tile, property = self.config.tiles[tileIndex], self.state.properties[tileIndex]
        if not tile or tile.kind ~= "property" or not property or property.ownerId ~= id then return false, "You don't own this property." end
        if action=="SetRent" then
            local cost=Plans.rentCost(self.config,tileIndex,property.rentTier or 1,targetLevel)
            if not cost then return false,"Choose a higher rent multiplier." end
            if player.cash<cost then return false,"This rental improvement costs $"..cost.."." end
            player.cash,property.rentTier=player.cash-cost,targetLevel
            self:log(player.name.." raised future rent at "..tile.name.." to "..self.config.rentTiers[targetLevel].."× for $"..cost..".")
        elseif action == "Paint" then
            property.paint = ((property.paint or 0) + 1) % 4
            self:log(player.name .. " refreshed the exterior of " .. tile.name .. ".")
        elseif action == "Sell" then
            self:liquidate(player, tileIndex)
        else
            if property.level >= self.config.maxLevel then return false, "This property is fully upgraded." end
            local level = targetLevel==nil and property.level+1 or targetLevel
            local cost = Plans.upgradeCost(self.config,tileIndex,property.level,level)
            if not cost then return false, "Choose a higher home level, up to "..self.config.maxLevel.."." end
            if player.cash < cost then return false, "You need $"..cost.." for this upgrade." end
            player.stats.upgrades=player.stats.upgrades+(level-property.level)
            player.cash, property.level = player.cash - cost, level
            self:log(player.name .. " upgraded " .. tile.name .. " to level " .. property.level .. " "..self.config.homeNames[level+1].." for $"..cost..".")
        end
    else
        return false, "That action is unavailable right now."
    end
    Tactics.refresh(self)
    return true
end

return Engine
