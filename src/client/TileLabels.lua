-- Upright, screen-sized labels keep the tabletop readable on every board edge.
local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Config,Architecture,Plans=require(shared.Config),require(shared.Architecture),require(shared.PropertyPlans)
local Labels={}
Labels.__index=Labels
function Labels.new(root,onSelect,onInteraction)
    local self=setmetatable({buttons={},revision=nil,enabled=nil},Labels)
    for index,tile in ipairs(Config.tiles) do
        local button=Instance.new("TextButton")
        button.Name,button.AnchorPoint,button.ZIndex="DeedLabel"..index,Vector2.new(0.5,0.5),5
        button.BackgroundColor3,button.BackgroundTransparency,button.BorderSizePixel=Color3.fromHex("FFF9E9"),0.12,0
        button.TextColor3,button.Font,button.TextWrapped=Color3.fromHex("263E34"),Enum.Font.GothamBold,true
        button.Text=tile.name;button.Parent=root
        local corner=Instance.new("UICorner");corner.CornerRadius,corner.Parent=UDim.new(0,5),button
        local outline=Instance.new("UIStroke");outline.Color,outline.Thickness,outline.ApplyStrokeMode,outline.Parent=Color3.fromHex(tile.group and Config.groups[tile.group].color or "85A393"),1.5,Enum.ApplyStrokeMode.Border,button
        button.Activated:Connect(function()
            if tile.kind=="property" then onSelect(index) else onInteraction(tile.kind=="park" and "contracts" or "news") end
        end)
        self.buttons[index]=button
    end
    return self
end
function Labels:update(camera,safe,scale,data,enabled,rect)
    local board=workspace:FindFirstChild("CitymoneyBoard")
    if self.enabled~=enabled or self.board~=board then
        self.enabled,self.board=enabled,board
        if board then
            for index=1,24 do
                local tile=board:FindFirstChild("Tile"..index)
                local caption=tile and tile:FindFirstChild("Caption")
                if caption then caption.Enabled=not enabled end
            end
        end
    end
    if data and self.revision~=data.revision then
        self.revision=data.revision
        for index,tile in ipairs(Config.tiles) do
            local property=data.game.properties[index]
            local owner
            for _,resident in ipairs(data.game.players) do if resident.id==property.ownerId then owner=resident end end
            local value=tile.kind=="property" and (owner and ("Rent $"..Plans.projectedRent(Config,data.game,owner.id,index,property.level)) or ("$"..tile.price)) or ""
            self.buttons[index].Text=tile.name..(value~="" and ("\n"..value) or "")
            self.buttons[index]:FindFirstChildOfClass("UIStroke").Color=Color3.fromHex(owner and Config.playerColors[owner.colorIndex] or (tile.group and Config.groups[tile.group].color or "85A393"))
        end
    end
    local offset=safe.AbsolutePosition
    for index,button in ipairs(self.buttons) do
        button.Visible=enabled
        if enabled then
            local p=Architecture.position(index)
            local q=Architecture.position(index%24+1)
            local screen,visible=camera:WorldToScreenPoint(Vector3.new(p[1],1.9,p[3]))
            local nextScreen=camera:WorldToScreenPoint(Vector3.new(q[1],1.9,q[3]))
            local dx,dy=math.abs(nextScreen.X-screen.X),math.abs(nextScreen.Y-screen.Y)
            local spacing=math.sqrt(dx*dx+dy*dy)
            local width=dx>=dy and math.clamp(spacing*0.9,34,88) or math.clamp(spacing*1.4,50,86)
            local height=dx>=dy and 40 or math.clamp(spacing*0.88,26,40)
            button.Size,button.Position=UDim2.fromOffset(width/scale,height/scale),UDim2.fromOffset((screen.X-offset.X)/scale,(screen.Y-offset.Y)/scale)
            button.TextSize=math.min(11,height/3.25)/scale
            button.Visible=visible and (not rect or (screen.X-width/2>=rect[1] and screen.X+width/2<=rect[1]+rect[3] and screen.Y-height/2>=rect[2] and screen.Y+height/2<=rect[2]+rect[4]))
        end
    end
end
return Labels
