-- Layout uses the actual safe GUI area, so Studio's top bar never clips it.
local Layout = {}
function Layout.calculate(width, height)
    local compact = width < 800 or width/height < 1.15
    local scale = compact and math.min(width/560,height/860) or math.min(height/720,1.35)
    scale = math.max(0.25, scale)
    local w, h = width/scale, height/scale
    local toolbarHeight = compact and 158 or 112
    local toolbarWidth = math.min(compact and 528 or 810,w-32)
    local headerHeight = compact and 100 or 68
    return { scale=scale, width=w, height=h, compact=compact, headerHeight=headerHeight,
        toolbar={ (w-toolbarWidth)/2,h-toolbarHeight-18,toolbarWidth,toolbarHeight },
        inspector={ w-282,headerHeight+46,258,math.min(462,h-headerHeight-toolbarHeight-78) },
        roster={ 24,headerHeight+46,188,320 } }
end
return Layout
