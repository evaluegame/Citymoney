-- Two deterministic visual dice. The server rolls values; animation never changes them.
local runtimeScript=getfenv().script
local Architecture=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Dice={size=5.2}
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
    local x=side==1 and -4.4 or 4.4
    local position={x+(side==1 and -8 or 8)*remain,4.8+9*math.sin(math.pi*t)*(1-t)+math.abs(math.sin(t*5*math.pi))*(1-t),-8*remain}
    return position,Architecture.rotation(yaw+remain*math.pi*4,pitch+remain*math.pi*6,roll+remain*math.pi*4)
end
function Dice.mesh(body,pip)
    local entries={{name="DiceBody",size={Dice.size,Dice.size,Dice.size},position={0,0,0},color=body,material="SmoothPlastic",reflectance=0.08,interaction="dice"}}
    for value,face in ipairs(Dice.faces) do
        for _,point in ipairs(Dice.pips[value]) do
            local p={}
            for axis=1,3 do p[axis]=face.normal[axis]*(Dice.size/2+0.03)+face.u[axis]*point[1]*1.18+face.v[axis]*point[2]*1.18 end
            table.insert(entries,{name="Pip"..value,size={0.68,0.68,0.68},position=p,color=pip,shape="Ball",canCollide=false,interaction="dice"})
        end
    end
    return entries
end
function Dice.preview(value,side)
    local entries=Dice.mesh("FFF8E8","294C40")
    local p,r=Dice.pose(value,side,1,1,0)
    for _,entry in ipairs(entries) do
        local old=entry.position
        entry.position={p[1]+r[1]*old[1]+r[2]*old[2]+r[3]*old[3],p[2]+r[4]*old[1]+r[5]*old[2]+r[6]*old[3],p[3]+r[7]*old[1]+r[8]*old[2]+r[9]*old[3]}
        entry.rotation=r
    end
    return entries
end
return Dice
