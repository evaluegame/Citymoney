local Config=require("../src/shared/Config")
local Engine=require("../src/shared/Engine")
local Tactics=require("../src/shared/Tactics")
local Plans=require("../src/shared/PropertyPlans")
local passed=0
local function check(value) assert(value,"Expected true") end
local function equal(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function test(name,callback)
    local ok,message=pcall(callback);if not ok then error("FAIL "..name..": "..tostring(message),0) end
    passed=passed+1;print("PASS "..name)
end
local function game(mode,count)
    local engine=Engine.new(Config,function(low) return low end)
    local players={}
    for id=1,count or 2 do table.insert(players,{id=id,name="Resident "..id}) end
    check(engine:start(players,{attackMode=mode or "destroy"}))
    return engine
end
local function own(engine,index,id,level)
    local asset=engine.state.properties[index]
    asset.ownerId,asset.level=id,level or 0
    return asset
end

test("full demolition removes a selected rival home and its paid effects",function()
    local e=game();local asset=own(e,24,2,3);asset.rentTier,asset.boost,asset.paint=4,2,2
    own(e,23,2,1)
    check(e:playCard(1,"demolish",24,nil,1))
    equal(asset.ownerId,false);equal(asset.level,0);equal(asset.rentTier,1);equal(asset.boost,0)
    equal(e.state.properties[23].ownerId,2);equal(e:player(1).cards.demolish,0)
end)
test("a chosen property's shield blocks demolition once",function()
    local e=game();local asset=own(e,24,2,3);asset.shield=true
    check(e:playCard(1,"demolish",24,nil,1))
    equal(asset.ownerId,2);equal(asset.level,3);equal(asset.shield,false)
    check(e.state.lastAction.blocked);equal(e:player(2).stats.blocks,1)
end)
test("optional soft attacks remove one level and destroy cottages",function()
    local e=game("downgrade");local asset=own(e,8,2,2)
    check(e:playCard(1,"demolish",8,nil,1));equal(asset.level,1);equal(asset.ownerId,2)
    local second=game("downgrade");local cottage=own(second,8,2,0)
    check(second:playCard(1,"demolish",8,nil,1));equal(cottage.ownerId,false)
end)
test("wrong turn, stale turn, unknown cards and malformed targets spend nothing",function()
    local e=game();own(e,8,2,2)
    check(not e:playCard(2,"demolish",8,nil,1))
    check(not e:playCard(1,"demolish",8,nil,0))
    check(not e:playCard(1,"hack",8,nil,1))
    for _,index in ipairs({-1,0,25,1.4,"8",{},0/0,math.huge}) do check(not e:playCard(1,"demolish",index,nil,1)) end
    equal(e:player(1).cards.demolish,1);check(not e.state.actionUsed)
end)
test("only one card can be played each turn",function()
    local e=game();own(e,8,2,2);own(e,2,1,1)
    check(e:playCard(1,"demolish",8,nil,1))
    check(not e:playCard(1,"shield",2,nil,1));equal(e:player(1).cards.shield,1)
end)
test("card allowance resets on the next turn",function()
    local e=game();own(e,2,1);own(e,8,2,2)
    check(e:playCard(1,"shield",2,nil,1))
    e.state.phase="end";check(e:act(1,"End"))
    check(e:playCard(2,"demolish",2,nil,2));check(not e.state.properties[2].shield)
end)
test("unowned, own demolition and rival utility targets are rejected",function()
    local e=game();own(e,2,1);own(e,8,2)
    check(not e:playCard(1,"demolish",2,nil,1));check(not e:playCard(1,"demolish",3,nil,1))
    for _,kind in ipairs({"boost","shield","repair","collect"}) do check(not e:playCard(1,kind,8,2,1)) end
    check(not e.state.actionUsed)
end)
test("rent demand uses the chosen property and chosen opponent",function()
    local e=game(nil,3);own(e,2,1,1);own(e,24,1,3)
    check(e:playCard(1,"collect",2,3,1))
    equal(e:player(3).cash,1428);equal(e:player(2).cash,1500);equal(e:player(1).cash,1572)
end)
test("rent demands are capped and cannot target self or eliminated players",function()
    local e=game(nil,3);own(e,24,1,3)
    check(not e:playCard(1,"collect",24,1,1));check(not e:playCard(1,"collect",24,99,1))
    e:player(3).alive=false;check(not e:playCard(1,"collect",24,3,1))
    check(e:playCard(1,"collect",24,2,1));equal(e:player(2).cash,1500-Config.demandCap)
end)
test("rent demand handles debt liquidation and bankruptcy",function()
    local e=game();own(e,24,1,3);own(e,2,2,0);e:player(2).cash=5
    check(e:playCard(1,"collect",24,2,1))
    equal(e:player(1).cash,1550);check(not e:player(2).alive);equal(e.state.winnerId,1)
    equal(e.state.properties[2].ownerId,false)
end)
test("temporary rent boosts expire after exactly two paid visits",function()
    local e=game();local asset=own(e,2,1,0)
    check(e:playCard(1,"boost",2,nil,1));equal(e:rent(2),18);equal(asset.boost,2)
    e:player(2).position=2;e:land(e:player(2));equal(asset.boost,1);equal(e:player(1).cash,1518)
    e:land(e:player(2));equal(asset.boost,0);equal(e:rent(2),12);equal(e:player(1).cash,1536)
end)
test("shields and boosts cannot be wastefully stacked",function()
    local e=game();local asset=own(e,2,1);asset.shield=true;asset.boost=2
    check(not e:playCard(1,"shield",2,nil,1));check(not e:playCard(1,"boost",2,nil,1))
    check(not e.state.actionUsed)
end)
test("renovation grants upgrade chosen homes without charging cash",function()
    local e=game();local asset=own(e,2,1,1);own(e,3,1,3)
    check(not e:playCard(1,"repair",3,nil,1));check(e:playCard(1,"repair",2,nil,1))
    equal(asset.level,2);equal(e:player(1).cash,1500);equal(e:player(1).stats.upgrades,1)
end)
test("hands are capped and hidden from other players' snapshots",function()
    local e=game();Tactics.grant(e,e:player(1),"demolish",10)
    equal(e:player(1).cards.demolish,Config.cardLimit)
    local view=e:view(2);equal(next(view.players[1].cards),nil)
    check(view.players[2].cards.demolish~=nil);check(e:player(1).cards.demolish~=nil)
end)
test("challenges require an explicit claim and cannot be claimed twice per turn",function()
    local e=game();own(e,2,1);own(e,3,1)
    Tactics.refresh(e);check(e:player(1).challenge.ready);equal(e:player(1).cash,1500)
    check(e:act(1,"Claim",nil,nil,1));equal(e:player(1).cash,1640)
    check(not e:act(1,"Claim",nil,nil,1));equal(e:player(1).completedChallenges,1)
end)
test("losing a home invalidates an unclaimed ownership challenge",function()
    local e=game();own(e,2,1);local asset=own(e,3,1)
    Tactics.refresh(e);check(e:player(1).challenge.ready)
    Tactics.resetProperty(asset);check(not e:act(1,"Claim",nil,nil,1));equal(e:player(1).cash,1500)
end)
test("challenge changes charge once and enforce cash and turn",function()
    local e=game();check(not e:act(2,"NewGoal"))
    check(e:act(1,"NewGoal",nil,nil,1));equal(e:player(1).cash,1450)
    check(not e:act(1,"NewGoal",nil,nil,1));equal(e:player(1).cash,1450)
end)
test("paid rent tiers charge a fee and affect all future visits",function()
    local e=game();local asset=own(e,2,1,0)
    check(e:act(1,"SetRent",2,2,1));equal(e:player(1).cash,1380);equal(e:rent(2),18)
    e:player(2).position=2;e:land(e:player(2));equal(e:player(2).cash,1482)
    check(e:act(1,"SetRent",2,4,1));equal(e:player(1).cash,1158);equal(e:rent(2),36)
    equal(asset.rentTier,4)
end)
test("rent fees reject malformed, current, lower, stale and unaffordable choices",function()
    local e=game();own(e,2,1,0)
    for _,tier in ipairs({0,1,5,1.5,"2",{},0/0,math.huge}) do check(not e:act(1,"SetRent",2,tier,1)) end
    check(not e:act(2,"SetRent",2,2,1));check(not e:act(1,"SetRent",2,2,0))
    e:player(1).cash=119;check(not e:act(1,"SetRent",2,2,1));equal(e:player(1).cash,119)
end)
test("rental quotes match server fees and preserve the house level",function()
    local e=game();local asset=own(e,24,1,2)
    local options=Plans.options(Config,e.state,1,24,"rent")
    local target=options[3];check(target.affordable)
    check(e:act(1,"SetRent",24,3,1));equal(e:player(1).cash,target.remaining)
    equal(e:rent(24),target.rent);equal(asset.level,2)
end)
test("rent improvements are valued in wealth and resale",function()
    local e=game();own(e,2,1,1)
    check(e:act(1,"SetRent",2,4,1))
    equal(e:wealth(e:player(1)),1650)
    local cash=e:player(1).cash;check(e:act(1,"Sell",2))
    equal(e:player(1).cash-cash,255);equal(e.state.properties[2].rentTier,1)
end)
test("all city news events resolve safely and record challenge progress",function()
    for chosen=1,#Config.events do
        local e=game(nil,4);own(e,2,1,1)
        e.random=function(low,high) return high==#Config.events and chosen or low end
        e:player(1).position=4;e:land(e:player(1));equal(e:player(1).stats.news,1)
        for _,player in ipairs(e.state.players) do check(player.cash>=0);for _,count in pairs(player.cards) do check(count>=0 and count<=Config.cardLimit) end end
    end
end)
test("200 tactical 2/4-player matches terminate with valid economy and effects",function()
    math.randomseed(20261101)
    for match=1,200 do
        local e=Engine.new(Config);local roster={}
        for id=1,(match%2==0 and 2 or 4) do table.insert(roster,{id=id,name="Bot "..id}) end
        check(e:start(roster,{attackMode="destroy"}))
        local ticks=0
        while e.state.status=="playing" do
            local player=e:current()
            if player.alive then
                if player.challenge.ready and not e.state.challengeClaimed then check(e:act(player.id,"Claim",nil,nil,e.state.turnCount)) end
                local move=Tactics.botMove(e,player.id)
                if move then check(e:playCard(player.id,move.kind,move.tile,move.targetId,move.turn)) end
            end
            if e.state.status~="playing" then break end
            local phase=e.state.phase
            if phase=="roll" then check(e:act(player.id,"Roll"))
            elseif phase=="buy" then
                local index=e.state.pendingTile;local tile=Config.tiles[index]
                local level=math.random(0,3)
                if player.cash>=tile.price+level*tile.upgrade+100 then check(e:act(player.id,"Buy",index,level,e.state.turnCount)) else check(e:act(player.id,"Skip")) end
            else
                if player.alive then
                    for index,asset in ipairs(e.state.properties) do
                        if asset.ownerId==player.id and asset.level<3 and player.cash>Config.tiles[index].upgrade+200 then e:act(player.id,"Upgrade",index,asset.level+1) end
                        local fee=asset.ownerId==player.id and Plans.rentCost(Config,index,asset.rentTier,math.min(4,asset.rentTier+1)) or nil
                        if fee and player.cash>fee+400 then check(e:act(player.id,"SetRent",index,asset.rentTier+1)) end
                    end
                end
                check(e:act(player.id,"End"))
            end
            ticks=ticks+1;check(ticks<700)
            for _,resident in ipairs(e.state.players) do check(resident.cash>=0);for _,count in pairs(resident.cards) do check(count>=0 and count<=3) end end
            for _,asset in ipairs(e.state.properties) do
                check(asset.level>=0 and asset.level<=3);check(asset.rentTier>=1 and asset.rentTier<=4);check(asset.boost>=0 and asset.boost<=2)
                if asset.ownerId then check(e:player(asset.ownerId).alive) end
            end
        end
        check(e.state.winnerId~=false)
    end
end)
print("\n"..passed.." strategy/rent tests passed, including 200 complete tactical matches.")
