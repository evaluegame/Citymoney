local Config=require("../src/shared/Config")
local Engine=require("../src/shared/Engine")
local Plans=require("../src/shared/PropertyPlans")
local passed=0
local function equal(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function check(value) assert(value,"Expected true") end
local function test(name,callback)
    local ok,message=pcall(callback)
    if not ok then error("FAIL "..name..": "..tostring(message),0) end
    passed=passed+1;print("PASS "..name)
end
local function game()
    local engine=Engine.new(Config,function(low) return low end)
    check(engine:start({{id=1,name="Buyer"},{id=2,name="Neighbor"}}))
    return engine
end
local function landed()
    local engine=game();check(engine:act(1,"Roll"));equal(engine.state.pendingTile,3)
    return engine
end

test("all four starting levels include land and selected building costs",function()
    for level=0,3 do
        local engine=landed()
        check(engine:act(1,"Buy",3,level,1))
        equal(engine.state.properties[3].level,level)
        equal(engine.state.properties[3].ownerId,1)
        equal(engine:player(1).cash,1500-(110+level*60))
        equal(engine:rent(3),16*Config.rentMultipliers[level+1])
        equal(engine:wealth(engine:player(1)),1500)
        equal(engine.state.phase,"end")
    end
end)
test("every property and starting level uses the same quote as the server",function()
    for index,tile in ipairs(Config.tiles) do
        if tile.kind=="property" then
            for level=0,3 do
                local engine=game()
                engine:player(1).position=index;engine:land(engine:player(1))
                local option=Plans.options(Config,engine.state,1,index,"buy")[level+1]
                check(option.available and option.affordable)
                check(engine:act(1,"Buy",index,level,1))
                equal(engine:player(1).cash,option.remaining)
                equal(engine:rent(index),option.rent)
                equal(option.cost,tile.price+level*tile.upgrade)
            end
        end
    end
end)
test("legacy buy defaults to the cottage without an explicit level",function()
    local engine=landed();check(engine:act(1,"Buy"))
    equal(engine.state.properties[3].level,0);equal(engine:player(1).cash,1390)
end)
test("an unaffordable starting villa changes neither ownership nor cash",function()
    local engine=landed();engine:player(1).cash=289
    check(not engine:act(1,"Buy",3,3,1))
    equal(engine:player(1).cash,289);equal(engine.state.properties[3].ownerId,false)
    equal(engine.state.phase,"buy")
end)
test("buying at exactly the selected price is allowed",function()
    local engine=landed();engine:player(1).cash=290
    check(engine:act(1,"Buy",3,3,1));equal(engine:player(1).cash,0)
    equal(engine.state.properties[3].level,3)
end)
test("malformed purchase levels are rejected without partial changes",function()
    for _,level in ipairs({-1,4,1.5,"3",false,true,{},0/0,math.huge,-math.huge}) do
        local engine=landed()
        check(not engine:act(1,"Buy",3,level,1))
        equal(engine:player(1).cash,1500);equal(engine.state.properties[3].ownerId,false)
    end
end)
test("purchase rejects other players, stale lots and stale turns",function()
    local engine=landed()
    check(not engine:act(2,"Buy",3,3,1))
    check(not engine:act(1,"Buy",2,3,1))
    check(not engine:act(1,"Buy",3,3,0))
    check(not engine:act(1,"Buy",3,3,"1"))
    equal(engine:player(1).cash,1500);equal(engine.state.properties[3].ownerId,false)
end)
test("duplicate purchase confirmations cannot charge twice",function()
    local engine=landed();check(engine:act(1,"Buy",3,2,1))
    local balance=engine:player(1).cash
    check(not engine:act(1,"Buy",3,2,1));equal(engine:player(1).cash,balance)
end)
test("one property can jump from cottage directly to grand villa",function()
    local engine=landed();check(engine:act(1,"Buy",3,0,1))
    check(engine:act(1,"Upgrade",3,3,1))
    equal(engine.state.properties[3].level,3);equal(engine:player(1).cash,1210)
    equal(engine:rent(3),160);equal(engine.state.properties[2].ownerId,false)
end)
test("later upgrades charge only the additional levels",function()
    local engine=landed();check(engine:act(1,"Buy",3,1,1))
    local before=engine:player(1).cash
    check(engine:act(1,"Upgrade",3,3,1))
    equal(before-engine:player(1).cash,120)
    equal(engine:wealth(engine:player(1)),1500)
end)
test("direct and sequential upgrades cost the same",function()
    local direct,sequential=landed(),landed()
    check(direct:act(1,"Buy",3,0,1));check(sequential:act(1,"Buy",3,0,1))
    check(direct:act(1,"Upgrade",3,3,1))
    for level=1,3 do check(sequential:act(1,"Upgrade",3,level,1)) end
    equal(direct:player(1).cash,sequential:player(1).cash)
    equal(direct:rent(3),sequential:rent(3))
end)
test("downgrades, identical levels and malformed upgrade targets are rejected",function()
    for _,level in ipairs({0,1,-1,4,1.2,"3",false,{},0/0,math.huge}) do
        local engine=landed();check(engine:act(1,"Buy",3,1,1))
        local cash=engine:player(1).cash
        check(not engine:act(1,"Upgrade",3,level,1))
        equal(engine:player(1).cash,cash);equal(engine.state.properties[3].level,1)
    end
end)
test("failed upgrades preserve the previous home, paint and cash",function()
    local engine=landed();check(engine:act(1,"Buy",3,1,1));check(engine:act(1,"Paint",3))
    engine:player(1).cash=119
    check(not engine:act(1,"Upgrade",3,3,1))
    equal(engine.state.properties[3].level,1);equal(engine.state.properties[3].paint,1)
    equal(engine:player(1).cash,119)
end)
test("upgrade rejects other owners and confirmations from an earlier turn",function()
    local engine=landed();check(engine:act(1,"Buy",3,0,1))
    check(not engine:act(2,"Upgrade",3,3,1))
    check(engine:act(1,"End"));check(engine:act(2,"Roll"));check(engine:act(2,"End"))
    equal(engine.state.turnCount,3)
    check(not engine:act(1,"Upgrade",3,3,1))
    check(engine:act(1,"Upgrade",3,3,3))
end)
test("quote cards identify current levels, added cost, affordability and remaining cash",function()
    local engine=landed();check(engine:act(1,"Buy",3,1,1));engine:player(1).cash=80
    local options=Plans.options(Config,engine.state,1,3,"upgrade")
    check(not options[1].available);check(options[2].current and not options[2].available)
    check(options[3].affordable);equal(options[3].cost,60);equal(options[3].remaining,20)
    check(not options[4].affordable);equal(options[4].cost,120);equal(options[4].remaining,-40)
    equal(options[4].rent,160)
end)
test("completing a district quotes the base-rent bonus before purchase",function()
    local engine=landed();engine.state.properties[2].ownerId=1
    local option=Plans.options(Config,engine.state,1,3,"buy")[1]
    equal(option.rent,32);check(engine:act(1,"Buy",3,0,1));equal(engine:rent(3),option.rent)
    check(engine:act(1,"Upgrade",3,2,1));equal(engine:rent(3),96)
    equal(engine:rent(2),24)
end)
test("selected high-level investments are included in resale",function()
    local engine=landed();check(engine:act(1,"Buy",3,3,1))
    local before=engine:player(1).cash
    check(engine:act(1,"Sell",3));equal(engine:player(1).cash-before,145)
    equal(engine.state.properties[3].level,0);equal(engine.state.properties[3].ownerId,false)
end)
test("selling another home refreshes an unaffordable upgrade quote",function()
    local engine=landed();check(engine:act(1,"Buy",3,0,1))
    engine.state.properties[2].ownerId=1;engine.state.properties[2].level=3;engine:player(1).cash=10
    check(not Plans.options(Config,engine.state,1,3,"upgrade")[3].affordable)
    check(engine:act(1,"Sell",2))
    check(Plans.options(Config,engine.state,1,3,"upgrade")[3].affordable)
    check(engine:act(1,"Upgrade",3,2,1));equal(engine.state.properties[3].level,2)
end)
print("\n"..passed.." purchase and upgrade tests passed.")
