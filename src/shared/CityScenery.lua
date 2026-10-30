-- Public city scenery stays outside the purchasable parcels and the pawn route.
local runtimeScript=getfenv().script
local A=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Art=runtimeScript and require(runtimeScript.Parent.CityArt) or require("./CityArt")
local City={}
function City.bounds()
    return {min={-130,-8,-156},max={130,38,139},target={0,6,-10}}
end
function City.generate()
    local parts={}
    local background=false
    local function add(name,size,p,color,extra)
        local entry={name=name,size=size,position=p,color=color,material="SmoothPlastic",background=background,canQuery=false}
        for k,v in pairs(extra or {}) do entry[k]=v end
        table.insert(parts,entry)
    end
    local function round(name,size,p,radius,color,extra)
        local flags={background=background,canQuery=false}
        for k,v in pairs(extra or {}) do flags[k]=v end
        for _,entry in ipairs(Art.rounded(name,size,p,radius,color,flags)) do table.insert(parts,entry) end
    end
    local function cylinder(name,width,height,p,color,extra)
        local flags={shape="Cylinder",rotation=A.rotation(0,0,math.pi/2)}
        for k,v in pairs(extra or {}) do flags[k]=v end
        add(name,{height,width,width},p,color,flags)
    end
    -- Pedestrian crossings connect the four existing, functional event stations.
    for _,side in ipairs({-1,1}) do
        add("CityCurb",{1,0.3,36},{side*6,1.95,side*30},"FFFFFF")
        add("CityCurb",{36,0.3,1},{side*30,1.95,-side*6},"FFFFFF")
        for stripe=-2,2 do
            add("Crosswalk",{8,0.06,0.75},{0,1.87,side*35+stripe*1.5},"FFFFFF")
            add("Crosswalk",{0.75,0.06,8},{side*35+stripe*1.5,1.87,0},"FFFFFF")
        end
    end
    for _,x in ipairs({-44,44}) do for _,z in ipairs({-44,44}) do
        round("PocketPlaza",{8.5,0.2,8.5},{x,1.72,z},1.8,"FFF3D7")
        cylinder("FountainBowl",6,0.65,{x,2.05,z},"FFF9EA")
        cylinder("FountainWater",5,0.12,{x,2.43,z},"51D4EE",{material="Glass"})
        cylinder("FountainPedestal",1.1,1.8,{x,3.2,z},"FFC34D")
        add("FountainJet",{0.4,1.6,0.4},{x,4.4,z},"B5F5FF",{material="Neon",canCollide=false})
        add("FountainSpark",{0.75,0.75,0.75},{x,5.2,z},"E6FCFF",{shape="Ball",canCollide=false})
    end end
    -- The waterfront is background scenery: overview framing remains focused
    -- on the complete playable board instead of shrinking it to fit a skyline.
    background=true
    for _,side in ipairs({-1,1}) do
        round("WaterfrontQuay",{216,7.1,15},{0,-2.4,side*99},3,"D6E4ED")
        round("WaterfrontQuay",{15,7.1,183},{side*99,-2.4,0},3,"D6E4ED")
        add("Boardwalk",{210,0.2,11},{0,1.17,side*99},"E9CFA7",{material="WoodPlanks"})
        add("Boardwalk",{11,0.2,181},{side*99,1.17,0},"E9CFA7",{material="WoodPlanks"})
        for _,railY in ipairs({2.2,3.4}) do
            add("HarborRail",{212,0.2,0.2},{0,railY,side*106},"446BA6",{material="Metal"})
            add("HarborRail",{0.2,0.2,181},{side*106,railY,0},"446BA6",{material="Metal"})
        end
        for at=-100,100,20 do
            add("HarborPost",{0.45,2.8,0.45},{at,2.6,side*106},"FFFFFF")
            add("RailCap",{0.65,0.25,0.65},{at,4.1,side*106},"FFC34D")
            if math.abs(at)<90 then
                add("HarborPost",{0.45,2.8,0.45},{side*106,2.6,at},"FFFFFF")
                add("RailCap",{0.65,0.25,0.65},{side*106,4.1,at},"FFC34D")
            end
        end
    end
    local function lamp(x,z)
        cylinder("StreetLampBase",1.3,0.35,{x,1.55,z},"3555A5")
        cylinder("StreetLamp",0.35,7,{x,5,z},"3555A5")
        cylinder("LampCap",1.8,0.3,{x,8.7,z},"FFC34D")
        add("LampGlow",{1.05,1.1,1.05},{x,8,z},"FFF1C9",{shape="Ball",material="Neon",light=true,canCollide=false})
    end
    local function bench(x,z,yaw,color)
        local c,s=math.cos(yaw),math.sin(yaw)
        local function piece(name,size,dx,y,dz,tint)
            add(name,size,{x+c*dx+s*dz,y,z-s*dx+c*dz},tint,{rotation=A.rotation(yaw)})
        end
        piece("BenchSeat",{5.5,0.35,1.7},0,2.2,0,color)
        piece("BenchBack",{5.5,1.4,0.3},0,3.05,0.65,color)
        for _,side in ipairs({-1,1}) do piece("BenchLeg",{0.35,1,1.6},side*2.1,1.65,0,"355079") end
    end
    for _,side in ipairs({-1,1}) do
        for _,at in ipairs({-70,0,70}) do lamp(at,side*101) end
        for _,at in ipairs({-50,50}) do
            lamp(side*101,at)
            bench(at,side*98,side<0 and 0 or math.pi,side<0 and "B8ACFF" or "FFAC8D")
            bench(side*98,at,side*math.pi/2,"76D8CD")
        end
    end
    -- A separate public downtown backs the player-owned waterfront lots.
    round("DowntownIsland",{248,9,45},{0,-3.55,-131},5,"D6E4ED")
    add("DowntownRoad",{235,0.12,10},{0,1.03,-113},"647EA5")
    for x=-112,112,14 do add("DowntownLane",{6,0.05,0.22},{x,1.12,-113},"FFF5D9") end
    local blocks={
        {-102,3,"B6A4F2","ARTS"},{-74,4,"6DCBD7","HARBOR"},{-45,3,"FFA98B","BAKERY"},
        {-16,5,"82B9F1","CITY HALL"},{16,4,"8CD7AD","LIBRARY"},{45,3,"F49DB9","CAFE"},
        {74,5,"8E9EEA","CITY HOTEL"},{102,3,"FFC96C","MARKET"},
    }
    for _,block in ipairs(blocks) do
        local x,floors,color,title=table.unpack(block)
        local h=floors*5.8
        add("CivicFoundation",{20,0.5,17},{x,1.5,-135},"FFFFFF")
        add("CivicBuilding",{17,h,13},{x,1.8+h/2,-135},color)
        for floor=1,floors do
            local y=1.8+(floor-0.5)*5.8
            add("CivicCornice",{18,0.35,14},{x,1.8+floor*5.8,-135},"FFF9EA")
            for column=-1,1 do
                add("CivicWindow",{3.8,3.4,0.16},{x+column*5,y,-128.4},"BCEBFA",{material="Glass"})
                add("CivicWindowSill",{4.3,0.28,0.7},{x+column*5,y-1.85,-128.1},"FFFFFF")
                add("WindowMullion",{0.14,3.4,0.22},{x+column*5,y,-128.25},"FFFFFF")
            end
        end
        add("CivicRoof",{18.5,0.6,14.5},{x,h+2.2,-135},"3F618C")
        add("RooftopGarden",{12,0.2,8},{x,h+2.6,-135},"79CFA4")
        add("RoofLantern",{2,2.1,2},{x-5,h+3.7,-135},"FFF1BC",{material="Neon"})
        add("PublicShopSign",{14,1.6,0.3},{x,4.5,-128.1},"3555A5",{text=title,textFace="Back",textColor="FFFFFF",textSize=42})
        for stripe=-2,2 do add("PublicAwning",{3.7,0.3,3.1},{x+stripe*3.7,5.6,-127.1},stripe%2==0 and color or "FFFFFF",{rotation=A.rotation(0,math.rad(12),0)}) end
    end
    -- A bright ferry makes the waterfront read as a small, lived-in city.
    round("FerryPier",{10,1.3,25},{0,0.3,117},1.5,"E2BF8F",{material="WoodPlanks"})
    for _,x in ipairs({-4,4}) do for _,z in ipairs({110,122}) do cylinder("PierBollard",0.8,1.5,{x,1.8,z},"3555A5") end end
    local boatStart=#parts+1
    round("FerryHull",{10,2.2,22},{15,-0.9,119},3,"386BF0")
    round("FerryDeck",{9.3,0.7,20},{15,0.6,119},2.7,"FFFFFF")
    round("FerryCabin",{7,3.3,12},{15,2.5,118},1.4,"B6ECFA")
    round("FerryRoof",{8.5,0.6,14},{15,4.45,118},1.8,"FFC34D")
    for _,x in ipairs({11.4,18.6}) do for z=114,122,4 do add("FerryWindowFrame",{0.18,2,0.25},{x,2.6,z},"FFFFFF") end end
    add("FerryMast",{0.25,4,0.25},{15,6.4,117},"3555A5")
    add("FerryFlag",{2.2,1.2,0.15},{16,8,117},"FF8C9F")
    for index=boatStart,#parts do parts[index].position[2]=parts[index].position[2]-3.7 end
    return parts
end
return City
