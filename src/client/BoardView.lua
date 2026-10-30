local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Fit,Layout,Architecture,Config=require(shared.BoardCamera),require(shared.Layout),require(shared.Architecture),require(shared.Config)
local Labels=require(script.Parent.TileLabels)
local Presentation=require(shared.Presentation)
local City=require(shared.CityScenery)
local View={}
View.__index=View
function View.new() return setmetatable({frame=nil,key=nil,wasVisiting=false,bounds=Fit.cityBounds(Config,Architecture)},View) end
function View:revealCharacter(character)
    if self.character~=character then
        if self.characterAdded then self.characterAdded:Disconnect() end
        self.character,self.characterParts=character,{}
        if character then
            for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then table.insert(self.characterParts,part) end end
            self.characterAdded=character.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then table.insert(self.characterParts,part) end end)
        end
    end
    for _,part in ipairs(self.characterParts or {}) do
        if part.Parent and part.LocalTransparencyModifier~=0 then part.LocalTransparencyModifier=0 end
    end
end
function View:update(_dt,root,safe,layout,_data,_focus,_inspector,visit,player)
    local camera=workspace.CurrentCamera
    if not camera or not layout then return end
    if visit then
        if self.labels then self.labels:update(camera,safe,layout.scale,_data,false) end
        local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            camera.CameraSubject,camera.CameraType=humanoid,Enum.CameraType.Custom
            player.CameraMinZoomDistance,player.CameraMaxZoomDistance=4,35
            if not self.wasVisiting and humanoid.RootPart then camera.CFrame=CFrame.lookAt(humanoid.RootPart.Position+Vector3.new(14,11,16),humanoid.RootPart.Position) end
        end
        self.wasVisiting=true;return
    end
    if self.wasVisiting then self.frame=nil;self.key=nil end
    self.wasVisiting=false
    camera.CameraType,camera.FieldOfView=Enum.CameraType.Scriptable,36
    local size,offset=camera.ViewportSize,safe.AbsolutePosition
    local mode=root:GetAttribute("ViewMode") or Presentation.defaultView
    -- Only an explicit view choice or a resized window reframes the board.
    -- Movement, purchases, upgrades and property panels keep the same camera.
    local key=table.concat({size.X,size.Y,layout.width,layout.height,layout.scale,offset.X,offset.Y,mode},":")
    if self.key~=key then
        self.key=key
        local rectangle=Layout.board(layout,false)
        local rect={offset.X+rectangle[1]*layout.scale,offset.Y+rectangle[2]*layout.scale,rectangle[3]*layout.scale,rectangle[4]*layout.scale}
        self.rect=rect
        local yaw,elevation=Presentation.viewAngles(mode,0)
        local bounds=mode=="city" and City.bounds() or self.bounds
        -- Calibrate using Roblox's own projection; this also handles top bars,
        -- phone cutouts and ViewportSize differing from the full rendering area.
        local rayA=camera:ScreenPointToRay(rect[1]+10,rect[2]+10)
        local rayB=camera:ScreenPointToRay(rect[1]+rect[3]-10,rect[2]+rect[4]-10)
        local a=camera.CFrame:VectorToObjectSpace(rayA.Direction)
        local b=camera.CFrame:VectorToObjectSpace(rayB.Direction)
        local fitted=Fit.fromSlopes({a.X/-a.Z,b.X/-b.Z,b.Y/-b.Z,a.Y/-a.Z},yaw,elevation,1,bounds)
        self.goal=CFrame.fromMatrix(Vector3.new(table.unpack(fitted.position)),Vector3.new(table.unpack(fitted.right)),Vector3.new(table.unpack(fitted.up)),Vector3.new(table.unpack(fitted.back)))
    end
    self.frame=self.goal
    camera.CFrame=self.frame
    if not self.labels then self.labels=Labels.new(root,self.onProperty,self.onInteraction) end
    self.labels:update(camera,safe,layout.scale,_data,mode=="table",self.rect)
end
return View
