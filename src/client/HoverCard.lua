local Input=game:GetService("UserInputService")
local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Config,Plans=require(shared.Config),require(shared.PropertyPlans)
local Layout=require(shared.Layout)
local Plaza=require(shared.Plaza)
local Hover={}
Hover.__index=Hover
function Hover.new(ui,player)
    local self=setmetatable({ui=ui,mouse=player:GetMouse(),pointer=nil,nextUpdate=0},Hover)
    self.card=ui.frame(ui.root,0,0,240,91,ui.colors.card)
    self.card.Name,self.card.ZIndex,self.card.Visible="PropertyHover",12,false
    self.name=ui.text(self.card,"",14,10,214,25,15,ui.colors.ink,true)
    self.owner=ui.text(self.card,"",14,38,214,17,11,ui.colors.muted)
    self.price=ui.text(self.card,"",14,61,214,18,12,ui.colors.green,true)
    for _,child in ipairs(self.card:GetChildren()) do if child:IsA("GuiObject") then child.ZIndex=13 end end
    Input.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then self.pointer=input.Position end end)
    return self
end
function Hover:update(data,layout,safe,blocked)
    self.card.Visible=false
    if blocked or not data or not layout or not self.pointer then return end
    local rect=Layout.board(layout,false)
    local point=self.pointer
    local x,y=(point.X-safe.AbsolutePosition.X)/layout.scale,(point.Y-safe.AbsolutePosition.Y)/layout.scale
    if x<rect[1] or x>rect[1]+rect[3] or y<rect[2] or y>rect[2]+rect[4] then return end
    local target=self.mouse.Target
    local index=target and (target:GetAttribute("TileIndex") or target.Parent:GetAttribute("TileIndex"))
    local tile=index and Config.tiles[index]
    local interaction=target and (target:GetAttribute("Interaction") or target.Parent:GetAttribute("Interaction"))
    if interaction then
        local descriptions={market={"City Market","Choose a tactical card","Click to open the market"},contracts={"Challenge Hall","Your city goals and rewards","Click to view challenges"},news={"City News","See what is happening","Click to read the bulletin"},dice={"Let's roll!","Your next move starts here","Click the dice on your turn"}}
        local details=descriptions[interaction]
        if interaction=="festival" then
            local offer,remaining=Plaza.festival(Config,data.game)
            details={offer.name,remaining.." turns until the next festival","Offer $"..offer.cost.." · click to explore"}
        end
        if not details then return end
        self.name.Text,self.owner.Text,self.price.Text=details[1],details[2],details[3]
    elseif tile and tile.kind=="property" then
    local p=data.game.properties[index]
    local owner
    for _,resident in ipairs(data.game.players) do if resident.id==p.ownerId then owner=resident end end
    self.name.Text=tile.name
    self.owner.Text=owner and (owner.name.." · Level "..p.level) or Config.groups[tile.group].name
    self.price.Text=owner and ("RENT $"..Plans.projectedRent(Config,data.game,owner.id,index,p.level).." · click to inspect") or ("FROM $"..tile.price.." · click to inspect")
    else return end
    self.card.Position=UDim2.fromOffset(math.clamp(x+18,12,layout.width-252),math.clamp(y+14,12,layout.height-105))
    self.card.Visible=true
end
return Hover
