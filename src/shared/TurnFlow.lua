-- Deadlines are keyed to the authoritative phase. UI activity cannot delay handoff.
local runtimeScript=getfenv().script
local Journey=runtimeScript and require(runtimeScript.Parent.Journey) or require("./Journey")
local Offers=runtimeScript and require(runtimeScript.Parent.Opportunities) or require("./Opportunities")
local Flow={}
Flow.__index=Flow
function Flow.new(config) return setmetatable({config=config,key=nil,deadline=0,handoffAt=0,journeyUntil=0,rollKey=nil,journeyTurn=0},Flow) end
function Flow.key(state) return state.status..":"..state.turnCount..":"..state.turn..":"..state.phase end
function Flow:observe(state,now)
    if state.status~="playing" or self.journeyTurn~=state.turnCount then self.journeyUntil=0;self.rollKey=nil;self.journeyTurn=state.turnCount end
    local roll=state.lastRoll
    if state.status=="playing" and roll and roll.turn==state.turnCount then
        local rollKey=state.turnCount..":"..roll.seq
        if rollKey~=self.rollKey then self.rollKey=rollKey;self.journeyUntil=now+Journey.duration(self.config,roll) end
    end
    local key=Flow.key(state)
    if self.key~=key then
        self.key=key
        local readyAt=math.max(now,self.journeyUntil)
        self.deadline=state.status=="playing" and readyAt+self.config.turnSeconds or 0
        self.handoffAt=state.status=="playing" and state.phase=="end" and readyAt+self.config.autoAdvanceSeconds or 0
    end
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
