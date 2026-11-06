local Config=require('../src/shared/Config')
local Spaces=require('../src/shared/BoardSpaces')
local Actors=require('../src/shared/Actors')
local A=require('../src/shared/Architecture')
local Camera=require('../src/shared/BoardCamera')
local P=require('../src/shared/Presentation')
local Layout=require('../src/shared/Layout')
local Board=require('../src/shared/Board')
local Engine=require('../src/shared/Engine')
local passed=0
local function test(name,fn)
 local ok,message=pcall(fn);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
end
local function cross(a,b) return a[1]*b[2]-a[2]*b[1] end
local screens={{1440,900},{1192,642},{800,560},{390,760},{1920,1080}}
test('every rotated label corner stays inside its own perspective space',function()
 for _,screen in ipairs(screens) do for _,inset in ipairs({0,36,58}) do for rotation=0,3 do
  local l=Layout.calculate(table.unpack(screen));local r=Layout.board(l,false)
  local rect={r[1]*l.scale,r[2]*l.scale+inset,r[3]*l.scale,r[4]*l.scale}
  local frame=Camera.fit(screen[1],screen[2]+inset,rect,P.defaultYaw+rotation*math.pi/2,P.defaultElevation,1,Camera.cityBounds(Config,A))
  for index=1,24 do
   local label=assert(Spaces.project(index,function(p) local x,y=Camera.project(frame,p);return {x,y} end))
   assert(label.width>0 and label.height>0)
   for _,sx in ipairs({-1,1}) do for _,sy in ipairs({-1,1}) do
    local point={label.x+sx*label.width/2*label.right[1]+sy*label.height/2*label.down[1],label.y+sx*label.width/2*label.right[2]+sy*label.height/2*label.down[2]}
    local sign
    for edge=1,4 do
     local a,b=label.polygon[edge],label.polygon[edge%4+1]
     local d=cross({b[1]-a[1],b[2]-a[2]},{point[1]-a[1],point[2]-a[2]})
     if sign then assert(sign*d>0,'A deed spills outside its reserved plate') else sign=d end
    end
   end end
  end
 end end end
end)
test('name and price plates fit completely inside all 24 physical spaces',function()
 local count=0
 for _,part in ipairs(Board.generate(Config)) do if string.match(part.name,'^DeedPlate%d+$') then
  count=count+1;assert(part.boardSpace and part.text)
  local center=A.position(part.tileIndex);local _,yaw=A.site(part.tileIndex)
  for _,p in ipairs(Spaces.corners(part.tileIndex)) do
   local dx,dz=p[1]-center[1],p[3]-center[3]
   local x,z=math.cos(yaw)*dx-math.sin(yaw)*dz,math.sin(yaw)*dx+math.cos(yaw)*dz
   assert(math.abs(x)<Spaces.size/2 and math.abs(z)<Spaces.size/2)
  end
 end end
 assert(count==24)
end)
test('physical plates show the current price or rent after upgrades, boosts and demolition',function()
 local e=Engine.new(Config);assert(e:start({{id=1,name='Avery'},{id=2,name='Riley'}}))
 local property=e.state.properties[2]
 assert(Board.caption(Config,2,e.state)=='ตรอกทองแดง\n$90')
 property.ownerId,property.level=1,1
 assert(Board.caption(Config,2,e.state)=='ตรอกทองแดง\nค่าเช่า $36')
 property.rentTier,property.boost=3,2
 assert(Board.caption(Config,2,e.state)=='ตรอกทองแดง\nค่าเช่า $108')
 property.ownerId=false
 assert(Board.caption(Config,2,e.state)=='ตรอกทองแดง\n$90')
end)
test('the resident lane and all player rings stay clear of the name and price band',function()
 for index=1,24 do for seat=1,6 do
  local dx,dz=Actors.offset(seat,index);local _,yaw=A.site(index)
  local x,z=math.cos(yaw)*dx-math.sin(yaw)*dz,math.sin(yaw)*dx+math.cos(yaw)*dz
  assert(math.abs(x)+Actors.ringSize/2<Spaces.size/2)
  assert(z-Actors.ringSize/2>-Spaces.size/2 and z+Actors.ringSize/2<Spaces.labelOffset-Spaces.labelDepth/2)
 end end
end)
test('board pawns show larger full bodies with both feet on the walking surface',function()
 assert(Config.boardAvatarScale>=1.7 and Config.avatarScale==1)
 local bottom,top=math.huge,-math.huge
 local limbs={}
 for _,part in ipairs(Actors.figure('FFC34D')) do
  bottom=math.min(bottom,part.position[2]-part.size[2]/2)
  top=math.max(top,part.position[2]+part.size[2]/2);limbs[part.name]=true
 end
 assert(top-bottom>=7.5)
 assert(math.abs(bottom+Actors.height-0.2)<0.001)
 for _,name in ipairs({'Head','Torso','LeftArm','RightArm','LeftLeg','RightLeg'}) do assert(limbs[name]) end
end)
test('new public city landmarks occupy only city-service parcels',function()
 local names={}
 for _,part in ipairs(Board.generate(Config)) do names[part.name]=true end
 for _,name in ipairs({'CityGateway','NewsKiosk','ParkFountain','BankCoin','CivicOffice','StopWindow','WaterfrontQuay'}) do assert(names[name],name) end
 for index,tile in ipairs(Config.tiles) do if tile.kind=='property' then
  for _,part in ipairs(A.property(Config,index,false,'FFC34D',0,0)) do
   assert(part.name~='NewsKiosk' and part.name~='CivicOffice' and not part.door)
  end
 end end
end)
print('\n'..passed..' inset-space and full-body visibility cases passed.')
