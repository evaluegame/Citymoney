-- Shared art direction and HUD geometry for the game and visual-review tools.
local P={
    colors={card="FFFFFF",paper="F0F5FC",ink="1B2C48",muted="687B94",line="D9E4F2",green="386BF0",gold="FFC34D",mint="E9F1FF",red="ED627B",white="FFFFFF"},
    board={water="59CBE8",deepWater="3895D2",sand="F5DDA0",grass="70D594",path="F7FAFE",navy="3555A5",gold="FFC34D"},
    defaultView="table",defaultYaw=0,defaultElevation=math.rad(78),
    cityYaw=math.rad(18),cityElevation=math.rad(56),
}
function P.viewAngles(mode,rotate)
    local city=mode=="city"
    return (rotate or 0)*math.pi/2+(city and P.cityYaw or P.defaultYaw),city and P.cityElevation or P.defaultElevation
end
function P.layout(width,height)
    local compact=width<800 or width/height<1.15
    local scale=compact and math.min(width/560,height/860) or math.min(height/720,1.3)
    scale=math.max(0.25,scale)
    local w,h=width/scale,height/scale
    local toolbarHeight=compact and 224 or 112
    local toolbarWidth=compact and math.min(528,w-36) or math.min(760,w-352)
    return {scale=scale,width=w,height=h,compact=compact,headerHeight=compact and 84 or 56,
        toolbar={(w-toolbarWidth)/2,h-toolbarHeight-18,toolbarWidth,toolbarHeight},
        inspector={w-290,92,270,math.min(462,h-toolbarHeight-118)},roster={20,96,154,300},
        menu={20,compact and 102 or h-66,compact and 106 or 134,compact and 64 or 46},camera={compact and w-408 or w-510,compact and 100 or 26,compact and 388 or 254,compact and 68 or 34}}
end
function P.shortcuts(layout,rosterHeight)
    if layout.compact then return {20,180,layout.width-40,64} end
    return {20,layout.roster[2]+(rosterHeight or 260)+54,154,144}
end
function P.goal(layout,rosterHeight)
    if layout.compact then return {20,256,layout.width-40,64} end
    local shortcuts=P.shortcuts(layout,rosterHeight)
    return {20,shortcuts[2]+shortcuts[4]+12,154,80}
end
function P.board(layout,inspector)
    local left=layout.compact and 12 or 188
    local top=layout.compact and 332 or 86
    local right=layout.width-(not layout.compact and inspector and 298 or 16)
    local bottom=layout.toolbar[2]-12
    return {left,top,math.max(140,right-left),math.max(140,bottom-top)}
end
return P
