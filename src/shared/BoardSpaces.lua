-- Physical space reservations and perspective-contained deed labels.
local runtimeScript=getfenv().script
local A=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Spaces={size=18.8,labelWidth=17.2,labelDepth=9,labelOffset=4.6,labelHeight=1.67}
function Spaces.point(index,x,z)
    local p=A.position(index);local _,yaw=A.site(index)
    local c,s=math.cos(yaw),math.sin(yaw)
    return {p[1]+c*x+s*z,Spaces.labelHeight,p[3]-s*x+c*z}
end
function Spaces.label(index)
    return Spaces.point(index,0,Spaces.labelOffset)
end
function Spaces.corners(index)
    local result={}
    for _,pair in ipairs({{-1,-1},{1,-1},{1,1},{-1,1}}) do
        table.insert(result,Spaces.point(index,pair[1]*Spaces.labelWidth/2,Spaces.labelOffset+pair[2]*Spaces.labelDepth/2))
    end
    return result
end
local function cross(a:{number},b:{number}) return a[1]*b[2]-a[2]*b[1] end
function Spaces.project(index:number,project:({number})->{number})
    local center=project(Spaces.label(index));local polygon:{{number}}={}
    for _,p in ipairs(Spaces.corners(index)) do table.insert(polygon,project(p)) end
    local a,b=polygon[1],polygon[2]
    local dx,dy=b[1]-a[1],b[2]-a[2]
    local width=math.sqrt(dx*dx+dy*dy)
    if width<0.01 then return nil end
    local r:{number}={dx/width,dy/width}
    if r[1]<0 then r={-r[1],-r[2]} end
    local n={-r[2],r[1]}
    local height=math.abs(cross(r,{polygon[4][1]-a[1],polygon[4][2]-a[2]}))
    local factor=1
    -- Perspective turns a world rectangle into a trapezoid. Every screen-space
    -- corner must satisfy every edge; a minimum font size must never enlarge it.
    for edge=1,4 do
        local p,q=polygon[edge],polygon[edge%4+1]
        local e={q[1]-p[1],q[2]-p[2]}
        local margin=math.abs(cross(e,{center[1]-p[1],center[2]-p[2]}))
        local extent=math.abs(cross(e,r))*width/2+math.abs(cross(e,n))*height/2
        if extent>0 then factor=math.min(factor,margin/extent) end
    end
    return {x=center[1],y=center[2],width=width*factor*0.93,height=height*factor*0.93,
        rotation=math.deg(math.atan2(r[2],r[1])),right=r,down=n,polygon=polygon}
end
return Spaces
