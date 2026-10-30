local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer
local shared = RS:WaitForChild("Citymoney")
local Config, Architecture, Scene, Layout = require(shared.Config),require(shared.Architecture),require(shared.Scene),require(shared.Layout)
local Plans=require(shared.PropertyPlans)
local Menus=require(script:WaitForChild("Menus"))
local Boutique=require(script:WaitForChild("Boutique"))
local Cosmetics=require(shared.Cosmetics)
local BoardView=require(script:WaitForChild("BoardView"))
local CityPlaza=require(script:WaitForChild("CityPlaza"))
local Presentation=require(shared.Presentation)
local Motion=require(script:WaitForChild("Motion"))
local CommandMenu=require(script:WaitForChild("CommandMenu"))
local HoverCard=require(script:WaitForChild("HoverCard"))
local CityOffer=require(script:WaitForChild("CityOffer"))
local GoalDisplay=require(script:WaitForChild("GoalDisplay"))
local MatchFeedback=require(script:WaitForChild("MatchFeedback"))
local Journey=require(shared.Journey)
local boardView=BoardView.new()
local remotes=shared:WaitForChild("Remotes")
local action,snapshot,feedback=remotes:WaitForChild("Action"),remotes:WaitForChild("Snapshot"),remotes:WaitForChild("Feedback")
-- The default chat and player-list panels obscured the old game HUD.
task.spawn(function()
    for _=1,8 do
        local ok=pcall(function()
            for _, kind in ipairs({Enum.CoreGuiType.Chat,Enum.CoreGuiType.PlayerList,Enum.CoreGuiType.Backpack,Enum.CoreGuiType.Health}) do StarterGui:SetCoreGuiEnabled(kind,false) end
        end)
        if ok then break end
        task.wait(0.5)
    end
end)
local C={}
for key,hex in pairs(Presentation.colors) do C[key]=Color3.fromHex(hex) end
local gui=Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.IgnoreGuiInset,gui.ZIndexBehavior="Citymoney",false,false,Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")
local safe=Instance.new("Frame")
safe.Size,safe.BackgroundTransparency,safe.Parent=UDim2.fromScale(1,1),1,gui
local root=Instance.new("Frame")
root.Name="CityRoot"
root.BackgroundTransparency,root.Parent=1,safe
local uiScale=Instance.new("UIScale"); uiScale.Parent=root
local function round(object,radius)
    local value=Instance.new("UICorner");value.CornerRadius,value.Parent=UDim.new(0,radius or 15),object
end
local function place(object,x,y,w,h) object.Position,object.Size=UDim2.fromOffset(x,y),UDim2.fromOffset(w,h) end
local function frame(parent,x,y,w,h,tint)
    local object=Instance.new("Frame");place(object,x,y,w,h)
    object.BackgroundColor3,object.BorderSizePixel,object.Parent=tint or C.card,0,parent
    round(object,16)
    local stroke=Instance.new("UIStroke");stroke.Color,stroke.Transparency,stroke.Parent=C.line,0.42,object
    return object
end
local function text(parent,value,x,y,w,h,size,tint,bold)
    local object=Instance.new("TextLabel");place(object,x,y,w,h)
    object.BackgroundTransparency,object.Text,object.TextColor3=1,value,tint or C.ink
    object.TextSize,object.Font=size or 16,bold and Enum.Font.GothamBold or Enum.Font.Gotham
    object.TextXAlignment,object.TextYAlignment,object.TextWrapped=Enum.TextXAlignment.Left,Enum.TextYAlignment.Center,true
    object.Parent=parent;return object
end
local function button(parent,value,x,y,w,h,tint,callback)
    local object=Instance.new("TextButton");place(object,x,y,w,h)
    object.Text,object.TextSize,object.Font=value,14,Enum.Font.GothamBold
    object.BackgroundColor3,object.TextColor3,object.BorderSizePixel=tint or C.green,(tint==C.paper or tint==C.card or tint==C.gold) and C.ink or C.white,0
    object.Parent=parent;round(object,11)
    object.Activated:Connect(function() if object.Active then callback() end end)
    Motion.button(object,root)
    return object
end
local function available(object,enabled,tint)
    object.Active,object.AutoButtonColor=enabled,enabled
    object.BackgroundColor3=enabled and tint or C.paper
    object.TextColor3=enabled and ((tint==C.paper or tint==C.card or tint==C.gold) and C.ink or C.white) or C.muted
end
local function truncate(object) object.TextWrapped,object.TextTruncate=false,Enum.TextTruncate.AtEnd end
local data,selected,focusIndex,mainCommand,visitIndex,layout
local inspectorOpen,portfolioOpen,rolling,locked=false,false,false,false
local notify,render,requestSale,openPlans,renderPlans,mainAction,menus,boutique,city,openCity,commandMenu,hover,opportunity,goals,moments
local journeyActive=false
local portraits={}
local function send(command,index,level,expectedTurn)
    if locked or (rolling and command~="Return") then return false end
    locked=true;action:FireServer(command,index,level,expectedTurn)
    task.delay(0.22,function() locked=false end)
    return true
end
local header=frame(root,24,16,1200,68)
header.Name="Header"
local mark=frame(header,14,12,32,32,C.green)
local logo=text(mark,"C",0,0,32,32,24,C.white,true);logo.TextXAlignment=Enum.TextXAlignment.Center
local brand=text(header,"citymoney",60,7,210,32,27,C.ink,true)
local strap=text(header,"BUILD YOUR CITY",62,40,240,15,9,C.muted,true)
local cashLabel=text(header,"$1,500",360,8,190,30,23,C.ink,true)
local worthLabel=text(header,"YOUR BALANCE",360,39,230,16,10,C.muted)
local homesButton=button(header,"Your homes",800,14,142,40,C.green,function() portfolioOpen=not portfolioOpen;inspectorOpen=false;render() end)
local night=false
local dayButton=button(header,"Golden hour",960,14,110,40,C.paper,function()
    night=not night;Lighting.ClockTime=night and 19.2 or 16.2
end)
local helpButton
local roster=frame(root,20,96,154,164)
roster.Name="PlayerList"
text(roster,"AT THE TABLE",12,8,130,24,10,C.muted,true)
local seats=Instance.new("Frame");place(seats,10,38,134,300);seats.BackgroundTransparency,seats.Parent=1,roster
local turnChip=frame(root,24,294,188,37,C.mint)
local roundText=text(turnChip,"WELCOME HOME",12,5,165,27,10,C.green,true)
local inspector=frame(root,970,114,258,462)
inspector.Name="PropertyCard"
local district=text(inspector,"THE NEIGHBORHOOD",18,13,204,19,10,C.muted,true)
local propertyName=text(inspector,"Your next address",18,35,188,46,23,C.ink,true)
button(inspector,"×",216,12,44,44,C.paper,function() inspectorOpen=false;focusIndex=nil;render() end)
local viewport=Instance.new("ViewportFrame");place(viewport,14,88,230,116)
viewport.BackgroundColor3,viewport.Ambient,viewport.LightColor=C.mint,Color3.fromRGB(180,180,165),Color3.fromRGB(255,235,206)
viewport.LightDirection,viewport.BorderSizePixel,viewport.Parent=Vector3.new(-1,-2,-1),0,inspector;round(viewport,12)
local viewWorld=Instance.new("WorldModel");viewWorld.Parent=viewport
local viewCamera=Instance.new("Camera");viewCamera.FieldOfView,viewCamera.Parent=34,viewport;viewport.CurrentCamera=viewCamera
local ownerText=text(inspector,"A place to call your own",18,213,222,20,12,C.muted)
truncate(ownerText)
local rentText=text(inspector,"RENT  $0",18,241,110,28,18,C.ink,true)
local levelText=text(inspector,"Cottage",139,241,103,28,13,C.green,true)
local nextRent=text(inspector,"Buy this lot to build a furnished cottage.",18,274,222,34,12,C.muted)
local upgradeButton=button(inspector,"Upgrade options",16,316,109,44,C.green,function() if selected and openPlans then openPlans("upgrade",selected) end end)
upgradeButton.TextSize=12
local rentButton=button(inspector,"Rent options",133,316,109,44,C.green,function() if selected and openPlans then openPlans("rent",selected) end end)
rentButton.TextSize=12
local sellButton=button(inspector,"Sell",95,424,70,32,C.paper,function() if requestSale then requestSale(selected) end end)
local visitButton=button(inspector,"Walk through your home",16,370,226,44,C.green,function() if selected then send("Visit",selected) end end)
local paintButton=button(inspector,"Repaint",16,424,70,32,C.paper,function() if selected then send("Paint",selected) end end)
paintButton.TextSize=11
local focusButton=button(inspector,"Close-up",173,424,69,32,C.paper,function() focusIndex=selected end);focusButton.TextSize=11
sellButton.TextSize=11
local ownerMark=frame(inspector,8,214,4,19,C.green)
local portfolio=frame(root,920,114,308,440)
portfolio.Name="PropertyCollection"
text(portfolio,"Your collection",18,15,245,35,23,C.ink,true)
text(portfolio,"Homes that work for you.",18,52,245,22,12,C.muted)
button(portfolio,"×",264,15,26,26,C.paper,function() portfolioOpen=false;render() end)
local homeList=Instance.new("ScrollingFrame");place(homeList,12,88,284,338)
homeList.BackgroundTransparency,homeList.BorderSizePixel,homeList.ScrollBarThickness,homeList.Parent=1,0,3,portfolio
homeList.ScrollBarImageColor3=C.green
local emptyHomes=text(portfolio,"Your first address is waiting.\nLand on a property and buy it to\nsee your new home appear.",22,135,264,130,16,C.muted)
local control=frame(root,235,670,810,112)
control.Name="TurnDock"
local dieA=button(control,"",16,18,48,48,C.paper,function() if mainCommand=="Roll" and mainAction then mainAction() end end)
local dieB=button(control,"",72,18,48,48,C.paper,function() if mainCommand=="Roll" and mainAction then mainAction() end end)
dieA.Name,dieB.Name="RollDieA","RollDieB"
local dieTextA=text(dieA,"·",0,0,48,48,28,C.ink,true);dieTextA.TextXAlignment=Enum.TextXAlignment.Center
local dieTextB=text(dieB,"·",0,0,48,48,28,C.ink,true);dieTextB.TextXAlignment=Enum.TextXAlignment.Center
local diceTotal=text(control,"TAP TO ROLL",18,90,154,17,11,C.muted,true);diceTotal.TextXAlignment=Enum.TextXAlignment.Center
local turnTitle=text(control,"A neighborhood of possibilities.",140,14,400,29,21,C.ink,true)
truncate(turnTitle)
local turnHint=text(control,"Start solo against City Bot, or invite your friends.",140,48,400,26,12,C.muted);truncate(turnHint)
local actionButton=button(control,"Connecting…",574,17,220,54,C.green,function() if mainAction then mainAction() end end)
local actionDepth=frame(control,574,21,220,54,Color3.fromHex("DCA031"));actionButton.ZIndex=2
local passButton=button(control,"SKIP",500,79,75,26,C.paper,function() send("Skip") end)
local timeText=text(control,"",16,81,400,18,10,C.muted)
local timeTrack=frame(control,16,104,778,3,C.paper)
local timeFill=Instance.new("Frame");timeFill.Size,timeFill.BackgroundColor3,timeFill.BorderSizePixel,timeFill.Parent=UDim2.fromScale(1,1),C.green,0,timeTrack
local cameraBar=frame(root,24,510,188,84)
cameraBar.Name,cameraBar.ZIndex="CameraDock",2
button(cameraBar,"Top view",6,6,86,30,C.paper,function() focusIndex=nil;root:SetAttribute("ViewMode",(root:GetAttribute("ViewMode") or "city")=="city" and "table" or "city");root:SetAttribute("Zoom",1);render() end).Name="TableView"
button(cameraBar,"Fit",39,45,44,30,C.paper,function() focusIndex=nil;inspectorOpen=false;root:SetAttribute("Rotate",0);root:SetAttribute("Zoom",1);render() end).Name="Fit"
button(cameraBar,"-",121,45,27,30,C.paper,function() root:SetAttribute("Zoom",math.min(1.5,(root:GetAttribute("Zoom") or 1)+0.1)) end).Name="ZoomOut"
button(cameraBar,"+",153,45,28,30,C.paper,function() root:SetAttribute("Zoom",math.max(0.75,(root:GetAttribute("Zoom") or 1)-0.1)) end).Name="ZoomIn"
local visitBanner=frame(root,420,110,440,58,C.green)
local visitText=text(visitBanner,"Welcome home",16,8,270,38,16,C.white,true)
button(visitBanner,"Back to board",292,10,134,38,C.paper,function() send("Return") end)
visitBanner.Visible=false
local toast=frame(root,440,105,400,45,C.card);toast.ZIndex=15;toast.Visible=false
toast.Name="NoticeToast"
local toastText=text(toast,"",16,5,368,35,14,C.green,true);toastText.ZIndex=16
local toastVersion=0
notify=function(message)
    if moments then moments:hide() end
    toastVersion=toastVersion+1;local version=toastVersion
    toastText.Text,toast.Visible=message,true
    Motion.pop(toast,root)
    task.delay(4,function() if toastVersion==version then toast.Visible=false end end)
end
local function overlay(w,h)
    local shade=Instance.new("Frame");shade.Size,shade.BackgroundColor3,shade.BackgroundTransparency=UDim2.fromScale(1,1),C.ink,0.35
    shade.Active,shade.ZIndex,shade.Visible,shade.Parent=true,30,false,root
    local card=frame(shade,0,0,w,h);card.AnchorPoint,card.Position,card.ZIndex=Vector2.new(0.5,0.5),UDim2.fromScale(0.5,0.5),31
    card.DescendantAdded:Connect(function(object) if object:IsA("GuiObject") then object.ZIndex=32 end end)
    return shade,card
end
local help,helpCard=overlay(510,420)
text(helpCard,"Your city. Your table.",26,22,458,44,27,C.ink,true)
text(helpCard,"01   CLICK THE DICE",26,91,458,25,13,C.green,true)
text(helpCard,"Tap either die or the central tray. The dice settle,\nthen your avatar moves around the 24-space board.",26,120,458,48,15,C.muted)
text(helpCard,"02   BUY & BUILD",26,183,458,25,13,C.green,true)
text(helpCard,"Choose a home level when buying. Use cards,\nupgrades and the city plaza before your next roll.",26,212,458,48,15,C.muted)
text(helpCard,"03   THE CITY KEEPS MOVING",26,275,458,25,13,C.green,true)
text(helpCard,"Resolved turns advance automatically after four seconds.\nPress P or click plaza stations for events and cards.",26,304,458,48,15,C.muted)
button(helpCard,"Let's build a neighborhood",26,365,458,36,C.green,function() help.Visible=false end)
helpButton=button(header,"How to play",1080,14,124,40,C.paper,function() help.Visible=not help.Visible end)
local sale,saleCard=overlay(470,260)
text(saleCard,"Let this home go?",26,22,418,42,26,C.ink,true)
local saleText=text(saleCard,"",26,82,418,82,16,C.muted)
local saleIndex,saleTurn
button(saleCard,"Keep my home",26,190,200,42,C.paper,function() sale.Visible=false end)
button(saleCard,"Confirm sale",238,190,206,42,C.green,function()
    sale.Visible=false
    if data and data.game.status=="playing" and data.game.turnCount==saleTurn then send("Sell",saleIndex) end
end)
requestSale=function(index)
    if not index or not data then return end
    local tile,property=Config.tiles[index],data.game.properties[index]
    saleIndex,saleTurn=index,data.game.turnCount
    saleText.Text=tile.name.." returns to the city for $"..math.floor(Plans.investment(Config,index,property.level,property.rentTier)/2)..". Its house will be removed, and you may lose your district bonus."
    sale.Visible=true
end
local results,resultCard=overlay(520,430)
local resultTitle=text(resultCard,"A neighborhood well built.",26,22,468,44,26,C.ink,true)
local resultSubtitle=text(resultCard,"",26,73,468,30,15,C.green)
local resultRows=Instance.new("Frame");place(resultRows,26,121,468,212);resultRows.BackgroundTransparency,resultRows.Parent=1,resultCard
local replay=button(resultCard,"Play again",26,360,292,44,C.green,function()
    results.Visible=false
    send(data and data.matchmaking and data.matchmaking.mode=="match" and "BackLobby" or "Start")
end)
button(resultCard,"Keep looking",330,360,164,44,C.paper,function() results.Visible=false end)
local chooser,chooserCard=overlay(Layout.homeChooserWidth,Layout.homeChooserHeight)
local chooserTitle=text(chooserCard,"Choose your home level",24,15,418,36,25,C.ink,true)
local chooserSubtitle=text(chooserCard,"",24,52,472,24,15,C.muted)
truncate(chooserSubtitle)
local planIndex,planMode,planLevel,planTurn,planPending,planError
local planRequestId=0
local planPreviewKey
local closeChooser=button(chooserCard,"×",452,17,44,44,C.paper,function() if not planPending then chooser.Visible=false end end)
local planViewport=Instance.new("ViewportFrame");place(planViewport,24,88,472,144)
planViewport.BackgroundColor3,planViewport.Ambient,planViewport.LightColor=C.mint,Color3.fromRGB(180,180,165),Color3.fromRGB(255,235,206)
planViewport.LightDirection,planViewport.BorderSizePixel,planViewport.Parent=Vector3.new(-1,-2,-1),0,chooserCard;round(planViewport,12)
local planWorld=Instance.new("WorldModel");planWorld.Parent=planViewport
local planCamera=Instance.new("Camera");planCamera.FieldOfView,planCamera.Parent=34,planViewport;planViewport.CurrentCamera=planCamera
local planDescription=text(chooserCard,"",24,241,472,38,15,C.muted)
local planCards={}
for level=0,Config.maxLevel do
    local x,y=24+(level%2)*242,290+math.floor(level/2)*96
    local option=button(chooserCard,"",x,y,230,86,C.paper,function()
        if not planPending then planLevel=level;planError=nil;renderPlans() end
    end)
    local border=Instance.new("UIStroke");border.Color,border.Transparency,border.Parent=C.line,0.1,option
    local name=text(option,"",12,7,208,25,17,C.ink,true)
    local price=text(option,"",12,35,208,22,15,C.muted)
    local status=text(option,"",12,60,208,19,13,C.muted)
    planCards[level+1]={ button=option, border=border, name=name, price=price, status=status }
end
local planTotal=text(chooserCard,"",24,487,472,30,20,C.ink,true)
local planBalance=text(chooserCard,"",24,525,472,24,16,C.green)
local planNote=text(chooserCard,"",24,558,472,33,14,C.muted)
local confirmPlan=button(chooserCard,"Confirm",24,607,332,64,C.green,function()
    if planPending or not data then return end
    local options=Plans.options(Config,data.game,player.UserId,planIndex,planMode)
    local option=options[(planLevel or -1)+1]
    if not option or not option.affordable then return end
    local command=planMode=="buy" and "Buy" or (planMode=="rent" and "SetRent" or "Upgrade")
    if send(command,planIndex,planMode=="rent" and planLevel+1 or planLevel,planTurn) then
        planPending=true;planError=nil;renderPlans()
        planRequestId=planRequestId+1
        local requestId=planRequestId
        task.delay(4,function()
            if requestId==planRequestId and planPending and chooser.Visible then
                planPending=false
                planError="No confirmation yet. Check the refreshed details before retrying."
                action:FireServer("Sync")
                renderPlans()
            end
        end)
    end
end)
local cancelPlan=button(chooserCard,"Back",368,607,128,64,C.paper,function() if not planPending then chooser.Visible=false end end)
confirmPlan.TextSize=18;cancelPlan.TextSize=18
local highlight=Instance.new("Highlight")
highlight.Name,highlight.FillColor,highlight.OutlineColor="SelectedAddress",C.gold,C.green
highlight.FillTransparency,highlight.OutlineTransparency,highlight.Parent=0.94,0.1,workspace
local function resident(state,id)
    for _, value in ipairs(state.players) do if value.id==id then return value end end
    return nil
end
local function pair(state,id,group)
    for index,tile in ipairs(Config.tiles) do if tile.group==group and state.properties[index].ownerId~=id then return false end end
    return true
end
local function rent(state,index)
    local property=state.properties[index]
    return Plans.projectedRent(Config,state,property.ownerId,index,property.level)
end
local function worth(state,person)
    local total=person.cash
    for index,property in ipairs(state.properties) do
        if property.ownerId==person.id then total=total+Plans.investment(Config,index,property.level,property.rentTier) end
    end
    return total
end
local previewKey
local function styleFor(id)
    for _,entry in ipairs(data and data.styles or {}) do if entry.id==id then return entry.styleId end end
    return "classic"
end
local function fillPreview(world,camera,index,owner,property,level)
    world:ClearAllChildren()
    local model=Scene.model(Architecture.property(Config,index,owner and owner.name or "Your next home",owner and Config.playerColors[owner.colorIndex] or "D4AF84",level,property.paint or 0,property,styleFor(owner and owner.id or player.UserId)),"Preview",world,true)
    local cf,size=model:GetBoundingBox()
    local target=cf.Position+Vector3.new(0,1,0)
    local _,yaw=Architecture.site(index)
    local x,z=22,-29
    camera.CFrame=CFrame.lookAt(target+Vector3.new(math.cos(yaw)*x+math.sin(yaw)*z,20+size.Y*0.3,-math.sin(yaw)*x+math.cos(yaw)*z),target)
end
local function propertyPreview(index,owner,property)
    local key=index..":"..tostring(property.ownerId)..":"..property.level..":"..(property.paint or 0)..":"..tostring(property.shield)..":"..(property.boost or 0)..":"..(property.rentTier or 1)..":"..styleFor(owner and owner.id or player.UserId)
    if previewKey==key then return end
    previewKey=key
    fillPreview(viewWorld,viewCamera,index,owner,property,property.level)
end
local homeNames=Config.homeNames
renderPlans=function()
    if not chooser.Visible or not data or not planIndex then return end
    local state=data.game
    local current=state.players[state.turn]
    local property=state.properties[planIndex]
    local valid=state.status=="playing" and state.turnCount==planTurn and current and current.id==player.UserId and current.alive
    if planMode=="buy" then valid=valid and state.phase=="buy" and state.pendingTile==planIndex and not property.ownerId
    else valid=valid and property.ownerId==player.UserId end
    if not valid then chooser.Visible=false;planPending=false;return end
    local mine=resident(state,player.UserId)
    local options=Plans.options(Config,state,player.UserId,planIndex,planMode)
    local chosen=options[planLevel+1]
    if not chosen then chooser.Visible=false;return end
    chooserTitle.Text=planMode=="buy" and "Choose your home level" or (planMode=="rent" and "Choose a rent multiplier" or "Choose your upgrade")
    chooserSubtitle.Text=Config.tiles[planIndex].name.." · $"..mine.cash.." available"..(planMode=="buy" and " · Land included" or (planMode=="rent" and (" · Current "..Config.rentTiers[property.rentTier or 1].."×") or (" · Current L"..property.level)))
    for _,option in ipairs(options) do
        local row=planCards[option.level+1]
        local active=option.level==planLevel
        row.button.BackgroundColor3=active and C.mint or C.paper
        row.border.Color,row.border.Thickness=active and C.green or C.line,active and 2 or 1
        row.name.Text=planMode=="rent" and option.name or ("L"..option.level.." · "..option.name)
        row.price.Text=(option.available and ("$"..option.cost..(planMode=="buy" and " total" or (planMode=="rent" and " fee" or " to upgrade"))) or "Included already").." · $"..option.rent.." rent"
        row.status.Text=option.current and (planMode=="rent" and "CURRENT RATE" or "YOUR CURRENT HOME") or (not option.available and "CHOOSE A HIGHER OPTION" or (option.affordable and (active and "SELECTED" or "TAP TO PREVIEW") or ("Need $"..(-option.remaining).." more")))
        row.status.TextColor3=option.available and not option.affordable and C.red or C.muted
        row.button.Active=not planPending
    end
    local shownLevel=planMode=="rent" and property.level or planLevel
    local key=planIndex..":"..shownLevel..":"..(property.paint or 0)..":"..mine.colorIndex..":"..(property.rentTier or 1)..":"..planLevel..":"..styleFor(player.UserId)
    if key~=planPreviewKey then
        local preview=table.clone(property)
        if planMode=="rent" then preview.rentTier=planLevel+1 end
        planPreviewKey=key;fillPreview(planWorld,planCamera,planIndex,mine,preview,shownLevel)
    end
    planDescription.Text=chosen.description
    local currentRent=planMode~="buy" and rent(state,planIndex) or 0
    planTotal.Text=chosen.available and ((planMode=="buy" and "Total price: $" or (planMode=="rent" and "Rental fee: $" or "Upgrade cost: $"))..chosen.cost.."   ·   Rent $"..currentRent.." → $"..chosen.rent) or "Choose a higher option. Your current one is included."
    planBalance.Text=chosen.available and (chosen.affordable and ("Balance after: $"..chosen.remaining) or ("Need $"..(-chosen.remaining).." more. Choose a lower option, or go back.")) or "Your current investment is already included."
    planBalance.TextColor3=chosen.available and not chosen.affordable and C.red or C.green
    planNote.Text=planError or (planMode=="rent" and "The multiplier stays on this property for future payments." or ("No district pair required. "..(planMode=="buy" and "Land + all selected building levels are included." or "You pay only for the levels you add.")))
    planNote.TextColor3=planError and C.red or C.muted
    local enabled=chosen.affordable and not planPending and not rolling
    confirmPlan.Text=planPending and "Confirming your selection…" or (rolling and "Dice are rolling…" or (chosen.available and ((planMode=="buy" and "Buy " or (planMode=="rent" and "Set " or "Upgrade to "))..chosen.name.." · $"..chosen.cost) or "Choose a higher option"))
    available(confirmPlan,enabled,C.green)
    available(cancelPlan,not planPending,C.paper)
    available(closeChooser,not planPending,C.paper)
end
local function closePanels()
    help.Visible=false;sale.Visible=false;chooser.Visible=false
    inspectorOpen=false;portfolioOpen=false
    inspector.Visible=false;portfolio.Visible=false
    if menus then menus.lobby.Visible=false;menus.actions.Visible=false;menus.practiceSettings.Visible=false end
    if boutique then boutique.shade.Visible=false end
    if city then city.shade.Visible=false end
    if commandMenu then commandMenu.shade.Visible=false end
    if opportunity then opportunity.shade.Visible=false end
end
openPlans=function(mode,index)
    if not data then return end
    if planIndex~=index or planMode~=mode or planTurn~=data.game.turnCount then
        planLevel=mode=="buy" and 0 or (mode=="rent" and math.min(#Config.rentTiers-1,data.game.properties[index].rentTier or 1) or math.min(Config.maxLevel,data.game.properties[index].level+1))
    end
    planIndex,planMode,planTurn,planPending,planError=index,mode,data.game.turnCount,false,nil
    closePanels();chooser.Visible=true
    renderPlans()
end
mainAction=function()
    if mainCommand=="Buy" and data then openPlans("buy",data.game.pendingTile)
    elseif mainCommand=="Offer" then opportunity:open()
    elseif mainCommand=="Plaza" then openCity("overview")
    elseif mainCommand=="Match" and menus then closePanels();menus:openLobby()
    elseif mainCommand=="Ready" and menus then menus:toggleReady()
    elseif mainCommand then send(mainCommand) end
end
do
    local ui={config=Config,colors=C,root=root,id=player.UserId,frame=frame,text=text,button=button,overlay=overlay,available=available,send=send,notify=notify,data=function() return data end,rent=rent,
        header=header,mark=mark,strap=strap,dieA=dieA,dieB=dieB,dieTextA=dieTextA,dieTextB=dieTextB,cameraBar=cameraBar,closePanels=closePanels,
        hideToast=function()
            toast.Visible=false
            for _,child in ipairs(header:GetChildren()) do if child.Name=="CashChange" then child:Destroy() end end
        end,
        focus=function(index) selected,focusIndex,inspectorOpen,portfolioOpen=index,nil,true,false;render() end,
        openGoals=function()
            if not data or data.game.status~="playing" or not resident(data.game,player.UserId) then notify("Start a match to receive cards and challenges.");return end
            closePanels();menus.actions.Visible=true;menus:render(data);render()
        end,
        openMatch=function() closePanels();menus:openLobby() end,
        openHomes=function() closePanels();portfolioOpen=true;render() end,
        openHelp=function() closePanels();help.Visible=true;render() end,
        openCity=function() openCity("overview") end,
        switchLight=function() night=not night;Lighting.ClockTime=night and 19.2 or 14.4 end,
        openStyles=function() closePanels();boutique:open();render() end}
    menus=Menus.new(ui);boutique=Boutique.new(ui);city=CityPlaza.new(ui);commandMenu=CommandMenu.new(ui);hover=HoverCard.new(ui,player)
    opportunity=CityOffer.new(ui);goals=GoalDisplay.new(ui);moments=MatchFeedback.new(ui)
    openCity=function(tab) closePanels();city:open(tab);render() end
    boardView.onProperty=function(index) selected,inspectorOpen,portfolioOpen=index,true,false;render() end
    boardView.onInteraction=function(tab) openCity(tab) end
end
render=function()
    if not data then return end
    local state=data.game
    root:SetAttribute("ReducedMotion",data.club and not data.club.effects or false)
    local current=state.players[state.turn]
    local mine=resident(state,player.UserId)
    local myTurn=state.status=="playing" and current and current.id==player.UserId and current.alive
    journeyActive=state.status=="playing" and workspace:GetServerTimeNow()<(data.journeyUntil or 0)
    local isHost=data.hostId==player.UserId
    visitIndex=nil
    for _, visitor in ipairs(data.visitors or {}) do if visitor.id==player.UserId then visitIndex=visitor.tile end end
    if sale.Visible and (not myTurn or state.turnCount~=saleTurn) then sale.Visible=false end
    cashLabel.Text=mine and ("$"..mine.cash) or "$1,500"
    worthLabel.Text=mine and ("NET WORTH  $"..worth(state,mine)) or "YOUR STARTING BALANCE"
    local count=0
    for _,property in ipairs(state.properties) do if property.ownerId==player.UserId then count=count+1 end end
    homesButton.Text="Your homes  ·  "..count
    seats:ClearAllChildren()
    local entries=state.status=="lobby" and data.lobby or state.players
    for seat,entry in ipairs(entries) do
        local row=frame(seats,0,(seat-1)*54,134,48,(current and state.status=="playing" and current.id==entry.id) and C.mint or C.card)
        local tint=Color3.fromHex(Config.playerColors[entry.colorIndex or seat] or "DCC098")
        local dot=frame(row,0,7,5,34,tint);round(dot,3)
        local avatar=frame(row,8,10,30,30,tint);round(avatar,15)
        local initial=text(avatar,string.sub(entry.name,1,1),0,0,30,30,16,C.white,true);initial.TextXAlignment=Enum.TextXAlignment.Center
        if type(entry.id)=="number" and entry.id>0 and portraits[entry.id]==nil then
            portraits[entry.id]=false
            task.spawn(function()
                local ok,url=pcall(function() return Players:GetUserThumbnailAsync(entry.id,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100) end)
                portraits[entry.id]=ok and url or ""
                if ok then render() end
            end)
        end
        if portraits[entry.id] and portraits[entry.id]~="" then
            local image=Instance.new("ImageLabel");image.Size,image.BackgroundTransparency,image.Image,image.Parent=UDim2.fromScale(1,1),1,portraits[entry.id],avatar
            round(image,15);initial.Visible=false
        end
        local name=text(row,entry.name,44,4,84,18,12,entry.alive==false and C.muted or C.ink,true);truncate(name)
        text(row,entry.cash and ("$"..entry.cash..(entry.alive==false and " · out" or "")) or "READY",44,24,84,19,14,C.green,true)
    end
    roster.Size=UDim2.fromOffset(154,44+math.min(#entries,4)*54)
    roundText.Text=state.status=="playing" and ("TURN "..state.turnCount.." / "..Config.maxTurns) or "LOBBY OPEN"
    if layout then turnChip.Position,turnChip.Size=UDim2.fromOffset(20,layout.roster[2]+roster.Size.Y.Offset+10),UDim2.fromOffset(154,32) end
    dieTextA.Text,dieTextB.Text="",""
    local pipColor=Color3.fromHex(Cosmetics.get(data.club and data.club.styleId or "classic").pip)
    passButton.Visible=false;mainCommand=nil
    if state.status~="playing" then
        turnTitle.Text=state.status=="finished" and "Your next city awaits." or "Build your city."
        local online=data.matchmaking and data.matchmaking.mode=="match"
        turnHint.Text=online and data.matchmaking.status or "Choose online play or practice with bots."
        mainCommand=online and (state.status=="finished" and "BackLobby" or "Match") or "Match"
        actionButton.Text=online and (state.status=="finished" and "Return to lobby" or "Connecting players...") or "PLAY NOW"
    else
        turnTitle.Text=myTurn and "YOUR TURN" or ((current and current.name or "A resident").."'s turn")
        if state.phase=="end" then turnTitle.Text=myTurn and "Turn complete." or ((current and current.name or "A resident").." has finished.") end
        turnHint.Text=state.notice or "A new address is waiting."
        if myTurn then turnHint.Text=state.phase=="roll" and "Roll to move. Events are optional." or (state.phase=="buy" and "Choose a home level, or skip this lot." or (state.phase=="offer" and "Choose cash or a tactical card." or "Next player starts automatically.")) end
        if myTurn then
            if state.phase=="roll" then mainCommand="Roll";actionButton.Text=mine.detained and "Serve detention" or "ROLL DICE"
            elseif state.phase=="buy" then
                local tile=Config.tiles[state.pendingTile]
                mainCommand="Buy"
                actionButton.Text="Buy home · $"..tile.price.."+"
                passButton.Visible=true
            elseif state.phase=="offer" then mainCommand="Offer";actionButton.Text="CHOOSE REWARD"
            else mainCommand="End";actionButton.Text="Next player" end
        elseif current and current.id==player.UserId and state.phase=="end" then mainCommand="End";actionButton.Text="End turn"
        else mainCommand="Plaza";actionButton.Text="City events" end
    end
    if state.status=="playing" and (not mine or not mine.alive) and data.matchmaking and data.matchmaking.mode=="lobby" then
        mainCommand="Match";actionButton.Text=data.matchmaking.queued and "View matchmaking queue" or "Find an online match"
    end
    if rolling then mainCommand=nil;actionButton.Text="Rolling the dice…" end
    if journeyActive and myTurn then
        mainCommand=nil;passButton.Visible=false;actionButton.Text="ON THE MOVE..."
        turnTitle.Text="YOUR TOKEN IS MOVING"
        turnHint.Text="Your result appears when you land."
    end
    dieA.Active,dieB.Active=mainCommand=="Roll",mainCommand=="Roll"
    dieA:SetAttribute("RollReady",dieA.Active);dieB:SetAttribute("RollReady",dieB.Active)
    dieA.AutoButtonColor,dieB.AutoButtonColor=dieA.Active,dieB.Active
    available(actionButton,mainCommand~=nil,C.gold)
    actionDepth.Visible=mainCommand~=nil and not rolling
    diceTotal.Text=rolling and "ROLLING..." or (state.lastRoll and ("TOTAL "..(state.dice[1]+state.dice[2])) or "TAP TO ROLL")
    if layout and layout.compact then
        actionButton.Size=UDim2.fromOffset(layout.toolbar[3]-(passButton.Visible and 130 or 32),64)
        actionDepth.Size=actionButton.Size
    end
    portfolio.Visible=portfolioOpen and not visitIndex
    homeList:ClearAllChildren()
    local row=0
    for index,property in ipairs(state.properties) do
        if property.ownerId==player.UserId then
            local tile=Config.tiles[index]
            local item=button(homeList,"",2,row*68,276,60,C.paper,function() selected=index;inspectorOpen=true;portfolioOpen=false;render() end)
            local strip=frame(item,9,10,5,40,Color3.fromHex(Config.groups[tile.group].color));round(strip,3)
            text(item,tile.name,26,8,235,24,15,C.ink,true)
            text(item,homeNames[property.level+1].." · $"..rent(state,index).." rent"..(pair(state,player.UserId,tile.group) and " · PAIR" or ""),26,32,235,18,11,C.muted)
            row=row+1
        end
    end
    homeList.CanvasSize=UDim2.fromOffset(0,row*68)
    emptyHomes.Visible=row==0
    inspector.Visible=inspectorOpen and selected~=nil and not portfolioOpen and not visitIndex
    highlight.Adornee=nil
    if selected and Config.tiles[selected] and Config.tiles[selected].kind=="property" then
        local tile,property=Config.tiles[selected],state.properties[selected]
        local owner=resident(state,property.ownerId)
        district.Text=string.upper(Config.groups[tile.group].name)
        propertyName.Text=tile.name
        ownerText.Text=owner and (owner.name.."'s home · "..homeNames[property.level+1]) or ("FOR SALE · from $"..tile.price.." including land")
        ownerMark.BackgroundColor3=owner and Color3.fromHex(Config.playerColors[owner.colorIndex]) or C.muted
        rentText.Text="$"..rent(state,selected).." / visit"
        levelText.Text="LEVEL "..property.level.." / 3"
        local own=property.ownerId==player.UserId
        nextRent.Text=owner and ("Rent "..Config.rentTiers[property.rentTier or 1].."×"..(property.shield and " · SHIELDED" or "")..((property.boost or 0)>0 and (" · BOOST "..property.boost) or "")) or "Choose your starting home level before you buy."
        propertyPreview(selected,owner,property)
        upgradeButton.Visible,sellButton.Visible,paintButton.Visible=own and myTurn,own and myTurn,own and myTurn
        rentButton.Visible=own and myTurn
        visitButton.Visible=own and mine and mine.alive and state.status=="playing"
        visitButton.Text="Walk through your home"
        upgradeButton.Text=property.level==3 and "Fully upgraded" or "Upgrade options"
        available(upgradeButton,myTurn and property.level<Config.maxLevel or false,C.green)
        rentButton.Text=(property.rentTier or 1)>=#Config.rentTiers and "Rent maxed" or "Rent options"
        available(rentButton,myTurn and (property.rentTier or 1)<#Config.rentTiers or false,C.green)
        local board=workspace:FindFirstChild("CitymoneyBoard")
        if board and inspector.Visible then highlight.Adornee=board:FindFirstChild("Property"..selected) or board:FindFirstChild("Tile"..selected) end
    else inspector.Visible=false end
    visitBanner.Visible=visitIndex~=nil
    if visitIndex then visitText.Text="At home · "..Config.tiles[visitIndex].name end
    roster.Visible=not visitIndex and not (layout and layout.compact)
    turnChip.Visible=roster.Visible
    cameraBar.Visible=not visitIndex
    cameraBar.TableView.Text=(root:GetAttribute("ViewMode") or "city")=="city" and "Top view" or "City view"
    replay.Visible=isHost or (data.matchmaking and data.matchmaking.mode=="match")
    replay.Text=data.matchmaking and data.matchmaking.mode=="match" and "Return to matchmaking" or "Play again"
    if state.status=="finished" then
        local winner=resident(state,state.winnerId)
        resultTitle.Text=winner and (winner.name.." wins the neighborhood.") or "A neighborhood well built."
        resultSubtitle.Text=winner and ("$"..worth(state,winner).." net worth. Home, sweet home.") or "Time for a fresh start."
        resultRows:ClearAllChildren()
        local standings=table.clone(state.players)
        table.sort(standings,function(a,b)
            if a.alive~=b.alive then return a.alive end
            local aw,bw=worth(state,a),worth(state,b)
            return aw>bw or (aw==bw and a.colorIndex<b.colorIndex)
        end)
        for rank,entry in ipairs(standings) do
            text(resultRows,rank.."   "..entry.name.."     $"..worth(state,entry),0,(rank-1)*33,468,30,16,rank==1 and C.green or C.muted,rank==1)
        end
    end
    renderPlans()
    menus:render(data)
    boutique:render(data)
    Motion.face(dieA,state.dice[1]>0 and state.dice[1] or 1,pipColor);Motion.face(dieB,state.dice[2]>0 and state.dice[2] or 6,pipColor)
    city:render(data)
    opportunity:render(data)
    commandMenu.button.Visible=not visitIndex
    commandMenu.button.Text="MENU  [M]"
    commandMenu.quick.Visible=state.status=="playing" and not visitIndex
    commandMenu.cards.Text=mine and mine.challenge and mine.challenge.ready and not state.challengeClaimed and "CLAIM REWARD" or "CARDS & GOALS"
    commandMenu.homes.Text="MY HOMES · "..count
    if layout then commandMenu:resize(layout,roster.Size.Y.Offset) end
    goals:render(data,layout,roster.Size.Y.Offset,visitIndex~=nil)
    if layout then menus:resize(layout,roster.Size.Y.Offset) end
end
local function updateLayout()
    local area=safe.AbsoluteSize
    if area.X<1 or area.Y<1 then return end
    layout=Layout.calculate(area.X,area.Y)
    local w,h=layout.width,layout.height
    uiScale.Scale=layout.scale;root.Size,root.Position=UDim2.fromOffset(w,h),UDim2.fromOffset(0,0)
    place(header,20,16,w-40,layout.headerHeight)
    local hw=w-40
    place(mark,14,12,32,32)
    place(brand,58,5,220,32);brand.TextSize=29
    place(strap,60,36,260,15);strap.Visible=not layout.compact
    place(cashLabel,hw-185,7,168,28);cashLabel.TextSize=25
    place(worthLabel,hw-185,36,168,15)
    homesButton.Visible,helpButton.Visible,dayButton.Visible=false,false,false
    if layout.compact then
        place(brand,58,12,210,32);brand.TextSize=25
        place(cashLabel,hw-166,12,150,28);place(worthLabel,hw-166,44,150,17)
    end
    local r=layout.roster;place(roster,r[1],r[2],r[3],roster.Size.Y.Offset)
    local card=layout.inspector;place(inspector,card[1],card[2],card[3],462)
    local fit=layout.compact and math.min(1.6,(layout.toolbar[2]-card[2]-16)/462) or math.min(1,math.max(0.76,card[4]/462))
    local inner=inspector:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    inner.Scale,inner.Parent=fit,inspector
    inspector.Position=UDim2.fromOffset(layout.compact and (w-card[3]*fit)/2 or w-20-card[3]*fit,card[2])
    place(portfolio,w-328,92,308,math.min(440,h-layout.toolbar[4]-125))
    local collectionScale=portfolio:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    collectionScale.Scale,collectionScale.Parent=layout.compact and 1.45 or 1,portfolio
    if layout.compact then
        portfolio.Position=UDim2.fromOffset((w-308*1.45)/2,92)
        portfolio.Size=UDim2.fromOffset(308,math.min(440,(layout.toolbar[2]-112)/1.45))
    end
    homeList.Size=UDim2.fromOffset(284,portfolio.Size.Y.Offset-102)
    local t=layout.toolbar;place(control,t[1],t[2],t[3],t[4])
    if layout.compact then
        place(dieA,16,14,80,80);place(dieB,108,14,80,80)
        place(diceTotal,16,104,172,22);diceTotal.TextSize=16
        place(turnTitle,208,14,t[3]-224,30);turnTitle.TextSize=23
        place(turnHint,208,50,t[3]-224,48);turnHint.TextSize=18
        place(timeText,208,104,t[3]-224,22);timeText.TextSize=16
        place(actionButton,16,144,t[3]-32,64);place(passButton,t[3]-98,144,82,64)
        actionButton.TextSize=22
    else
        place(dieA,18,14,72,72);place(dieB,102,14,72,72)
        place(diceTotal,18,89,156,17);diceTotal.TextSize=11
        place(turnTitle,194,13,t[3]-498,30);turnTitle.TextSize=22
        place(turnHint,194,46,t[3]-498,36);turnHint.TextSize=14
        place(timeText,194,84,t[3]-230,16);timeText.TextSize=12
        place(actionButton,t[3]-208,25,190,58);place(passButton,t[3]-288,31,70,50)
        actionButton.TextSize=18
    end
    turnHint.TextWrapped=true
    place(dieTextA,0,0,48,48);place(dieTextB,0,0,48,48)
    actionDepth.Position,actionDepth.Size=actionButton.Position+UDim2.fromOffset(0,4),actionButton.Size
    place(timeTrack,16,t[4]-5,t[3]-32,3)
    place(toast,(w-400)/2,86,400,45)
    place(visitBanner,(w-440)/2,86,440,58)
    if menus then menus:resize(layout,roster.Size.Y.Offset) end
    if commandMenu then commandMenu:resize(layout,roster.Size.Y.Offset) end
    if data then render() end
end
safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)
updateLayout()
local animationVersion=0
local function diceAnimation(first,second)
    if data and data.club and not data.club.effects then
        Motion.face(dieA,first,dieTextA.TextColor3);Motion.face(dieB,second,dieTextB.TextColor3);return
    end
    animationVersion=animationVersion+1;local version=animationVersion
    rolling=true;render()
    task.spawn(function()
        for step=1,10 do
            if version~=animationVersion then return end
            Motion.face(dieA,math.random(1,6),dieTextA.TextColor3);Motion.face(dieB,math.random(1,6),dieTextB.TextColor3)
            dieA.Rotation,dieB.Rotation=step%2==0 and 7 or -7,step%2==0 and -7 or 7
            task.wait(0.045+step*0.003)
        end
        if version~=animationVersion then return end
        Motion.face(dieA,first,dieTextA.TextColor3);Motion.face(dieB,second,dieTextB.TextColor3);dieA.Rotation,dieB.Rotation=0,0
        rolling=false;render()
    end)
end
snapshot.OnClientEvent:Connect(function(incoming)
    if data and incoming.revision<data.revision then return end
    local old=data
    local before=old and resident(old.game,player.UserId)
    local after=resident(incoming.game,player.UserId)
    data=incoming
    local state=data.game
    if old and state.status=="playing" and old.game.status~="playing" then
        results.Visible=false;focusIndex=nil;inspectorOpen=false;portfolioOpen=false
        chooser.Visible=false;planPending=false;planIndex=nil;planTurn=nil
    end
    if old and state.status=="playing" and state.players[state.turn].id==player.UserId and (old.game.turnCount~=state.turnCount or old.game.status~="playing") then
        notify("YOUR TURN · Upgrade, play a card, or roll the dice!")
    end
    if after and before and after.cash~=before.cash then
        local delta=after.cash-before.cash
        if not layout or not layout.compact then Motion.delta(cashLabel,delta,delta>0 and C.green or C.red,root) end
    end
    if state.status=="playing" and state.phase=="buy" and state.players[state.turn].id==player.UserId then
        if not old or old.game.phase~="buy" or old.game.pendingTile~=state.pendingTile then
            selected,portfolioOpen=state.pendingTile,false
            local turn,index=state.turnCount,state.pendingTile
            local delay=math.max(0,(data.journeyUntil or 0)-workspace:GetServerTimeNow())
            task.delay(delay,function()
                if data and data.game.status=="playing" and data.game.turnCount==turn and data.game.phase=="buy" and data.game.pendingTile==index and not chooser.Visible then openPlans("buy",index) end
            end)
        end
    end
    if planPending and chooser.Visible then
        local property=state.properties[planIndex]
        local applied=property and (planMode=="rent" and (property.rentTier or 1)==planLevel+1 or planMode~="rent" and property.level==planLevel)
        if property and property.ownerId==player.UserId and applied then
            chooser.Visible=false;planPending=false
        end
    end
    if old then
        for index,property in ipairs(state.properties) do
            if property.ownerId==player.UserId and old.game.properties[index].ownerId~=player.UserId then
                selected=index
                notify("Your level "..property.level.." "..homeNames[property.level+1].." at "..Config.tiles[index].name.." is ready.")
            elseif property.ownerId==player.UserId and old.game.properties[index].ownerId==player.UserId and property.level>old.game.properties[index].level then
                selected=index
                notify(Config.tiles[index].name.." is now a level "..property.level.." "..homeNames[property.level+1].."!")
            elseif property.ownerId==player.UserId and (property.rentTier or 1)>(old.game.properties[index].rentTier or 1) then
                notify(Config.tiles[index].name.." now charges "..Config.rentTiers[property.rentTier].."× rent on future visits.")
            elseif old.game.properties[index].ownerId==player.UserId and property.ownerId~=player.UserId and state.lastAction and state.lastAction.kind=="demolish" and state.lastAction.tile==index and state.lastAction.seq>(old.game.lastAction and old.game.lastAction.seq or 0) then
                notify("Your house at "..Config.tiles[index].name.." was demolished. The lot is now for sale.")
            end
        end
        if state.turnCount~=old.game.turnCount then focusIndex=nil end
        if state.lastRoll and state.lastRoll.seq>(old.game.lastRoll and old.game.lastRoll.seq or 0) then diceAnimation(state.lastRoll.values[1],state.lastRoll.values[2]) end
    end
    if state.status=="finished" and (not old or old.game.status~="finished") then
        results.Visible=true;help.Visible=false;sale.Visible=false
        menus.lobby.Visible=false;menus.actions.Visible=false;menus.practiceSettings.Visible=false;boutique.shade.Visible=false
        city.shade.Visible=false;commandMenu.shade.Visible=false
        opportunity.shade.Visible=false
        boutique:celebrate()
    end
    moments:observe(data,old)
    render()
end)
feedback.OnClientEvent:Connect(function(message)
    locked=false;planPending=false
    if chooser.Visible then planError=message end
    notify(message);renderPlans();menus:feedback(message);boutique:feedback(message);city:feedback(message)
    opportunity:feedback(message);goals:feedback()
end)
local function inspect(position)
    if help.Visible or sale.Visible or results.Visible or chooser.Visible or visitIndex or menus:isOpen() or boutique:isOpen() or city:isOpen() or commandMenu:isOpen() or opportunity:isOpen() then return end
    local camera,board=workspace.CurrentCamera,workspace:FindFirstChild("CitymoneyBoard")
    if not camera or not board then return end
    local ray=camera:ScreenPointToRay(position.X,position.Y)
    local parameters=RaycastParams.new();parameters.FilterType,parameters.FilterDescendantsInstances=Enum.RaycastFilterType.Include,{board}
    local hit=workspace:Raycast(ray.Origin,ray.Direction*1500,parameters)
    local interaction=hit and (hit.Instance:GetAttribute("Interaction") or hit.Instance.Parent:GetAttribute("Interaction"))
    if interaction=="dice" then
        if mainCommand=="Roll" then mainAction() else notify("Click the dice when it is your turn to roll.") end
        return
    elseif interaction then openCity(interaction);return end
    local index=hit and (hit.Instance:GetAttribute("TileIndex") or hit.Instance.Parent:GetAttribute("TileIndex"))
    if index and Config.tiles[index].kind=="property" then selected,inspectorOpen,portfolioOpen=index,true,false;render() end
end
Input.TouchTapInWorld:Connect(function(position,processed) if not processed then inspect(position) end end)
Input.InputBegan:Connect(function(input,processed)
    if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then inspect(input.Position) end
    if not processed and input.KeyCode==Enum.KeyCode.M and not visitIndex and not help.Visible and not sale.Visible and not results.Visible and not chooser.Visible and not menus:isOpen() and not boutique:isOpen() and not city:isOpen() and not opportunity:isOpen() then commandMenu.shade.Visible=not commandMenu.shade.Visible;return end
    if processed or help.Visible or sale.Visible or results.Visible or chooser.Visible or menus:isOpen() or boutique:isOpen() or city:isOpen() or commandMenu:isOpen() or opportunity:isOpen() then return end
    if input.KeyCode==Enum.KeyCode.B and visitIndex then send("Return")
    elseif input.KeyCode==Enum.KeyCode.R and mainCommand=="Roll" then send("Roll")
    elseif input.KeyCode==Enum.KeyCode.P and not visitIndex then openCity("overview")
    elseif input.KeyCode==Enum.KeyCode.Space and mainCommand and not visitIndex then mainAction() end
end)
Input.InputChanged:Connect(function(input,processed)
    if not processed and not visitIndex and input.UserInputType==Enum.UserInputType.MouseWheel then
        root:SetAttribute("Zoom",math.clamp((root:GetAttribute("Zoom") or 1)-input.Position.Z*0.06,0.75,1.5))
    end
end)
RunService.RenderStepped:Connect(function(dt)
    if data then
        local travelling=data.game.status=="playing" and workspace:GetServerTimeNow()<(data.journeyUntil or 0)
        if travelling~=journeyActive then render() end
        opportunity:update(data)
    end
    boardView:update(dt,root,safe,layout,data,focusIndex,inspector.Visible or portfolio.Visible,visitIndex,player)
    local blocked=visitIndex or inspector.Visible or portfolio.Visible or help.Visible or sale.Visible or results.Visible or chooser.Visible or menus:isOpen() or boutique:isOpen() or city:isOpen() or commandMenu:isOpen() or opportunity:isOpen()
    hover:update(data,layout,safe,blocked or moments.card.Visible)
    if data then moments:update(data,layout,blocked) end
    if data and data.game.status=="playing" then
        local handing=data.game.phase=="end"
        local seconds=math.max(0,(handing and data.handoffAt or data.deadline)-workspace:GetServerTimeNow())
        local myTurn=data.game.players[data.game.turn].id==player.UserId
        timeText.Text=journeyActive and "DICE · MOVE · ARRIVE" or (handing and ("NEXT TURN IN "..math.ceil(seconds).."s") or (myTurn and (math.ceil(seconds).."s left"..(layout.compact and "" or " · Events [P]")) or "Your turn starts automatically"))
        if chooser.Visible and not planError then
            local tile=Config.tiles[planIndex]
            planNote.Text=(planMode=="buy" and ("Land $"..tile.price.." + building $"..planLevel*tile.upgrade) or (planMode=="rent" and "This multiplier applies to future rent payments." or "Only the added levels are charged.")).."  ·  "..math.ceil(seconds).."s left"
        end
        timeFill.Size,timeFill.BackgroundColor3=UDim2.fromScale(math.clamp(seconds/(handing and Config.autoAdvanceSeconds or Config.turnSeconds),0,1),1),not handing and seconds<10 and C.red or C.green
        if journeyActive then timeFill.Size,timeFill.BackgroundColor3=UDim2.fromScale(Journey.progress(Config,data.game.lastRoll,data.journeyUntil-workspace:GetServerTimeNow()),1),C.gold end
    else timeText.Text="2 / 4 players · online queues or practice with bots";timeFill.Size=UDim2.fromScale(0,1) end
end)
action:FireServer("Sync")
task.delay(3,function() if not data then action:FireServer("Sync") end end)
