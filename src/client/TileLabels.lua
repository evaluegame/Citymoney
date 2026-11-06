-- Clickable labels fit inside their physical space, including perspective sides.
local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Players=game:GetService("Players")
local Thai=require(shared.Thai)
local Config,Plans,Spaces,Actors=require(shared.Config),require(shared.PropertyPlans),require(shared.BoardSpaces),require(shared.Actors)
local Labels={}
Labels.__index=Labels
local special={start={"CITY GATE","+$200"},visit={"JAIL","JUST VISIT"},park={"PARK","FREE CARD"},detention={"GO TO","JAIL"},event={"CITY","NEWS"},tax={"CITY TAX","$120"}}
function Labels.new(root,onSelect,onInteraction,language)
    local self=setmetatable({language=language,buttons={},captions={},sources={},revision=nil},Labels)
    for index,tile in ipairs(Config.tiles) do
        local button=Instance.new("TextButton")
        button.Name,button.AnchorPoint,button.ZIndex="DeedLabel"..index,Vector2.new(0.5,0.5),5
        button.BackgroundColor3,button.BackgroundTransparency,button.BorderSizePixel=Color3.fromHex("FFFFFF"),0,0
        button.TextColor3,button.Font,button.TextWrapped=Color3.fromHex("1B2C48"),Enum.Font.GothamBold,false
        button.TextScaled,button.ClipsDescendants=true,true
        button:SetAttribute("CitymoneyTile",index)
        button.Text=tile.name;button.Parent=root
        local corner=Instance.new("UICorner");corner.CornerRadius,corner.Parent=UDim.new(0,2),button
        local limit=Instance.new("UITextSizeConstraint");limit.MinTextSize,limit.Parent=1,button
        local outline=Instance.new("UIStroke");outline.Color,outline.Thickness,outline.ApplyStrokeMode,outline.Parent=Color3.fromHex(tile.group and Config.groups[tile.group].color or "85A393"),0.8,Enum.ApplyStrokeMode.Border,button
        button.Activated:Connect(function()
            if tile.kind=="property" then onSelect(index) else onInteraction(tile.kind=="card" and "cards" or (tile.kind=="park" and "contracts" or "news")) end
        end)
        self.buttons[index]=button
    end
    return self
end
function Labels:update(camera,safe,scale,data,enabled,rect)
    local board=workspace:FindFirstChild("CitymoneyBoard")
    if data and self.revision~=data.revision then
        self.revision=data.revision
        for index,tile in ipairs(Config.tiles) do
            local property=data.game.properties[index]
            local owner
            for _,resident in ipairs(data.game.players) do if resident.id==property.ownerId then owner=resident end end
            local value=tile.kind=="property" and ("$"..(owner and Plans.projectedRent(Config,data.game,owner.id,index,property.level) or tile.price)) or (tile.kind=="card" and "FREE CARD" or "")
            self.captions[index]={name=tile.name,value=value,owned=owner~=nil}
            local stroke=self.buttons[index]:FindFirstChildOfClass("UIStroke")
            stroke.Color=Color3.fromHex(owner and Config.playerColors[owner.colorIndex] or (tile.group and Config.groups[tile.group].color or tile.color or "85A393"))
            stroke.Thickness=owner and 1.2 or 0.8
        end
    end
    local offset=safe.AbsolutePosition
    local figures={}
    if enabled and data and board then
        for _,resident in ipairs(data.game.players) do if resident.alive then
            local player=type(resident.id)=="number" and Players:GetPlayerByUserId(resident.id)
            local character=player and player.Character
            local model=character and character:GetAttribute("CitymoneyPrepared") and character or board:FindFirstChild("Figure_"..resident.id)
            local head=model and model:FindFirstChild("Head")
            if head then
                local point,visible=camera:WorldToScreenPoint(head.Position)
                if visible then
                    local root=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
                    local humanoid=model:FindFirstChildOfClass("Humanoid")
                    local leg=model:FindFirstChild("Left Leg") or model:FindFirstChild("Right Leg")
                    local height=humanoid and root and root.Size.Y/2+(leg and leg.Size.Y or humanoid.HipHeight) or Actors.height-0.2
                    local foot=root and camera:WorldToScreenPoint(root.Position-Vector3.new(0,height,0)) or point
                    local margin=math.max(2,8*math.min(1,scale))
                    table.insert(figures,{left=math.min(point.X,foot.X)-margin,right=math.max(point.X,foot.X)+margin,
                        top=math.min(point.Y,foot.Y)-margin,bottom=math.max(point.Y,foot.Y)+margin})
                end
            end
        end end
    end
    for index,button in ipairs(self.buttons) do
        button.Visible=false
        if enabled then
            local projected=Spaces.project(index,function(p)
                local screen=camera:WorldToScreenPoint(Vector3.new(table.unpack(p)))
                return {screen.X,screen.Y}
            end)
            if projected then
                local x,y,w,h=projected.x,projected.y,projected.width,projected.height
                local caption=self.captions[index]
                if caption then
                    local short=special[Config.tiles[index].kind]
                    local sourceName=short and short[1] or string.match(caption.name,"^%S+")
                    local sourceValue=short and short[2] or ((caption.owned and "RENT " or "")..caption.value)
                    local name=self.language:shortName(index,sourceName)
                    local value=self.language:text(sourceValue)
                    local source=sourceName.."\n"..sourceValue
                    if self.sources[index]~=source then self.sources[index]=source;button.Text=source end
                    local font=math.min(12,h/2.8,w/(math.max(Thai.width(name),Thai.width(value))*0.62+1))
                    button.TextSize=math.max(1,font/scale)
                    button:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=math.max(1,math.floor(font/scale))
                end
                button.Size,button.Position=UDim2.fromOffset(w/scale,h/scale),UDim2.fromOffset((x-offset.X)/scale,(y-offset.Y)/scale)
                button.Rotation=projected.rotation
                local rx,ry=projected.right[1],projected.right[2]
                local ex,ey=math.abs(rx)*w/2+math.abs(ry)*h/2,math.abs(ry)*w/2+math.abs(rx)*h/2
                button.Visible=not rect or (x-ex>=rect[1] and x+ex<=rect[1]+rect[3] and y-ey>=rect[2] and y+ey<=rect[2]+rect[4])
                -- Floor lettering remains within the space when a body passes
                -- in front. An opaque screen badge must never hide that body.
                for _,figure in ipairs(figures) do
                    if x-ex<figure.right and x+ex>figure.left and y-ey<figure.bottom and y+ey>figure.top then button.Visible=false;break end
                end
            end
        end
        local plate=board and board:FindFirstChild("DeedPlate"..index)
        local caption=plate and plate:FindFirstChild("Caption")
        if caption then caption.Enabled=not button.Visible end
    end
end
return Labels
