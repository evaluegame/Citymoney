local P=require("../src/shared/Presentation")
local Layout=require("../src/shared/Layout")
local Camera=require("../src/shared/BoardCamera")
local Config=require("../src/shared/Config")
local A=require("../src/shared/Architecture")
local Art=require("../src/shared/CityArt")
local Board=require("../src/shared/Board")
local Dice=require("../src/shared/Dice")
local passed=0
local function check(value,message) assert(value,message or "Expected true") end
local function test(name,callback)
    local ok,message=pcall(callback);if not ok then error("FAIL "..name..": "..tostring(message),0) end
    passed=passed+1;print("PASS "..name)
end
local function luminance(hex)
    local result=0
    for i,weight in ipairs({0.2126,0.7152,0.0722}) do
        local v=tonumber(string.sub(hex,i*2-1,i*2),16)/255
        result=result+(v<=0.04045 and v/12.92 or ((v+0.055)/1.055)^2.4)*weight
    end
    return result
end
local function contrast(a,b) local x,y=luminance(a),luminance(b);return (math.max(x,y)+0.05)/(math.min(x,y)+0.05) end
local screens={{1440,900},{1192,642},{800,560},{390,760}}
test("primary controls and text have strong light-theme contrast",function()
    check(contrast(P.colors.gold,P.colors.ink)>7)
    check(contrast(P.colors.green,P.colors.white)>4)
    check(contrast(P.colors.card,P.colors.muted)>4)
end)
test("the menu and turn dock do not overlap on desktop or portrait screens",function()
    for _,screen in ipairs(screens) do
        local l=Layout.calculate(table.unpack(screen));local a,b=l.menu,l.toolbar
        local overlapX=math.max(0,math.min(a[1]+a[3],b[1]+b[3])-math.max(a[1],b[1]))
        local overlapY=math.max(0,math.min(a[2]+a[4],b[2]+b[4])-math.max(a[2],b[2]))
        check(overlapX*overlapY==0,"Menu covers the action dock")
    end
end)
test("all HUD regions remain inside the safe area",function()
    for _,screen in ipairs(screens) do
        local l=Layout.calculate(table.unpack(screen))
        for _,r in ipairs({l.menu,l.toolbar,l.camera}) do
            check(r[1]>=0 and r[2]>=0 and r[1]+r[3]<=l.width and r[2]+r[4]<=l.height,"HUD rectangle is cropped")
        end
    end
end)
test("direct shortcuts fit below the roster and leave the board and turn controls clear",function()
    for _,screen in ipairs(screens) do for _,players in ipairs({2,4}) do
        local l=Layout.calculate(table.unpack(screen));local rosterHeight=44+players*54
        local q=P.shortcuts(l,rosterHeight);local board=Layout.board(l,false)
        check(q[1]>=0 and q[2]>=0 and q[1]+q[3]<=l.width and q[2]+q[4]<=l.height)
        if l.compact then
            check(q[2]+q[4]<board[2],"Shortcuts cover the board")
            check(q[4]*l.scale>=44,"Event shortcut is too small for touch")
        else
            check(q[2]>l.roster[2]+rosterHeight+32,"Shortcuts cover the player list")
            check(q[2]+q[4]<l.toolbar[2] and q[1]+q[3]<board[1],"Shortcuts overlap play controls")
        end
    end end
end)
test("rounded platforms have no overlapping coplanar rectangular top surfaces",function()
    for _,size in ipairs({{181,5,181},{23,0.6,21},{40,0.45,28},{3.8,1.2,6.4}}) do
        local parts=Art.rounded("Platform",size,{0,0,0},math.min(size[1],size[3])*0.15,"FFFFFF")
        for i,a in ipairs(parts) do for j,b in ipairs(parts) do if j>i and not a.shape and not b.shape then
            local dx=math.min(a.position[1]+a.size[1]/2,b.position[1]+b.size[1]/2)-math.max(a.position[1]-a.size[1]/2,b.position[1]-b.size[1]/2)
            local dz=math.min(a.position[3]+a.size[3]/2,b.position[3]+b.size[3]/2)-math.max(a.position[3]-a.size[3]/2,b.position[3]-b.size[3]/2)
            check(dx<=1e-6 or dz<=1e-6,"Coplanar tops would flicker")
        end end end
        for _,part in ipairs(parts) do if part.shape=="Cylinder" then check(part.position[2]+part.size[1]/2<size[2]/2) end end
    end
end)
test("rounded dice have curved edges and corners while retaining all 21 face pips",function()
    local edges,corners,pips=0,0,0
    for _,part in ipairs(Dice.mesh("FFFFFF","224377")) do
        if part.name=="DiceEdge" then edges=edges+1 end
        if part.name=="DiceCorner" then corners=corners+1 end
        if string.match(part.name,"^Pip") then
            pips=pips+1
            check(part.shape=="Cylinder" and part.size[1]<0.2 and part.size[2]>=1,"Pips must be large, flat face markings")
            local r=part.rotation or {1,0,0,0,1,0,0,0,1}
            local normal=Dice.faces[tonumber(string.match(part.name,"%d"))].normal
            check(math.abs(math.abs(r[1]*normal[1]+r[4]*normal[2]+r[7]*normal[3])-1)<1e-6,"Pip disc is sideways")
        end
    end
    check(Dice.size>=8 and edges==12 and corners==8 and pips==21)
end)
test("enlarged dice and flat pips stay above the tray throughout the complete tumble",function()
    local identity={1,0,0,0,1,0,0,0,1}
    for value=1,6 do for step=0,60 do
        local p,r=Dice.pose(value,1,step/60,1,3)
        for _,part in ipairs(Dice.mesh("FFFFFF","224377")) do
            local a=part.rotation or identity
            local y={r[4]*a[1]+r[5]*a[4]+r[6]*a[7],r[4]*a[2]+r[5]*a[5]+r[6]*a[8],r[4]*a[3]+r[5]*a[6]+r[6]*a[9]}
            local half
            if part.shape=="Ball" then half=part.size[1]/2
            elseif part.shape=="Cylinder" then half=math.abs(y[1])*part.size[1]/2+math.sqrt(y[2]^2+y[3]^2)*part.size[2]/2
            else half=(math.abs(y[1])*part.size[1]+math.abs(y[2])*part.size[2]+math.abs(y[3])*part.size[3])/2 end
            local center=p[2]+r[4]*part.position[1]+r[5]*part.position[2]+r[6]*part.position[3]
            check(center-half>=2.175-1e-6,"The die intersects the felt while tumbling")
        end
    end end
end)
test("unowned properties stay empty and show only a priced lot",function()
    for index,tile in ipairs(Config.tiles) do if tile.kind=="property" then
        local sale=false
        for _,part in ipairs(A.property(Config,index,false,tile.group,0,0)) do
            check(not part.door and part.name~="OwnerFlag" and part.name~="OwnerSign")
            check(string.sub(part.name,1,8)~="Display_" and part.name~="BackWall" and part.name~="FrontRoof" and part.name~="Floor","An unbought home is visible")
            check(part.position[2]+part.size[2]/2<2.2,"An empty lot contains a tall object")
            if part.name=="SaleSign" then sale=string.find(part.text,"$"..tile.price,1,true)~=nil end
        end
        check(sale,"The empty lot has no price")
    end end
end)
test("owned homes retain wider facades, shutters and walkable doors at every level",function()
    for level=0,3 do
        local width,shutters,door=0,0,false
        for _,part in ipairs(A.property(Config,2,"Avery","FFC34D",level,0)) do
            if part.name=="Foundation" then width=part.size[1] end
            if part.name=="WindowShutter" then shutters=shutters+1 end
            if part.door then door=part.size[1]>=2.8 end
        end
        check(width>=13 and shutters>=4 and door)
    end
end)
local function corners(entry)
    local points={};local r=entry.rotation or {1,0,0,0,1,0,0,0,1}
    for _,x in ipairs({-entry.size[1]/2,entry.size[1]/2}) do for _,y in ipairs({-entry.size[2]/2,entry.size[2]/2}) do for _,z in ipairs({-entry.size[3]/2,entry.size[3]/2}) do
        table.insert(points,{entry.position[1]+r[1]*x+r[2]*y+r[3]*z,entry.position[2]+r[4]*x+r[5]*y+r[6]*z,entry.position[3]+r[7]*x+r[8]*y+r[9]*z})
    end end end
    return points
end
test("the default camera uses the full available height instead of leaving an empty band",function()
    local l=Layout.calculate(1440,900);local r=Layout.board(l,false)
    local rect={r[1]*l.scale,r[2]*l.scale,r[3]*l.scale,r[4]*l.scale}
    local bounds=Camera.cityBounds(Config,A)
    local frame=Camera.fit(1440,900,rect,P.defaultYaw,P.defaultElevation,1,bounds)
    local low,high=math.huge,-math.huge
    for _,p in ipairs(bounds.points) do local _,y=Camera.project(frame,p);low=math.min(low,y);high=math.max(high,y) end
    check(math.abs(low-rect[2]-10)<0.01 and math.abs(high-rect[2]-rect[4]+10)<0.01,"Camera wastes vertical board space")
end)
test("cinematic framing includes the complete city and every fully upgraded property",function()
    local points={}
    for _,entry in ipairs(Board.generate(Config)) do if entry.name~="Sea" then for _,p in ipairs(corners(entry)) do table.insert(points,p) end end end
    for index,tile in ipairs(Config.tiles) do if tile.kind=="property" then
        for _,entry in ipairs(A.property(Config,index,"Owner","FFC34D",3,0)) do for _,p in ipairs(corners(entry)) do table.insert(points,p) end end
    end end
    for _,screen in ipairs(screens) do for _,inspector in ipairs({false,true}) do
        local l=Layout.calculate(table.unpack(screen));local r=Layout.board(l,inspector)
        local rect={r[1]*l.scale,r[2]*l.scale,r[3]*l.scale,r[4]*l.scale}
        local frame=Camera.fit(screen[1],screen[2],rect,P.defaultYaw,P.defaultElevation,1,Camera.cityBounds(Config,A))
        for _,p in ipairs(points) do
            local x,y,z=Camera.project(frame,p)
            check(z>0 and x>=rect[1]-0.1 and x<=rect[1]+rect[3]+0.1 and y>=rect[2]-0.1 and y<=rect[2]+rect[4]+0.1,"Visible city geometry crosses the HUD")
        end
    end end
end)
test("the initial city and a fully owned city stay within the geometry budget",function()
    local scene=Board.generate(Config);check(#scene<3000)
    local ownedCount=0
    for _,entry in ipairs(scene) do if not entry.tileIndex or Config.tiles[entry.tileIndex].kind~="property" then ownedCount=ownedCount+1 end end
    for index,tile in ipairs(Config.tiles) do if tile.kind=="property" then ownedCount=ownedCount+#A.property(Config,index,"Owner","FFC34D",3,0) end end
    check(ownedCount<5500,"City geometry exceeded its budget")
end)
print("\n"..passed.." presentation/geometry/readability tests passed.")
