local TweenService = game:GetService("TweenService")
local Board = require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").Board)
local World = {}
World.__index = World

local function color(hex) return Color3.fromHex(hex) end

local function part(parent, name, size, position, tint, material)
    local object = Instance.new("Part")
    object.Name, object.Size, object.Position = name, size, position
    object.Anchored, object.Color = true, tint
    object.Material = material or Enum.Material.SmoothPlastic
    object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    object.Parent = parent
    return object
end

local function surface(object, text, tint, textSize)
    local gui = Instance.new("SurfaceGui")
    gui.Face, gui.SizingMode, gui.PixelsPerStud = Enum.NormalId.Top, Enum.SurfaceGuiSizingMode.PixelsPerStud, 48
    gui.Parent = object
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
    label.Text, label.TextColor3, label.TextSize = text, tint, textSize or 32
    label.Font, label.TextWrapped = Enum.Font.GothamBold, true
    label.Parent = gui
end

function World.tilePosition(index)
    return Vector3.new(table.unpack(Board.position(index)))
end

function World.new(config)
    local self = setmetatable({ config = config, tokens = {}, propertyViews = {}, positions = {}, animations = {}, tweens = {} }, World)
    local old = workspace:FindFirstChild("CitymoneyBoard")
    if old then old:Destroy() end
    self.root = Instance.new("Folder")
    self.root.Name, self.root.Parent = "CitymoneyBoard", workspace
    for _, entry in ipairs(Board.generate(config)) do
        local object
        if entry.className == "SpawnLocation" then
            object = Instance.new("SpawnLocation")
            object.Name, object.Size = entry.name, Vector3.new(table.unpack(entry.size))
            object.Position, object.Anchored, object.Neutral, object.Duration = Vector3.new(table.unpack(entry.position)), true, true, 0
            object.Parent = self.root
        else
            object = part(self.root, entry.name, Vector3.new(table.unpack(entry.size)), Vector3.new(table.unpack(entry.position)), color(entry.color), Enum.Material[entry.material or "SmoothPlastic"])
        end
        object.Transparency = entry.transparency or 0
        if entry.shape then object.Shape = Enum.PartType[entry.shape] end
        if entry.tileIndex then object:SetAttribute("TileIndex", entry.tileIndex) end
        if entry.text then surface(object, entry.text, color(entry.textColor), entry.textSize) end
        if entry.light then
            local light = Instance.new("PointLight")
            light.Color, light.Brightness, light.Range, light.Parent = color(entry.color), 0.4, 10, object
        end
    end
    for index = 1, #config.tiles do
        local view = Instance.new("Folder")
        view.Name, view.Parent = "Ownership" .. index, self.root
        self.propertyViews[index] = { folder = view, key = "" }
    end
    return self
end

function World:tokenPosition(index, seat)
    local offset = Vector3.new(((seat - 1) % 3 - 1) * 2.6, 2.2, math.floor((seat - 1) / 3) * 2.6)
    return World.tilePosition(index) + offset
end

function World:sync(state)
    local present = {}
    for seat, player in ipairs(state.players) do
        present[player.id] = true
        local token = self.tokens[player.id]
        if not token then
            token = part(self.root, "Token_" .. player.id, Vector3.new(2.1, 2.1, 2.1), self:tokenPosition(player.position, seat), color(self.config.playerColors[player.colorIndex]), Enum.Material.Neon)
            token.Shape, token.CanCollide = Enum.PartType.Ball, false
            local tag = Instance.new("BillboardGui")
            tag.Size, tag.StudsOffset, tag.AlwaysOnTop, tag.MaxDistance = UDim2.fromOffset(140, 26), Vector3.new(0, 2, 0), true, 300
            tag.Parent = token
            local label = Instance.new("TextLabel")
            label.Size, label.BackgroundColor3, label.BackgroundTransparency = UDim2.fromScale(1, 1), color("173940"), 0.15
            label.Text, label.Font, label.TextSize, label.TextColor3 = player.name, Enum.Font.GothamBold, 13, color("FFFFFF")
            label.Parent = tag
            self.tokens[player.id] = token
        end
        token.Transparency = player.alive and 0 or 0.8
        local old = self.positions[player.id]
        if old ~= player.position then
            self.positions[player.id] = player.position
            local animation = (self.animations[player.id] or 0) + 1
            self.animations[player.id] = animation
            if self.tweens[player.id] then
                self.tweens[player.id]:Cancel()
                self.tweens[player.id] = nil
            end
            local destination = player.position
            local isDetention = player.detained
            task.spawn(function()
                local distance = old and ((destination - old) % #self.config.tiles) or 0
                if old and not isDetention and distance > 0 and distance <= 12 then
                    for step = 1, distance do
                        if self.animations[player.id] ~= animation or not token.Parent then return end
                        local index = (old + step - 1) % #self.config.tiles + 1
                        local tween = TweenService:Create(token, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Position = self:tokenPosition(index, seat) })
                        self.tweens[player.id] = tween
                        tween:Play()
                        tween.Completed:Wait()
                    end
                elseif token.Parent then
                    token.Position = self:tokenPosition(destination, seat)
                end
            end)
        end
    end
    for id, token in pairs(self.tokens) do
        if not present[id] then
            if self.tweens[id] then self.tweens[id]:Cancel(); self.tweens[id] = nil end
            token:Destroy()
            self.tokens[id], self.positions[id] = nil, nil
            self.animations[id] = (self.animations[id] or 0) + 1
        end
    end
    for index, property in ipairs(state.properties) do
        local view = self.propertyViews[index]
        local key = tostring(property.ownerId) .. ":" .. property.level
        if view.key ~= key then
            view.key = key
            view.folder:ClearAllChildren()
            if property.ownerId then
                local owner
                for _, player in ipairs(state.players) do
                    if player.id == property.ownerId then owner = player end
                end
                if owner then
                    local position = World.tilePosition(index)
                    part(view.folder, "OwnerMarker", Vector3.new(10, 0.25, 0.65), position + Vector3.new(0, 0.7, 4.8), color(self.config.playerColors[owner.colorIndex]), Enum.Material.Neon)
                    for level = 1, property.level do
                        local height = property.level == 3 and 4.5 or 1.8
                        local buildingPosition = position + Vector3.new((level - 2) * 2.8, 0.5 + height / 2, -2)
                        local building = part(view.folder, "Upgrade", Vector3.new(2.2, height, 2.5), buildingPosition, color(self.config.playerColors[owner.colorIndex]))
                        building:SetAttribute("TileIndex", index)
                        local roof = part(view.folder, "Roof", Vector3.new(2.5, 0.35, 2.8), buildingPosition + Vector3.new(0, height / 2, 0), color("304851"))
                        roof:SetAttribute("TileIndex", index)
                        part(view.folder, "Window", Vector3.new(0.8, 0.7, 0.08), buildingPosition + Vector3.new(0, 0.1, 1.3), color("FFE7AA"), Enum.Material.Neon)
                    end
                end
            end
        end
    end
end

return World
