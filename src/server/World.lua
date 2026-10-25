local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Board, Architecture, Scene = require(shared.Board), require(shared.Architecture), require(shared.Scene)
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
        if not (entry.tileIndex and config.tiles[entry.tileIndex].kind == "property" and entry.name ~= "Tile"..entry.tileIndex and entry.name ~= "DistrictInlay") then
            table.insert(entries, entry)
        end
    end
    Scene.populate(entries, self.root)
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

function World:tokenFrame(index, seat, model)
    local position = World.tilePosition(index)
    local x, z = ((seat-1)%3-1)*2.2, math.floor((seat-1)/3)*2.2-1
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local height = humanoid and root and (humanoid.HipHeight+root.Size.Y/2+0.2) or 2.3
    return CFrame.new(position + Vector3.new(x, height, z)) * CFrame.Angles(0, math.rad(-35), 0)
end

function World:figure(resident)
    local tint = self.config.playerColors[resident.colorIndex]
    local origin = { 0,0,0 }
    local parts = {
        { name="Torso", size={1.4,1.5,0.8}, position={0,0,0}, color=tint },
        { name="Head", size={1,1,1}, position={0,1.25,0}, color="E7C8A2", shape="Ball" },
        { name="Hair", size={1.1,0.4,1.05}, position={0,1.65,0}, color="4D4B47" },
        { name="LeftLeg", size={0.5,1.1,0.65}, position={-0.4,-1.25,0}, color="394E52" },
        { name="RightLeg", size={0.5,1.1,0.65}, position={0.4,-1.25,0}, color="394E52" },
        { name="LeftArm", size={0.4,1.4,0.6}, position={-0.95,0,0}, color=tint },
        { name="RightArm", size={0.4,1.4,0.6}, position={0.95,0,0}, color=tint },
        { name="Briefcase", size={0.8,0.7,0.3}, position={1.2,-0.7,0}, color="A58E6F" },
    }
    local model = Scene.model(parts,"Figure_"..resident.id,self.root)
    model.PrimaryPart = model:FindFirstChild("Torso")
    model:PivotTo(CFrame.new(table.unpack(origin)))
    return model
end

function World:prepareCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    if not humanoid or not root or player.Character ~= character then return end
    if not character:GetAttribute("CitymoneyScaled") then
        pcall(function() character:ScaleTo(0.72) end)
        character:SetAttribute("CitymoneyScaled", true)
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

function World:sync(state)
    self.state = state
    -- Buying immediately constructs a complete home, including its owner's sign.
    for index, view in pairs(self.propertyViews) do
        local property = state.properties[index]
        local key = tostring(property.ownerId)..":"..property.level..":"..(property.paint or 0)
        if key ~= view.key then
            view.key = key
            if view.model then view.model:Destroy() end
            local owner
            for _, resident in ipairs(state.players) do if resident.id==property.ownerId then owner=resident end end
            local entries = Architecture.property(self.config,index,owner and owner.name or false,
                owner and self.config.playerColors[owner.colorIndex] or "A6B4A0",property.level,property.paint or 0)
            view.model = Scene.model(entries,"Property"..index,self.root)
            view.model:SetAttribute("TileIndex",index)
            if owner then
                self:wireDoor(view.model,owner.id)
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
    end
    local present = {}
    for seat, resident in ipairs(state.players) do
        present[resident.id] = true
        local player = type(resident.id)=="number" and Players:GetPlayerByUserId(resident.id) or nil
        local character = player and player.Character
        if character and not character:FindFirstChild("HumanoidRootPart") then character=nil end
        local model = self.tokens[resident.id]
        if character and model~=character then
            self:cancelMotion(resident.id)
            if model and model:GetAttribute("GeneratedFigure") then model:Destroy() end
            model, self.tokens[resident.id], self.positions[resident.id] = character, character, nil
        elseif not model or not model.Parent then
            model = self:figure(resident)
            model:SetAttribute("GeneratedFigure",true)
            self.tokens[resident.id], self.positions[resident.id] = model, nil
        end
        local tag = model:FindFirstChild("ResidentTag")
        if not tag then
            tag=Instance.new("BillboardGui")
            tag.Name, tag.Size, tag.StudsOffset, tag.AlwaysOnTop, tag.MaxDistance = "ResidentTag", UDim2.fromOffset(100,22),Vector3.new(0,3.5,0),true,500
            tag.Adornee, tag.Parent = model:FindFirstChild("Head") or model.PrimaryPart, model
            local label=Instance.new("TextLabel")
            label.Size,label.BackgroundTransparency,label.TextSize,label.Font = UDim2.fromScale(1,1),1,12,Enum.Font.GothamBold
            label.TextColor3,label.TextStrokeTransparency,label.Parent = Color3.fromHex("FFFFFF"),0.5,tag
        end
        local active = state.status=="playing" and state.players[state.turn].id==resident.id
        tag.TextLabel.Text = (active and "▸ " or "")..resident.name
        tag.Enabled = resident.alive
        if self.visiting[resident.id] and (not resident.alive or state.status~="playing") then self:endVisit(resident.id) end
        if not self.visiting[resident.id] then
            local old = self.positions[resident.id]
            if old~=resident.position then
                self:cancelMotion(resident.id)
                self.positions[resident.id] = resident.position
                local generation = self.generations[resident.id]
                local destination, detained = resident.position, resident.detained
                task.spawn(function()
                    if self.generations[resident.id]~=generation or not model.Parent then return end
                    local steps=old and (destination-old)%#self.config.tiles or 0
                    if not old or detained or steps>12 then model:PivotTo(self:tokenFrame(destination,seat,model)); return end
                    for step=1,steps do
                        if self.generations[resident.id]~=generation or not model.Parent then return end
                        local value=Instance.new("CFrameValue")
                        value.Value=model:GetPivot()
                        local target=self:tokenFrame((old+step-1)%#self.config.tiles+1,seat,model)
                        local connection=value.Changed:Connect(function(frame) if model.Parent then model:PivotTo(frame) end end)
                        local tween=TweenService:Create(value,TweenInfo.new(0.18,Enum.EasingStyle.Sine),{Value=target})
                        self.motions[resident.id]={ value=value, connection=connection, tween=tween }
                        tween:Play(); tween.Completed:Wait()
                        if self.generations[resident.id]~=generation then return end
                        connection:Disconnect(); value:Destroy(); self.motions[resident.id]=nil
                    end
                end)
            end
        end
    end
    for id, model in pairs(self.tokens) do
        if not present[id] then
            self:cancelMotion(id)
            if model:GetAttribute("GeneratedFigure") then model:Destroy() end
            self.tokens[id],self.positions[id],self.visiting[id] = nil,nil,nil
        end
    end
end
return World
