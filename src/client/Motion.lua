local Tween=game:GetService("TweenService")
local Motion={}
local Dice=require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").Dice)
function Motion.face(button,value,color)
    local layer=button:FindFirstChild("Pips")
    if not layer then
        local surface=Instance.new("Frame")
        surface.Name,surface.Position,surface.Size,surface.BorderSizePixel,surface.Parent="DieFace",UDim2.fromOffset(3,2),UDim2.new(1,-6,1,-9),0,button
        local round=Instance.new("UICorner");round.CornerRadius,round.Parent=UDim.new(0,12),surface
        local edge=Instance.new("UIStroke");edge.Thickness,edge.Transparency,edge.Parent=1.4,0.55,surface
        layer=Instance.new("Frame");layer.Name,layer.Position,layer.Size,layer.BackgroundTransparency,layer.Parent="Pips",UDim2.fromScale(0.07,0.015),UDim2.fromScale(0.86,0.86),1,button
        for i=1,6 do
            local dot=Instance.new("Frame")
            dot.Name,dot.AnchorPoint,dot.Size,dot.BorderSizePixel,dot.Parent=tostring(i),Vector2.new(0.5,0.5),UDim2.fromScale(0.13,0.13),0,layer
            local corner=Instance.new("UICorner");corner.CornerRadius,corner.Parent=UDim.new(1,0),dot
        end
    end
    local face=button:FindFirstChild("DieFace")
    local body=button.BackgroundColor3
    face.BackgroundColor3=Color3.new(math.min(1,body.R+0.035),math.min(1,body.G+0.035),math.min(1,body.B+0.035))
    face:FindFirstChildOfClass("UIStroke").Color=button:GetAttribute("RollReady") and Color3.fromHex("386BF0") or color
    local points=Dice.pips[value>0 and value or 3]
    for i=1,6 do
        local dot=layer:FindFirstChild(tostring(i));local point=points[i]
        dot.Visible=point~=nil
        if point then dot.Position,dot.BackgroundColor3=UDim2.fromScale(0.5+point[1]*0.25,0.5+point[2]*0.25),color end
    end
end
function Motion.button(button,root)
    local scale=Instance.new("UIScale");scale.Parent=button
    local function to(value)
        if root:GetAttribute("ReducedMotion") then scale.Scale=1;return end
        Tween:Create(scale,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=value}):Play()
    end
    button.MouseEnter:Connect(function() if button.Active then to(1.025) end end)
    button.MouseLeave:Connect(function() to(1) end)
    button.MouseButton1Down:Connect(function() if button.Active then to(0.96) end end)
    button.MouseButton1Up:Connect(function() to(1) end)
end
function Motion.pop(frame,root)
    if root:GetAttribute("ReducedMotion") then return end
    local original=frame.Position
    frame.Position=original+UDim2.fromOffset(0,8)
    local animation=Tween:Create(frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=original})
    animation:Play()
    return animation
end
function Motion.delta(parent,value,color,root)
    local label=Instance.new("TextLabel")
    local y=parent.Parent.Size.Y.Offset+12
    label.Name,label.Size,label.Position,label.BackgroundTransparency="CashChange",UDim2.fromOffset(130,24),UDim2.fromOffset(parent.Position.X.Offset,y),0.05
    label.BackgroundColor3,label.BorderSizePixel=Color3.fromHex("FFFFFF"),0
    label.Text,label.TextColor3,label.TextSize,label.Font=(value>0 and "+$" or "-$")..math.abs(value),color,17,Enum.Font.GothamBold
    label.ZIndex,label.Parent=20,parent.Parent
    local corner=Instance.new("UICorner");corner.CornerRadius,corner.Parent=UDim.new(0,10),label
    local goal={TextTransparency=1}
    goal.BackgroundTransparency=1
    if not root:GetAttribute("ReducedMotion") then goal.Position=UDim2.fromOffset(parent.Position.X.Offset,y-10) end
    Tween:Create(label,TweenInfo.new(1.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal):Play()
    task.delay(1.2,function() label:Destroy() end)
end
function Motion.burst(parent,root,color)
    if root:GetAttribute("ReducedMotion") then return end
    for index=1,10 do
        local piece=Instance.new("Frame")
        piece.Name,piece.Size,piece.Position,piece.BorderSizePixel="RewardConfetti",UDim2.fromOffset(7,11),UDim2.fromOffset(46,42),0
        piece.BackgroundColor3,piece.ZIndex,piece.Parent=index%2==0 and color or Color3.fromHex("FFC34D"),16,parent
        local angle=index*math.pi/5
        Tween:Create(piece,TweenInfo.new(0.85,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(46+math.cos(angle)*100,42+math.sin(angle)*55),Rotation=index*47,BackgroundTransparency=1}):Play()
        task.delay(0.9,function() piece:Destroy() end)
    end
end
return Motion
