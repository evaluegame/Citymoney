-- Deadlines are keyed to the authoritative phase. UI activity cannot delay handoff.
local runtimeScript=getfenv().script
local Journey=runtimeScript and require(runtimeScript.Parent.Journey) or require("./Journey")
local Offers=runtimeScript and require(runtimeScript.Parent.Opportunities) or require("./Opportunities")
local Flow={}
Flow.__index=Flow
function Flow.new(config) return setmetatable({config=config,key=nil,deadline=0,handoffAt=0,journeyUntil=0,diceEndsAt=0,moveAt=0,settledKey=nil,rollKey=nil,journeyTurn=0},Flow) end
function Flow.key(state) return state.status..":"..state.turnCount..":"..state.turn..":"..state.phase end
function Flow:observe(state,now)
    if state.status~="playing" or self.journeyTurn~=state.turnCount then
        self.journeyUntil,self.diceEndsAt,self.moveAt=0,0,0
        self.rollKey,self.settledKey=nil,nil;self.journeyTurn=state.turnCount
    end
    local roll=state.lastRoll
    if state.status=="playing" and roll and roll.turn==state.turnCount then
        local rollKey=state.turnCount..":"..roll.seq
        if rollKey~=self.rollKey then
            self.rollKey,self.settledKey=rollKey,nil
            self.diceEndsAt=now+self.config.diceSeconds
            self.moveAt=self.diceEndsAt+Journey.resultSeconds(self.config)
            self.journeyUntil=now+Journey.duration(self.config,roll)
        end
    end
    local key=Flow.key(state)
    if self.key~=key then
        self.key=key
        local readyAt=math.max(now,self.journeyUntil)
        self.deadline=state.status=="playing" and readyAt+self.config.turnSeconds or 0
        self.handoffAt=state.status=="playing" and state.phase=="end" and readyAt+self.config.autoAdvanceSeconds or 0
    end
end
function Flow:diceSettled(state,sequence,now)
    local roll=state.lastRoll
    if state.status~="playing" or not roll or roll.seq~=sequence or roll.turn~=state.turnCount or self.journeyTurn~=state.turnCount or self.settledKey==self.rollKey then return false end
    self.settledKey=self.rollKey
    self.diceEndsAt=math.max(self.diceEndsAt,now)
    local ready=self.diceEndsAt+Journey.resultSeconds(self.config)
    local extra=math.max(0,ready-self.moveAt)
    self.moveAt=self.moveAt+extra;self.journeyUntil=self.journeyUntil+extra
    if self.deadline>0 then self.deadline=self.deadline+extra end
    if self.handoffAt>0 then self.handoffAt=self.handoffAt+extra end
    return extra>0
end
function Flow:allows(state,command,now)
    local waits=command=="End" or command=="Buy" or command=="Skip" or command=="Offer"
    return not waits or state.turnCount~=self.journeyTurn or now>=self.journeyUntil
end
function Flow:due(state,now)
    if state.status~="playing" or self.key~=Flow.key(state) then return nil end
    if state.phase=="end" and self.handoffAt>0 and now>=self.handoffAt then return "End" end
    if now>=self.deadline then
        if state.phase=="offer" then return "Offer",Offers.request(state,1) end
        return state.phase=="roll" and "Roll" or (state.phase=="buy" and "Skip" or "End")
    end
    return nil
end
return Flow
