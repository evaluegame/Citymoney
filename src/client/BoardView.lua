local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Fit,Layout,Architecture,Config=require(shared.BoardCamera),require(shared.Layout),require(shared.Architecture),require(shared.Config)
local Labels=require(script.Parent.TileLabels)
local Presentation=require(shared.Presentation)
local Follow=require(shared.FollowView)
local Players=game:GetService("Players")
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
function View:update(dt,root,safe,layout,data,focus,inspector,visit,player)
    local camera=workspace.CurrentCamera
    if not camera or not layout then return end
    if data and self.revision~=data.revision then
        self.revision=data.revision
        local heights={}
        for _,property in ipairs(data.game.properties) do table.insert(heights,property.ownerId and property.level+1 or 0) end
        local signature=table.concat(heights,":")
        if signature~=self.heights then self.heights=signature;self.bounds=Fit.cityBounds(Config,Architecture,data.game);self.key=nil end
    end
    if visit then
        self.following=false;root:SetAttribute("FollowingResident",nil)
        if self.labels then self.labels:update(camera,safe,layout.scale,data,false) end
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
    local rotate,zoom=root:GetAttribute("Rotate") or 0,root:GetAttribute("Zoom") or 1
    local still=data and data.club and not data.club.effects
    local tracking=not focus and data and Follow.plan(Config,data.game,data.journeyUntil,workspace:GetServerTimeNow(),root:GetAttribute("FollowSuppressed"),still)
    if (tracking~=nil and tracking~=false)~=self.following then self.key=nil end
    self.following=tracking~=nil and tracking~=false
    root:SetAttribute("FollowingResident",tracking and tracking.id or nil)
    local key=table.concat({size.X,size.Y,layout.width,layout.height,layout.scale,offset.X,offset.Y,mode,rotate,zoom,tostring(focus),tostring(inspector),data and data.game.properties[focus or 0] and data.game.properties[focus].level or 0},":")
    if self.key~=key or tracking then
        self.key=key
        local rectangle=Layout.board(layout,inspector)
        local rect={offset.X+rectangle[1]*layout.scale,offset.Y+rectangle[2]*layout.scale,rectangle[3]*layout.scale,rectangle[4]*layout.scale}
        self.rect=rect
        local yaw,elevation=Presentation.viewAngles(mode,rotate)
        local bounds=mode=="city" and City.bounds() or self.bounds
        if tracking then
            local resident=type(tracking.id)=="number" and Players:GetPlayerByUserId(tracking.id)
            local board=workspace:FindFirstChild("CitymoneyBoard")
            local character=resident and resident.Character
            local model=character and character:GetAttribute("CitymoneyPrepared") and character or (board and board:FindFirstChild("Figure_"..tracking.id))
            local body=model and (model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso"))
            local position=body and {body.Position.X,body.Position.Y,body.Position.Z} or tracking.position
            bounds,yaw,elevation=Follow.framing(position)
        elseif focus then
            local p,angle=Architecture.site(focus)
            local level=data and data.game.properties[focus].level or 0
            bounds={min={p[1]-11,1,p[3]-11},max={p[1]+11,13+level*6,p[3]+11}}
            yaw,elevation=angle+math.rad(150),math.rad(40)
        end
        -- Calibrate using Roblox's own projection; this also handles top bars,
        -- phone cutouts and ViewportSize differing from the full rendering area.
        local rayA=camera:ScreenPointToRay(rect[1]+10,rect[2]+10)
        local rayB=camera:ScreenPointToRay(rect[1]+rect[3]-10,rect[2]+rect[4]-10)
        local a=camera.CFrame:VectorToObjectSpace(rayA.Direction)
        local b=camera.CFrame:VectorToObjectSpace(rayB.Direction)
        local fitted=Fit.fromSlopes({a.X/-a.Z,b.X/-b.Z,b.Y/-b.Z,a.Y/-a.Z},yaw,elevation,zoom,bounds)
        self.goal=CFrame.fromMatrix(Vector3.new(table.unpack(fitted.position)),Vector3.new(table.unpack(fitted.right)),Vector3.new(table.unpack(fitted.up)),Vector3.new(table.unpack(fitted.back)))
    end
    if not self.frame or still then self.frame=self.goal
    else self.frame=self.frame:Lerp(self.goal,1-math.exp(-(tracking and 12 or 8)*math.min(dt,0.1))) end
    camera.CFrame=self.frame
    if not self.labels then self.labels=Labels.new(root,self.onProperty,self.onInteraction) end
    self.labels:update(camera,safe,layout.scale,data,mode=="table" and not focus and not tracking,self.rect)
end
return View
