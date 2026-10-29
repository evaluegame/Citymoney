local RunService=game:GetService("RunService")
local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Dice,Scene,Cosmetics=require(shared.Dice),require(shared.Scene),require(shared.Cosmetics)
local World={}
World.__index=World
function World.new(root,config)
    local self=setmetatable({config=config,models={},seq=0,generation=0},World)
    for side=1,2 do
        local model=Scene.model(Dice.mesh("FFF8E8","294C40"),"InteractiveDie"..side,root)
        model.PrimaryPart=model:FindFirstChild("DiceBody")
        model:SetAttribute("Interaction","dice")
        self.models[side]=model
    end
    self:place({1,6},1,1,0)
    return self
end
function World:place(values,time,duration,sequence)
    for side,model in ipairs(self.models) do
        local p,r=Dice.pose(values[side],side,time,duration,sequence)
        model:PivotTo(CFrame.new(p[1],p[2],p[3],table.unpack(r)))
    end
end
function World:sync(state,club)
    local roll=state.lastRoll
    if not roll then
        if self.seq~=0 then self.generation=self.generation+1;self.seq=0;self:place({1,6},1,1,0) end
        return false
    end
    if self.seq==roll.seq then return false end
    self.seq=roll.seq;self.generation=self.generation+1
    local generation=self.generation
    local styleId,effects="classic",true
    if club then styleId,effects=club:visual(roll.actorId) end
    local style=Cosmetics.get(styleId)
    for _,model in ipairs(self.models) do
        for _,part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") then part.Color=Color3.fromHex(part.Name=="DiceBody" and style.dice or style.pip) end
        end
    end
    if not effects then self:place(roll.values,1,1,roll.seq);return true end
    task.spawn(function()
        local started=os.clock()
        repeat
            if self.generation~=generation then return end
            self:place(roll.values,os.clock()-started,self.config.diceSeconds,roll.seq)
            RunService.Heartbeat:Wait()
        until os.clock()-started>=self.config.diceSeconds
        if self.generation==generation then self:place(roll.values,1,1,roll.seq) end
    end)
    return true
end
return World
