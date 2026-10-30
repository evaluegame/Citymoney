local RunService=game:GetService("RunService")
local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Dice,Scene,Cosmetics=require(shared.Dice),require(shared.Scene),require(shared.Cosmetics)
local World={}
World.__index=World
function World.new(root,config)
    local self=setmetatable({config=config,models={},seq=0,generation=0},World)
    for side=1,2 do
        local model=Scene.model(Dice.mesh("F9FCFF","224377"),"InteractiveDie"..side,root)
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
function World:settled(roll,generation)
    if self.generation~=generation then return end
    self:place(roll.values,1,1,roll.seq)
    self.settledSeq,self.settledAt=roll.seq,workspace:GetServerTimeNow()
    local settledAt=self.settledAt
    task.defer(function()
        if self.generation==generation and self.onSettled then self.onSettled(roll.seq,settledAt) end
    end)
end
function World:waitUntilSettled(sequence)
    while self.seq==sequence and self.settledSeq~=sequence do RunService.Heartbeat:Wait() end
    return self.seq==sequence and self.settledSeq==sequence
end
function World:sync(state,club)
    local roll=state.lastRoll
    if not roll then
        if self.seq~=0 then self.generation=self.generation+1;self.seq=0;self.settledSeq,self.settledAt=nil,nil;self:place({1,6},1,1,0) end
        return false
    end
    if self.seq==roll.seq then return false end
    self.seq=roll.seq;self.generation=self.generation+1
    self.settledSeq,self.settledAt=nil,nil
    local generation=self.generation
    local started=workspace:GetServerTimeNow()
    local styleId,effects="classic",true
    if club then styleId,effects=club:visual(roll.actorId) end
    local style=Cosmetics.get(styleId)
    for _,model in ipairs(self.models) do
        for _,part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") then part.Color=Color3.fromHex(string.sub(part.Name,1,4)=="Dice" and style.dice or style.pip) end
        end
    end
    if not effects then self:settled(roll,generation);return true end
    task.spawn(function()
        repeat
            if self.generation~=generation then return end
            self:place(roll.values,workspace:GetServerTimeNow()-started,self.config.diceSeconds,roll.seq)
            RunService.Heartbeat:Wait()
        until workspace:GetServerTimeNow()-started>=self.config.diceSeconds
        self:settled(roll,generation)
    end)
    return true
end
return World
