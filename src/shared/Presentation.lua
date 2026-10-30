-- Shared art direction and HUD geometry for the game and visual-review tools.
local P={
    colors={card="FFFFFF",paper="F0F5FC",ink="1B2C48",muted="687B94",line="D9E4F2",green="386BF0",gold="FFC34D",mint="E9F1FF",red="ED627B",white="FFFFFF"},
    board={water="59CBE8",deepWater="3895D2",sand="F5DDA0",grass="70D594",path="F7FAFE",navy="3555A5",gold="FFC34D"},
    defaultYaw=math.rad(18),defaultElevation=math.rad(56),
}
function P.layout(width,height)
    local compact=width<800 or width/height<1.15
    local scale=compact and math.min(width/560,height/860) or math.min(height/720,1.3)
    scale=math.max(0.25,scale)
    local w,h=width/scale,height/scale
    local toolbarHeight=compact and 188 or 88
    local toolbarWidth=math.min(compact and 528 or 700,w-36)
    return {scale=scale,width=w,height=h,compact=compact,headerHeight=compact and 84 or 56,
        toolbar={(w-toolbarWidth)/2,h-toolbarHeight-18,toolbarWidth,toolbarHeight},
        inspector={w-290,92,270,math.min(462,h-toolbarHeight-118)},roster={20,96,154,300},
        menu={20,compact and 100 or h-66,compact and 106 or 134,compact and 38 or 46},camera={compact and (w-254)/2 or w-510,compact and 104 or 26,254,34}}
end
function P.board(layout,inspector)
    local left=layout.compact and 12 or 188
    local top=layout.compact and 152 or 86
    local right=layout.width-(not layout.compact and inspector and 298 or 16)
    local bottom=layout.toolbar[2]-12
    return {left,top,math.max(140,right-left),math.max(140,bottom-top)}
end
return P
