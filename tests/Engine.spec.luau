local Config = require("../src/shared/Config")
local Engine = require("../src/shared/Engine")
local passed = 0
local function expect(value, message) assert(value, message or "Expectation failed") end
local function equal(actual, expected) assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected)) end
local function test(name, callback)
    local ok, message = pcall(callback)
    if not ok then error("FAIL " .. name .. ": " .. tostring(message), 0) end
    passed = passed + 1
    print("PASS " .. name)
end
local function gameWith(rolls, count)
    local cursor = 0
    local engine = Engine.new(Config, function(low, high)
        cursor = cursor + 1
        local result = rolls and rolls[cursor] or low
        assert(result >= low and result <= high, "Invalid test roll")
        return result
    end)
    local roster = {}
    for index = 1, count or 2 do table.insert(roster, { id = index, name = "Player " .. index }) end
    expect(engine:start(roster))
    return engine
end

test("starts with equal cash and reset ownership", function()
    local engine = gameWith()
    equal(engine.state.status, "playing")
    equal(engine:current().id, 1)
    equal(engine:player(2).cash, 1500)
    equal(#engine.state.properties, #Config.tiles)
    equal(engine.state.turnCount, 1)
end)
test("rejects invalid rosters without changing lobby", function()
    local engine = Engine.new(Config)
    expect(not engine:start({ { id = 1 }, { id = 1 } }))
    expect(not engine:start({ { id = 1 } }))
    equal(engine.state.status, "lobby")
end)
test("rejects out-of-turn and out-of-phase actions", function()
    local engine = gameWith()
    expect(not engine:act(2, "Roll"))
    expect(not engine:act(1, "Buy"))
    expect(not engine:act(1, "End"))
    expect(not engine:act(1, "Hack"))
    equal(engine:player(1).cash, 1500)
end)
test("roll, buy, end and next turn", function()
    local engine = gameWith({ 1, 1 })
    expect(engine:act(1, "Roll"))
    equal(engine:player(1).position, 3)
    equal(engine.state.phase, "buy")
    expect(engine:act(1, "Buy"))
    equal(engine:player(1).cash, 1390)
    equal(engine.state.properties[3].ownerId, 1)
    expect(not engine:act(1, "Buy"))
    expect(engine:act(1, "End"))
    equal(engine:current().id, 2)
end)
test("declining a deed leaves it unowned", function()
    local engine = gameWith({ 1, 1 })
    engine:act(1, "Roll")
    expect(engine:act(1, "Skip"))
    equal(engine.state.properties[3].ownerId, false)
    equal(engine.state.phase, "end")
end)
test("cannot buy without sufficient cash", function()
    local engine = gameWith({ 1, 1 })
    engine:player(1).cash = 1
    engine:act(1, "Roll")
    expect(not engine:act(1, "Buy"))
    equal(engine.state.phase, "buy")
end)
test("pays rent to another owner", function()
    local engine = gameWith({ 1, 1 })
    engine.state.properties[3].ownerId = 2
    expect(engine:act(1, "Roll"))
    equal(engine:player(1).cash, 1484)
    equal(engine:player(2).cash, 1516)
end)
test("own properties charge no rent", function()
    local engine = gameWith({ 1, 1 })
    engine.state.properties[3].ownerId = 1
    engine:act(1, "Roll")
    equal(engine:player(1).cash, 1500)
    equal(engine.state.phase, "end")
end)
test("matching district doubles base rent", function()
    local engine = gameWith()
    engine.state.properties[2].ownerId, engine.state.properties[3].ownerId = 1, 1
    equal(engine:rent(2), 24)
    equal(engine:rent(3), 32)
    expect(engine:ownsGroup(1, "old"))
end)
test("build requires complete district and owner turn", function()
    local engine = gameWith()
    engine.state.properties[2].ownerId = 1
    expect(not engine:act(1, "Upgrade", 2))
    engine.state.properties[3].ownerId = 1
    expect(not engine:act(2, "Upgrade", 2))
    expect(engine:act(1, "Upgrade", 2))
    equal(engine.state.properties[2].level, 1)
    equal(engine:player(1).cash, 1440)
    equal(engine:rent(2), 36)
end)
test("build caps at three levels and requires cash", function()
    local engine = gameWith()
    engine.state.properties[2].ownerId, engine.state.properties[3].ownerId = 1, 1
    for _ = 1, 3 do expect(engine:act(1, "Upgrade", 2)) end
    expect(not engine:act(1, "Upgrade", 2))
    equal(engine:rent(2), 120)
    engine:player(1).cash = 0
    expect(not engine:act(1, "Upgrade", 3))
end)
test("rejects malformed property indexes", function()
    local engine = gameWith()
    for _, index in ipairs({ -1, 0, 25, 1.2, "2", 0 / 0, math.huge }) do
        expect(not engine:act(1, "Upgrade", index))
        expect(not engine:act(1, "Sell", index))
    end
    expect(not engine:act(1, "Upgrade", nil))
    expect(not engine:act(1, "Sell", {}))
end)
test("sell refunds half invested cost and clears levels", function()
    local engine = gameWith()
    engine.state.properties[2].ownerId, engine.state.properties[2].level = 1, 2
    expect(engine:act(1, "Sell", 2))
    equal(engine:player(1).cash, 1605)
    equal(engine.state.properties[2].level, 0)
    equal(engine.state.properties[2].ownerId, false)
end)
test("passing City Gate pays exactly once", function()
    local engine = gameWith({ 1, 1 })
    engine:player(1).position = 24
    engine:act(1, "Roll")
    equal(engine:player(1).position, 2)
    equal(engine:player(1).cash, 1700)
end)
test("landing exactly on City Gate pays bonus", function()
    local engine = gameWith({ 1, 1 })
    engine:player(1).position = 23
    engine:act(1, "Roll")
    equal(engine:player(1).position, 1)
    equal(engine:player(1).cash, 1700)
end)
test("city tax is collected", function()
    local engine = gameWith({ 4, 5 })
    engine:act(1, "Roll")
    equal(engine:player(1).position, 10)
    equal(engine:player(1).cash, 1380)
end)
test("detention moves player without awarding a lap", function()
    local engine = gameWith({ 1, 1 })
    engine:player(1).position = 17
    engine:act(1, "Roll")
    equal(engine:player(1).position, 7)
    equal(engine:player(1).cash, 1500)
    expect(engine:player(1).detained)
    engine:act(1, "End")
    engine:act(2, "Roll")
    engine:act(2, "Skip")
    engine:act(2, "End")
    engine:act(1, "Roll")
    equal(engine:player(1).position, 7)
    expect(not engine:player(1).detained)
    equal(engine.state.phase, "end")
end)
test("just visiting detention does not detain", function()
    local engine = gameWith({ 3, 3 })
    engine:act(1, "Roll")
    equal(engine:player(1).position, 7)
    expect(not engine:player(1).detained)
end)
test("event awards cash", function()
    local engine = gameWith({ 1, 2, 1 })
    engine:act(1, "Roll")
    equal(engine:player(1).cash, 1620)
end)
test("event deducts cash", function()
    local engine = gameWith({ 1, 2, 3 })
    engine:act(1, "Roll")
    equal(engine:player(1).cash, 1410)
end)
test("event sends to City Gate with one bonus", function()
    local engine = gameWith({ 1, 2, 6 })
    engine:act(1, "Roll")
    equal(engine:player(1).position, 1)
    equal(engine:player(1).cash, 1700)
end)
test("event sends to detention", function()
    local engine = gameWith({ 1, 2, 5 })
    engine:act(1, "Roll")
    equal(engine:player(1).position, 7)
    expect(engine:player(1).detained)
end)
test("shortfall auto-sells deeds before declaring bankruptcy", function()
    local engine = gameWith({ 4, 5 })
    engine:player(1).cash = 100
    engine.state.properties[2].ownerId = 1
    engine:act(1, "Roll")
    equal(engine:player(1).cash, 25)
    expect(engine:player(1).alive)
    equal(engine.state.properties[2].ownerId, false)
end)
test("insolvency transfers remaining cash and ends two-player game", function()
    local engine = gameWith({ 1, 1 })
    engine:player(1).cash = 5
    engine.state.properties[3].ownerId = 2
    engine:act(1, "Roll")
    expect(not engine:player(1).alive)
    equal(engine:player(2).cash, 1505)
    equal(engine.state.status, "finished")
    equal(engine.state.winnerId, 2)
end)
test("bankrupt player can end turn in multiplayer", function()
    local engine = gameWith({ 1, 1 }, 3)
    engine:player(1).cash = 1
    engine.state.properties[3].ownerId = 2
    engine:act(1, "Roll")
    equal(engine.state.status, "playing")
    expect(not engine:act(1, "Sell", 3))
    expect(engine:act(1, "End"))
    equal(engine:current().id, 2)
end)
test("disconnect releases deeds and advances active turn", function()
    local engine = gameWith(nil, 3)
    engine.state.properties[2].ownerId, engine.state.properties[2].level = 1, 3
    engine:remove(1)
    equal(engine:current().id, 2)
    equal(engine.state.properties[2].ownerId, false)
    equal(engine.state.properties[2].level, 0)
    engine:remove(3)
    equal(engine.state.winnerId, 2)
end)
test("turn limit selects highest net worth", function()
    local engine = gameWith()
    engine.state.properties[24].ownerId = 2
    engine.state.turnCount, engine.state.phase = Config.maxTurns, "end"
    engine:act(1, "End")
    equal(engine.state.status, "finished")
    equal(engine.state.winnerId, 2)
end)
test("replay resets money, properties, dice and detention", function()
    local engine = gameWith()
    engine.state.properties[2].ownerId = 1
    engine:player(1).detained = true
    engine:remove(2)
    expect(engine:start({ { id = 3, name = "New player" }, { id = -1, name = "Bot", bot = true } }))
    equal(engine:current().cash, 1500)
    equal(engine.state.properties[2].ownerId, false)
    expect(not engine:current().detained)
    equal(engine.state.turnCount, 1)
    expect(engine:player(-1).bot)
end)
test("solo bot identity cannot collide with Studio test UserIds", function()
    local engine = Engine.new(Config)
    expect(engine:start({ { id = -1, name = "Player1" }, { id = Config.botId, name = "City Bot", bot = true } }))
    engine.state.phase = "end"
    expect(engine:act(-1, "End"))
    equal(engine:current().id, Config.botId)
    expect(engine:current().bot)
    expect(engine:act(Config.botId, "Roll"))
end)
test("board has complete district pairs and valid economics", function()
    equal(#Config.tiles, 24)
    for group in pairs(Config.groups) do
        local count = 0
        for _, tile in ipairs(Config.tiles) do
            if tile.group == group then
                count = count + 1
                expect(tile.price > 0 and tile.rent > 0 and tile.upgrade > 0)
            end
        end
        equal(count, 2)
    end
end)
test("200 full seeded matches preserve economy and terminate", function()
    math.randomseed(20261024)
    for match = 1, 200 do
        local engine = Engine.new(Config)
        local roster = {}
        for id = 1, 2 + match % 5 do table.insert(roster, { id = id, name = "Bot " .. id }) end
        expect(engine:start(roster))
        local actions = 0
        while engine.state.status == "playing" do
            local current = engine:current()
            local phase = engine.state.phase
            local command
            if phase == "roll" then command = "Roll"
            elseif phase == "buy" then
                command = current.cash >= Config.tiles[engine.state.pendingTile].price + 100 and "Buy" or "Skip"
            else
                for index, property in ipairs(engine.state.properties) do
                    local tile = Config.tiles[index]
                    if current.alive and property.ownerId == current.id and property.level < 3 and engine:ownsGroup(current.id, tile.group) and current.cash > tile.upgrade + 200 then
                        expect(engine:act(current.id, "Upgrade", index))
                    end
                end
                command = "End"
            end
            expect(engine:act(current.id, command))
            actions = actions + 1
            expect(actions < 500, "Match did not terminate")
            for _, entry in ipairs(engine.state.players) do
                expect(entry.cash >= 0 and entry.cash % 1 == 0, "Invalid balance")
                expect(entry.position >= 1 and entry.position <= 24, "Invalid position")
            end
            for _, property in ipairs(engine.state.properties) do
                expect(property.level >= 0 and property.level <= 3, "Invalid upgrade level")
                if property.ownerId then expect(engine:player(property.ownerId).alive, "Eliminated owner") end
            end
        end
        expect(engine.state.winnerId ~= false, "No winner")
    end
end)
print("\n" .. passed .. " tests passed, including 200 complete simulated matches.")
