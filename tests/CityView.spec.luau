local Config=require('../src/shared/Config')
local Actors=require('../src/shared/Actors')
local Camera=require('../src/shared/BoardCamera')
local Layout=require('../src/shared/Layout')
local A=require('../src/shared/Architecture')
local City=require('../src/shared/CityScenery')
local Board=require('../src/shared/Board')
local passed=0
local function check(v,message) assert(v,message or 'Expected true') end
local function equal(a,b) check(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) check(math.abs(a-b)<1e-6,tostring(a)..' is not '..tostring(b)) end
local function test(name,callback)
 local ok,message=pcall(callback);if not ok then error('FAIL '..name..': '..tostring(message),0) end
 passed=passed+1;print('PASS '..name)
end
test('all six resident positions stay separated and within each rotated space',function()
 for index=1,24 do
  local seen={};local _,yaw=A.site(index)
  for seat=1,6 do
   local x,z=Actors.offset(seat,index)
   local lx,lz=math.cos(yaw)*x-math.sin(yaw)*z,math.sin(yaw)*x+math.cos(yaw)*z
   check(math.abs(lx)+2.2<9.4 and math.abs(lz)+2.2<5.7)
   for _,p in ipairs(seen) do check((x-p[1])^2+(z-p[2])^2>=4.4^2-1e-6) end
   table.insert(seen,{x,z})
  end
 end
end)
test('residents face their actual movement direction on every side and corner',function()
 for index=1,24 do
  local nextIndex=index%24+1
  local _,yaw=Actors.pose(nextIndex,1,2.3,index)
  local a,b=A.position(index),A.position(nextIndex)
  near(-math.sin(yaw)*(b[1]-a[1])/20-math.cos(yaw)*(b[3]-a[3])/20,1)
 end
end)
test('travel holds exact centers, crosses City Gate and reaches event destinations',function()
 local roll={from=22,steps=6,landedTile=4,to=1}
 for space=1,6 do
  local p=Actors.travel(Config,roll,2,(space-1)*Config.stepSeconds+0.32)
  local expected=Actors.pose((roll.from+space-1)%24+1,2)
  for axis=1,3 do near(p[axis],expected[axis]) end
 end
 local destination=Actors.travel(Config,roll,2,6*Config.stepSeconds)
 local expected=Actors.pose(1,2)
 for axis=1,3 do near(destination[axis],expected[axis]) end
end)
test('shared fallback residents have readable faces, clothing and owner colors',function()
 local names={}
 for _,entry in ipairs(Actors.figure('FFBE55')) do names[entry.name]=true;check(entry.canCollide==false) end
 for _,name in ipairs({'Torso','Head','Eye','Smile','Shirt','Tie','Shoe','LeftLeg','RightLeg','Briefcase'}) do check(names[name],name) end
 check(Config.avatarScale>=1,'Real avatars are still shrunk')
end)
test('board and city names have modest surface-text limits',function()
 for _,entry in ipairs(Board.generate(Config)) do
  if entry.name=="CityTitle" then check(entry.size[1]<=26 and entry.textSize<=40) end
  if string.match(entry.name,"^Tile%d+$") then check(entry.textSize<=60) end
  if entry.name=="PublicShopSign" then check(entry.textSize<=42) end
 end
end)
test('downtown, the boardwalk and ferry stay outside every purchasable parcel',function()
 for _,entry in ipairs(City.generate()) do if entry.background then
  check(not entry.tileIndex and not entry.interaction and entry.canQuery==false)
  for index,tile in ipairs(Config.tiles) do if tile.kind=='property' then
   local site=A.site(index)
   local overlapX=math.min(entry.position[1]+entry.size[1]/2,site[1]+9.5)-math.max(entry.position[1]-entry.size[1]/2,site[1]-9.5)
   local overlapZ=math.min(entry.position[3]+entry.size[3]/2,site[3]+9.5)-math.max(entry.position[3]-entry.size[3]/2,site[3]-9.5)
   check(overlapX<=0 or overlapZ<=0,'Public scenery occupies an unbought parcel: '..entry.name)
  end end
 end end
end)
test('public city buildings have windows, storefronts and a physical waterfront',function()
 local names={};local buildings=0
 for _,entry in ipairs(City.generate()) do names[entry.name]=true;if entry.name=='CivicBuilding' then buildings=buildings+1 end end
 equal(buildings,8)
 for _,name in ipairs({'CivicWindow','PublicAwning','PublicShopSign','WaterfrontQuay','Boardwalk','StreetLamp','BenchSeat','FerryHull','FountainWater','Crosswalk'}) do check(names[name],name) end
end)
test('3D city framing includes the whole public waterfront across screen sizes',function()
 local scenery=City.generate()
 for _,size in ipairs({{1440,900},{1192,642},{800,560},{390,760}}) do
  local l=Layout.calculate(table.unpack(size));local r=Layout.board(l,false)
  local rect={r[1]*l.scale,r[2]*l.scale,r[3]*l.scale,r[4]*l.scale}
  local frame=Camera.fit(size[1],size[2],rect,math.rad(18),math.rad(56),1,City.bounds())
  for _,entry in ipairs(scenery) do for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do for _,sz in ipairs({-1,1}) do
   local x,y,z=Camera.project(frame,{entry.position[1]+sx*entry.size[1]/2,entry.position[2]+sy*entry.size[2]/2,entry.position[3]+sz*entry.size[3]/2})
   check(z>0 and x>=rect[1]+9.9 and x<=rect[1]+rect[3]-9.9 and y>=rect[2]+9.9 and y<=rect[2]+rect[4]-9.9,'3D city clips the waterfront')
  end end end end
 end
end)
test('city details leave the route centers and all four event stations clear',function()
 for _,entry in ipairs(City.generate()) do if not entry.background then
  check(not entry.tileIndex and not entry.interaction and entry.canQuery==false)
  for index=1,24 do
   local p=A.position(index)
   check(math.abs(entry.position[1]-p[1])>entry.size[1]/2+3 or math.abs(entry.position[3]-p[3])>entry.size[3]/2+3,'Scenery blocks the walking route')
  end
  for _,x in ipairs({-27,27}) do for _,z in ipairs({-27,27}) do
   local overlapX=math.min(entry.position[1]+entry.size[1]/2,x+11.5)-math.max(entry.position[1]-entry.size[1]/2,x-11.5)
   local overlapZ=math.min(entry.position[3]+entry.size[3]/2,z+10.5)-math.max(entry.position[3]-entry.size[3]/2,z-10.5)
   check(overlapX<=0 or overlapZ<=0,'Scenery covers a functional event station')
  end end
 end end
end)
print('\n'..passed..' player-visibility and city-layout cases passed.')
