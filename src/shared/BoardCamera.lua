-- Perspective fitting into a HUD-free screen rectangle, including tall houses.
local Camera={}
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
function Camera.fromSlopes(slopes,yaw,elevation,zoom,bounds)
    local left,right,bottom,top=table.unpack(slopes)
    local cx,cy=(left+right)/2,(bottom+top)/2
    local back={math.sin(yaw)*math.cos(elevation),math.sin(elevation),math.cos(yaw)*math.cos(elevation)}
    local rightAxis={math.cos(yaw),0,-math.sin(yaw)}
    local up={-math.sin(yaw)*math.sin(elevation),math.cos(elevation),-math.cos(yaw)*math.sin(elevation)}
    bounds=bounds or {min={-88,0,-88},max={88,32,88}}
    local target={}
    for axis=1,3 do target[axis]=(bounds.min[axis]+bounds.max[axis])/2 end
    local distance=1
    for _,x in ipairs({bounds.min[1],bounds.max[1]}) do
        for _,y in ipairs({bounds.min[2],bounds.max[2]}) do
            for _,z in ipairs({bounds.min[3],bounds.max[3]}) do
                local p={x-target[1],y-target[2],z-target[3]}
                local r,u,b=dot(p,rightAxis),dot(p,up),dot(p,back)
                distance=math.max(distance,b+1,(r+right*b)/(right-cx),(-r-left*b)/(cx-left),
                    (u+top*b)/(top-cy),(-u-bottom*b)/(cy-bottom))
            end
        end
    end
    distance=distance*(zoom or 1)
    local position={}
    for axis=1,3 do position[axis]=target[axis]+back[axis]*distance-rightAxis[axis]*cx*distance-up[axis]*cy*distance end
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
