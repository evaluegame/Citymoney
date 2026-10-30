-- Upright, screen-sized labels keep the tabletop readable on every board edge.
local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Players=game:GetService("Players")
local Config,Architecture,Plans=require(shared.Config),require(shared.Architecture),require(shared.PropertyPlans)
local Labels={}
Labels.__index=Labels
local special={start={"GATE","+$200"},visit={"JAIL","VISIT"},park={"PARK","CARD"},detention={"JAIL","GO TO"},event={"NEWS",""},tax={"TAX","$120"}}
local function position(index)
    local p=Architecture.position(index)
    return Vector3.new(p[1],1.9,p[3])
end
function Labels.new(root,onSelect,onInteraction)
    local self=setmetatable({buttons={},captions={},revision=nil,enabled=nil},Labels)
    for index,tile in ipairs(Config.tiles) do
        local button=Instance.new("TextButton")
        button.Name,button.AnchorPoint,button.ZIndex="DeedLabel"..index,Vector2.new(0.5,0.5),5
        button.BackgroundColor3,button.BackgroundTransparency,button.BorderSizePixel=Color3.fromHex("FFFFFF"),0.04,0
        button.TextColor3,button.Font,button.TextWrapped=Color3.fromHex("1B2C48"),Enum.Font.GothamBold,false
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
            local value=tile.kind=="property" and ("$"..(owner and Plans.projectedRent(Config,data.game,owner.id,index,property.level) or tile.price)) or ""
            self.captions[index]={name=tile.name,value=value,owned=owner~=nil}
            local stroke=self.buttons[index]:FindFirstChildOfClass("UIStroke")
            stroke.Color=Color3.fromHex(owner and Config.playerColors[owner.colorIndex] or (tile.group and Config.groups[tile.group].color or "85A393"))
            stroke.Thickness=owner and 2.5 or 1.5
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
                if visible then table.insert(figures,point) end
            end
        end end
    end
    for index,button in ipairs(self.buttons) do
        button.Visible=enabled
        if enabled then
            local screen,visible=camera:WorldToScreenPoint(position(index))
            local nextScreen=camera:WorldToScreenPoint(position(index%24+1))
            local previousScreen=camera:WorldToScreenPoint(position((index-2)%24+1))
            local dx,dy=math.abs(nextScreen.X-screen.X),math.abs(nextScreen.Y-screen.Y)
            local px,py=previousScreen.X-screen.X,previousScreen.Y-screen.Y
            local spacing=math.min(math.sqrt(dx*dx+dy*dy),math.sqrt(px*px+py*py))
            local corner=(index-1)%6==0
            -- Corners need compact badges; an oversized corner would obscure
            -- the neighboring space. Every badge scales down with the route.
            local width=corner and math.min(44,spacing*0.8) or math.min(96,spacing*(dx>=dy and 0.96 or 1.7))
            local height=math.min(corner and 44 or (dx>=dy and 44 or 38),spacing*(corner and 0.8 or (dx>=dy and 0.88 or 0.8)))
            local caption=self.captions[index]
            if caption then
                -- Short map names stay legible; the property card gives the full name.
                local name=string.match(caption.name,"^%S+")
                local short=special[Config.tiles[index].kind]
                if short then name=short[1] end
                local value=short and short[2] or caption.value
                if caption.owned then value=(width<48 and "RENT\n" or "Rent ")..value end
                if width<48 then
                    if not short then name=""
                    elseif Config.tiles[index].kind=="start" then name,value="GO",""
                    elseif Config.tiles[index].kind=="visit" or Config.tiles[index].kind=="park" then value=""
                    elseif Config.tiles[index].kind=="detention" then name,value="TO","JAIL" end
                end
                button.Text=name..(value~="" and ((name~="" and "\n" or "")..value) or "")
                local longest=math.max(#name,#value)
                button.TextSize=math.max(9,math.min(12,height/2.8,(width-3)/math.max(1,longest*0.85)))/scale
            end
            button.Size,button.Position=UDim2.fromOffset(width/scale,height/scale),UDim2.fromOffset((screen.X-offset.X)/scale,(screen.Y-offset.Y)/scale)
            button.Visible=visible and (not rect or (screen.X-width/2>=rect[1] and screen.X+width/2<=rect[1]+rect[3] and screen.Y-height/2>=rect[2] and screen.Y+height/2<=rect[2]+rect[4]))
            -- A screen label must never cover a pawn. Reveal the underlying
            -- floor caption while a real avatar or bot crosses its space.
            for _,figure in ipairs(figures) do
                if math.abs(figure.X-screen.X)<width/2+14 and math.abs(figure.Y-screen.Y)<height/2+14 then button.Visible=false;break end
            end
        end
        local tile=board and board:FindFirstChild("Tile"..index)
        local caption=tile and tile:FindFirstChild("Caption")
        if caption then caption.Enabled=not button.Visible end
    end
end
return Labels
