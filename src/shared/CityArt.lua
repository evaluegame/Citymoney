-- Sculpted primitives shared by Studio, the runtime world and review renders.
local runtimeScript=getfenv().script
local Architecture=runtimeScript and require(runtimeScript.Parent.Architecture) or require("./Architecture")
local Art={}
function Art.rounded(name,size,position,radius,color,extra)
    local result={}
    local function add(s,p,shape,rotation)
        local entry={name=name,size=s,position=p,color=color,shape=shape,rotation=rotation,material="SmoothPlastic"}
        for key,value in pairs(extra or {}) do entry[key]=value end
        table.insert(result,entry)
    end
    local x,y,z=table.unpack(size)
    add({x-2*radius,y,z},position)
    for _,side in ipairs({-1,1}) do
        add({radius,y,z-2*radius},{position[1]+side*(x/2-radius/2),position[2],position[3]})
    end
    for _,dx in ipairs({-1,1}) do for _,dz in ipairs({-1,1}) do
        -- Sink round caps slightly; coplanar overlapping top faces flicker in-engine.
        add({y,radius*2,radius*2},{position[1]+dx*(x/2-radius),position[2]-0.018,position[3]+dz*(z/2-radius)},"Cylinder",Architecture.rotation(0,0,math.pi/2))
    end end
    return result
end
return Art
