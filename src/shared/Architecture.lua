-- Asset-free, walkable homes. Shared by the live world, deed previews and build.
local Architecture = {}
Architecture.spacing, Architecture.radius = 20, 60

function Architecture.position(index)
    local step = index - 1
    if step <= 6 then return { 60 - step * 20, 1.4, 60 } end
    if step <= 12 then return { -60, 1.4, 60 - (step - 6) * 20 } end
    if step <= 18 then return { -60 + (step - 12) * 20, 1.4, -60 } end
    return { 60, 1.4, -60 + (step - 18) * 20 }
end

function Architecture.site(index)
    local position = Architecture.position(index)
    local side = math.floor((index - 1) / 6)
    local yaw = -side * math.pi / 2
    local s, c = math.sin(yaw), math.cos(yaw)
    return { position[1] + s * 14, 1.8, position[3] + c * 14 }, yaw
end

-- Rotation = yaw * pitch * roll. Matrix rows are Roblox CFrame components.
function Architecture.rotation(yaw, pitch, roll)
    local c, s, a, b, d, e = math.cos(yaw), math.sin(yaw), math.cos(pitch or 0), math.sin(pitch or 0), math.cos(roll or 0), math.sin(roll or 0)
    return { c*d+s*b*e, -c*e+s*b*d, s*a, a*e, a*d, -b, -s*d+c*b*e, s*e+c*b*d, c*a }
end

function Architecture.house(origin, yaw, theme, level, tint, paint, owned)
    local parts = {}
    local c, s = math.cos(yaw), math.sin(yaw)
    local function add(name, size, x, y, z, color, extra)
        local value = { name = name, size = size, position = { origin[1]+c*x+s*z, origin[2]+y, origin[3]-s*x+c*z }, color = color,
            rotation = Architecture.rotation(yaw), material = "SmoothPlastic" }
        for key, entry in pairs(extra or {}) do value[key] = entry end
        if value.pitch or value.roll then value.rotation = Architecture.rotation(yaw, value.pitch, value.roll) end
        table.insert(parts, value)
        return value
    end
    local wall = ({ theme, tint, "F0E7D5", "56636A" })[(paint or 0) + 1] or theme
    local roof, trim, glass = owned and tint or "40535B", "F8F0DF", "96C2CE"
    local floors = level == 0 and 1 or (level == 3 and 3 or 2)
    local height, width, depth = floors * 6.5, level >= 2 and 11.5 or 10, 9
    add("Foundation", { width+1, 0.5, depth+1 }, 0, 0.25, 0.8, "D7D1C4", { material = "Concrete" })
    add("Floor", { width, 0.25, depth }, 0, 0.65, 0.8, "C9AE89", { material = "WoodPlanks" })
    add("BackWall", { width, height, 0.4 }, 0, 0.7+height/2, 5.1, wall)
    add("LeftWall", { 0.4, height, depth }, -width/2, 0.7+height/2, 0.8, wall)
    add("RightWall", { 0.4, height, depth }, width/2, 0.7+height/2, 0.8, wall)
    -- A real opening, rather than a solid box with a painted-on door.
    add("FrontLeft", { width/2-1.5, 6.5, 0.4 }, -(width/4+0.75), 3.95, -3.7, wall)
    add("FrontRight", { width/2-1.5, 6.5, 0.4 }, width/4+0.75, 3.95, -3.7, wall)
    add("DoorLintel", { 3, 1, 0.5 }, 0, 6.7, -3.7, trim)
    add("Door", { 2.8, 5.5, 0.22 }, 0, 3.45, -3.78, "556F66", { door = true, material = "Wood" })
    add("DoorGlass", { 1.75, 2.3, 0.08 }, 0, 4.1, -3.92, glass, { transparency = 0.2, material = "Glass", canCollide = false })
    add("Doorknob", { 0.16, 0.16, 0.16 }, 0.95, 3, -3.98, "CDB67E", { shape = "Ball", material = "Metal", canCollide = false })
    add("DoorFrame", { 3.3, 0.25, 0.7 }, 0, 6.25, -3.75, trim)
    add("Porch", { width+0.5, 0.35, 2.7 }, 0, 0.6, -5.1, "E4DDCD")
    add("Step", { 4, 0.2, 1.4 }, 0, 0.25, -7, "E4DDCD")
    for _, x in ipairs({ -width/2+0.35, width/2-0.35 }) do
        add("PorchColumn", { 0.35, 5.8, 0.35 }, x, 3.65, -5.9, trim)
    end
    add("PorchCanopy", { width+1, 0.35, 3.1 }, 0, 6.7, -5.1, roof)
    add("OwnerFascia", { width+1.05, 0.2, 0.25 }, 0, 6.65, -6.65, tint)
    for floor = 0, floors-1 do
        local base = 0.7 + floor * 6.5
        if floor > 0 then
            add("UpperFacade", { width, 6.5, 0.4 }, 0, base+3.25, -3.7, wall)
            add("FloorBand", { width+0.3, 0.3, 0.5 }, 0, base, -3.7, trim)
            add("FloorBand", { width+0.3, 0.3, 0.5 }, 0, base, 5.1, trim)
            add("UpperFloor", { width-2.6, 0.25, depth }, -1.3, base, 0.8, "C9AE89", { material = "WoodPlanks" })
            add("StairLanding", { 2.6, 0.25, 1.5 }, width/2-1.3, base, 4.45, "C9AE89", { material = "WoodPlanks" })
            for step = 1, 12 do
                local rise = step*6.5/12
                add("StairTread", { 2.1, 0.2, 0.65 }, width/2-1.3, base-6.5+rise, -2.7+step*0.5, "C9AE89", { material = "WoodPlanks" })
            end
            add("BedFrame", { 3.5, 0.6, 4 }, -2.1, base+0.6, 1.1, "A38D70", { material = "Wood" })
            add("BedLinen", { 3.3, 0.4, 3.8 }, -2.1, base+1.1, 1.1, "EAE2CF")
            add("BedPillow", { 2.7, 0.3, 0.8 }, -2.1, base+1.4, 2.4, tint)
        end
        for _, x in ipairs({ -width*0.32, width*0.32 }) do
            add("WindowFrame", { 2.7, 3.3, 0.3 }, x, base+3.45, -3.98, trim)
            add("Window", { 2.25, 2.8, 0.1 }, x, base+3.45, -4.16, glass, { material = "Glass", canCollide = false })
            add("WindowMullion", { 0.12, 2.8, 0.12 }, x, base+3.45, -4.25, trim)
            add("WindowCrossbar", { 2.3, 0.12, 0.12 }, x, base+3.45, -4.25, trim)
            if floor == 0 then
                add("FlowerBox", { 3, 0.5, 0.7 }, x, base+1.6, -4.45, "9D8069", { material = "WoodPlanks" })
                add("Flowers", { 2.6, 0.35, 0.6 }, x, base+1.9, -4.45, "64815C", { canCollide = false })
                for flower = -1, 1 do
                    add("Blossom", { 0.4, 0.4, 0.4 }, x+flower*0.75, base+2.15, -4.45, flower==0 and "E6CCA2" or "D4A4AD", { shape = "Ball", canCollide = false })
                end
            end
        end
        for _, side in ipairs({ -1, 1 }) do
            add("SideWindowFrame", { 0.2, 2.9, 3 }, side*(width/2+0.22), base+3.5, 0.8, trim)
            add("SideWindow", { 0.1, 2.45, 2.6 }, side*(width/2+0.35), base+3.5, 0.8, glass, { material = "Glass", canCollide = false })
            add("BackWindowFrame", { 2.8, 3.1, 0.25 }, side*width*0.28, base+3.5, 5.35, trim)
            add("BackWindow", { 2.3, 2.6, 0.2 }, side*width*0.28, base+3.5, 5.52, glass, { material = "Glass", canCollide = false })
            add("BackMullion", { 0.13, 2.6, 0.1 }, side*width*0.28, base+3.5, 5.67, trim)
        end
    end
    if level < 2 then
        local roofY = height + 2.35
        add("FrontRoof", { width+2, 0.5, 6.3 }, 0, roofY, -1.65, roof, { pitch = math.rad(-27), material = "Slate" })
        add("BackRoof", { width+2, 0.5, 6.3 }, 0, roofY, 3.25, roof, { pitch = math.rad(27), material = "Slate" })
        add("RoofRidge", { width+2.1, 0.4, 0.45 }, 0, roofY+1.4, 0.8, tint)
        add("Chimney", { 1.1, 3.3, 1.1 }, width/2-1.2, height+2.2, 2, "B88B72", { material = "Brick" })
    else
        add("PenthouseRoof", { width+1.1, 0.5, depth+1.1 }, 0, height+0.95, 0.8, owned and tint or trim)
        add("RoofGarden", { width-1, 0.25, depth-1 }, 0, height+1.35, 0.8, "7E9D76", { material = "Grass" })
        add("RoofHedge", { width, 1, 0.7 }, 0, height+1.9, 5, "547C61", { material = "Grass" })
        for _, x in ipairs({ -width*0.35, width*0.35 }) do
            for _, z in ipairs({ -2, 3.2 }) do
                add("PergolaPost", { 0.22, 3.1, 0.22 }, x, height+2.9, z, "A38D70", { material = "Wood" })
            end
        end
        for z = -2.3, 3.7, 1 do
            add("PergolaSlat", { width*0.8, 0.2, 0.35 }, 0, height+4.5, z, "A38D70", { material = "Wood" })
        end
        add("Balcony", { width+0.6, 0.3, 2.3 }, 0, 7.1, -4.6, trim)
        add("BalconyGlass", { width+0.6, 1.9, 0.15 }, 0, 8.15, -5.65, glass, { transparency = 0.4, material = "Glass" })
        for _, x in ipairs({ -width/2, width/2 }) do add("BalconyPost", { 0.12, 2, 0.2 }, x, 8.1, -5.65, roof) end
    end
    -- Interior details visible through the doorway in walking mode.
    add("Rug", { 5, 0.06, 4 }, 0, 0.81, 0.3, "D8BD9C", { canCollide = false })
    add("Sofa", { 4, 0.9, 1.8 }, -2.4, 1.4, 3.4, "A4B5A8")
    add("SofaBack", { 4, 1.5, 0.4 }, -2.4, 2, 4.1, "A4B5A8")
    add("CoffeeTable", { 2.4, 0.7, 1.4 }, -1.8, 1.2, 1, "9B7C5B", { material = "Wood" })
    add("InteriorLight", { 1.4, 0.2, 1.4 }, 0, 6.7, 0.8, "FFE4BA", { material = "Neon", light = true, canCollide = false })
    return parts
end

function Architecture.property(config, index, ownerName, ownerTint, level, paint, effects)
    local tile = config.tiles[index]
    local origin, yaw = Architecture.site(index)
    local c, s, entries = math.cos(yaw), math.sin(yaw), {}
    local function add(name, size, x, y, z, tint, extra)
        local value = { name = name, size = size, position = { origin[1]+c*x+s*z, origin[2]+y, origin[3]-s*x+c*z }, color = tint,
            rotation = Architecture.rotation(yaw), tileIndex = index }
        for key, entry in pairs(extra or {}) do value[key] = entry end
        table.insert(entries, value)
    end
    add("Lawn", { 18.6, 0.3, 18.6 }, 0, -0.1, 0, "91AA7E", { material = "Grass" })
    add("GardenPath", { 3.5, 0.12, 8 }, 0, 0.12, -5.2, "E2D7BF", { material = "Cobblestone" })
    for _, x in ipairs({ -8.4, 8.4 }) do
        add("Hedge", { 0.85, 1.3, 16.5 }, x, 0.6, 0.2, "557D5A", { material = "Grass" })
        for z = -7, 7, 7 do add("FencePost", { 0.35, 1.8, 0.35 }, x, 0.8, z, "EEE3CC") end
    end
    add("BackHedge", { 17.6, 1.3, 0.85 }, 0, 0.6, 8.1, "557D5A", { material = "Grass" })
    if ownerName then
        for _,x in ipairs({-9,9}) do add("OwnershipBorder",{0.3,0.35,18.3},x,0.22,0,ownerTint) end
        for _,z in ipairs({-9,9}) do add("OwnershipBorder",{18.3,0.35,0.3},0,0.22,z,ownerTint) end
        local house = Architecture.house(origin, yaw, config.groups[tile.group].color, level or 0, ownerTint, paint or 0, true)
        for _, entry in ipairs(house) do entry.tileIndex = index; table.insert(entries, entry) end
        add("Mailbox", { 0.7, 1, 0.65 }, 5.9, 1.7, -7.9, ownerTint)
        add("MailboxPost", { 0.2, 1.4, 0.2 }, 5.9, 0.7, -7.9, "EEE3CC")
        add("OwnerSign", { 5, 1.4, 0.16 }, -5.2, 1.7, -8, "F6EFDF",
            { text = ownerName .. "'s home", textFace = "Front", textColor = "263E3A", textSize = 27, canCollide = false })
        add("OwnerStripe", { 5, 0.18, 0.2 }, -5.2, 2.5, -8, ownerTint)
        add("OwnerFlagpole",{0.16,4.2,0.16},7.6,2.1,-7.6,"ECE6D5",{material="Metal"})
        add("OwnerFlag",{1.8,1.1,0.12},6.7,3.7,-7.6,ownerTint)
        if effects and effects.shield then
            add("ProtectionSign",{4,0.9,0.16},-5.2,3.4,-8,"A9D0DE",{text="SHIELDED",textFace="Front",textColor="284453",textSize=24,canCollide=false})
        end
        if effects and (effects.boost or 0)>0 then
            add("RentBoostSign",{4,0.9,0.16},2.5,1.5,-8,"E8C78B",{text="RENT +50%",textFace="Front",textColor="59462C",textSize=22,canCollide=false})
        end
        if effects and (effects.rentTier or 1)>1 then
            add("RentRateSign",{4,0.9,0.16},2.5,2.6,-8,"DCE4CF",{text=tostring(config.rentTiers[effects.rentTier]).."× RENT",textFace="Front",textColor="3D583D",textSize=22,canCollide=false})
        end
        add("GardenTreeTrunk", { 0.35, 2.5, 0.35 }, 6.8, 1.25, 5.6, "9C8366", { material = "Wood" })
        add("GardenTree", { 2.6, 2.7, 2.6 }, 6.8, 3.7, 5.6, "7C9B70", { shape = "Ball", material = "Grass" })
    else
        add("SaleSign", { 5.8, 3, 0.2 }, 0, 2, 0, "F5F0E5",
            { text = "FOR SALE\n$" .. tile.price, textFace = "Front", textColor = "35564A", textSize = 38 })
        add("SaleSignPost", { 0.3, 2, 0.3 }, 0, 0.7, 0, "A58C6E", { material = "Wood" })
        add("FlowerBed", { 4, 0.5, 2.5 }, 5, 0.3, 5, "B7C899", { material = "Grass" })
    end
    return entries
end

function Architecture.porch(index)
    local origin, yaw = Architecture.site(index)
    return { origin[1]-math.sin(yaw)*7, 2.5, origin[3]-math.cos(yaw)*7 }, yaw
end

return Architecture
