--!nocheck
-- Actual Matchmaker with controlled native-service adapters and the real Engine.
-- Reserved teleports here are recorded calls, not live Roblox connections.
return function(sources)
 local passed=0
 local function test(name,fn)
  local ok,message=pcall(fn);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
 end
 local function copy(value)
  if type(value)~='table' then return value end
  local result={};for k,v in pairs(value) do result[k]=copy(v) end;return result
 end
 local function map()
  local m={rows={},sort={}}
  function m:GetAsync(key) return copy(self.rows[key]) end
  function m:SetAsync(key,value,_,sort) self.rows[key],self.sort[key]=copy(value),sort or 0 end
  function m:RemoveAsync(key) self.rows[key],self.sort[key]=nil,nil end
  function m:UpdateAsync(key,fn)
   if self.failUpdate then error('temporary update failure') end
   if self.beforeUpdate then local hook=self.beforeUpdate;self.beforeUpdate=nil;hook(self,key) end
   local value,sort=fn(copy(self.rows[key]),self.sort[key]);if value==nil then return nil end
   self.rows[key],self.sort[key]=copy(value),sort or 0;return copy(value)
  end
  function m:GetRangeAsync()
   local result={};for key,value in pairs(self.rows) do table.insert(result,{key=key,value=copy(value)}) end
   table.sort(result,function(a,b) return self.sort[a.key]<self.sort[b.key] end);return result
  end
  return m
 end
 local function harness(studio,reserved)
  local clock,guid,people,maps,teleports=0,0,{},{},{}
  local c={failTeleport=false,blocked={},changes=0}
  local shared={}
  for path in pairs(sources) do if string.find(path,'src/shared/',1,true) then shared[string.match(path,'([^/]+)%.lua$')]={source=path,Parent=shared} end end
  local players={GetPlayerByUserId=function(_,id) return people[id] end,GetPlayers=function() local list={};for _,p in pairs(people) do table.insert(list,p) end;return list end}
  local teleport={TeleportInitFailed={Connect=function() end},ReserveServerAsync=function() return 'test-only-code','test-private' end}
  function teleport:TeleportAsync(place,list,options)
   assert(place==123);table.insert(teleports,{users=list,data=options.data})
   if c.failTeleport then error('Controlled teleport failure') end
  end
  local env={game={PlaceId=studio and 0 or 123,JobId='test-public',PrivateServerId=reserved and 'test-private' or '',PrivateServerOwnerId=0,BindToClose=function() end,
   GetService=function(_,name)
    if name=='ReplicatedStorage' then return {WaitForChild=function() return shared end} end
    if name=='Players' then return players end
    if name=='RunService' then return {IsStudio=function() return studio==true end} end
    if name=='TeleportService' then return teleport end
    if name=='MemoryStoreService' then return {GetSortedMap=function(_,key) if not maps[key] then maps[key]=map() end;return maps[key] end} end
    if name=='HttpService' then return {GenerateGUID=function() guid=guid+1;return 'queue-'..guid end} end
    error(name)
   end},os={clock=function() return clock end,time=function() return math.floor(clock) end},task={spawn=function() end,wait=function(dt) clock=clock+dt end},
   Enum={SortDirection={Ascending='Ascending'}},Instance={new=function(class)
    assert(class=='TeleportOptions');return {SetTeleportData=function(self,data) self.data=data end}
   end}}
  local cache={};local function load(module)
   if cache[module] then return cache[module] end
   local scope=setmetatable({script=module},{__index=env});local fn=assert(loadstring(sources[module.source],'@'..module.source));setfenv(fn,scope)
   local value=fn();cache[module]=value;return value
  end
  setmetatable(env,{__index=getfenv()});env.require=load
  local config=load(shared.Config);c.engine=load(shared.Engine).new(config)
  local Native=load({source='src/server/Matchmaker.lua'})
  c.matcher=Native.new(config,{changed=function() c.changes=c.changes+1 end,canQueue=function(id) return not c.blocked[id] end,
   canStart=function() return c.engine.state.status~='playing' end,start=function(roster,rules) return c.engine:start(roster,rules) end})
  function c:add(id,join)
   local p={UserId=id,DisplayName='Resident '..id,join=join or {}}
   function p:GetJoinData() return self.join end;people[id]=p;return p
  end
  function c:party(ids,seats)
   local party=load(shared.Lobby).new(config);party.seats=seats
   for _,id in ipairs(ids) do c:add(id);assert(party:join(id,'Resident '..id));assert(party:setReady(id,true)) end
   return party
  end
  function c:ticket()
   local t={id='test-ticket',privateId='test-private',status='ready',seats=2,users={{id=1,name='One',colorIndex=1},{id=2,name='Two',colorIndex=2}}}
   c.matcher.tickets:SetAsync(t.id,t);return t
  end
  function c:advance(dt) clock=clock+dt end
  c.teleports=teleports
  return c
 end
 test('native two-player matchmaking starts the real engine with exactly two humans',function()
  local c=harness(true);local a,b=c:party({1},2),c:party({2},2)
  assert(c.matcher:enqueue(1,a));assert(c.matcher:enqueue(2,b));c.matcher:tickLocal()
  assert(c.engine.state.status=='playing' and #c.engine.state.players==2)
  for _,p in ipairs(c.engine.state.players) do assert(not p.bot and not c.matcher:isQueued(p.id)) end
 end)
 test('a failed cancellation stays queued until the backend acknowledges it',function()
  local c=harness(false);local party=c:party({1},2);assert(c.matcher:enqueue(1,party))
  local map=c.matcher.maps[2];local id=c.matcher.byPlayer[1];map.failUpdate=true
  assert(not c.matcher:cancel(1,false));assert(c.matcher:isQueued(1) and not map.rows[id].cancelled)
  map.failUpdate=false;assert(c.matcher:cancel(1,false));assert(not c.matcher:isQueued(1) and map.rows[id].cancelled)
 end)
 test('a match claimed during cancellation cannot be cancelled using a stale read',function()
  local c=harness(false);local party=c:party({1},2);assert(c.matcher:enqueue(1,party))
  local map=c.matcher.maps[2];local id=c.matcher.byPlayer[1]
  map.beforeUpdate=function(m,key) m.rows[key].matchId='claimed-match' end
  assert(not c.matcher:cancel(1,false));assert(c.matcher:isQueued(1) and not map.rows[id].cancelled)
 end)
 test('forced departures retry a failed queue cancellation before matching new groups',function()
  local c=harness(false);local party=c:party({1},2);assert(c.matcher:enqueue(1,party))
  local map=c.matcher.maps[2];local id=c.matcher.byPlayer[1];map.failUpdate=true
  assert(c.matcher:cancel(1,true));assert(not c.matcher:isQueued(1) and c.matcher.cancelPending[id])
  map.failUpdate=false;c.matcher:tickLive()
  assert(map.rows[id].cancelled and not c.matcher.cancelPending[id])
 end)
 test('native four-player matchmaking keeps two parties together with distinct colors',function()
  local c=harness(true);local a,b=c:party({1,2},4),c:party({3,4},4)
  assert(c.matcher:enqueue(1,a));assert(c.matcher:enqueue(3,b));c.matcher:tickLocal()
  assert(#c.engine.state.players==4);local colors={}
  for _,p in ipairs(c.engine.state.players) do assert(not p.bot and not colors[p.colorIndex]);colors[p.colorIndex]=true end
 end)
 test('native queues reject unready party members and players already in an active match',function()
  local c=harness(true);local party=c:party({1,2},2)
  assert(party:setReady(2,false));assert(not c.matcher:enqueue(1,party));assert(not c.matcher:isQueued(1))
  assert(party:setReady(2,true));c.blocked[2]=true;assert(not c.matcher:enqueue(1,party));assert(not c.matcher:isQueued(2))
 end)
 test('reserved matches require each player to present the validated match ticket',function()
  local c=harness(false,true);local ticket=c:ticket()
  local a=c:add(1,{TeleportData={citymoneyMatch=ticket.id}})
  local b=c:add(2,{TeleportData={citymoneyMatch='wrong-ticket'}})
  c.matcher:playerAdded(a);c.matcher:playerAdded(b);c.matcher:tickReserved()
  assert(c.engine.state.status=='lobby' and c.matcher.admitted[1] and not c.matcher.admitted[2])
  b.join={TeleportData={citymoneyMatch=ticket.id}};c.matcher:playerAdded(b);c.matcher:tickReserved()
  assert(c.engine.state.status=='playing' and #c.engine.state.players==2)
 end)
 test('a stranger cannot join a reserved match by copying its match identifier',function()
  local c=harness(false,true);local ticket=c:ticket();local stranger=c:add(99,{TeleportData={citymoneyMatch=ticket.id}})
  c.matcher:playerAdded(stranger)
  assert(not c.matcher.admitted[99] and c.matcher.ticket==nil and #c.teleports==1)
 end)
 test('an incomplete match retries failed lobby returns and cannot start after cancellation',function()
  local c=harness(false,true);local ticket=c:ticket();local a=c:add(1,{TeleportData={citymoneyMatch=ticket.id}})
  c.matcher:playerAdded(a);c.failTeleport=true;c:advance(61);c.matcher:tickReserved()
  assert(c.matcher.arrivalFailed and #c.teleports==1 and c.engine.state.status=='lobby')
  c:advance(11);c.matcher:tickReserved();assert(#c.teleports==2)
  local b=c:add(2,{TeleportData={citymoneyMatch=ticket.id}});c.matcher:playerAdded(b);c.matcher:tickReserved()
  assert(not c.matcher.admitted[2] and c.engine.state.status=='lobby')
 end)
 test('departures remove a reserved admission before a player can rejoin',function()
  local c=harness(false,true);local ticket=c:ticket();local a=c:add(1,{TeleportData={citymoneyMatch=ticket.id}})
  c.matcher:playerAdded(a);assert(c.matcher.admitted[1]);c.matcher:remove(1);assert(not c.matcher.admitted[1])
 end)
 return passed
end
