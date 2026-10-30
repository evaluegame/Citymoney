-- Perspective fitting into a HUD-free screen rectangle, including tall houses.
local Camera={}
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
function Camera.cityBounds(config,architecture,state)
    local points={}
    for _,x in ipairs({-91,91}) do for _,y in ipairs({-4,2}) do for _,z in ipairs({-91,91}) do table.insert(points,{x,y,z}) end end end
    for index,tile in ipairs(config.tiles) do if tile.kind=="property" then
        local site=architecture.site(index)
        local height=29
        if state then
            local property=state.properties[index]
            height=property.ownerId and ({13,20,21,29})[property.level+1] or 2.2
        end
        for _,x in ipairs({-9.5,9.5}) do for _,y in ipairs({1.5,height}) do for _,z in ipairs({-9.5,9.5}) do table.insert(points,{site[1]+x,y,site[3]+z}) end end end
    end end
    for _,x in ipairs({-39,39}) do for _,z in ipairs({-39,39}) do table.insert(points,{x,21,z}) end end
    return {min={-92,-4,-92},max={92,29,92},target={0,5,0},points=points}
end
function Camera.fromSlopes(slopes,yaw,elevation,zoom,bounds)
    local left,right,bottom,top=table.unpack(slopes)
    local back={math.sin(yaw)*math.cos(elevation),math.sin(elevation),math.cos(yaw)*math.cos(elevation)}
    local rightAxis={math.cos(yaw),0,-math.sin(yaw)}
    local up={-math.sin(yaw)*math.sin(elevation),math.cos(elevation),-math.cos(yaw)*math.sin(elevation)}
    bounds=bounds or {min={-92,-4,-92},max={92,33,92}}
    local target={}
    for axis=1,3 do target[axis]=(bounds.min[axis]+bounds.max[axis])/2 end
    target=bounds.target or target
    local points=bounds.points
    if not points then
        points={}
        for _,x in ipairs({bounds.min[1],bounds.max[1]}) do for _,y in ipairs({bounds.min[2],bounds.max[2]}) do for _,z in ipairs({bounds.min[3],bounds.max[3]}) do table.insert(points,{x,y,z}) end end end
    end
    -- Solve the smallest perspective frustum containing the city. Allowing the
    -- target to shift within the free rectangle avoids wasted space above it.
    local rMax,rMin,uMax,uMin,near=-math.huge,math.huge,-math.huge,math.huge,1
    for _,point in ipairs(points) do
        local p={point[1]-target[1],point[2]-target[2],point[3]-target[3]}
        local r,u,b=dot(p,rightAxis),dot(p,up),dot(p,back)
        rMax,rMin=math.max(rMax,r+right*b),math.min(rMin,r+left*b)
        uMax,uMin=math.max(uMax,u+top*b),math.min(uMin,u+bottom*b)
        near=math.max(near,b+1)
    end
    local distance=math.max(near,(rMax-rMin)/(right-left),(uMax-uMin)/(top-bottom))*(zoom or 1)
    local offsetR=(rMax+rMin-(right+left)*distance)/2
    local offsetU=(uMax+uMin-(top+bottom)*distance)/2
    local position={}
    for axis=1,3 do position[axis]=target[axis]+back[axis]*distance+rightAxis[axis]*offsetR+up[axis]*offsetU end
    return {position=position,right=rightAxis,up=up,back=back,fov=36}
end
function Camera.fit(width,height,rect,yaw,elevation,zoom,bounds)
    local tanV=math.tan(math.rad(36)/2)
    local tanH=tanV*width/height
    local left,right=((rect[1]+10)/width*2-1)*tanH,((rect[1]+rect[3]-10)/width*2-1)*tanH
    local bottom,top=(1-(rect[2]+rect[4]-10)/height*2)*tanV,(1-(rect[2]+10)/height*2)*tanV
    local result=Camera.fromSlopes({left,right,bottom,top},yaw,elevation,zoom,bounds)
    result.tanV,result.tanH,result.width,result.height=tanV,tanH,width,height
    return result
end
function Camera.project(frame,point)
    local relative={point[1]-frame.position[1],point[2]-frame.position[2],point[3]-frame.position[3]}
    local depth=-dot(relative,frame.back)
    return (dot(relative,frame.right)/(depth*frame.tanH)+1)*frame.width/2,(1-dot(relative,frame.up)/(depth*frame.tanV))*frame.height/2,depth
end
return Camera
