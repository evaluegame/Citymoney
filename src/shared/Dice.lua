-- Two deterministic visual dice. The server rolls values; animation never changes them.
local runtimeScript=getfenv().script
local Architecture=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Dice={size=8.4,cornerRadius=0.75,baseHeight=2.3}
Dice.restHeight=Dice.baseHeight+Dice.size/2
Dice.faces={
    {normal={0,1,0},u={1,0,0},v={0,0,1}},
    {normal={0,0,-1},u={1,0,0},v={0,1,0}},
    {normal={1,0,0},u={0,0,1},v={0,1,0}},
    {normal={-1,0,0},u={0,0,1},v={0,1,0}},
    {normal={0,0,1},u={1,0,0},v={0,1,0}},
    {normal={0,-1,0},u={1,0,0},v={0,0,1}},
}
Dice.pips={{{0,0}},{{-1,-1},{1,1}},{{-1,-1},{0,0},{1,1}},{{-1,-1},{-1,1},{1,-1},{1,1}},{{-1,-1},{-1,1},{0,0},{1,-1},{1,1}},{{-1,-1},{-1,0},{-1,1},{1,-1},{1,0},{1,1}}}
function Dice.angles(value)
    if value==2 then return math.pi/2,0 elseif value==5 then return -math.pi/2,0
    elseif value==3 then return 0,math.pi/2 elseif value==4 then return 0,-math.pi/2
    elseif value==6 then return math.pi,0 end
    return 0,0
end
function Dice.pose(value,side,elapsed,duration,sequence)
    local t=math.clamp(elapsed/duration,0,1)
    local remain=(1-t)^3
    local pitch,roll=Dice.angles(value)
    local yaw=(side==1 and -0.25 or 0.3)+(sequence%3-1)*0.12
    local x=side==1 and -6 or 6
    local position={x+(side==1 and -6 or 6)*remain,Dice.restHeight+9*math.sin(math.pi*t)*(1-t)+math.abs(math.sin(t*5*math.pi))*(1-t),-6*remain}
    local rotation=Architecture.rotation(yaw+remain*math.pi*4,pitch+remain*math.pi*6,roll+remain*math.pi*4)
    local support=(Dice.size/2-Dice.cornerRadius)*(math.abs(rotation[4])+math.abs(rotation[5])+math.abs(rotation[6]))+Dice.cornerRadius
    position[2]=math.max(position[2],Dice.baseHeight+support)
    return position,rotation
end
function Dice.mesh(body,pip)
    local r=Dice.cornerRadius
    local inner=Dice.size-r*2
    local entries={}
    local function shell(name,size,p,shape,rotation)
        table.insert(entries,{name=name,size=size,position=p,color=body,shape=shape,rotation=rotation,material="SmoothPlastic",reflectance=0.08,interaction="dice"})
    end
    shell("DiceBody",{Dice.size,inner,inner},{0,0,0})
    shell("DiceShell",{inner,Dice.size,inner},{0,0,0})
    shell("DiceShell",{inner,inner,Dice.size},{0,0,0})
    local edge=Dice.size/2-r
    for _,a in ipairs({-1,1}) do for _,b in ipairs({-1,1}) do
        shell("DiceEdge",{inner,r*2,r*2},{0,a*edge,b*edge},"Cylinder")
        shell("DiceEdge",{inner,r*2,r*2},{a*edge,0,b*edge},"Cylinder",Architecture.rotation(0,0,math.pi/2))
        shell("DiceEdge",{inner,r*2,r*2},{a*edge,b*edge,0},"Cylinder",Architecture.rotation(math.pi/2,0,0))
        for _,c in ipairs({-1,1}) do shell("DiceCorner",{r*2,r*2,r*2},{a*edge,b*edge,c*edge},"Ball") end
    end end
    for value,face in ipairs(Dice.faces) do
        for _,point in ipairs(Dice.pips[value]) do
            local p={}
            for axis=1,3 do p[axis]=face.normal[axis]*(Dice.size/2+0.025)+face.u[axis]*point[1]*1.95+face.v[axis]*point[2]*1.95 end
            local rotation=face.normal[2]~=0 and Architecture.rotation(0,0,math.pi/2) or (face.normal[3]~=0 and Architecture.rotation(math.pi/2,0,0) or nil)
            table.insert(entries,{name="Pip"..value,size={0.12,1.16,1.16},position=p,color=pip,shape="Cylinder",rotation=rotation,material="SmoothPlastic",canCollide=false,interaction="dice"})
        end
    end
    return entries
end
function Dice.preview(value,side)
    local entries=Dice.mesh("F9FCFF","224377")
    local p,r=Dice.pose(value,side,1,1,0)
    for _,entry in ipairs(entries) do
        local old=entry.position
        entry.position={p[1]+r[1]*old[1]+r[2]*old[2]+r[3]*old[3],p[2]+r[4]*old[1]+r[5]*old[2]+r[6]*old[3],p[3]+r[7]*old[1]+r[8]*old[2]+r[9]*old[3]}
        local oldR=entry.rotation or {1,0,0,0,1,0,0,0,1}
        local combined={}
        for a=0,2 do for b=1,3 do
            combined[a*3+b]=r[a*3+1]*oldR[b]+r[a*3+2]*oldR[b+3]+r[a*3+3]*oldR[b+6]
        end end
        entry.rotation=combined
    end
    return entries
end
return Dice
