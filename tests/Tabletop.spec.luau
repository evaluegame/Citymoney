local Config=require("../src/shared/Config")
local Engine=require("../src/shared/Engine")
local Flow=require("../src/shared/TurnFlow")
local Camera=require("../src/shared/BoardCamera")
local Layout=require("../src/shared/Layout")
local Architecture=require("../src/shared/Architecture")
local Board=require("../src/shared/Board")
local Dice=require("../src/shared/Dice")
local Plaza=require("../src/shared/Plaza")
local passed=0
local function check(value,message) assert(value,message or "Expected true") end
local function equal(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function near(a,b) check(math.abs(a-b)<1e-6,tostring(a).." not near "..tostring(b)) end
local function test(name,callback)
    local ok,message=pcall(callback);if not ok then error("FAIL "..name..": "..tostring(message),0) end
    passed=passed+1;print("PASS "..name)
end
local function game(count)
    local e=Engine.new(Config,function(low) return low end)
    local roster={}
    for id=1,count or 2 do table.insert(roster,{id=id,name="Resident "..id}) end
    check(e:start(roster));return e
end
local function own(e,index,id,level)
    local p=e.state.properties[index];p.ownerId,p.level=id,level or 0;return p
end
local sizes={{1337,720},{1192,642},{1192,610},{1920,1016},{1366,660},{800,560},{390,760},{430,840},{1024,680}}
local function assertFits(frame,rectangle,point)
    local x,y,depth=Camera.project(frame,point)
    check(depth>0,"Board is behind the camera")
    check(x>=rectangle[1]+9.9 and x<=rectangle[1]+rectangle[3]-9.9,"Board clips a horizontal HUD edge")
    check(y>=rectangle[2]+9.9 and y<=rectangle[2]+rectangle[4]-9.9,"Board clips a vertical HUD edge")
end
local function fitAll(elevation,inspector,zoom)
    for _,size in ipairs(sizes) do
        for _,inset in ipairs({0,36,58}) do
            local l=Layout.calculate(size[1],size[2])
            local r=Layout.board(l,inspector)
            local rect={r[1]*l.scale,r[2]*l.scale+inset,r[3]*l.scale,r[4]*l.scale}
            check(r[1]>=0 and r[2]>=0 and r[1]+r[3]<=l.width and r[2]+r[4]<=l.height,"Board rectangle leaves the safe area")
            for rotation=0,3 do
                local frame=Camera.fit(size[1],size[2]+inset,rect,rotation*math.pi/2,elevation,zoom)
                for _,x in ipairs({-88,88}) do for _,y in ipairs({0,32}) do for _,z in ipairs({-88,88}) do assertFits(frame,rect,{x,y,z}) end end end
                for index=1,24 do assertFits(frame,rect,Architecture.position(index)) end
            end
        end
    end
end
test("table camera keeps all 24 tiles and tall homes inside the safe board area",function() fitAll(math.rad(76),false,1) end)
test("city camera fits every rotation with the property inspector open",function() fitAll(math.rad(52),true,1) end)
test("zooming out preserves the complete board across desktop and portrait screens",function() fitAll(math.rad(76),true,1.4) end)
test("property closeups fit all levels without hiding beneath HUD panels",function()
    local l=Layout.calculate(1337,720);local rect=Layout.board(l,true)
    for index,tile in ipairs(Config.tiles) do if tile.kind=="property" then
        local p,yaw=Architecture.site(index)
        for level=0,3 do
            local bounds={min={p[1]-11,1,p[3]-11},max={p[1]+11,13+level*6,p[3]+11}}
            local frame=Camera.fit(1337,720,rect,yaw+math.rad(150),math.rad(40),1,bounds)
            for _,x in ipairs({bounds.min[1],bounds.max[1]}) do for _,y in ipairs({bounds.min[2],bounds.max[2]}) do for _,z in ipairs({bounds.min[3],bounds.max[3]}) do assertFits(frame,rect,{x,y,z}) end end end
        end
    end end
end)
test("the center contains functional plaza destinations instead of decorative trees and houses",function()
    local destinations={}
    for _,entry in ipairs(Board.generate(Config)) do
        check(entry.name~="TreeTrunk" and entry.name~="TreeCanopy" and string.sub(entry.name,1,5)~="Club_","Old central scenery remains")
        if entry.interaction then destinations[entry.interaction]=true end
    end
    for _,id in ipairs({"dice","market","festival","contracts","news"}) do check(destinations[id],"Missing interactive destination") end
end)
test("the editor and runtime share two complete clickable six-faced dice",function()
    local bodies,pips=0,0
    for _,entry in ipairs(Board.generate(Config)) do
        if entry.name=="DiceBody" then bodies=bodies+1;equal(entry.interaction,"dice") end
        if string.match(entry.name,"^Pip%d$") then pips=pips+1;equal(entry.interaction,"dice") end
    end
    equal(bodies,2);equal(pips,42)
end)
test("dice pips are correct and opposite faces sum to seven",function()
    for value,face in ipairs(Dice.faces) do
        equal(#Dice.pips[value],value)
        local other=Dice.faces[7-value]
        for axis=1,3 do near(face.normal[axis],-other.normal[axis]) end
    end
end)
test("every final dice pose displays the server's exact rolled value on top",function()
    for value=1,6 do for side=1,2 do for seq=1,8 do
        local p,r=Dice.pose(value,side,1,1,seq)
        local n=Dice.faces[value].normal
        near(r[1]*n[1]+r[2]*n[2]+r[3]*n[3],0)
        near(r[4]*n[1]+r[5]*n[2]+r[6]*n[3],1)
        near(r[7]*n[1]+r[8]*n[2]+r[9]*n[3],0)
        near(p[2],Dice.restHeight)
    end end end
end)
test("dice animation bounces above its tray and has finite orthonormal transforms",function()
    for value=1,6 do for step=0,60 do
        local p,r=Dice.pose(value,1,step/60,1,3)
        check(p[2]>=Dice.restHeight and p[2]<20)
        for a=0,2 do for b=0,2 do
            local dot=0;for c=1,3 do dot=dot+r[a*3+c]*r[b*3+c] end
            near(dot,a==b and 1 or 0)
        end end
    end end
end)
test("a new roll phase gets the full decision clock and lobbies do not advance",function()
    local e=game();local f=Flow.new(Config);f:observe(e.state,100)
    equal(f.deadline,155);equal(f.handoffAt,0);equal(f:due(e.state,154),nil);equal(f:due(e.state,155),"Roll")
    e.state.status="lobby";f:observe(e.state,160);equal(f.deadline,0);equal(f:due(e.state,1000),nil)
end)
test("resolved turns automatically hand off after four seconds",function()
    local e=game();local f=Flow.new(Config);e.state.phase="end";f:observe(e.state,10)
    equal(f.handoffAt,14);equal(f:due(e.state,13.99),nil);equal(f:due(e.state,14),"End")
    check(e:act(1,f:due(e.state,14)));equal(e:current().id,2);equal(e.state.phase,"roll")
end)
test("unresolved purchases keep the full buying clock instead of handing off early",function()
    local e=game();local f=Flow.new(Config);e.state.phase,e.state.pendingTile="buy",2;f:observe(e.state,20)
    equal(f.handoffAt,0);equal(f:due(e.state,24),nil);equal(f:due(e.state,74.99),nil);equal(f:due(e.state,75),"Skip")
end)
test("both buying and passing begin an automatic handoff without another confirmation",function()
    for _,command in ipairs({"Buy","Skip"}) do
        local e=game();local f=Flow.new(Config);e.state.phase,e.state.pendingTile="buy",2;f:observe(e.state,0)
        check(e:act(1,command));f:observe(e.state,5);equal(f:due(e.state,9),"End")
    end
end)
test("rent, detention and city-news results all enter the same short handoff",function()
    for _,index in ipairs({2,10,19,4}) do
        local e=game();local f=Flow.new(Config);own(e,2,2);e:player(1).position=index;e:land(e:player(1));f:observe(e.state,50)
        equal(e.state.phase,"end");equal(f:due(e.state,54),"End")
    end
end)
test("cosmetic, menu, tactical and property updates cannot extend a completed turn",function()
    local e=game();local f=Flow.new(Config);e.state.phase="end";f:observe(e.state,10)
    own(e,2,1);check(e:act(1,"Paint",2));f:observe(e.state,12)
    check(e:playCard(1,"shield",2,nil,1));f:observe(e.state,13)
    equal(f.handoffAt,14);equal(f:due(e.state,14),"End")
end)
test("an old phase clock cannot act on a later player's turn",function()
    local e=game();local f=Flow.new(Config);e.state.phase="end";f:observe(e.state,0)
    check(e:act(1,"End"));equal(f:due(e.state,100),nil)
    f:observe(e.state,100);equal(f.deadline,155);equal(f.handoffAt,0)
end)
test("automatic handoff happens once and gives the next player a fresh roll clock",function()
    local e=game();local f=Flow.new(Config);e.state.phase="end";f:observe(e.state,0)
    check(e:act(1,f:due(e.state,4)));f:observe(e.state,4)
    equal(e.state.turnCount,2);equal(f:due(e.state,4),nil);equal(f.deadline,59)
end)
test("players can still finish immediately without waiting for the handoff countdown",function()
    local e=game();local f=Flow.new(Config);e.state.phase="end";f:observe(e.state,0)
    check(e:act(1,"End"));f:observe(e.state,1);equal(e:current().id,2);equal(f.handoffAt,0)
end)
test("automatic turns skip eliminated seats and stop after the game ends",function()
    local e=game(4);e:player(2).alive=false;e.state.phase="end"
    local f=Flow.new(Config);f:observe(e.state,0);check(e:act(1,f:due(e.state,4)));equal(e:current().id,3)
    e.state.status="finished";f:observe(e.state,5);equal(f.deadline,0);equal(f:due(e.state,1000),nil)
end)
test("200 complete 2/4-player games advance using the automatic phase clock",function()
    for seed=1,200 do
        local randomSeed=seed
        local e=Engine.new(Config,function(low,high) randomSeed=(randomSeed*48271)%2147483647;return low+randomSeed%(high-low+1) end)
        local roster={};for id=1,seed%2==0 and 2 or 4 do table.insert(roster,{id=id,name="Resident "..id}) end
        check(e:start(roster));local f=Flow.new(Config);local now=0
        for _=1,700 do
            if e.state.status=="finished" then break end
            f:observe(e.state,now)
            local current=e:current()
            if e.state.phase=="buy" then
                local index=e.state.pendingTile;local cost=Config.tiles[index].price
                check(e:act(current.id,current.cash>=cost+150 and "Buy" or "Skip"))
            else
                now=e.state.phase=="end" and f.handoffAt or f.deadline
                local command,argument=f:due(e.state,now)
                check(e:act(current.id,command,argument))
            end
            for _,player in ipairs(e.state.players) do check(player.cash>=0) end
        end
        equal(e.state.status,"finished")
    end
end)
test("the market charges the listed game-cash price and delivers the chosen card",function()
    local e=game();local count=e:player(1).cards.shield
    check(e:act(1,"Plaza",{shop="market",kind="shield",turn=1}))
    equal(e:player(1).cash,1500-Config.cityMarket.shield);equal(e:player(1).cards.shield,count+1);check(e.state.plazaUsed)
end)
test("malformed, stale and out-of-turn market requests spend nothing",function()
    local e=game()
    for _,request in ipairs({{},false,"market",{shop="market",kind="shield",turn=0},{shop="market",kind="fake",turn=1},{shop="hack",turn=1}}) do check(not e:act(1,"Plaza",request)) end
    check(not e:act(2,"Plaza",{shop="market",kind="shield",turn=1}));equal(e:player(1).cash,1500);check(not e.state.plazaUsed)
end)
test("market hand caps and insufficient funds cannot consume a plaza purchase",function()
    local e=game();e:player(1).cards.shield=3;check(not e:act(1,"Plaza",{shop="market",kind="shield",turn=1}))
    e:player(1).cash=0;check(not e:act(1,"Plaza",{shop="market",kind="boost",turn=1}));check(not e.state.plazaUsed)
end)
test("plaza purchases are made before rolling and cannot postpone the completed-turn handoff",function()
    local e=game();e.state.phase="end";local f=Flow.new(Config);f:observe(e.state,0)
    check(not e:act(1,"Plaza",{shop="market",kind="shield",turn=1}));f:observe(e.state,3);equal(f.handoffAt,4)
end)
test("festivals rotate predictably every eight turns and wrap around",function()
    local e=game()
    for turn=1,48 do
        e.state.turnCount=turn
        local event,remaining,index=Plaza.festival(Config,e.state)
        equal(event.id,Config.festivals[math.floor((turn-1)/8)%3+1].id);equal(index,math.floor((turn-1)/8)%3+1);equal(remaining,8-(turn-1)%8)
    end
end)
test("the lantern festival boosts the chosen home's next two rent collections",function()
    local e=game();local p=own(e,2,1)
    check(e:act(1,"Plaza",{shop="festival",tile=2,turn=1,festivalId="lantern"}))
    equal(p.boost,2);equal(e:rent(2),18);equal(e:player(1).cash,1420)
end)
test("the design fair adds exactly one level and updates the building challenge",function()
    local e=game();local p=own(e,2,1,1);e.state.turnCount=9
    check(e:act(1,"Plaza",{shop="festival",tile=2,turn=9,festivalId="renovation"}))
    equal(p.level,2);equal(e:player(1).cash,1390);equal(e:player(1).stats.upgrades,1)
end)
test("neighborhood-watch protection blocks a rival demolition once",function()
    local e=game();local p=own(e,2,1);e.state.turnCount=17
    check(e:act(1,"Plaza",{shop="festival",tile=2,turn=17,festivalId="safety"}))
    e.state.turn=2;e.state.turnCount=18;check(e:playCard(2,"demolish",2,nil,18))
    equal(p.ownerId,1);equal(p.shield,false)
end)
test("expired festivals, rival targets, stacked effects and maximum levels reject without a charge",function()
    local e=game();local p=own(e,2,1);own(e,8,2)
    check(not e:act(1,"Plaza",{shop="festival",tile=2,turn=1,festivalId="safety"}))
    for _,tile in ipairs({8,0,1,1.4,0/0,math.huge,"2",{}}) do check(not e:act(1,"Plaza",{shop="festival",tile=tile,turn=1,festivalId="lantern"})) end
    p.boost=2;check(not e:act(1,"Plaza",{shop="festival",tile=2,turn=1,festivalId="lantern"}))
    e.state.turnCount=9;p.level=3;check(not e:act(1,"Plaza",{shop="festival",tile=2,turn=9,festivalId="renovation"}))
    equal(e:player(1).cash,1500);check(not e.state.plazaUsed)
end)
test("one plaza purchase is separate from the tactical allowance and resets next turn",function()
    local e=game();own(e,2,1)
    check(e:act(1,"Plaza",{shop="market",kind="shield",turn=1}));check(e:playCard(1,"shield",2,nil,1))
    check(not e:act(1,"Plaza",{shop="market",kind="boost",turn=1}))
    e.state.phase="end";check(e:act(1,"End"));check(not e.state.plazaUsed)
    check(e:act(2,"Plaza",{shop="market",kind="boost",turn=2}))
end)
test("bots choose a valid affordable festival target and respect the plaza allowance",function()
    local e=game();own(e,2,1);own(e,24,1,2)
    local offer=Plaza.botMove(e,1);equal(offer.tile,24);check(e:act(1,"Plaza",offer));equal(Plaza.botMove(e,1),nil)
    local poor=game();own(poor,2,1);poor:player(1).cash=100;equal(Plaza.botMove(poor,1),nil)
end)
print("\n"..passed.." tabletop/camera/dice/automatic-turn/plaza tests passed, including 200 automatic matches.")
