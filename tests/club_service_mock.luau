--!nocheck
-- Executes the real Marketplace callback and reconciliation against controlled
-- Roblox service adapters. No Robux transaction takes place in this harness.
return function(sources)
 local passed=0
 local function test(name,fn)
  local ok,message=pcall(fn);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
 end
 local function harness(studio,passId)
  local clock,queued,checks,changed=0,{},0,0
  local c={owns=false,readyAt=nil,fail=false,present=true}
  local shared={}
  for path in pairs(sources) do if string.find(path,'src/shared/',1,true) then shared[string.match(path,'([^/]+)%.lua$')]={source=path,Parent=shared} end end
  local callback
  local marketplace={PromptGamePassPurchaseFinished={Connect=function(_,fn) callback=fn end}}
  function marketplace:UserOwnsGamePassAsync(id,asset)
   assert(id==1 and asset==12345);checks=checks+1
   if c.fail then error('Controlled Roblox outage') end
   return c.owns or c.readyAt and clock>=c.readyAt or false
  end
  local player={UserId=1}
  local store={GetAsync=function() return nil end,UpdateAsync=function(_,_,fn) return fn(nil) end}
  local env={game={PlaceId=studio and 0 or 100,BindToClose=function() end,GetService=function(_,name)
   if name=='ReplicatedStorage' then return {WaitForChild=function() return shared end} end
   if name=='MarketplaceService' then return marketplace end
   if name=='Players' then return {GetPlayerByUserId=function() return c.present and player or nil end} end
   if name=='RunService' then return {IsStudio=function() return studio==true end} end
   if name=='DataStoreService' then return {GetDataStore=function() return store end} end
   error(name)
  end},DateTime={now=function() return {UnixTimestampMillis=clock*1000} end},os={clock=function() return clock end},task={
   spawn=function(fn) table.insert(queued,fn) end,delay=function() end,
   wait=function(dt) clock=clock+dt;if c.onWait then c.onWait(clock) end end,
  }}
  local cache={};local function load(module)
   if cache[module] then return cache[module] end
   local scope=setmetatable({script=module},{__index=env});local fn=assert(loadstring(sources[module.source],'@'..module.source));setfenv(fn,scope)
   local result=fn();cache[module]=result;return result
  end
  setmetatable(env,{__index=getfenv()});env.require=load
  local config=table.clone(load(shared.Config));config.clubPassId=passId==nil and 12345 or passId
  local Club=load({source='src/server/ClubService.lua'})
  c.club=Club.new(config,function() changed=changed+1 end)
  c.record=c.club.profiles:begin(1);c.club.profiles:load(1,c.record);checks=0
  function c:finish(asset,purchased) callback(player,asset,purchased) end
  function c:runPurchase() local fn=table.remove(queued);assert(fn);fn() end -- Leave the perpetual autosave loop suspended.
  function c:checks() return checks end
  function c:changes() return changed end
  function c:queueCount() return #queued end
  function c:now() return clock end
  return c
 end
 test('native cancelled and unrelated purchase events make no entitlement requests',function()
  local c=harness();local count=c:queueCount()
  c:finish(12345,false);c:finish(999,true)
  assert(c:queueCount()==count and c:checks()==0 and c:changes()==1 and not c.record.ownsPass)
  assert(c.record.checkoutSequence==1 and c.record.checkoutResult=='cancelled')
 end)
 test('native delayed purchase verification retries until Roblox confirms ownership',function()
  local c=harness();c.readyAt=3;c:finish(12345,true);c:runPurchase()
  assert(c.record.ownsPass and not c.record.purchasePending and c:checks()==3 and c:now()==3)
  assert(c.club:snapshot(1).checkoutResult=='verified')
  assert(c.club.profiles:select(1,'rose',false))
 end)
 test('native verification failure never grants a paid style and leaves a recovery message',function()
  local c=harness();c.fail=true;c:finish(12345,true);c:runPurchase()
  assert(not c.record.ownsPass and not c.record.purchasePending and c:checks()==4 and c:now()==7)
  assert(not c.club.profiles:select(1,'gilded',true))
  assert(string.find(c.record.status,'Check ownership',1,true))
  c.fail=false;c.owns=true;assert(c.club:refresh(1));assert(c.record.ownsPass)
 end)
 test('duplicate native completions do not recheck or charge an already verified owner',function()
  local c=harness();c.owns=true;c:finish(12345,true);c:runPurchase()
  local calls=c:checks();c:finish(12345,true);c:runPurchase();assert(c:checks()==calls)
 end)
 test('a purchase arriving during profile loading waits before checking ownership',function()
  local c=harness();c.record.loading=true;c.readyAt=0.25
  c.onWait=function() c.record.loading=false end
  c:finish(12345,true);c:runPurchase()
  assert(c.record.ownsPass and not c.record.purchasePending and c:checks()==1)
 end)
 test('a departed buyer cannot overwrite a fresh profile during verification',function()
  local c=harness();local fresh
  c.onWait=function()
   c.onWait=nil;c.club.profiles:detach(1);fresh=c.club.profiles:begin(1)
   c.owns=true;c.club.profiles:load(1,fresh)
  end
  c:finish(12345,true);c:runPurchase()
  assert(c.club.profiles.records[1]==fresh and fresh.ownsPass and fresh.styleId=='classic')
 end)
 test('unconfigured and Studio passes never perform real entitlement verification',function()
  for _,c in ipairs({harness(false,0),harness(true,12345)}) do
   assert(not c.club:reconcile(1,12345));assert(c:checks()==0)
  end
 end)
 return passed
end
