-- A clear tabletop route surrounding four interactive city-plaza destinations.
local runtimeScript=getfenv().script
local Architecture=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Dice=runtimeScript and require(runtimeScript.Parent.Dice) or require("./Dice")
local Art=runtimeScript and require(runtimeScript.Parent.CityArt) or require("./CityArt")
local Districts=runtimeScript and require(runtimeScript.Parent.CityDistricts) or require("./CityDistricts")
local Board={spacing=Architecture.spacing}
Board.position=Architecture.position
function Board.generate(config)
    local parts={}
    local function add(name,size,position,color,extra)
        local entry={name=name,size=size,position=position,color=color,material="SmoothPlastic"}
        for key,value in pairs(extra or {}) do entry[key]=value end
        table.insert(parts,entry)
    end
    local function rounded(name,size,position,radius,color,extra)
        for _,entry in ipairs(Art.rounded(name,size,position,radius,color,extra)) do table.insert(parts,entry) end
    end
    add("Sea",{1400,3,1400},{0,-7,0},"56C9E6",{reflectance=0.08,canCollide=false})
    rounded("IslandBody",{181,5,181},{0,-2,0},14,"3F9DD4")
    rounded("IslandBeach",{179,0.7,179},{0,0.75,0},13,"F8DE9D")
    rounded("TableSurface",{175,0.4,175},{0,1.22,0},11,"F7FAFF")
    rounded("EventPlaza",{99,0.28,99},{0,1.5,0},8,"74D6A0")
    add("CityRoad",{10,0.12,97},{0,1.75,0},"8FA9CB")
    add("CityRoad",{97,0.12,10},{0,1.75,0},"8FA9CB")
    for offset=-43,43,8.6 do
        add("RoadMark",{0.3,0.06,3},{0,1.84,offset},"FFFFFF")
        add("RoadMark",{3,0.06,0.3},{offset,1.84,0},"FFFFFF")
    end
    rounded("DiceTray",{40,0.45,28},{0,1.95,0},3,"386BF0",{interaction="dice"})
    for _,x in ipairs({-20,20}) do add("DiceRail",{0.55,0.65,23},{x,2.5,0},"FFFFFF",{interaction="dice"}) end
    for _,z in ipairs({-14,14}) do add("DiceRail",{34,0.65,0.55},{0,2.5,z},"FFFFFF",{interaction="dice"}) end
    add("DiceInstructions",{30,0.08,4.7},{0,2.23,9},"386BF0",{text="LET'S ROLL!",textColor="FFFFFF",textSize=60,interaction="dice"})
    for side,value in ipairs({1,6}) do for _,entry in ipairs(Dice.preview(value,side)) do table.insert(parts,entry) end end
    for _,entry in ipairs(Districts.generate()) do table.insert(parts,entry) end
    add("CityTitle",{40,0.1,6},{0,1.75,-44},"74D6A0",{text="CITYMONEY",textSize=80,textColor="FFFFFF"})
    local function car(x,z,color)
        rounded("CityCar",{3.8,1.2,6.4},{x,2.7,z},0.8,color)
        rounded("CarCabin",{3.2,1.4,3.1},{x,3.75,z+0.25},0.6,"C8EDFA")
        for _,dx in ipairs({-1.7,1.7}) do for _,dz in ipairs({-1.9,1.9}) do add("CarWheel",{0.55,1.25,1.25},{x+dx,2.3,z+dz},"355079",{shape="Cylinder"}) end end
    end
    car(-44,17,"FFC34D");car(44,-17,"FF8B9B")
    for index,tile in ipairs(config.tiles) do
        local position=Board.position(index)
        local _,yaw=Architecture.site(index)
        local tint=tile.group and config.groups[tile.group].color or "7DC8F1"
        local caption=tile.price and (tile.name.."\n$"..tile.price) or tile.name
        local tileSize=(index-1)%6==0 and {18.8,0.4,18.8} or {18.8,0.4,11.4}
        add("Tile"..index,tileSize,position,"FFFFFF",{rotation=Architecture.rotation(yaw),text=caption,textSize=100,textColor="29466D",tileIndex=index})
        local c,s=math.cos(yaw),math.sin(yaw)
        add("DistrictInlay",{18.4,0.1,1.65},{position[1]+s*4.7,1.68,position[3]+c*4.7},tint,{tileIndex=index,rotation=Architecture.rotation(yaw)})
        if tile.kind=="property" then
            for _,entry in ipairs(Architecture.property(config,index,false,tint,0,0)) do table.insert(parts,entry) end
        else
            local site=Architecture.site(index)
            for _,entry in ipairs(Art.rounded("CityStop",{16,0.3,16},site,2.5,tint)) do table.insert(parts,entry) end
            local interaction=tile.kind=="event" and "news" or (tile.kind=="park" and "contracts" or "news")
            add("CityStopLabel",{14,0.1,9},{site[1],2,site[3]},"FFFFFF",{rotation=Architecture.rotation(yaw),interaction=interaction,text=tile.kind=="park" and "FREE CARD" or (tile.kind=="start" and "+$200" or tile.name),textColor="386BF0",textSize=70})
        end
    end
    add("LobbySpawn",{4,1,4},{0,2,44},"FFFFFF",{className="SpawnLocation",transparency=1})
    return parts
end
return Board
