local Config=require('../src/shared/Config')
local Engine=require('../src/shared/Engine')
local Offers=require('../src/shared/Opportunities')
local Flow=require('../src/shared/TurnFlow')
local Board=require('../src/shared/Board')
local Plans=require('../src/shared/PropertyPlans')
local passed=0
local function test(name,fn)
 local ok,message=pcall(fn);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
end
local function game()
 local e=Engine.new(Config,function(low) return low end)
 assert(e:start({{id=1,name='Avery'},{id=2,name='Riley'}}));return e
end
local function land(e,index)
 local p=e:current();p.position=index;e:land(p);return p
end
local function total(player) local n=0;for _,v in pairs(player.cards) do n=n+v end;return n end
test('two dedicated card spaces cover all five tactics while all sixteen homes remain',function()
 local spaces,homes,kinds=0,0,{}
 for _,tile in ipairs(Config.tiles) do
  if tile.kind=='card' then spaces=spaces+1;assert(not tile.price and not tile.group);for _,kind in ipairs(tile.cardChoices) do kinds[kind]=true end end
  if tile.kind=='property' then homes=homes+1 end
 end
 assert(spaces==2 and homes==16 and #Config.tiles==24)
 for _,kind in ipairs(Config.cardTypes) do assert(kinds[kind],kind) end
 assert(Config.cityMarket==nil)
end)
test('landing on Tactic Cards opens a free choice without buying or changing news progress',function()
 local e=game();local p=land(e,4)
 assert(e.state.phase=='offer' and e.state.pendingOffer.kind=='cardSpace' and e.state.pendingOffer.tile==4)
 assert(p.cash==1500 and total(p)==5 and p.stats.news==0 and not e.state.properties[4].ownerId)
 local definition=Offers.definition(Config,e.state)
 assert(#definition.choices==3 and string.find(definition.choices[1].detail,'return the plot to the city',1,true))
 e.state.rules.attackMode='downgrade'
 assert(string.find(Offers.definition(Config,e.state).choices[1].detail,'Remove one level',1,true))
end)
test('demolition, shield and renovation choices each grant exactly the selected free card',function()
 for option,kind in ipairs({'demolish','shield','repair'}) do
  local e=game();local p=land(e,4);local old=p.cards[kind]
  assert(e:act(1,'Offer',Offers.request(e.state,option)))
  assert(p.cards[kind]==old+1 and total(p)==6 and p.cash==1500)
  assert(e.state.phase=='end' and e.state.lastOpportunity.fromCardSpace and e.state.lastOpportunity.card==kind)
 end
end)
test('Rent Cards offers rent demand or rent boost with no charge',function()
 for option,kind in ipairs({'collect','boost'}) do
  local e=game();local p=land(e,22)
  assert(#Offers.definition(Config,e.state).choices==2)
  assert(e:act(1,'Offer',Offers.request(e.state,option)))
  assert(p.cards[kind]==2 and p.cash==1500 and not e.state.properties[22].ownerId)
 end
end)
test('buying any home level gives only the purchased home and no bonus card',function()
 for level=0,3 do
  local e=game();local p=land(e,2);local count=total(p)
  assert(e:act(1,'Buy',2,level,1));assert(total(p)==count)
  assert(p.cash==1500-Plans.purchaseCost(Config,2,level))
 end
end)
test('the removed card market cannot sell or grant any card',function()
 local e=game();local p=e:current();local before=total(p)
 for _,kind in ipairs(Config.cardTypes) do
  assert(not e:act(1,'Plaza',{shop='market',kind=kind,turn=1}))
  assert(p.cash==1500 and total(p)==before and not e.state.plazaUsed)
 end
end)
test('clicking a card from elsewhere cannot create a landing reward',function()
 local e=game();assert(not e:act(1,'Offer',{turn=1,seq=1,option=1}))
 assert(e.state.phase=='roll' and total(e:current())==5)
end)
test('card-space plots cannot be bought or upgraded as property',function()
 local e=game();land(e,4)
 assert(not e:act(1,'Buy',4,0,1));assert(not e:act(1,'Upgrade',4,1,1))
 assert(Plans.purchaseCost(Config,4,0)==nil and e:rent(4)==0)
 assert(e:current().cash==1500 and not e.state.properties[4].ownerId)
end)
test('stale, malformed and out-of-range collection requests grant nothing',function()
 local e=game();local p=land(e,4);local seq=e.state.pendingOffer.seq
 for _,request in ipairs({false,{},'collect',{turn=0,seq=seq,option=1},{turn=1,seq=seq+1,option=1},{turn=1,seq=seq,option=4},{turn=1,seq=seq,option=-1},{turn=1,seq=seq,option=1.5},{turn=1,seq=seq,option=0/0},{turn=1,seq=seq,option=math.huge}}) do
  assert(not e:act(1,'Offer',request));assert(total(p)==5 and p.cash==1500)
 end
end)
test('opponents and spectators cannot collect the current player card',function()
 local e=game();land(e,4);local request=Offers.request(e.state,1)
 assert(not e:act(2,'Offer',request));assert(not e:act(99,'Offer',request))
 assert(total(e:player(1))==5 and total(e:player(2))==5)
end)
test('a landing can be claimed once and the next landing receives a fresh token',function()
 local e=game();local p=land(e,4);local request=Offers.request(e.state,1)
 assert(e:act(1,'Offer',request));assert(not e:act(1,'Offer',request));assert(p.cards.demolish==2)
 land(e,4);assert(not e:act(1,'Offer',request))
 assert(e:act(1,'Offer',Offers.request(e.state,1)));assert(p.cards.demolish==3)
end)
test('a full card type stays capped while another choice can be collected',function()
 local e=game();local p=land(e,4);p.cards.demolish=3
 assert(not e:act(1,'Offer',Offers.request(e.state,1)))
 assert(e:act(1,'Offer',Offers.request(e.state,2)));assert(p.cards.demolish==3 and p.cards.shield==2)
end)
test('players can continue without a card and cannot gain cash by declining',function()
 local e=game();local p=land(e,4);local count=total(p)
 assert(e:act(1,'Offer',Offers.request(e.state,0)))
 assert(e.state.phase=='end' and not e.state.pendingOffer and total(p)==count and p.cash==1500)
end)
test('AFK collection picks an available card when the first card is full',function()
 local e=game();local p=land(e,4);p.cards.demolish=3
 local flow=Flow.new(Config);flow:observe(e.state,100)
 local command,request=flow:due(e.state,155)
 assert(command=='Offer' and request.option==2);assert(e:act(1,command,request));assert(p.cards.shield==2)
end)
test('a completely full hand automatically continues and hands off the turn',function()
 local e=game();local p=land(e,4);for _,kind in ipairs(Config.cardTypes) do p.cards[kind]=3 end
 local flow=Flow.new(Config);flow:observe(e.state,100)
 local command,request=flow:due(e.state,155);assert(request.option==0)
 assert(e:act(1,command,request));flow:observe(e.state,155)
 assert(flow:due(e.state,159)=='End' and total(p)==15 and p.cash==1500)
end)
test('collection waits for the settled dice and movement then receives the full decision clock',function()
 local e=game();land(e,4)
 e.state.lastRoll={seq=1,turn=1,steps=3,from=1,landedTile=4,to=4,actorId=1}
 local flow=Flow.new(Config);flow:observe(e.state,100)
 assert(not flow:allows(e.state,'Offer',flow.journeyUntil-0.01))
 assert(flow:allows(e.state,'Offer',flow.journeyUntil))
 assert(math.abs(flow.deadline-flow.journeyUntil-55)<1e-6)
end)
test('bots choose usable cards and continue safely with a full hand',function()
 local e=game();local p=land(e,4);e.state.properties[2].ownerId=2
 assert(Offers.botChoice(e,1).option==1)
 for _,kind in ipairs(Config.cardTypes) do p.cards[kind]=3 end
 assert(Offers.botChoice(e,1).option==0)
 p.cards.repair=1;assert(Offers.botChoice(e,1).option==3)
end)
test('a roll reaches the physical card space without an extra random draw',function()
 local calls=0;local values={1,2};local e=Engine.new(Config,function() calls=calls+1;return values[calls] end)
 assert(e:start({{id=1,name='One'},{id=2,name='Two'}}));assert(e:act(1,'Roll'))
 assert(calls==2 and e:current().position==4 and e.state.lastRoll.to==4 and e.state.phase=='offer')
end)
test('card booths and their FREE labels are on the marked parcels',function()
 local plots,faces,labels={},{},{}
 for _,part in ipairs(Board.generate(Config)) do
  if part.name=='CardSpacePlatform' then plots[part.tileIndex]=true end
  if part.name=='BoardCardFace' then faces[part.tileIndex]=(faces[part.tileIndex] or 0)+1 end
  if part.name=='FreeCardPlaque' then labels[part.tileIndex]=true;assert(part.interaction=='cards') end
 end
 assert(plots[4] and plots[22] and labels[4] and labels[22] and faces[4]==3 and faces[22]==2)
 assert(Board.caption(Config,4)=='การ์ดกลยุทธ์\nการ์ดฟรี')
end)
print('\n'..passed..' physical-card-space cases passed.')
