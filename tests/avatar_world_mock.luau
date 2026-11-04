--!nocheck
-- Actual World methods with controlled body sizes; native rig rendering still
-- needs Studio. In particular R6 and R15 use different standing-height rules.
return function(sources)
 local passed=0
 local function test(name,fn)
  local ok,message=pcall(fn);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
 end
 local function v(x,y,z)
  return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},{__add=function(a,b) return v(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end})
 end
 local function cf(x,y,z)
  return setmetatable({Position=type(x)=='table' and x or v(x,y,z)},{__mul=function(a,b) return cf(a.Position+b.Position) end})
 end
 local shared={}
 for path in pairs(sources) do if string.find(path,'src/shared/',1,true) then shared[string.match(path,'([^/]+)%.lua$')]={source=path,Parent=shared} end end
 local modules={DiceWorld={},WorldEffects={}}
 local env={Vector3={new=v,zero=v()},CFrame={new=cf,Angles=function() return cf() end},Enum={HumanoidDisplayDistanceType={None='None'}},game={GetService=function(_,name)
  if name=='ReplicatedStorage' then return {WaitForChild=function() return shared end} end
  return {}
 end}}
 local cache={}
 local function load(module)
  if module==shared.Scene or module==modules.DiceWorld or module==modules.WorldEffects then return {} end
  if cache[module] then return cache[module] end
  local scope=setmetatable({script=module},{__index=env});local fn=assert(loadstring(sources[module.source],'@'..module.source));setfenv(fn,scope)
  local value=fn();cache[module]=value;return value
 end
 setmetatable(env,{__index=getfenv()});env.require=load
 local World=load({source='src/server/World.lua',Parent=modules})
 local Config,A,Actors=load(shared.Config),load(shared.Architecture),load(shared.Actors)
 local function character(rig)
  local model={attrs={},parts={},Parent=true,scaleCalls=0}
  function model:FindFirstChild(name) for _,part in ipairs(self.parts) do if part.Name==name and part.Parent then return part end end;return nil end
  function model:WaitForChild(name) return self:FindFirstChild(name) end
  function model:FindFirstChildOfClass(name) return self:FindFirstChild(name) end
  function model:GetDescendants() return table.clone(self.parts) end
  function model:SetAttribute(k,value) self.attrs[k]=value end
  function model:GetAttribute(k) return self.attrs[k] end
  function model:PivotTo(frame) self.pivot=frame end
  function model:add(name,size,class)
   local part={Name=name,ClassName=class or 'BasePart',Size=size or v(1,1,1),Parent=self}
   function part:IsA(kind) return kind==self.ClassName end
   function part:Destroy() self.Parent=nil end
   table.insert(self.parts,part);return part
  end
  model:add('HumanoidRootPart',v(2,2,1));model:add('Head',v(2,1,1))
  model:add(rig=='R6' and 'Torso' or 'UpperTorso',v(2,2,1))
  if rig=='R6' then model:add('Left Leg',v(1,2,1));model:add('Right Leg',v(1,2,1)) end
  local humanoid=model:add('Humanoid',nil,'Humanoid');humanoid.HipHeight=rig=='R6' and 0 or 2
  function model:ScaleTo(scale)
   self.scaleCalls=self.scaleCalls+1;self.scale=scale
   self:FindFirstChild('HumanoidRootPart').Size=v(2*scale,2*scale,scale)
   humanoid.HipHeight=(rig=='R6' and 0 or 2)*scale
   for _,name in ipairs({'Left Leg','Right Leg'}) do local leg=self:FindFirstChild(name);if leg then leg.Size=v(scale,2*scale,scale) end end
  end
  return model
 end
 local function harness(rig)
  local c=character(rig);local player={UserId=1,Character=c}
  function player:HasAppearanceLoaded() return self.appearanceLoaded~=false end
  local w=setmetatable({config=Config,visiting={},tokens={[1]=c},positions={[1]=2},motions={},generations={},state={players={{id=1}}},syncs=0},World)
  function w:sync() self.syncs=self.syncs+1 end
  return w,player,c
 end
 test('native R6 and R15 feet stand above the board instead of sinking into it',function()
  for _,rig in ipairs({'R6','R15'}) do
   local w,p,c=harness(rig);w:prepareCharacter(p,c)
   assert(c:GetAttribute('CitymoneyPrepared') and c.scale==Config.boardAvatarScale)
   local frame=w:tokenFrame(2,1,c);local space=A.position(2)
   assert(math.abs(frame.Position.Y-space[2]-(3*Config.boardAvatarScale+0.2))<1e-6,'A body is buried in its space')
   assert(c:FindFirstChild('HumanoidRootPart').Anchored and c:FindFirstChild('Humanoid').WalkSpeed==0)
  end
 end)
 test('home visits restore normal body size and return to the enlarged board pawn',function()
  for _,rig in ipairs({'R6','R15'}) do
   local w,p,c=harness(rig);w:prepareCharacter(p,c)
   for _=1,3 do
    assert(w:visit(p,2));assert(c.scale==1 and not c:FindFirstChild('HumanoidRootPart').Anchored)
    local porch=A.porch(2);assert(math.abs(c.pivot.Position.Y-porch[2]-3)<1e-6)
    w:endVisit(1);assert(c.scale==Config.boardAvatarScale and c:FindFirstChild('HumanoidRootPart').Anchored)
    local spot=Actors.pose(2,1,3*Config.boardAvatarScale+0.2)
    assert(math.abs(c.pivot.Position.Y-spot[2])<1e-6)
   end
  end
 end)
 test('rescaling rebuilds adornments without enlarging names or leaving duplicate rings',function()
  local w,_,c=harness('R15')
  local ring=c:add('PlayerColorRing');local aura=c:add('ClubAura');local tag=c:add('ResidentTag',nil,'BillboardGui')
  c:SetAttribute('ClubStyle','gilded');w:scaleCharacter(c,Config.boardAvatarScale)
  assert(not ring.Parent and not aura.Parent and tag.Parent==c and c:GetAttribute('ClubStyle')==nil)
  w:scaleCharacter(c,Config.boardAvatarScale);assert(c.scaleCalls==1,'Snapshots repeatedly rescale the player')
 end)
 test('unfinished or superseded characters keep the full-body fallback available',function()
  for _,name in ipairs({'Head','UpperTorso','HumanoidRootPart'}) do
   local w,p,c=harness('R15');c:FindFirstChild(name):Destroy();w:prepareCharacter(p,c)
   assert(not c:GetAttribute('CitymoneyPrepared') and c.scaleCalls==0)
  end
  local w,p,c=harness('R15');p.Character=character('R6');w:prepareCharacter(p,c)
  assert(not c:GetAttribute('CitymoneyPrepared') and w.syncs==0)
  w,p,c=harness('R15');p.appearanceLoaded=false;w:prepareCharacter(p,c)
  assert(not c:GetAttribute('CitymoneyPrepared') and c.scaleCalls==0)
  assert(not w:visit(p,2),'An unfinished avatar replaced the full-body board pawn')
 end)
 return passed
end
