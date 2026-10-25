local Architecture = require("../src/shared/Architecture")
local Layout = require("../src/shared/Layout")
local Config = require("../src/shared/Config")
local function check(value, message) assert(value, message) end
local identity={1,0,0,0,1,0,0,0,1}
for index,tile in ipairs(Config.tiles) do
    if tile.kind=="property" then
        local empty=Architecture.property(Config,index,false,"E2B792",0,0)
        for _,entry in ipairs(empty) do check(entry.name~="Door", "Unowned property already contains a home") end
        local previousHeight=0
        for level=0,3 do
            local home=Architecture.property(Config,index,"Owner","E2B792",level,0)
            local door,ownerSign,furniture,stairs=false,false,false,0
            local maximum=0
            for _,entry in ipairs(home) do
                door=door or entry.door==true
                ownerSign=ownerSign or entry.name=="OwnerSign"
                furniture=furniture or entry.name=="Sofa"
                if entry.name=="StairTread" then stairs=stairs+1 end
                maximum=math.max(maximum,entry.position[2]+entry.size[2]/2)
                check(entry.tileIndex==index, "A home part lost its inspection target")
                for _,size in ipairs(entry.size) do check(size>0 and size<math.huge,"Invalid building geometry") end
                local r=entry.rotation or identity
                for a=0,2 do
                    for b=0,2 do
                        local dot=0
                        for c=1,3 do dot=dot+r[a*3+c]*r[b*3+c] end
                        check(math.abs(dot-(a==b and 1 or 0))<1e-6,"Roof/house rotation is not orthonormal")
                    end
                end
            end
            check(door and ownerSign and furniture, "Purchase must include a real door, owner sign and furnished home")
            check(maximum>=previousHeight, "An upgrade unexpectedly shrinks the home")
            if level>0 then check(stairs>0,"An upper-floor home needs a staircase") end
            previousHeight=maximum
        end
        local porch=Architecture.porch(index)
        local lot=Architecture.site(index)
        check(math.abs((porch[1]-lot[1])^2+(porch[3]-lot[3])^2-49)<1e-6,"Visitor must arrive at the front path")
    end
end
print("PASS homes: all 16 parcels, four building levels, walkable doors, furniture, stairs, rotation matrices and visit arrival points.")
for _,area in ipairs({{1192,642},{1192,610},{1920,1016},{1366,660},{800,560},{390,760},{430,840},{1024,680}}) do
    local layout=Layout.calculate(area[1],area[2])
    check(layout.width*layout.scale<=area[1]+0.01 and layout.height*layout.scale<=area[2]+0.01,"HUD exceeds safe GUI area")
    local bar=layout.toolbar
    check(bar[1]>=0 and bar[2]>=0 and bar[1]+bar[3]<=layout.width and bar[2]+bar[4]<=layout.height,"Action buttons are cropped")
    check(layout.inspector[1]>=0,"Inspector is outside screen")
end
print("PASS responsive layout: screenshot size, short Studio windows, desktop and portrait safe areas.")
