-- One scene definition for Studio's editor preview and the running server.
-- Plain numbers/tables keep it usable by the offline place builder, too.
local Board = {}

function Board.position(index)
    local step = index - 1
    if step <= 6 then return { 36 - step * 12, 1, 36 } end
    if step <= 12 then return { -36, 1, 36 - (step - 6) * 12 } end
    if step <= 18 then return { -36 + (step - 12) * 12, 1, -36 } end
    return { 36, 1, -36 + (step - 18) * 12 }
end

function Board.generate(config)
    local parts = {}
    local function add(name, size, position, color, extra)
        local entry = { name = name, size = size, position = position, color = color }
        for key, value in pairs(extra or {}) do entry[key] = value end
        table.insert(parts, entry)
        return entry
    end
    add("Ocean", { 600, 2, 600 }, { 0, -9, 0 }, "608F9A")
    add("Table", { 96, 5, 96 }, { 0, -3, 0 }, "182F35")
    add("TableTrim", { 94, 0.4, 94 }, { 0, -0.4, 0 }, "D5AC66", { material = "Metal" })
    add("CityIsland", { 58, 1.5, 58 }, { 0, 0, 0 }, "94B99E")
    add("MainRoad", { 56, 0.2, 6 }, { 0, 0.85, 0 }, "3C535A")
    add("CrossRoad", { 6, 0.2, 56 }, { 0, 0.85, 0 }, "3C535A")
    for offset = -24, 24, 8 do
        add("LaneMark", { 3, 0.05, 0.15 }, { offset, 0.98, 0 }, "E9D9AE")
        add("LaneMark", { 0.15, 0.05, 3 }, { 0, 0.98, offset }, "E9D9AE")
    end
    local palette = { "EEE2C7", "E4AD89", "8AB6B6", "B3B0CD", "DDC78E" }
    local seed = 42
    local function random(low, high)
        seed = seed * 48271 % 2147483647
        return low + seed % (high - low + 1)
    end
    for x = -20, 20, 10 do
        for z = -20, 20, 10 do
            if math.abs(x) >= 10 and math.abs(z) >= 10 then
                local height = random(5, 13)
                add("CityBuilding", { 6, height, 6 }, { x, 0.8 + height / 2, z }, palette[random(1, #palette)])
                add("Roof", { 6.6, 0.5, 6.6 }, { x, height + 0.8, z }, "304851")
                add("RoofGarden", { 4.8, 0.3, 4.8 }, { x, height + 1.1, z }, "6FA58A")
                for y = 3, height - 1, 3 do
                    for dx = -1.5, 1.5, 3 do
                        add("Window", { 1, 1.3, 0.08 }, { x + dx, y, z + 3.04 }, "FFE7AA", { material = "Neon" })
                        add("Window", { 0.08, 1.3, 1 }, { x + 3.04, y, z + dx }, "FFE7AA", { material = "Neon" })
                    end
                end
            end
        end
    end
    for _, position in ipairs({ { -10, 0 }, { 10, 0 }, { 0, -10 }, { 0, 10 } }) do
        local x, z = position[1], position[2]
        add("Planter", { 5, 0.6, 5 }, { x, 1, z }, "D6CFB2")
        add("TreeTrunk", { 0.8, 3, 0.8 }, { x, 2.5, z }, "947253")
        add("TreeCrown", { 4, 4, 4 }, { x, 5, z }, "4D9778", { shape = "Ball" })
    end
    for _, x in ipairs({ -27, 27 }) do
        for _, z in ipairs({ -27, 27 }) do
            add("StreetLamp", { 0.35, 5, 0.35 }, { x, 3.25, z }, "304851", { material = "Metal" })
            add("LampGlow", { 1.4, 1.2, 1.4 }, { x, 6, z }, "FFE7AA", { material = "Neon", light = true })
        end
    end
    add("FountainBase", { 5.5, 0.8, 5.5 }, { 0, 1.3, 0 }, "E0D9BC")
    add("FountainWater", { 4.5, 0.15, 4.5 }, { 0, 1.8, 0 }, "80D7E0", { material = "Glass" })
    add("FountainColumn", { 0.8, 3, 0.8 }, { 0, 3, 0 }, "B3F1E5", { material = "Neon" })
    add("CitySign", { 24, 0.4, 5 }, { 0, 16, 0 }, "153D43", { text = "CITYMONEY", textColor = "F8D99A", textSize = 95 })
    for index, tile in ipairs(config.tiles) do
        local position = Board.position(index)
        local caption = tile.name
        if tile.price then caption = caption .. "\n$" .. tile.price end
        if tile.kind == "start" then caption = caption .. "\n+$200 →" end
        if tile.kind == "tax" then caption = caption .. "\n−$120" end
        add("Tile" .. index, { 11.5, 1, 11.5 }, position, tile.kind == "property" and "F5EDDB" or "DBEAE3",
            { text = caption, textColor = "233F46", textSize = 65, tileIndex = index })
        if tile.group then
            add("District" .. index, { 10.8, 0.15, 1.8 }, { position[1], 1.58, position[3] - 4.5 }, config.groups[tile.group].color, { tileIndex = index })
        end
    end
    add("LobbySpawn", { 8, 1, 8 }, { 0, 2, 48 }, "FFFFFF", { className = "SpawnLocation", transparency = 1 })
    return parts
end

return Board
