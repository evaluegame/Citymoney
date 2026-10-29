-- Deadlines are keyed to the authoritative phase. UI activity cannot delay handoff.
local Flow={}
Flow.__index=Flow
function Flow.new(config) return setmetatable({config=config,key=nil,deadline=0,handoffAt=0},Flow) end
function Flow.key(state) return state.status..":"..state.turnCount..":"..state.turn..":"..state.phase end
function Flow:observe(state,now)
    local key=Flow.key(state)
    if self.key~=key then
        self.key=key
        self.deadline=state.status=="playing" and now+self.config.turnSeconds or 0
        self.handoffAt=state.status=="playing" and state.phase=="end" and now+self.config.autoAdvanceSeconds or 0
    end
end
function Flow:due(state,now)
    if state.status~="playing" or self.key~=Flow.key(state) then return nil end
    if state.phase=="end" and self.handoffAt>0 and now>=self.handoffAt then return "End" end
    if now>=self.deadline then
        return state.phase=="roll" and "Roll" or (state.phase=="buy" and "Skip" or "End")
    end
    return nil
end
return Flow
