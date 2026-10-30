-- Asset-free residents and board poses, shared with the runtime and previews.
local runtimeScript=getfenv().script
local A=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Journey=runtimeScript and require(runtimeScript.Parent.Journey) or require("./Journey")
local Actors={}
function Actors.offset(seat,index)
    local x,z=((seat-1)%3-1)*4.4,math.floor((seat-1)/3)*4.4-2.2
    local _,yaw=A.site(index or 1)
    return math.cos(yaw)*x+math.sin(yaw)*z,-math.sin(yaw)*x+math.cos(yaw)*z
end
function Actors.pose(index,seat,height,from)
    local p=A.position(index);local x,z=Actors.offset(seat,index)
    local dx,dz=-p[1],-p[3]
    if from then local previous=A.position(from);dx,dz=p[1]-previous[1],p[3]-previous[3] end
    return {p[1]+x,p[2]+(height or 2.3),p[3]+z},math.atan2(-dx,-dz)
end
function Actors.travel(config,roll,seat,elapsed,height)
    local steps=math.clamp(roll.steps or 0,0,12)
    if elapsed<0 or steps==0 then return Actors.pose(roll.from,seat,height) end
    if elapsed>=steps*Journey.stepSeconds(config) then return Actors.pose(roll.to or roll.landedTile,seat,height) end
    local step,progress,lift=Journey.sample(config,steps,elapsed)
    local from=(roll.from+step-2)%#config.tiles+1
    local to=from%#config.tiles+1
    local p=Actors.pose(from,seat,height)
    local q,yaw=Actors.pose(to,seat,height,from)
    return {p[1]+(q[1]-p[1])*progress,p[2]+(q[2]-p[2])*progress+lift,p[3]+(q[3]-p[3])*progress},yaw
end
function Actors.figure(color)
    local parts={}
    local function add(name,size,p,tint,extra)
        local s={};local position={}
        for axis=1,3 do s[axis]=size[axis]*1.15;position[axis]=p[axis]*1.15 end
        local entry={name=name,size=s,position=position,color=tint,material="SmoothPlastic",canCollide=false}
        for k,v in pairs(extra or {}) do entry[k]=v end
        table.insert(parts,entry)
    end
    add("Torso",{1.45,1.5,0.8},{0,0,0},color)
    add("Shirt",{0.7,1.15,0.09},{0,0.04,-0.45},"FFFFFF")
    add("Tie",{0.18,0.75,0.1},{0,0.14,-0.52},"3555A5")
    add("Collar",{1.1,0.18,0.1},{0,0.59,-0.49},"FFFFFF")
    add("Head",{1.1,1.1,1},{0,1.28,0},"F3C9A2",{shape="Ball"})
    add("Hair",{1.18,0.36,1.05},{0,1.74,0.08},"384C73")
    add("Fringe",{0.75,0.22,0.15},{-0.18,1.6,-0.48},"384C73")
    for _,side in ipairs({-1,1}) do
        add("Eye",{0.09,0.12,0.07},{side*0.22,1.33,-0.5},"243757",{shape="Ball"})
        add(side<0 and "LeftLeg" or "RightLeg",{0.57,1.15,0.7},{side*0.4,-1.28,0},"355079")
        add("Shoe",{0.62,0.32,0.86},{side*0.4,-1.72,-0.08},"233554")
        add(side<0 and "LeftArm" or "RightArm",{0.45,1.2,0.65},{side*1.02,0.02,0},color)
        add("Hand",{0.46,0.35,0.64},{side*1.02,-0.76,0},"F3C9A2")
    end
    add("Smile",{0.24,0.06,0.07},{0,1.06,-0.51},"A25D57")
    add("Briefcase",{0.7,0.65,0.32},{1.18,-1.04,0},"FFC34D")
    add("CaseHandle",{0.3,0.12,0.13},{1.18,-0.68,0},"355079")
    return parts
end
function Actors.preview(color,p,yaw)
    local parts=Actors.figure(color)
    local c,s=math.cos(yaw),math.sin(yaw)
    for _,entry in ipairs(parts) do
        local x,y,z=table.unpack(entry.position)
        entry.position={p[1]+c*x+s*z,p[2]+y,p[3]-s*x+c*z}
        entry.rotation=A.rotation(yaw)
    end
    table.insert(parts,{name="PlayerColorRing",size={0.12,4.4,4.4},position={p[1],p[2]-2.04,p[3]},color=color,shape="Cylinder",rotation=A.rotation(0,0,math.pi/2),material="Neon",canCollide=false})
    return parts
end
return Actors
