local Tween=game:GetService("TweenService")
local Motion={}
local Dice=require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").Dice)
function Motion.face(button,value,color)
    local layer=button:FindFirstChild("Pips")
    if not layer then
        layer=Instance.new("Frame");layer.Name,layer.Size,layer.BackgroundTransparency,layer.Parent="Pips",UDim2.fromScale(1,1),1,button
        for i=1,6 do
            local dot=Instance.new("Frame")
            dot.Name,dot.AnchorPoint,dot.Size,dot.BorderSizePixel,dot.Parent=tostring(i),Vector2.new(0.5,0.5),UDim2.fromScale(0.13,0.13),0,layer
            local corner=Instance.new("UICorner");corner.CornerRadius,corner.Parent=UDim.new(1,0),dot
        end
    end
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
    Tween:Create(frame,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=original}):Play()
end
function Motion.delta(parent,value,color,root)
    local label=Instance.new("TextLabel")
    label.Size,label.Position,label.BackgroundTransparency=UDim2.fromOffset(130,24),UDim2.fromOffset(0,8),1
    label.Text,label.TextColor3,label.TextSize,label.Font=(value>0 and "+$" or "-$")..math.abs(value),color,17,Enum.Font.GothamBold
    label.ZIndex,label.Parent=20,parent
    local goal={TextTransparency=1}
    if not root:GetAttribute("ReducedMotion") then goal.Position=UDim2.fromOffset(0,-26) end
    Tween:Create(label,TweenInfo.new(1.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal):Play()
    task.delay(1.2,function() label:Destroy() end)
end
return Motion
