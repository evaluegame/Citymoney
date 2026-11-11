local Recap=require('../src/shared/MatchRecap')
local Engine=require('../src/shared/Engine')
local Config=require('../src/shared/Config')
local passed=0
local function test(name,callback)
 local ok,message=pcall(callback);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
end
local function fixture()
 local e=Engine.new(Config);assert(e:start({{id=1,name='One',colorIndex=4},{id=2,name='Two',colorIndex=1}}));return e
end
test('the declared winner remains first even when another player has more cash',function()
 local e=fixture();e.state.winnerId=1;e:player(2).cash=9999
 local recap=Recap.build(Config,e.state);assert(recap.winner.id==1 and recap.rows[1].id==1)
end)
test('equal net worth follows match seats rather than chosen cosmetic colors',function()
 local e=fixture();local rows=Recap.build(Config,e.state).rows;assert(rows[1].id==1 and rows[2].id==2)
end)
test('the recap uses the actual home and rent-tier investment value',function()
 local e=fixture();e.state.properties[2].ownerId=1;e.state.properties[2].level=2;e.state.properties[2].rentTier=3
 local row=Recap.build(Config,e.state).rows[1]
 assert(row.netWorth==e:wealth(e:player(1)) and row.homes==1 and row.levels==2)
end)
test('sold and demolished homes do not remain in the final home count',function()
 local e=fixture();e.state.properties[2].ownerId=1;e:liquidate(e:player(1),2)
 local rows=Recap.build(Config,e.state).rows;for _,row in ipairs(rows) do assert(row.homes==0) end
end)
test('an eliminated resident does not outrank an active rival',function()
 local e=fixture();e:player(1).alive=false;e:player(1).cash=9999
 assert(Recap.build(Config,e.state).rows[1].id==2)
end)
test('awards come from recorded rent, construction and card statistics',function()
 local e=fixture();e:player(1).stats.upgrades=3;e:player(2).stats.rent=230;e:player(2).stats.tactics=2
 local awards=Recap.build(Config,e.state).awards
 assert(#awards==3 and awards[1].id==1 and awards[2].id==2 and awards[2].value==230 and awards[3].id==2)
end)
test('empty and early matches cannot fabricate a winner or an award',function()
 local empty=Recap.build(Config,{players={},properties={}});assert(not empty.winner and #empty.rows==0 and #empty.awards==0)
 local early=Recap.build(Config,fixture().state);assert(not early.winner and #early.awards==0)
end)
test('a six-player recap preserves private names, inventories and money',function()
 local e=Engine.new(Config);local roster={}
 for index=1,6 do table.insert(roster,{id=index,name=index==1 and 'READY' or ('Player '..index)}) end
 assert(e:start(roster));e.state.winnerId=3
 local cash=e:player(1).cash;local card=e:player(1).cards.demolish
 local recap=Recap.build(Config,e.state);assert(#recap.rows==6 and recap.rows[1].id==3)
 for _,row in ipairs(recap.rows) do if row.id==1 then assert(row.name=='READY') end end
 assert(e:player(1).cash==cash and e:player(1).cards.demolish==card and e.state.players[1].id==1)
end)
print('\n'..passed..' match-recap cases passed.')
