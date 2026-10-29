-- A clear tabletop route surrounding four interactive city-plaza destinations.
local runtimeScript=getfenv().script
local Architecture=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Dice=runtimeScript and require(runtimeScript.Parent.Dice) or require("./Dice")
local Board={spacing=Architecture.spacing}
Board.position=Architecture.position
function Board.generate(config)
    local parts={}
    local function add(name,size,position,color,extra)
        local entry={name=name,size=size,position=position,color=color,material="SmoothPlastic"}
        for key,value in pairs(extra or {}) do entry[key]=value end
        table.insert(parts,entry)
    end
    add("Sea",{1400,3,1400},{0,-7,0},"87B4B3",{reflectance=0.08,canCollide=false})
    add("TableBase",{181,5,181},{0,-1.8,0},"35594B",{material="Wood"})
    add("TableLip",{179,0.7,179},{0,0.9,0},"D8C49D",{material="Wood"})
    add("TableSurface",{175,0.3,175},{0,1.2,0},"E8EBDD")
    add("EventPlaza",{97,0.25,97},{0,1.4,0},"CDDDD0")
    for _,x in ipairs({-49,49}) do add("PlazaBorder",{0.35,0.15,98},{x,1.6,0},"85A393") end
    for _,z in ipairs({-49,49}) do add("PlazaBorder",{98,0.15,0.35},{0,1.6,z},"85A393") end
    add("PlazaPath",{8,0.1,98},{0,1.6,0},"F5EFE0")
    add("PlazaPath",{98,0.1,8},{0,1.6,0},"F5EFE0")
    add("DiceTray",{40,0.45,28},{0,1.95,0},"355C4A",{interaction="dice"})
    for _,x in ipairs({-20,20}) do add("DiceRail",{0.6,1.1,29},{x,2.5,0},"D7C496",{interaction="dice"}) end
    for _,z in ipairs({-14,14}) do add("DiceRail",{40,1.1,0.6},{0,2.5,z},"D7C496",{interaction="dice"}) end
    add("DiceInstructions",{31,0.08,5},{0,2.23,9},"355C4A",{text="CLICK DICE TO ROLL",textColor="F8EBD0",textSize=44,interaction="dice"})
    for side,value in ipairs({1,6}) do for _,entry in ipairs(Dice.preview(value,side)) do table.insert(parts,entry) end end
    local stations={
        {id="market",x=-27,z=27,color="D6AA70",title="CITY MARKET",hint="PICK A CARD"},
        {id="festival",x=27,z=27,color="CBA3B5",title="CITY FESTIVAL",hint="ROTATING OFFERS"},
        {id="contracts",x=-27,z=-27,color="A4B8D5",title="CHALLENGE HALL",hint="CLAIM YOUR REWARD"},
        {id="news",x=27,z=-27,color="9EC8BA",title="CITY NEWS",hint="EVENTS & BULLETIN"},
    }
    for _,station in ipairs(stations) do
        local function item(name,size,x,y,z,color,extra)
            local properties={interaction=station.id}
            for key,value in pairs(extra or {}) do properties[key]=value end
            add(name,size,{station.x+x,y,station.z+z},color,properties)
        end
        item("StationPlatform",{22,0.5,20},0,1.9,0,"F5F0E4")
        item("StationAccent",{22,0.12,1.2},0,2.2,9.3,station.color)
        item("StationLabel",{20,0.08,6.5},0,2.23,6,station.color,{text=station.title.."\n"..station.hint,textColor="2C433B",textSize=48})
        if station.id=="market" then
            item("MarketCounter",{16,2.4,5},0,3.3,-2,"AA8964",{material="Wood"})
            for i=-1,1 do
                item("MarketCardDeck",{3.4,0.7,4.6},i*4.6,4.9,-2,({"D9A4AE","D5BD80","98C5CA"})[i+2])
                item("MarketCardMark",{1.3,0.12,1.8},i*4.6,5.32,-2,"F8F0DE")
            end
        elseif station.id=="festival" then
            item("FestivalStage",{16,0.7,8},0,2.6,-3,"B18C75",{material="WoodPlanks"})
            for _,x in ipairs({-7,7}) do item("FestivalPost",{0.4,5.5,0.4},x,5.4,-3,"997D65",{material="Wood"}) end
            item("FestivalCanopy",{17,0.4,5},0,8.3,-3,station.color)
            for x=-6,6,3 do item("FestivalLantern",{0.8,0.8,0.8},x,7.4,-3,"FFDC9B",{shape="Ball",material="Neon"}) end
        elseif station.id=="contracts" then
            item("ChallengeDesk",{15,0.6,9},0,2.7,-3,"8DABBD")
            for _,x in ipairs({-4,4}) do
                item("ContractSheet",{4,0.12,6},x,3.08,-3,"FCF6E8")
                for z=-4.5,-1.5,1.5 do item("ContractLine",{2.8,0.08,0.15},x,3.19,z,"6C8F99") end
            end
            item("TrophyBase",{2,0.4,2},0,3.1,-3,"775E45")
            item("TrophyStem",{0.55,2,0.55},0,4.2,-3,"E0B968",{material="Metal"})
            item("TrophyCup",{2.3,1.7,2.3},0,5.5,-3,"E0B968",{shape="Ball",material="Metal"})
        else
            for i=-1,1 do
                item("NewsCard",{5.8,0.45,8},i*4.8,2.8+math.abs(i)*0.35,-3,"F8F0DE")
                item("NewsHeadline",{4.2,0.1,1.1},i*4.8,3.08+math.abs(i)*0.35,-5,"638A7C")
                item("NewsPicture",{4.2,0.1,3.2},i*4.8,3.08+math.abs(i)*0.35,-2.4,station.color)
            end
        end
    end
    add("CityTitle",{39,0.1,7},{0,1.72,-45},"CDDDD0",{text="C I T Y M O N E Y",textSize=70,textColor="3E6452"})
    for index,tile in ipairs(config.tiles) do
        local position=Board.position(index)
        local _,yaw=Architecture.site(index)
        local tint=tile.group and config.groups[tile.group].color or "91B7AA"
        local caption=tile.price and (tile.name.."\n$"..tile.price) or tile.name
        local tileSize=(index-1)%6==0 and {18.8,0.4,18.8} or {18.8,0.4,11.4}
        add("Tile"..index,tileSize,position,"FFF9E9",{rotation=Architecture.rotation(yaw),text=caption,textSize=100,textColor="263E34",tileIndex=index})
        local c,s=math.cos(yaw),math.sin(yaw)
        add("DistrictInlay",{18.4,0.1,1.65},{position[1]+s*4.7,1.68,position[3]+c*4.7},tint,{tileIndex=index,rotation=Architecture.rotation(yaw)})
        if tile.kind=="property" then
            for _,entry in ipairs(Architecture.property(config,index,false,tint,0,0)) do table.insert(parts,entry) end
        else
            local site=Architecture.site(index)
            add("CityStop",{16,0.3,16},site,tint,{rotation=Architecture.rotation(yaw)})
            local interaction=tile.kind=="event" and "news" or (tile.kind=="park" and "contracts" or "news")
            add("CityStopLabel",{14,0.1,9},{site[1],2,site[3]},"F5F0E4",{rotation=Architecture.rotation(yaw),interaction=interaction,text=tile.kind=="park" and "FREE CARD" or (tile.kind=="start" and "+$200" or tile.name),textColor="3C5D50",textSize=70})
        end
    end
    add("LobbySpawn",{4,1,4},{0,2,44},"FFFFFF",{className="SpawnLocation",transparency=1})
    return parts
end
return Board
