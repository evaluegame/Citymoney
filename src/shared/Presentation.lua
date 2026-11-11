-- Shared art direction and HUD geometry for the game and visual-review tools.
local P={
    colors={card="0F1D33",paper="1B2F4D",ink="F4F7FF",muted="B8C7DC",line="526D91",green="2563EB",accent="8FC3FF",gold="FFC04D",mint="203E60",red="FF8BA0",white="FFFFFF",darkInk="10213A",overlay="030B16"},
    boardColors={water="177FA3",deepWater="225C8C",sand="E4BD62",grass="39B777",path="E4EBF5",navy="214975",gold="FFC04D",road="526D96",tray="2458C7"},
    defaultView="table",defaultYaw=0,defaultElevation=math.rad(64),
    cityYaw=math.rad(18),cityElevation=math.rad(46),
}
local function linear(value) return value<=0.04045 and value/12.92 or ((value+0.055)/1.055)^2.4 end
function P.foregroundRGB(r,g,b)
    local luminance=linear(r)*0.2126+linear(g)*0.7152+linear(b)*0.0722
    local dark=linear(0x10/255)*0.2126+linear(0x21/255)*0.7152+linear(0x3a/255)*0.0722
    return (luminance+0.05)/(dark+0.05)>1.05/(luminance+0.05) and "darkInk" or "white"
end
function P.viewAngles(mode,rotate)
    local city=mode=="city"
    return (rotate or 0)*math.pi/2+(city and P.cityYaw or P.defaultYaw),city and P.cityElevation or P.defaultElevation
end
function P.layout(width,height)
    local compact=width<800 or width/height<1.15
    local scale=compact and math.min(width/560,height/860) or math.min(height/720,1.3)
    scale=math.max(0.25,scale)
    local w,h=width/scale,height/scale
    local toolbarHeight=compact and 252 or 140
    local toolbarWidth=compact and math.min(528,w-36) or math.min(760,w-352)
    return {scale=scale,width=w,height=h,compact=compact,headerHeight=compact and 84 or 56,
        toolbar={(w-toolbarWidth)/2,h-toolbarHeight-18,toolbarWidth,toolbarHeight},
        inspector={w-290,92,270,math.min(462,h-toolbarHeight-118)},roster={20,96,154,300},
        menu={20,compact and 102 or h-66,compact and 106 or 134,compact and 64 or 46},camera={compact and w-408 or w-426,compact and 100 or 26,compact and 388 or 170,compact and 68 or 34}}
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
