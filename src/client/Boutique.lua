-- The native Roblox prompt handles all Robux payments. Snapshots grant access.
local Marketplace=game:GetService("MarketplaceService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Cosmetics,Architecture,Scene=require(shared.Cosmetics),require(shared.Architecture),require(shared.Scene)
local Boutique={}
Boutique.__index=Boutique
function Boutique.new(ui)
    local self=setmetatable({ui=ui,selected="gilded",price=nil,forSale=false,infoPass=nil,infoState="idle",error=nil,angle=0},Boutique)
    local C=ui.colors
    self.shade,self.card=ui.overlay(520,660)
    ui.text(self.card,"THE WATERFRONT ATELIER",24,16,430,20,10,C.green,true)
    ui.text(self.card,"Make it yours.",24,42,430,37,28,C.ink,true)
    ui.button(self.card,"×",468,18,28,28,C.paper,function() self.shade.Visible=false end)
    ui.text(self.card,"Three signature collections · one permanent Club pass",24,84,472,22,12,C.muted)
    self.viewport=Instance.new("ViewportFrame")
    self.viewport.Position,self.viewport.Size=UDim2.fromOffset(24,118),UDim2.fromOffset(472,180)
    self.viewport.BackgroundColor3,self.viewport.BorderSizePixel=C.mint,0
    self.viewport.Ambient,self.viewport.LightColor=Color3.fromRGB(185,185,178),Color3.fromRGB(255,239,212)
    self.viewport.LightDirection,self.viewport.Parent=Vector3.new(-1,-2,-1),self.card
    local corner=Instance.new("UICorner");corner.CornerRadius,corner.Parent=UDim.new(0,12),self.viewport
    self.world=Instance.new("WorldModel");self.world.Parent=self.viewport
    self.camera=Instance.new("Camera");self.camera.FieldOfView,self.camera.Parent=34,self.viewport
    self.viewport.CurrentCamera=self.camera
    self.buttons={}
    for index,style in ipairs(Cosmetics.styles) do
        local choose=ui.button(self.card,style.name,24+((index-1)%2)*242,311+math.floor((index-1)/2)*48,230,40,C.paper,function()
            self.selected=style.id;self.error=nil;self:render(ui.data())
        end)
        choose.TextSize=12;self.buttons[style.id]=choose
    end
    self.description=ui.text(self.card,"",24,411,472,42,13,C.muted)
    self.motion=ui.button(self.card,"Reduced motion: OFF",24,465,472,34,C.paper,function()
        local data=ui.data()
        if data and data.club then
            self.error=nil;ui.send("Style",{styleId=data.club.styleId,effects=not data.club.effects})
        end
    end);self.motion.TextSize=12
    self.status=ui.text(self.card,"",24,508,472,29,12,C.green,true)
    self.primary=ui.button(self.card,"Preview collection",24,548,304,42,C.green,function() self:activate() end)
    self.restore=ui.button(self.card,"Check ownership",340,548,156,42,C.paper,function()
        self.error=nil;ui.send("ClubRefresh")
        local data=ui.data();if data and data.club then self:product(data.club.passId,true) end
    end);self.restore.TextSize=11
    self.note=ui.text(self.card,"Cosmetics only. Your cash, rent, cards and dice odds stay the same.",24,601,472,39,12,C.muted)
    RunService.RenderStepped:Connect(function(dt)
        if not self.shade.Visible or not self.target then return end
        local data=ui.data()
        if not data or not data.club or data.club.effects then self.angle=self.angle+math.min(dt,0.05)*0.13 end
        local theta=math.rad(145)+math.sin(self.angle)*0.22
        self.camera.CFrame=CFrame.lookAt(self.target+Vector3.new(math.sin(theta)*38,22,math.cos(theta)*38),self.target)
    end)
    Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,passId)
        if player==Players.LocalPlayer and passId==self.infoPass then self.prompting=false;self:render(ui.data()) end
    end)
    return self
end
function Boutique:isOpen() return self.shade.Visible end
function Boutique:open()
    self.shade.Visible=true;self.error=nil
    self:render(self.ui.data())
end
function Boutique:feedback(message)
    if self.shade.Visible then self.error=message;self:render(self.ui.data()) end
end
function Boutique:product(passId,retry)
    if passId<=0 or (self.infoPass==passId and (not retry or self.infoState=="loading")) then return end
    self.infoPass,self.infoState,self.price,self.forSale=passId,"loading",nil,false
    task.spawn(function()
        -- Fetch on the client so Roblox regional/personalized prices are accurate.
        local ok,info=pcall(function() return Marketplace:GetProductInfoAsync(passId,Enum.InfoType.GamePass) end)
        if self.infoPass~=passId then return end
        self.infoState=ok and "ready" or "failed"
        self.forSale=ok and info.IsForSale==true
        self.price=self.forSale and type(info.PriceInRobux)=="number" and info.PriceInRobux or nil
        self:render(self.ui.data())
    end)
end
function Boutique:activate()
    local data=self.ui.data()
    if not data or not data.club or data.club.loading or self.prompting then return end
    local profile,style=data.club,Cosmetics.get(self.selected)
    if Cosmetics.allowed(style.id,profile.ownsPass,profile.studio) then
        self.error=nil;self.ui.send("Style",{styleId=style.id,effects=profile.effects})
    elseif profile.passId>0 and self.forSale then
        self.prompting=true
        local ok=pcall(function() Marketplace:PromptGamePassPurchase(Players.LocalPlayer,profile.passId) end)
        if not ok then self.prompting=false end
        self.error=not ok and "Roblox could not open the purchase prompt. Please try again." or nil
        self:render(data)
    end
end
function Boutique:render(data)
    if not data or not data.club then return end
    local ui,C,profile=self.ui,self.ui.colors,data.club
    local equipped=Cosmetics.get(profile.styleId)
    -- Apply the active collection throughout the HUD, even with the showroom closed.
    ui.dieA.BackgroundColor3,ui.dieB.BackgroundColor3=Color3.fromHex(equipped.dice),Color3.fromHex(equipped.dice)
    ui.dieTextA.TextColor3,ui.dieTextB.TextColor3=Color3.fromHex(equipped.pip),Color3.fromHex(equipped.pip)
    ui.mark.BackgroundColor3=Color3.fromHex(equipped.accent)
    ui.header:FindFirstChildOfClass("UIStroke").Color=equipped.premium and Color3.fromHex(equipped.accent) or C.line
    ui.strap.Text=equipped.premium and ("W A T E R F R O N T   C L U B  ·  "..equipped.label) or "T H E   W A T E R F R O N T   C L U B"
    if not self.shade.Visible then return end
    self:product(profile.passId,false)
    local selected=Cosmetics.get(self.selected)
    for id,button in pairs(self.buttons) do
        local style=Cosmetics.get(id)
        button.BackgroundColor3=id==selected.id and Color3.fromHex(style.dice) or C.paper
        button.TextColor3=id==selected.id and Color3.fromHex(style.pip) or C.ink
        button.Text=style.name..(id==profile.styleId and " ✓" or "")
    end
    local color=ui.config.playerColors[1]
    for _,resident in ipairs(data.game.players) do if resident.id==ui.id then color=ui.config.playerColors[resident.colorIndex] end end
    for _,member in ipairs(data.lobby) do if member.id==ui.id and data.game.status~="playing" then color=ui.config.playerColors[member.colorIndex] or color end end
    local key=selected.id..":"..color
    if self.previewKey~=key then
        self.previewKey=key;self.world:ClearAllChildren();self.angle=0
        local model=Scene.model(Architecture.property(ui.config,2,Players.LocalPlayer.DisplayName,color,2,0,nil,selected.id),"CollectionPreview",self.world,true)
        local cf=model:GetBoundingBox();self.target=cf.Position+Vector3.new(0,0.4,0)
        self.viewport.BackgroundColor3=selected.premium and Color3.fromHex(selected.stone) or C.mint
    end
    self.description.Text=selected.description
    self.motion.Text=profile.effects and "Reduced motion: OFF · animated preview, dice and walking trail" or "Reduced motion: ON · still preview and dice; walking trail off"
    ui.available(self.motion,not profile.loading,C.paper)
    local allowed=Cosmetics.allowed(selected.id,profile.ownsPass,profile.studio)
    local enabled=not profile.loading and not self.prompting and (allowed and profile.styleId~=selected.id or not allowed and self.forSale)
    if self.prompting then self.primary.Text="Complete Roblox checkout…"
    elseif profile.loading then self.primary.Text="Loading collection…"
    elseif profile.styleId==selected.id then self.primary.Text="Equipped ✓"
    elseif allowed then self.primary.Text=profile.studio and "Equip in Studio preview" or "Equip "..selected.name
    elseif profile.passId==0 then self.primary.Text="Club pass coming soon"
    elseif self.infoState=="loading" then self.primary.Text="Checking Roblox price…"
    elseif not self.forSale then self.primary.Text="Pass currently unavailable"
    else self.primary.Text=self.price and ("Unlock all styles · R$ "..self.price) or "Unlock Club · Roblox checkout" end
    ui.available(self.primary,enabled==true,C.green)
    ui.available(self.restore,not profile.loading and not profile.studio and profile.passId>0,C.paper)
    self.status.Text=self.error or (profile.loading and "Loading your collection…" or (profile.studio and "STUDIO PREVIEW · no purchases or permanent unlocks" or (profile.ownsPass and "CLUB MEMBER · all three collections unlocked" or "Preview any collection before purchasing.")))
    self.status.TextColor3=self.error and C.red or C.green
    self.note.Text=self.error and "Purchases and ownership are handled by Roblox. Try Check ownership if needed." or (profile.status~="" and profile.status or "Cosmetics only. Your cash, rent, cards and dice odds stay the same.")
end
function Boutique:celebrate()
    local data=self.ui.data()
    if not data or not data.club or not data.club.effects then return end
    local style=Cosmetics.get(data.club.styleId)
    local layer=Instance.new("Frame")
    layer.Size,layer.BackgroundTransparency,layer.ZIndex,layer.Parent=UDim2.fromScale(1,1),1,40,self.ui.root
    layer.ClipsDescendants=true
    for i=1,28 do
        local confetti=Instance.new("Frame")
        confetti.Size,confetti.Position=UDim2.fromOffset(5+i%3*2,10),UDim2.fromScale((i*0.618)%1,-0.06-i%4*0.06)
        confetti.BackgroundColor3=Color3.fromHex(i%2==0 and style.accent or "F0DCA8")
        confetti.BorderSizePixel,confetti.Rotation,confetti.ZIndex,confetti.Parent=0,i*27,41,layer
        TweenService:Create(confetti,TweenInfo.new(2.3+i%5*0.15,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromScale((i*0.618+0.12)%1,1.1),Rotation=i*27+190,BackgroundTransparency=0.7}):Play()
    end
    task.delay(3.2,function() layer:Destroy() end)
end
return Boutique
