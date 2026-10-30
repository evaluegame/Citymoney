local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Effects={}
function Effects.landing(position,color,parent)
    local ring=Instance.new("Part")
    ring.Name,ring.Shape,ring.Size="LandingPulse",Enum.PartType.Cylinder,Vector3.new(0.08,4,4)
    ring.CFrame=CFrame.new(position+Vector3.new(0,0.3,0))*CFrame.Angles(0,0,math.pi/2)
    ring.Anchored,ring.CanCollide,ring.CanQuery,ring.CanTouch=true,false,false,false
    ring.Material,ring.Color,ring.Transparency,ring.Parent=Enum.Material.Neon,Color3.fromHex(color),0.25,parent
    Tween:Create(ring,TweenInfo.new(0.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(0.08,13,13),Transparency=1}):Play()
    Debris:AddItem(ring,0.65)
end
function Effects.reveal(model,position,color,level,upgrade,animated)
    if not animated then return end
    for _,part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local transparency=part.Transparency
            part.Transparency=1
            Tween:Create(part,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=transparency}):Play()
        end
    end
    local anchor=model:FindFirstChild("OwnerSign")
    if anchor then
        local tag=Instance.new("BillboardGui")
        tag.Name,tag.Size,tag.AlwaysOnTop,tag.MaxDistance="OwnershipCelebration",UDim2.fromOffset(140,34),true,1500
        tag.StudsOffsetWorldSpace,tag.Adornee,tag.Parent=Vector3.new(0,9+level*6.5,0),anchor,anchor
        local label=Instance.new("TextLabel")
        label.Size,label.BackgroundTransparency,label.Font,label.TextSize=UDim2.fromScale(1,1),1,Enum.Font.GothamBlack,23
        label.Text,label.TextColor3,label.TextStrokeTransparency,label.Parent=upgrade and "UPGRADED!" or "SOLD!",Color3.fromHex(color),0.7,tag
        Tween:Create(label,TweenInfo.new(1),{TextTransparency=1,TextStrokeTransparency=1}):Play()
        Debris:AddItem(tag,1.1)
    end
    for i=1,8 do
        local angle=i*math.pi/4
        local confetti=Instance.new("Part")
        confetti.Name,confetti.Size,confetti.Shape="OwnershipSpark",Vector3.new(0.5,0.5,0.5),Enum.PartType.Ball
        confetti.Anchored,confetti.CanCollide,confetti.CanQuery,confetti.CanTouch=true,false,false,false
        confetti.Color=Color3.fromHex(i%2==0 and color or "FFC34D")
        confetti.Position,confetti.Parent=position+Vector3.new(0,3,0),model.Parent
        Tween:Create(confetti,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=position+Vector3.new(math.cos(angle)*8,5+i%3,math.sin(angle)*8),Size=Vector3.new(0.1,0.1,0.1),Transparency=1}):Play()
        Debris:AddItem(confetti,0.9)
    end
end
return Effects
