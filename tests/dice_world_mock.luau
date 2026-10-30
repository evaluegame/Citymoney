--!nocheck
-- Runs the actual DiceWorld adapter with a controlled heartbeat and model sink.
-- It tests coroutine ordering; native rendering/replication still need Studio.
return function(sources)
 local passed=0
 local function test(name,callback)
  local ok,message=pcall(callback);assert(ok,'FAIL '..name..': '..tostring(message))
  passed=passed+1;print('PASS '..name)
 end
 local function harness()
  local now,waiters,deferred,queued=0,{},{},{}
  local paused=false
  local function resume(thread) local ok,message=coroutine.resume(thread);assert(ok,message) end
  local function spawn(callback)
   local thread=coroutine.create(callback)
   if paused then table.insert(queued,thread) else resume(thread) end
   return thread
  end
  local heartbeat={Wait=function() table.insert(waiters,coroutine.running());coroutine.yield() end}
  local shared={}
  function shared:WaitForChild(name) return assert(self[name],name) end
  for path in pairs(sources) do if string.find(path,'src/shared/',1,true) then
   shared[string.match(path,'([^/]+)%.lua$')]={source=path,Parent=shared}
  end end
  local Scene={}
  function Scene.model(entries,name,root)
   local model={Name=name,Parent=root,parts={}}
   for _,entry in ipairs(entries) do
    local part={Name=entry.name,Color=entry.color,IsA=function(_,kind) return kind=='BasePart' end}
    table.insert(model.parts,part)
   end
   function model:FindFirstChild(name) for _,p in ipairs(self.parts) do if p.Name==name then return p end end;return nil end
   function model:GetChildren() return self.parts end
   function model:SetAttribute() end
   function model:PivotTo(frame) self.pivot=frame end
   return model
  end
  local cache={}
  local env={workspace={GetServerTimeNow=function() return now end},CFrame={new=function(...) return {...} end},Color3={fromHex=function(value) return value end},task={spawn=spawn,defer=function(callback) table.insert(deferred,callback) end}}
  env.game={GetService=function(_,name)
   if name=='RunService' then return {Heartbeat=heartbeat} end
   if name=='ReplicatedStorage' then return {WaitForChild=function() return shared end} end
   error(name)
  end}
  local function load(module)
   if module==shared.Scene then return Scene end
   if cache[module] then return cache[module] end
   local scope=setmetatable({script=module},{__index=env})
   local fn=assert(loadstring(assert(sources[module.source]),'@'..module.source));setfenv(fn,scope)
   local result=fn();cache[module]=result;return result
  end
  setmetatable(env,{__index=getfenv()});env.require=load
  local Config=load(shared.Config);local Native=load({source='src/server/DiceWorld.lua'})
  local world=Native.new({},Config)
  local ctx={world=world,config=Config,Flow=load(shared.TurnFlow),Engine=load(shared.Engine),Offers=load(shared.Opportunities)}
  function ctx:router(engine,flow)
   local source=sources['src/server/init.server.lua']
   local first=assert(string.find(source,'local function perform(',1,true))
   local last=assert(string.find(source,'\nmatcher=Matchmaker.new',first,true))
   local connect=assert(string.find(source,'action.OnServerEvent:Connect(',1,true))
   local after=assert(string.find(source,'\n-- A short server-owned clock',connect,true))
   local handler
   local result={published=0,errors={}}
   local scope=setmetatable({engine=engine,flow=flow,Config=Config,lastRequest={},
    os={clock=function() return now end},world={endVisit=function() end},
    parties={get=function() return {} end},matcher={},
    feedback={FireClient=function(_,_,message) table.insert(result.errors,message) end},
    publish=function() result.published=result.published+1;flow:observe(engine.state,now) end,
    action={OnServerEvent={Connect=function(_,callback) handler=callback end}},
   },{__index=env})
   local perform=assert(loadstring(string.sub(source,first,last-1)..'\nreturn perform'))
   setfenv(perform,scope);scope.perform=perform()
   local wire=assert(loadstring(string.sub(source,connect,after-1)))
   setfenv(wire,scope);wire()
   return handler,result
  end
  function ctx:advance(dt)
   now=now+dt
   local pending=waiters;waiters={}
   -- Run consumers first to expose an early-resume race if the barrier is wrong.
   for index=#pending,1,-1 do resume(pending[index]) end
   local callbacks=deferred;deferred={}
   for _,callback in ipairs(callbacks) do callback() end
  end
  function ctx:pause(value) paused=value end
  function ctx:release() local pending=queued;queued={};for _,thread in ipairs(pending) do resume(thread) end end
  function ctx:consumer(callback) local thread=coroutine.create(callback);resume(thread) end
  function ctx:now() return now end
  function ctx:rest(values)
   local Dice=load(shared.Dice)
   for side,model in ipairs(world.models) do
    local p,r=Dice.pose(values[side],side,1,1,self.world.seq)
    local expected={p[1],p[2],p[3],table.unpack(r)}
    for axis,value in ipairs(expected) do assert(math.abs(model.pivot[axis]-value)<1e-6,'Dice have not reached their final pose') end
   end
  end
  return ctx
 end
 local function state(seq) return {status='playing',turnCount=1,turn=1,phase='end',lastRoll={seq=seq or 1,turn=1,values={2,5},steps=7}} end
 test('native dice finish both models before any waiting mover is released',function()
  local c=harness();local s=state();assert(c.world:sync(s))
  local ready=false;c:consumer(function() ready=c.world:waitUntilSettled(1);if ready then c:rest(s.lastRoll.values) end end)
  c:advance(0.8);assert(not ready);c:advance(0.31);c:advance(0.02)
  assert(ready and c.world.settledAt>=c.config.diceSeconds)
 end)
 test('reduced motion settles exact faces before its completion callback',function()
  local c=harness();local s=state();local callback=false
  c.world.onSettled=function() callback=true end
  assert(c.world:sync(s,{visual=function() return 'classic',false end}))
  assert(c.world:waitUntilSettled(1));c:rest(s.lastRoll.values);assert(not callback)
  c:advance(0);assert(callback)
 end)
 test('a superseding native roll cancels the old mover and completion',function()
  local c=harness();local result=nil;local callbacks={}
  c.world.onSettled=function(seq) table.insert(callbacks,seq) end
  c.world:sync(state(1));c:consumer(function() result=c.world:waitUntilSettled(1) end)
  c:advance(0.2);c.world:sync(state(2));c:advance(0.2);assert(result==false)
  c:advance(1.2);c:advance(0.02);assert(#callbacks==1 and callbacks[1]==2)
 end)
 test('match reset cancels a waiting roll without leaking its callback into a new match',function()
  local c=harness();local result=nil;local calls=0
  c.world.onSettled=function() calls=calls+1 end
  c.world:sync(state());c:consumer(function() result=c.world:waitUntilSettled(1) end)
  c.world:sync({});c:advance(0.5);assert(result==false and calls==0)
  c.world:sync(state());c:advance(1.2);c:advance(0.02);assert(calls==1)
 end)
 test('late native dice completion retimes the real turn clock before movement can begin',function()
  local c=harness();local s=state();local flow=c.Flow.new(c.config);flow:observe(s,0)
  c.world.onSettled=function(seq,at) flow:diceSettled(s,seq,at) end
  c:pause(true);c.world:sync(s);c:advance(2);assert(not c.world.settledSeq)
  c:release();c:advance(0.02);c:rest(s.lastRoll.values)
  assert(flow.moveAt>=c.world.settledAt+c.config.diceResultSeconds)
  assert(not flow:allows(s,'End',flow.moveAt))
  assert(math.abs(flow.handoffAt-flow.journeyUntil-c.config.autoAdvanceSeconds)<1e-6)
 end)
 test('the real remote router accepts reward tables after arrival and rejects early or other-player choices',function()
  local c=harness();local e=c.Engine.new(c.config,function(low) return low end)
  assert(e:start({{id=1,name='Avery'},{id=2,name='Riley'}}))
  local p=e:player(1);p.stats.news=1;p.position=4;e:land(p)
  local flow=c.Flow.new(c.config);flow:observe(e.state,0);flow.journeyUntil=0.2;flow.journeyTurn=1
  local handle,result=c:router(e,flow);local a,b={UserId=1},{UserId=2}
  local request=c.Offers.request(e.state,1)
  handle(a,'Offer',request);assert(p.cash==1500 and #result.errors==1)
  c:advance(0.25);handle(b,'Offer',request);assert(p.cash==1500 and #result.errors==2)
  c:advance(0.25);handle(a,'Offer',request)
  assert(p.cash==1590 and e.state.phase=='end' and result.published==1,'The reward was discarded by the native index filter')
 end)
 return passed
end
