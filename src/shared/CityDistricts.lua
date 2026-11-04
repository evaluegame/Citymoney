local runtimeScript=getfenv().script
local A=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Art=runtimeScript and require(runtimeScript.Parent.CityArt) or require("./CityArt")
local Districts={}
function Districts.stop(index,tile,tint)
    local origin,yaw=A.site(index);local c,s=math.cos(yaw),math.sin(yaw)
    local entries={}
    local interaction=tile.kind=="park" and "contracts" or "news"
    local function add(name,size,x,y,z,color,extra)
        local entry={name=name,size=size,position={origin[1]+c*x+s*z,origin[2]+y,origin[3]-s*x+c*z},
            rotation=A.rotation(yaw),color=color,material="SmoothPlastic",interaction=interaction}
        for k,v in pairs(extra or {}) do entry[k]=v end
        table.insert(entries,entry)
    end
    local function cylinder(name,diameter,height,x,y,z,color)
        add(name,{height,diameter,diameter},x,y,z,color,{shape="Cylinder",rotation=A.rotation(yaw,0,math.pi/2)})
    end
    for _,entry in ipairs(Art.rounded("CityStop",{17,0.3,17},origin,2,tint,{interaction=interaction})) do table.insert(entries,entry) end
    if tile.kind=="start" then
        for _,x in ipairs({-5.2,5.2}) do
            add("GatePillar",{1.8,8,2},x,4,-0.4,"FFFFFF")
            add("GateBase",{2.8,0.6,3},x,0.5,-0.4,"386BF0")
            add("GateCap",{2.8,0.6,3},x,8,-0.4,"FFC34D")
        end
        add("CityGateway",{13,2,2},0,8,-0.4,"386BF0",{text="CITY GATE",textFace="Front",textColor="FFFFFF",textSize=42})
        add("GateMedallion",{2,2,0.2},0,10,-0.6,"FFC34D",{shape="Ball"})
    elseif tile.kind=="park" then
        cylinder("ParkFountain",12,0.8,0,0.7,-1,"FFFFFF")
        cylinder("ParkWater",10.7,0.15,0,1.2,-1,"54D9F0")
        cylinder("ParkTier",5,2,0,2,-1,"FFF1CD")
        cylinder("ParkUpperWater",4.5,0.1,0,3.1,-1,"54D9F0")
        add("ParkSculpture",{2.2,2.2,2.2},0,4.5,-1,"FFC34D",{shape="Ball"})
        for _,x in ipairs({-6.3,6.3}) do add("ParkBench",{1.1,0.6,5},x,0.8,-1,"C8ACFF") end
    else
        local news=tile.kind=="event"
        local bank=tile.kind=="tax"
        local roof=news and "39BAD1" or (bank and "818FF0" or "4A7DE8")
        add(news and "NewsKiosk" or "CivicOffice",{12,5.4,8},0,2.9,-1,"F4F9FF")
        add("StopRoof",{13.5,0.7,9.4},0,5.95,-1,roof)
        add("StopCornice",{13.6,0.25,9.5},0,6.4,-1,"FFFFFF")
        for _,x in ipairs({-4.1,4.1}) do
            add("StopWindowFrame",{3.3,3.4,0.2},x,3,-5.1,roof)
            add("StopWindow",{2.8,2.8,0.25},x,3,-5.25,"A0E8F8",{material="Glass"})
            add("StopWindowBar",{0.16,2.8,0.3},x,3,-5.4,"FFFFFF")
        end
        add("StopDoor",{2.3,4.2,0.25},0,2.3,-5.2,"386BF0")
        add("StopCanopy",{13,0.3,2.5},0,5,-5.7,roof)
        add("StopTitle",{10,1.1,0.2},0,7,-5.15,roof,{text=news and "CITY NEWS" or (bank and "CITY BANK" or "CITY POLICE"),textFace="Front",textColor="FFFFFF",textSize=36})
        if bank then
            cylinder("BankCoin",3,0.7,0,8,-1,"FFC34D")
            for _,x in ipairs({-5.8,5.8}) do cylinder("BankColumn",0.75,4.8,x,2.6,-5.6,"FFFFFF") end
        elseif news then
            for i=0,2 do add("NewspaperStack",{2.4,0.22,1.8},4,0.8+i*0.25,-6.5,i%2==0 and "FFFFFF" or "B5CCF2") end
            add("NewsAntenna",{0.15,3.6,0.15},4,8,-1,"386BF0")
            add("NewsAntennaTip",{0.65,0.65,0.65},4,10,-1,"FFC34D",{shape="Ball"})
        else
            add("PoliceBeacon",{1.2,0.9,1.2},0,7,-1,"FF7C8E",{shape="Ball",material="Neon"})
        end
    end
    add("CityStopLabel",{13.5,0.08,2.7},0,0.22,6.3,"FFFFFF",{text=tile.kind=="start" and "+$200" or (tile.kind=="park" and "FREE CARD" or "CITY SERVICES"),textColor="386BF0",textSize=40})
    return entries
end
function Districts.generate()
    local entries={}
    local stations={
        {id="market",x=-27,z=27,color="FF9A65",title="CARD MARKET"},
        {id="festival",x=27,z=27,color="F58EC2",title="FESTIVAL"},
        {id="contracts",x=-27,z=-27,color="818FF0",title="CHALLENGES"},
        {id="news",x=27,z=-27,color="62CDE1",title="CITY NEWS"},
    }
    for _,station in ipairs(stations) do
        local function add(name,size,x,y,z,color,extra)
            local p={name=name,size=size,position={station.x+x,y,station.z+z},color=color,material="SmoothPlastic",interaction=station.id}
            for k,v in pairs(extra or {}) do p[k]=v end
            table.insert(entries,p)
        end
        local function cylinder(name,width,height,x,y,z,color)
            add(name,{height,width,width},x,y,z,color,{shape="Cylinder",rotation=A.rotation(0,0,math.pi/2)})
        end
        for _,p in ipairs(Art.rounded("StationPlatform",{23,0.6,21},{station.x,1.9,station.z},3,"F9FCFF",{interaction=station.id})) do table.insert(entries,p) end
        add("StationLabel",{20,0.09,5},0,2.25,7.2,station.color,{text=station.title,textColor="FFFFFF",textSize=48})
        if station.id=="market" then
            add("MarketShop",{16,5.4,8},0,4.9,-2.2,"FFF6DF")
            add("MarketFascia",{17,1.2,0.5},0,7.7,-6.4,station.color)
            for i=-2,2 do
                add("ShopGlass",{2.55,3.5,0.2},i*3.1,4.8,-6.33,"73D8EB",{material="Glass"})
                add("ShopMullion",{0.18,4.5,0.3},i*3.1-1.4,4.9,-6.5,"FFFFFF")
                add("ShopAwning",{3.2,0.3,3.6},i*3.2,7.8,-6.4,i%2==0 and "FF926B" or "FFFFFF",{rotation=A.rotation(0,math.rad(-14),0)})
                add("AwningValance",{3.2,0.7,0.2},i*3.2,7.1,-8,i%2==0 and "FF926B" or "FFFFFF")
            end
            add("MarketTower",{6.5,6.5,6},3,9.5,-1,"FFFFFF")
            add("MarketRoof",{7.5,0.6,7},3,13,-1,"FF9A65")
            add("ClockRim",{0.3,3.6,3.6},3,10.6,-4.18,"FFC34D",{shape="Cylinder",rotation=A.rotation(math.pi/2,0,0)})
            add("MarketClock",{0.18,3.1,3.1},3,10.6,-4.4,"FFFFFF",{shape="Cylinder",rotation=A.rotation(math.pi/2,0,0)})
            add("ClockHand",{0.15,1.1,0.28},3,10.9,-4.55,"3555A5")
            add("ClockHand",{0.9,0.15,0.28},3.4,10.35,-4.55,"3555A5")
        elseif station.id=="festival" then
            cylinder("FestivalStage",16,0.8,0,2.7,-1,"FFC34D")
            cylinder("FestivalDeck",14.8,0.4,0,3.3,-1,"FFF4EE")
            for i=0,7 do
                local angle=i*math.pi/4
                cylinder("FestivalColumn",0.55,5,math.cos(angle)*6,5.9,-1+math.sin(angle)*6,"FFFFFF")
                add("FestivalBulb",{0.75,0.75,0.75},math.cos(angle)*6,8.7,-1+math.sin(angle)*6,"FFE2A4",{shape="Ball",material="Neon"})
            end
            add("FestivalDome",{17,6,17},0,8.6,-1,"F68CBC",{shape="Ball"})
            cylinder("FestivalCrown",11,0.5,0,10.5,-1,"FFFFFF")
            cylinder("FestivalMast",0.3,4,0,12.2,-1,"FFC34D")
            add("FestivalFlag",{3,1.5,0.2},1.3,13.6,-1,"FFBA4C")
        elseif station.id=="contracts" then
            add("HallBody",{14,7,10},0,5.8,-1,"A7B3FF")
            add("HallGlass",{12,4.7,0.15},0,5.4,-6.1,"6CCDE5",{material="Glass"})
            for _,x in ipairs({-6,-2,2,6}) do
                cylinder("HallColumn",1.1,6,x,5.3,-6.6,"FFFFFF")
                cylinder("HallCapital",1.65,0.4,x,8.5,-6.6,"FFF4D6")
            end
            add("HallCornice",{17,0.7,13},0,9.2,-1,"FFFFFF")
            add("HallRoof",{12.5,4.2,8.5},0,9.3,-1,"7F91EC",{shape="Ball"})
            cylinder("TrophyBase",2.8,0.5,0,11.7,-1,"FFFFFF")
            cylinder("TrophyStem",0.65,1.6,0,12.7,-1,"FFC34D")
            add("TrophyCup",{2.5,1.9,2.5},0,13.8,-1,"FFC34D",{shape="Ball"})
        else
            add("NewsPodium",{14,4,10},0,4.5,-1,"FFFFFF")
            add("BroadcastTower",{7.2,11,7.2},0,10,-1,"66D1E5",{material="Glass"})
            for _,x in ipairs({-3.6,3.6}) do for _,z in ipairs({-4.6,2.6}) do add("BroadcastPillar",{0.45,12,0.45},x,10,z,"FFFFFF") end end
            for y=5,14,3 do add("BroadcastBand",{7.8,0.3,7.8},0,y,-1,"FFFFFF") end
            add("NewsScreen",{11,4.3,0.4},0,6.8,-6.2,"386BF0",{text="NEWS",textFace="Front",textColor="FFFFFF",textSize=60})
            add("NewsScreenBack",{11,4.3,0.4},0,6.8,4.2,"386BF0",{text="NEWS",textFace="Back",textColor="FFFFFF",textSize=60})
            cylinder("BroadcastCap",10,0.7,0,15.8,-1,"FFC34D")
            cylinder("BroadcastAntenna",0.3,3.4,0,17.7,-1,"FFFFFF")
            add("BroadcastOrb",{1.4,1.4,1.4},0,19.5,-1,"FFC34D",{shape="Ball"})
        end
    end
    return entries
end
return Districts
