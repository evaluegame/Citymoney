-- The same part descriptions power the world and the property ViewportFrames.
local Scene = {}
function Scene.populate(entries, parent, preview)
    local objects = {}
    for _, entry in ipairs(entries) do
        local object = Instance.new(entry.className or "Part")
        object.Name, object.Size = entry.name, Vector3.new(table.unpack(entry.size))
        local p, r = entry.position, entry.rotation or { 1,0,0,0,1,0,0,0,1 }
        object.CFrame = CFrame.new(p[1], p[2], p[3], table.unpack(r))
        object.Anchored, object.Color = true, Color3.fromHex(entry.color)
        object.Material = Enum.Material[entry.material or "SmoothPlastic"]
        object.TopSurface, object.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        object.Transparency, object.Reflectance = entry.transparency or 0, entry.reflectance or 0
        object.CanCollide = entry.canCollide ~= false
        if entry.shape then object.Shape = Enum.PartType[entry.shape] end
        if object:IsA("SpawnLocation") then object.Neutral, object.Duration = true, 0 end
        if entry.tileIndex then object:SetAttribute("TileIndex", entry.tileIndex) end
        if entry.interaction then object:SetAttribute("Interaction",entry.interaction) end
        if entry.door then object:SetAttribute("Door", true) end
        object.Parent = parent
        if entry.text and not preview then
            local surface = Instance.new("SurfaceGui")
            surface.Name, surface.Face = "Caption", Enum.NormalId[entry.textFace or "Top"]
            surface.SizingMode, surface.PixelsPerStud, surface.LightInfluence = Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, 0
            surface.Parent = object
            local label = Instance.new("TextLabel")
            label.Size, label.BackgroundTransparency = UDim2.fromScale(1,1), 1
            label.Text, label.TextColor3 = entry.text, Color3.fromHex(entry.textColor or "3C5149")
            label.Font, label.TextWrapped, label.TextScaled = Enum.Font.GothamBold, true, true
            label.Parent = surface
            local limit = Instance.new("UITextSizeConstraint")
            limit.MaxTextSize, limit.MinTextSize, limit.Parent = entry.textSize or 72, 8, label
            local padding = Instance.new("UIPadding")
            padding.PaddingTop, padding.PaddingBottom, padding.PaddingLeft, padding.PaddingRight = UDim.new(0.08,0), UDim.new(0.08,0), UDim.new(0.06,0), UDim.new(0.06,0)
            padding.Parent = label
        end
        if entry.light and not preview then
            local light = Instance.new("PointLight")
            light.Color, light.Brightness, light.Range = Color3.fromHex(entry.color), 0.7, 13
            light.Parent = object
        end
        table.insert(objects, object)
    end
    return objects
end
function Scene.model(entries, name, parent, preview)
    local model = Instance.new("Model")
    model.Name, model.Parent = name, parent
    Scene.populate(entries, model, preview)
    return model
end
return Scene
