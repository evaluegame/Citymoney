-- A waterfront neighborhood. Each purchasable parcel is a physical garden lot.
local runtimeScript = getfenv().script
local Architecture = runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Board = { spacing = Architecture.spacing }
Board.position = Architecture.position

function Board.generate(config)
    local parts = {}
    local function add(name, size, position, tint, extra)
        local entry = { name = name, size = size, position = position, color = tint }
        for key, value in pairs(extra or {}) do entry[key] = value end
        table.insert(parts, entry)
    end
    local function tree(x, z, scale)
        scale = scale or 1
        add("TreeTrunk", { 0.6*scale, 4*scale, 0.6*scale }, { x, 2+2*scale, z }, "967B60", { material = "Wood" })
        for layer = 0, 2 do
            local size = (4.3-layer*0.65)*scale
            add("TreeCanopy", { size, size, size }, { x+layer*0.2, 4*scale+layer*1.3, z }, ({ "648B64", "7E9C6D", "92AC7C" })[layer+1], { shape = "Ball", material = "Grass" })
        end
    end
    local function bench(x, z)
        add("BenchSeat", { 5, 0.3, 1.5 }, { x, 2.3, z }, "A48862", { material = "WoodPlanks" })
        add("BenchBack", { 5, 1.3, 0.2 }, { x, 3, z+0.7 }, "A48862", { material = "WoodPlanks" })
        for _, dx in ipairs({ -1.8, 1.8 }) do add("BenchLeg", { 0.25, 1.1, 1.3 }, { x+dx, 1.8, z }, "44594F", { material = "Metal" }) end
    end
    add("Sea", { 1400, 3, 1400 }, { 0, -7, 0 }, "87B4B3", { material = "SmoothPlastic", reflectance = 0.12, canCollide = false })
    add("IslandStone", { 181, 6, 181 }, { 0, -2, 0 }, "ACB4A5", { material = "Limestone" })
    add("IslandRim", { 179, 0.8, 179 }, { 0, 0.7, 0 }, "D7D4BD", { material = "Concrete" })
    add("IslandGarden", { 174, 0.4, 174 }, { 0, 1, 0 }, "A8B98F", { material = "Grass" })
    -- A pale promenade with colored deed inlays around the park.
    for side = 0, 3 do
        local vertical = side % 2 == 1
        local x, z = vertical and (side == 1 and -60 or 60) or 0, not vertical and (side == 0 and 60 or -60) or 0
        add("Promenade", vertical and { 14, 0.35, 134 } or { 134, 0.35, 14 }, { x, 1.2, z }, "D7D1BE", { material = "Cobblestone" })
    end
    add("CentralPark", { 92, 0.3, 92 }, { 0, 1.25, 0 }, "8FAA81", { material = "Grass" })
    add("ParkCrossing", { 10, 0.16, 98 }, { 0, 1.55, 0 }, "E3D8C0", { material = "Cobblestone" })
    add("ParkCrossing", { 98, 0.16, 10 }, { 0, 1.55, 0 }, "E3D8C0", { material = "Cobblestone" })
    add("FountainPlaza", { 27, 0.2, 27 }, { 0, 1.6, 0 }, "DDD9C7", { material = "Marble" })
    add("FountainBase", { 15, 0.6, 15 }, { 0, 1.9, 0 }, "C4C0AD", { material = "Marble" })
    add("FountainWater", { 12.8, 0.2, 12.8 }, { 0, 2.4, 0 }, "A2CDD0", { material = "Glass", reflectance = 0.2 })
    for _, z in ipairs({ -7, 7 }) do add("FountainRim", { 15, 0.9, 0.65 }, { 0, 2.5, z }, "D9D3BE", { material = "Marble" }) end
    for _, x in ipairs({ -7, 7 }) do add("FountainRim", { 0.65, 0.9, 15 }, { x, 2.5, 0 }, "D9D3BE", { material = "Marble" }) end
    add("FountainColumn", { 1.4, 4.4, 1.4 }, { 0, 4.4, 0 }, "E2D9C2", { material = "Marble" })
    add("FountainUpperTray", { 5.6, 0.4, 5.6 }, { 0, 5.7, 0 }, "C9C4B0", { material = "Marble" })
    add("FountainUpperWater", { 5, 0.1, 5 }, { 0, 5.95, 0 }, "A2CDD0", { material = "Glass" })
    add("FountainFinial", { 2.1, 2.1, 2.1 }, { 0, 7, 0 }, "D8D2BF", { shape = "Ball", material = "Marble" })
    -- Landscaped terraces rather than a field of identical towers.
    local themes = { "E3C1A0", "C0CCB6", "C8BCC4", "C6D5D5" }
    local count = 0
    for _, x in ipairs({ -29, 29 }) do
        for _, z in ipairs({ -29, 29 }) do
            count = count+1
            local yaw = z > 0 and 0 or math.pi
            local home = Architecture.house({ x, 1.7, z }, yaw, themes[count], count == 1 and 2 or 0, "E1B783", 0)
            for _, entry in ipairs(home) do entry.name = "Club_" .. entry.name; entry.door = nil; table.insert(parts, entry) end
            tree(x-11, z, 1.2)
            tree(x+11, z, 0.95)
        end
    end
    for _, x in ipairs({ -17, 17 }) do
        for _, z in ipairs({ -17, 17 }) do
            add("FlowerGarden", { 9, 0.3, 9 }, { x, 1.6, z }, "B1BD91", { material = "Grass" })
            for dx = -2, 2, 2 do
                for dz = -2, 2, 2 do add("Flowers", { 1.3, 0.9, 1.3 }, { x+dx, 2.2, z+dz }, dx == dz and "E4BCB0" or "E4D4AB", { shape = "Ball", canCollide = false }) end
            end
        end
    end
    bench(-13, 10); bench(13, 10); bench(-13, -10); bench(13, -10)
    for _, x in ipairs({ -46, 46 }) do
        for z = -40, 40, 20 do tree(x, z, z == 0 and 1.3 or 1) end
    end
    for _, z in ipairs({ -46, 46 }) do for x = -30, 30, 30 do tree(x, z, 0.8) end end
    for _, x in ipairs({ -50, 50 }) do
        for _, z in ipairs({ -50, -10, 10, 50 }) do
            add("StreetLamp", { 0.25, 6, 0.25 }, { x, 4.5, z }, "4D6258", { material = "Metal" })
            add("Lantern", { 1.1, 1.4, 1.1 }, { x, 7.8, z }, "FFE6BA", { material = "Neon", light = true })
            add("LanternCap", { 1.6, 0.2, 1.6 }, { x, 8.55, z }, "4D6258")
        end
    end
    add("ClubName", { 33, 0.12, 7 }, { 0, 1.8, 23 }, "DCD7C4", { text = "C I T Y M O N E Y", textSize = 44, textColor = "526A59" })
    for index, tile in ipairs(config.tiles) do
        local position = Board.position(index)
        local _, yaw = Architecture.site(index)
        local tint = tile.group and config.groups[tile.group].color or "9BB6AE"
        local caption = tile.price and (tile.name .. "\n$" .. tile.price) or tile.name
        local tileSize = (index-1)%6==0 and { 18.8, 0.4, 18.8 } or { 18.8, 0.4, 11.4 }
        add("Tile" .. index, tileSize, position, "F0EADA", { rotation = Architecture.rotation(yaw), text = caption,
            textSize = 100, textColor = "475C50", tileIndex = index, material = "Concrete" })
        local c, s = math.cos(yaw), math.sin(yaw)
        add("DistrictInlay", { 18.4, 0.07, 1 }, { position[1]+s*4.9, 1.65, position[3]+c*4.9 }, tint, { tileIndex = index, rotation = Architecture.rotation(yaw) })
        if tile.kind == "property" then
            for _, entry in ipairs(Architecture.property(config, index, false, tint, 0, 0)) do table.insert(parts, entry) end
        else
            local site = Architecture.site(index)
            add("CornerGarden", { 16, 0.3, 16 }, site, "B3C09A", { rotation = Architecture.rotation(yaw), material = "Grass" })
            tree(site[1], site[3], tile.kind == "park" and 1.2 or 0.8)
        end
    end
    -- Timber jetties and moored boats soften the edge of the island.
    for _, x in ipairs({ -52, 45 }) do
        add("Jetty", { 7, 0.6, 24 }, { x, -0.2, 100 }, "A78D66", { material = "WoodPlanks" })
        for _, dx in ipairs({ -3, 3 }) do
            for z = 91, 111, 10 do add("JettyPost", { 0.5, 5, 0.5 }, { x+dx, -1.4, z }, "8D7657", { material = "Wood" }) end
        end
        add("BoatHull", { 5, 1.6, 12 }, { x+7, -3, 102 }, "F4EBDD")
        add("BoatDeck", { 4, 0.4, 9 }, { x+7, -2.1, 102 }, "B7996B", { material = "WoodPlanks" })
        add("BoatCabin", { 3, 2.7, 4 }, { x+7, -0.6, 103 }, "E4D6BB")
        add("BoatWindow", { 3.1, 1.1, 1.6 }, { x+7, 0, 102 }, "9FBEC1", { material = "Glass" })
    end
    add("LobbySpawn", { 4, 1, 4 }, { 0, 2, 42 }, "FFFFFF", { className = "SpawnLocation", transparency = 1 })
    return parts
end
return Board
