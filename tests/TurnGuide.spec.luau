local Guide=require('../src/shared/TurnGuide')
local Config=require('../src/shared/Config')
local Engine=require('../src/shared/Engine')
local Journey=require('../src/shared/Journey')
local passed=0
local function test(name,callback)
 local ok,message=pcall(callback);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
end
local function fixture()
 local e=Engine.new(Config);assert(e:start({{id=1,name='A'},{id=2,name='B'}}))
 return e,{game=e.state,journeyUntil=0}
end
test('the guide stays inactive outside a running match',function()
 assert(Guide.stage(Config,nil,0)==0);assert(Guide.stage(Config,{game={status='finished'}},0)==0)
end)
test('rolling and the settled result stay in the dice stage until movement starts',function()
 local _,data=fixture();local roll={turn=1,steps=4};data.game.lastRoll=roll;data.game.phase='buy'
 data.journeyUntil=100+Journey.duration(Config,roll);data.diceEndsAt=101.1;data.moveAt=101.5
 assert(Guide.stage(Config,data,100.2)==1);assert(Guide.stage(Config,data,101.3)==1)
end)
test('the guide does not invite a purchase before the pawn arrives',function()
 local _,data=fixture();local roll={turn=1,steps=12};data.game.lastRoll=roll;data.game.phase='buy'
 data.journeyUntil=100+Journey.duration(Config,roll);data.diceEndsAt=101.1;data.moveAt=101.5
 assert(Guide.stage(Config,data,102)==2);assert(Guide.stage(Config,data,data.journeyUntil)==3)
end)
test('both buying and free card collection use the choice stage',function()
 local _,data=fixture();for _,phase in ipairs({'buy','offer'}) do data.game.phase=phase;assert(Guide.stage(Config,data,10)==3) end
 data.game.phase='end';assert(Guide.stage(Config,data,10)==4)
end)
test('a stale previous-turn journey cannot hide the new players roll',function()
 local _,data=fixture();data.game.lastRoll={turn=0,steps=12};data.journeyUntil=1000
 assert(Guide.stage(Config,data,100)==1)
end)
test('new residents receive a first-home hint and low cash takes priority',function()
 local e=fixture();local state=e.state
 assert(Guide.tip(Config,state,1)=='Your first home starts on an empty property.')
 e:player(1).cash=100;assert(Guide.tip(Config,state,1)=='Keep cash for rent. Sell a home if you need funds.')
end)
test('card and district hints follow the residents real inventory',function()
 local e=fixture();e.state.properties[2].ownerId=1
 for _,kind in ipairs(Config.cardTypes) do e:player(1).cards[kind]=0 end
 assert(Guide.tip(Config,e.state,1)=='Complete a district pair to double its base rent.')
 e:player(1).cards.shield=1;assert(Guide.tip(Config,e.state,1)=='Cards and upgrades are optional before you roll.')
end)
test('all new guidance is translated while spectators get a safe hint',function()
 local Thai=require('../src/shared/Thai');local e=fixture()
 local values=table.clone(Guide.labels)
 table.insert(values,Guide.tip(Config,e.state,99));table.insert(values,Guide.tip(Config,e.state,1))
 e:player(1).cash=100;table.insert(values,Guide.tip(Config,e.state,1))
 for _,text in ipairs(values) do assert(Thai.text(text)~=text,text) end
end)
print('\n'..passed..' guided-turn cases passed.')
