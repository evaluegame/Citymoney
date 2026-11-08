-- Actual World synchronization and clock code with injected native failures.
return function(sources)
 local passed=0
 local function test(name,callback)
  local ok,message=pcall(callback);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
 end
 local function harness()
  local c={builds={},effects=0}
  local shared={};for path in pairs(sources) do if string.find(path,'src/shared/',1,true) then shared[string.match(path,'([^/]+)%.lua$')]={source=path,Parent=shared} end end
  local modules={DiceWorld={},WorldEffects={}}
  local function model(parent)
   local m={Parent=parent,attrs={}}
   function m:SetAttribute(key,value) if c.failSetup then error('model configuration unavailable') end;self.attrs[key]=value end
   function m:FindFirstChild() return nil end
   function m:Destroy() self.Parent=nil;self.destroyed=true end
   return m
  end
  local scene={model=function(_,name,parent)
   if c.failBuild or c.failName==name then error('temporary model construction failure') end
   local m=model(parent);table.insert(c.builds,m);return m
  end,populate=function() c.effects=c.effects+1;if c.failEffects then error('temporary sign construction failure') end end}
  local root={FindFirstChild=function() return nil end}
  local tween={Create=function() return {Play=function() end} end}
  local env={workspace={GetServerTimeNow=function() return 0 end},game={GetService=function(_,name)
   if name=='ReplicatedStorage' then return {WaitForChild=function() return shared end} end
   if name=='TweenService' then return tween end
   return {GetPlayerByUserId=function() return nil end}
  end},Color3={fromHex=function(value) return value end},Vector3={new=function(...) return {...} end},TweenInfo={new=function() return {} end},
   Instance={new=function() return {Destroy=function(self) self.Parent=nil end} end},task={delay=function() end}}
  local cache={};local function load(module)
   if module==shared.Scene then return scene end
   if module==modules.DiceWorld then return {} end
   if module==modules.WorldEffects then return {reveal=function() end} end
   if cache[module] then return cache[module] end
   local scope=setmetatable({script=module},{__index=env});local fn=assert(loadstring(sources[module.source],'@'..module.source));setfenv(fn,scope)
   local result=fn();cache[module]=result;return result
  end
  setmetatable(env,{__index=getfenv()});env.require=load
  local Native=load({source='src/server/World.lua',Parent=modules});local config=load(shared.Config)
  c.old=model(root);c.view={key='old',model=c.old,ownerId=1,level=0}
  c.state={status='playing',turnCount=1,turn=1,lastRoll=false,players={{id=1,name='Avery',colorIndex=1,alive=false}},properties={[2]={ownerId=1,level=1,paint=0,shield=false,boost=0,rentTier=1}}}
  c.world=setmetatable({config=config,root=root,propertyViews={[2]=c.view},dice={sync=function() return false end},tokens={},positions={},visiting={},generations={}},Native)
  return c
 end
 test('a failed home rebuild preserves its previous model and leaves the change retryable',function()
  local c=harness();c.failBuild=true;assert(not pcall(c.world.sync,c.world,c.state))
  assert(c.view.model==c.old and c.old.Parent and c.view.key=='old')
  c.failBuild=false;c.world:sync(c.state)
  assert(c.view.model~=c.old and c.old.destroyed and c.view.key~='old')
 end)
 test('failed home configuration destroys the staged model without deleting the old home',function()
  local c=harness();c.failSetup=true;assert(not pcall(c.world.sync,c.world,c.state))
  assert(#c.builds==1 and c.builds[1].destroyed and not c.old.destroyed and c.view.model==c.old and c.view.key=='old')
  c.failSetup=false;c.world:sync(c.state);assert(c.view.model==c.builds[2] and c.view.model.Parent)
 end)
 test('a missing physical model is rebuilt even when ownership and level are unchanged',function()
  local c=harness();c.world:sync(c.state);local previous=c.view.model;previous.Parent=nil
  c.world:sync(c.state);assert(c.view.model~=previous and c.view.model.Parent and #c.builds==2)
 end)
 test('failed shield and rent signs retry without rebuilding or charging the house',function()
  local c=harness();c.world:sync(c.state);local home,oldKey=c.view.model,c.view.effectsKey
  c.state.properties[2].shield=true;c.failEffects=true
  assert(not pcall(c.world.sync,c.world,c.state));assert(c.view.effectsKey==oldKey and c.view.model==home)
  c.failEffects=false;c.world:sync(c.state)
  assert(c.view.effectsKey~=oldKey and c.view.model==home and #c.builds==1)
 end)
 test('a failed festival label does not cache an update that never appeared',function()
  local c=harness();c.failFestival=true
  c.world.festivalLabel={TextLabel=setmetatable({},{__newindex=function(self,key,value) if c.failFestival then error('label unavailable') end;rawset(self,key,value) end})}
  assert(not pcall(c.world.sync,c.world,c.state));assert(c.world.festivalTurn==nil)
  c.failFestival=false;c.world:sync(c.state)
  assert(c.world.festivalTurn==1 and c.world.festivalLabel.TextLabel.Text=='FESTIVAL\n$80')
 end)
 test('a broken home cannot prevent another property from updating',function()
  local c=harness();local other={Parent=c.world.root,Destroy=function(self) self.Parent=nil end}
  c.world.propertyViews[3]={key='old-other',model=other,ownerId=1,level=0}
  c.state.properties[3]={ownerId=1,level=1,paint=0,shield=false,boost=0,rentTier=1}
  c.failName='Property2';assert(not pcall(c.world.sync,c.world,c.state))
  assert(c.view.model==c.old and c.world.propertyViews[3].model~=other and c.world.propertyViews[3].model.Parent)
 end)
 test('a temporary clock error cannot stop future automatic turns',function()
  local source=sources['src/server/init.server.lua']
  local first=assert(string.find(source,'-- A short server-owned clock',1,true));local last=assert(string.find(source,'\nmatcher:start()',first,true))
  local ticks,turns,reports=0,0,0
  local scope=setmetatable({task={wait=function() ticks=ticks+1;if ticks>3 then error('STOP_TEST_CLOCK',0) end end,spawn=function(callback)
   local ok,message=pcall(callback);assert(not ok and message=='STOP_TEST_CLOCK',tostring(message))
  end},publisher={retry=function() if ticks==1 then error('transient error') end end,report=function(_,kind) assert(kind=='clock');reports=reports+1 end},
   engine={state={status='playing'},current=function() return {id=1,bot=false} end},workspace={GetServerTimeNow=function() return ticks end},
   flow={due=function() return 'End' end},perform=function(id,command) assert(id==1 and command=='End');turns=turns+1 end}, {__index=getfenv()})
  local fn=assert(loadstring(string.sub(source,first,last-1)));setfenv(fn,scope);fn()
  assert(turns==2 and reports==1)
 end)
 return passed
end
