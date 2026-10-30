local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Board, Architecture, Scene = require(shared.Board), require(shared.Architecture), require(shared.Scene)
local Cosmetics=require(shared.Cosmetics)
local DiceWorld=require(script.Parent.DiceWorld)
local Plaza=require(shared.Plaza)
local Effects=require(script.Parent.WorldEffects)
local Journey=require(shared.Journey)
local Actors=require(shared.Actors)
local World = {}
World.__index = World

function World.tilePosition(index)
    return Vector3.new(table.unpack(Board.position(index)))
end

function World.new(config)
    local self = setmetatable({ config=config, tokens={}, positions={}, motions={}, generations={}, propertyViews={}, visiting={} }, World)
    local old = workspace:FindFirstChild("CitymoneyBoard")
    if old then old:Destroy() end
    self.root = Instance.new("Folder")
    self.root.Name, self.root.Parent = "CitymoneyBoard", workspace
    -- Parcel geometry is replaced independently on purchase, repaint and upgrade.
    local entries = {}
    for _, entry in ipairs(Board.generate(config)) do
        local die=entry.interaction=="dice" and (string.match(entry.name,"^DiceBody") or string.match(entry.name,"^DiceShell") or string.match(entry.name,"^DiceEdge") or string.match(entry.name,"^DiceCorner") or string.match(entry.name,"^Pip%d$"))
        if not die and not (entry.tileIndex and config.tiles[entry.tileIndex].kind == "property" and entry.name ~= "Tile"..entry.tileIndex and entry.name ~= "DistrictInlay") then
            table.insert(entries, entry)
        end
    end
    Scene.populate(entries, self.root)
    self.dice=DiceWorld.new(self.root,config)
    for _,part in ipairs(self.root:GetChildren()) do
        if part.Name=="StationLabel" and part:GetAttribute("Interaction")=="festival" then self.festivalLabel=part:FindFirstChild("Caption") end
    end
    for index, tile in ipairs(config.tiles) do
        if tile.kind == "property" then self.propertyViews[index] = { key="", model=nil } end
    end
    return self
end

function World:cancelMotion(id)
    self.generations[id] = (self.generations[id] or 0) + 1
    local motion = self.motions[id]
    if motion then
        motion.connection:Disconnect()
        motion.tween:Cancel()
        motion.value:Destroy()
        self.motions[id] = nil
    end
end

function World:tokenFrame(index, seat, model, from)
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local height = humanoid and root and (humanoid.HipHeight+root.Size.Y/2+0.2) or 2.3
    local p,yaw=Actors.pose(index,seat,height,from)
    return CFrame.new(table.unpack(p))*CFrame.Angles(0,yaw,0)
end

function World:figure(resident)
    local model = Scene.model(Actors.figure(self.config.playerColors[resident.colorIndex]),"Figure_"..resident.id,self.root)
    model.PrimaryPart = model:FindFirstChild("Torso")
    model:PivotTo(CFrame.new())
    return model
end

function World:prepareCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root or player.Character ~= character then return end
    if character:GetAttribute("CitymoneyScale")~=self.config.avatarScale then
        local scaled=pcall(function() character:ScaleTo(self.config.avatarScale) end)
        if scaled then character:SetAttribute("CitymoneyScale",self.config.avatarScale) end
    end
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    if self.visiting[player.UserId] then
        self:visit(player, self.visiting[player.UserId])
    else
        humanoid.WalkSpeed, humanoid.AutoRotate, root.Anchored = 0, false, true
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    character:SetAttribute("CitymoneyPrepared",true)
    if self.state then self:sync(self.state) end
end

function World:visitorList()
    local list = {}
    for id, tile in pairs(self.visiting) do table.insert(list,{ id=id, tile=tile }) end
    return list
end

function World:visit(player, index)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return false, "Your avatar is still loading." end
    self:cancelMotion(player.UserId)
    self.visiting[player.UserId] = index
    local position, yaw = Architecture.porch(index)
    root.Anchored, humanoid.WalkSpeed, humanoid.AutoRotate = false, 12, true
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = part==root or part.Name=="Torso" or part.Name=="UpperTorso" or part.Name=="LowerTorso"
        end
    end
    humanoid.JumpPower = 32
    root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    character:PivotTo(CFrame.new(position[1],position[2]+humanoid.HipHeight+root.Size.Y/2,position[3]) * CFrame.Angles(0,yaw,0))
    return true
end

function World:endVisit(id)
    if not self.visiting[id] then return end
    self.visiting[id] = nil
    local model = self.tokens[id]
    if model and model.Parent then
        local humanoid, root = model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
        if humanoid and root then humanoid.WalkSpeed, humanoid.AutoRotate, root.Anchored = 0, false, true end
        for _, part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end
        local seat = 1
        for index, resident in ipairs(self.state and self.state.players or {}) do if resident.id==id then seat=index end end
        model:PivotTo(self:tokenFrame(self.positions[id] or 1,seat,model))
    end
end

function World:wireDoor(model, ownerId)
    local door = model:FindFirstChild("Door")
    if not door then return end
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText, prompt.ObjectText, prompt.HoldDuration = "Open / close", "Your front door", 0
    prompt.MaxActivationDistance, prompt.RequiresLineOfSight, prompt.Parent = 8, false, door
    local pieces = {}
    local hinge = door.CFrame * CFrame.new(-door.Size.X/2,0,0)
    for _, name in ipairs({ "Door", "DoorGlass", "Doorknob" }) do
        local object=model:FindFirstChild(name)
        if object then table.insert(pieces,{ object=object, offset=hinge:ToObjectSpace(object.CFrame) }) end
    end
    local opened, busy = false, false
    prompt.Triggered:Connect(function(player)
        if player.UserId ~= ownerId or busy or not model.Parent then return end
        busy, opened = true, not opened
        for _, piece in ipairs(pieces) do
            piece.object.CanCollide = not opened and piece.object==door
            TweenService:Create(piece.object,TweenInfo.new(0.35,Enum.EasingStyle.Quad),
                { CFrame=hinge*CFrame.Angles(0,opened and math.rad(105) or 0,0)*piece.offset }):Play()
        end
        task.delay(0.4,function() busy=false end)
    end)
end

function World:styleAvatar(model,resident)
    local styleId,effects="classic",true
    if self.club then styleId,effects=self.club:visual(resident.id) end
    local style=Cosmetics.get(styleId)
    local root=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root then return end
    if model:GetAttribute("ClubStyle")~=style.id then
        for _,name in ipairs({"ClubAura","ClubTrail","ClubTrailStart","ClubTrailEnd"}) do
            local old=model:FindFirstChild(name,true);if old then old:Destroy() end
        end
        model:SetAttribute("ClubStyle",style.id)
        if style.premium then
            local humanoid=model:FindFirstChildOfClass("Humanoid")
            local offset=humanoid and (humanoid.HipHeight+root.Size.Y/2) or 2.1
            local aura=Instance.new("Part")
            aura.Name,aura.Shape,aura.Size="ClubAura",Enum.PartType.Cylinder,Vector3.new(0.05,4.1,4.1)
            aura.Material,aura.Color,aura.Transparency=Enum.Material.Neon,Color3.fromHex(style.accent),0.65
            aura.CanCollide,aura.CanTouch,aura.CanQuery,aura.Massless=false,false,false,true
            aura.CFrame=root.CFrame*CFrame.new(0,-offset+0.01,0)*CFrame.Angles(0,0,math.pi/2)
            aura.Parent=model
            local weld=Instance.new("WeldConstraint");weld.Part0,weld.Part1,weld.Parent=root,aura,aura
            local a,b=Instance.new("Attachment"),Instance.new("Attachment")
            a.Name,a.Position,a.Parent="ClubTrailStart",Vector3.new(-0.65,-0.6,0.15),root
            b.Name,b.Position,b.Parent="ClubTrailEnd",Vector3.new(0.65,-0.6,0.15),root
            local trail=Instance.new("Trail")
            trail.Name,trail.Attachment0,trail.Attachment1="ClubTrail",a,b
            trail.Color=ColorSequence.new(Color3.fromHex(self.config.playerColors[resident.colorIndex]),Color3.fromHex(style.accent))
            trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.65),NumberSequenceKeypoint.new(1,1)})
            trail.Lifetime,trail.MinLength,trail.LightEmission=0.35,0.1,0.7
            trail.Enabled,trail.Parent=false,model
        end
    end
    local aura=model:FindFirstChild("ClubAura")
    if aura then aura.Transparency=resident.alive and 0.65 or 1 end
    local trail=model:FindFirstChild("ClubTrail")
    if trail then
        trail.Color=ColorSequence.new(Color3.fromHex(self.config.playerColors[resident.colorIndex]),Color3.fromHex(style.accent))
        trail.Enabled=resident.alive and effects and self.state.status=="playing" and self.visiting[resident.id]~=nil
    end
end

function World:sync(state)
    self.state = state
    if self.festivalLabel and state.turnCount~=self.festivalTurn then
        self.festivalTurn=state.turnCount
        local event=Plaza.festival(self.config,state)
        self.festivalLabel.TextLabel.Text="FESTIVAL\n$"..event.cost
    end
    local newRoll=self.dice:sync(state,self.club)
    if newRoll then self.moveReadyAt=os.clock()+self.config.diceSeconds end
    -- Buying immediately constructs a complete home, including its owner's sign.
    for index, view in pairs(self.propertyViews) do
        local property = state.properties[index]
        local styleId=self.club and self.club:visual(property.ownerId) or "classic"
        local key = tostring(property.ownerId)..":"..property.level..":"..(property.paint or 0)..":"..styleId
        if key ~= view.key then
            local previousOwner,previousLevel=view.ownerId,view.level
            view.key = key
            view.ownerId,view.level=property.ownerId,property.level
            if view.model then view.model:Destroy() end
            local owner
            for _, resident in ipairs(state.players) do if resident.id==property.ownerId then owner=resident end end
            local entries = Architecture.property(self.config,index,owner and owner.name or false,
                owner and self.config.playerColors[owner.colorIndex] or "A6B4A0",property.level,property.paint or 0,nil,styleId)
            view.model = Scene.model(entries,"Property"..index,self.root)
            view.model:SetAttribute("TileIndex",index)
            view.model:SetAttribute("OwnerId",owner and owner.id or false)
            view.model:SetAttribute("OwnerName",owner and owner.name or "For sale")
            view.model:SetAttribute("OwnerColor",owner and self.config.playerColors[owner.colorIndex] or "DCC098")
            view.model:SetAttribute("ClubStyle",styleId)
            view.effectsKey=nil
            if owner then
                self:wireDoor(view.model,owner.id)
                if previousOwner~=owner.id or property.level>(previousLevel or 0) then
                    local p=Architecture.site(index)
                    local animated=true
                    if self.club then local _,effects=self.club:visual(owner.id);animated=effects end
                    Effects.reveal(view.model,Vector3.new(table.unpack(p)),self.config.playerColors[owner.colorIndex],property.level,previousOwner==owner.id,animated)
                end
                local glow=Instance.new("Highlight")
                glow.FillTransparency,glow.OutlineColor,glow.OutlineTransparency=1,Color3.fromHex(self.config.playerColors[owner.colorIndex]),0.1
                glow.Adornee,glow.Parent=view.model,view.model
                TweenService:Create(glow,TweenInfo.new(1.1),{OutlineTransparency=1}):Play()
                task.delay(1.2,function() glow:Destroy() end)
            end
            for id, visitingIndex in pairs(self.visiting) do
                if visitingIndex==index then
                    local visitor=Players:GetPlayerByUserId(id)
                    if owner and owner.id==id and visitor then self:visit(visitor,index) else self:endVisit(id) end
                end
            end
        end
        local effectsKey=tostring(property.shield)..":"..(property.boost or 0)..":"..(property.rentTier or 1)
        if view.model and view.effectsKey~=effectsKey then
            view.effectsKey=effectsKey
            for _,name in ipairs({"ProtectionSign","RentBoostSign","RentRateSign"}) do
                local sign=view.model:FindFirstChild(name)
                if sign then sign:Destroy() end
            end
            local owner
            for _,entry in ipairs(state.players) do if entry.id==property.ownerId then owner=entry end end
            if owner then
                local effects={}
                for _,entry in ipairs(Architecture.property(self.config,index,owner.name,self.config.playerColors[owner.colorIndex],property.level,property.paint or 0,property)) do
                    if entry.name=="ProtectionSign" or entry.name=="RentBoostSign" or entry.name=="RentRateSign" then table.insert(effects,entry) end
                end
                Scene.populate(effects,view.model)
            end
        end
    end
    local present = {}
    for seat, resident in ipairs(state.players) do
        present[resident.id] = true
        local player = type(resident.id)=="number" and Players:GetPlayerByUserId(resident.id) or nil
        local character = player and player.Character
        if character and (not character:FindFirstChild("HumanoidRootPart") or not character:GetAttribute("CitymoneyPrepared")) then character=nil end
        local model = self.tokens[resident.id]
        if character and model~=character then
            self:cancelMotion(resident.id)
            if model and model:GetAttribute("GeneratedFigure") then model:Destroy() end
            model, self.tokens[resident.id], self.positions[resident.id] = character, character, nil
        elseif not model or not model.Parent then
            self:cancelMotion(resident.id)
            model = self:figure(resident)
            model:SetAttribute("GeneratedFigure",true)
            self.tokens[resident.id], self.positions[resident.id] = model, nil
        end
        local tag = model:FindFirstChild("ResidentTag")
        if not tag then
            tag=Instance.new("BillboardGui")
            tag.Name, tag.Size, tag.StudsOffset, tag.AlwaysOnTop, tag.MaxDistance = "ResidentTag", UDim2.fromOffset(132,28),Vector3.new(0,2.5,0),true,500
            tag.Adornee, tag.Parent = model:FindFirstChild("Head") or model.PrimaryPart, model
            local label=Instance.new("TextLabel")
            label.Size,label.BackgroundTransparency,label.TextSize,label.Font = UDim2.fromScale(1,1),0.12,12,Enum.Font.GothamBold
            label.BackgroundColor3,label.BorderSizePixel=Color3.fromHex("1B2C48"),0
            label.TextColor3,label.TextStrokeTransparency,label.TextTruncate,label.Parent = Color3.fromHex("FFFFFF"),1,Enum.TextTruncate.AtEnd,tag
            local corner=Instance.new("UICorner");corner.CornerRadius,corner.Parent=UDim.new(0,8),label
        end
        local active = state.status=="playing" and state.players[state.turn].id==resident.id
        local style=Cosmetics.get(self.club and self.club:visual(resident.id) or "classic")
        tag.TextLabel.Text = (active and "> " or "")..(style.premium and "★ " or "")..resident.name
        tag.TextLabel.TextColor3=Color3.fromHex(self.config.playerColors[resident.colorIndex])
        tag.Size=active and UDim2.fromOffset(132,28) or UDim2.fromOffset(88,20)
        tag.TextLabel.TextSize=active and 12 or 10
        tag.Enabled = resident.alive
        local outline=model:FindFirstChild("ResidentOutline")
        if not outline then
            outline=Instance.new("Highlight");outline.Name,outline.Adornee,outline.Parent="ResidentOutline",model,model
            outline.DepthMode,outline.FillTransparency,outline.OutlineTransparency=Enum.HighlightDepthMode.AlwaysOnTop,1,0.1
        end
        outline.OutlineColor=Color3.fromHex(self.config.playerColors[resident.colorIndex])
        outline.Enabled=active and resident.alive and not self.visiting[resident.id]
        if not model:FindFirstChild("PlayerColorRing") then
            local root=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            local humanoid=model:FindFirstChildOfClass("Humanoid")
            if root then
                local ring=Instance.new("Part")
                ring.Name,ring.Shape,ring.Size="PlayerColorRing",Enum.PartType.Cylinder,Vector3.new(0.12,4.4,4.4)
                ring.Color,ring.Transparency=Color3.fromHex(self.config.playerColors[resident.colorIndex]),0.18
                ring.CanCollide,ring.CanTouch,ring.CanQuery,ring.Massless=false,false,false,true
                local offset=humanoid and (humanoid.HipHeight+root.Size.Y/2) or 2.1
                ring.CFrame=root.CFrame*CFrame.new(0,-offset+0.06,0)*CFrame.Angles(0,0,math.pi/2)
                ring.Parent=model
                local weld=Instance.new("WeldConstraint");weld.Part0,weld.Part1,weld.Parent=root,ring,ring
            end
        end
        local colorRing=model:FindFirstChild("PlayerColorRing")
        if colorRing then colorRing.Color=Color3.fromHex(self.config.playerColors[resident.colorIndex]);colorRing.Transparency=resident.alive and 0.18 or 1 end
        if model:GetAttribute("GeneratedFigure") then
            for _,name in ipairs({"Torso","LeftArm","RightArm"}) do
                local part=model:FindFirstChild(name)
                if part then part.Color=Color3.fromHex(self.config.playerColors[resident.colorIndex]) end
            end
        end
        self:styleAvatar(model,resident)
        if self.visiting[resident.id] and (not resident.alive or state.status~="playing") then self:endVisit(resident.id) end
        if not self.visiting[resident.id] then
            local old = self.positions[resident.id]
            local route=newRoll and state.lastRoll and state.lastRoll.actorId==resident.id and state.lastRoll.from==old and state.lastRoll or nil
            if old~=resident.position or route then
                self:cancelMotion(resident.id)
                self.positions[resident.id] = resident.position
                local generation = self.generations[resident.id]
                local destination, detained = resident.position, resident.detained
                task.spawn(function()
                    local delay=math.max(0,(self.moveReadyAt or 0)-os.clock())
                    if delay>0 and old then task.wait(delay) end
                    if self.generations[resident.id]~=generation or not model.Parent then return end
                    local steps=route and route.steps or (old and (destination-old)%#self.config.tiles or 0)
                    local animated=true
                    if self.club then local _,effects=self.club:visual(resident.id);animated=effects end
                    if not old or (not route and detained) or steps>12 or not animated or not resident.alive then model:PivotTo(self:tokenFrame(destination,seat,model)); return end
                    if steps>0 then
                        local frames={model:GetPivot()}
                        for step=1,steps do table.insert(frames,self:tokenFrame((old+step-1)%#self.config.tiles+1,seat,model,(old+step-2)%#self.config.tiles+1)) end
                        local value=Instance.new("NumberValue")
                        value.Value=0
                        local connection=value.Changed:Connect(function(elapsed)
                            local step,progress,height=Journey.sample(self.config,steps,elapsed)
                            if model.Parent then model:PivotTo(frames[step]:Lerp(frames[step+1],progress)+Vector3.new(0,height,0)) end
                        end)
                        local duration=steps*Journey.stepSeconds(self.config)
                        local tween=TweenService:Create(value,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Value=duration})
                        self.motions[resident.id]={value=value,connection=connection,tween=tween}
                        tween:Play();tween.Completed:Wait()
                        if self.generations[resident.id]~=generation then return end
                        connection:Disconnect(); value:Destroy(); self.motions[resident.id]=nil
                    end
                    if self.generations[resident.id]==generation and model.Parent then
                        model:PivotTo(self:tokenFrame(destination,seat,model))
                        if route then Effects.landing(World.tilePosition(destination),self.config.playerColors[resident.colorIndex],self.root) end
                    end
                end)
            end
        end
    end
    for id, model in pairs(self.tokens) do
        if not present[id] then
            self:cancelMotion(id)
            if model:GetAttribute("GeneratedFigure") then model:Destroy()
            elseif model.Parent then
                local tag=model:FindFirstChild("ResidentTag");if tag then tag.Enabled=false end
                local outline=model:FindFirstChild("ResidentOutline");if outline then outline.Enabled=false end
                local ring=model:FindFirstChild("PlayerColorRing");if ring then ring.Transparency=1 end
                local aura=model:FindFirstChild("ClubAura");if aura then aura.Transparency=1 end
                local trail=model:FindFirstChild("ClubTrail");if trail then trail.Enabled=false end
                model:PivotTo(CFrame.new(0,5,42))
            end
            self.tokens[id],self.positions[id],self.visiting[id] = nil,nil,nil
        end
    end
    local event=state.lastAction
    if not event then self.lastActionSeq=0
    elseif event.seq~=self.lastActionSeq then
        self.lastActionSeq=event.seq
        local site=Architecture.site(event.tile)
        local position=Vector3.new(table.unpack(site))
        local pulse=Instance.new("Part")
        pulse.Name,pulse.Shape,pulse.Size="TacticalEffect",Enum.PartType.Ball,Vector3.new(2,2,2)
        pulse.Position,pulse.Anchored,pulse.CanCollide,pulse.CanQuery=position+Vector3.new(0,3,0),true,false,false
        pulse.Color=Color3.fromHex(event.blocked and "9AC5DE" or (event.kind=="demolish" and "D5B18B" or "9FCAAC"))
        pulse.Transparency,pulse.Parent=0.2,self.root
        TweenService:Create(pulse,TweenInfo.new(0.8),{Size=Vector3.new(12,7,12),Transparency=1,Position=position+Vector3.new(0,6,0)}):Play()
        task.delay(0.9,function() pulse:Destroy() end)
    end
end
return World
