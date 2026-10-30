-- Shared timeline for the dice, board movement, result reveal and turn clock.
local Journey={}
function Journey.stepSeconds(config) return config.stepSeconds or 0.38 end
-- The tween spans a whole step. Reach the exact space early, then hold still
-- there so a board move reads as individual spaces instead of a continuous run.
function Journey.step(config,alpha)
    local seconds=Journey.stepSeconds(config)
    local pause=math.clamp(config.stepPauseSeconds or 0.13,0,seconds*0.75)
    local travel=math.clamp(alpha*seconds/(seconds-pause),0,1)
    local progress=travel*travel*(3-2*travel)
    local height=travel<1 and math.sin(math.pi*travel)*0.55 or 0
    return progress,height
end
-- One tween drives the complete route, avoiding a scheduler delay at every
-- space. Each boundary is still the exact center of the next board space.
function Journey.sample(config,steps,elapsed)
    local seconds=Journey.stepSeconds(config)
    local index=math.clamp(math.floor(elapsed/seconds)+1,1,steps)
    local progress,height=Journey.step(config,(elapsed-(index-1)*seconds)/seconds)
    return index,progress,height
end
function Journey.duration(config,roll)
    if not roll then return 0 end
    return config.diceSeconds+math.clamp(roll.steps or 0,0,12)*Journey.stepSeconds(config)+0.15
end
function Journey.progress(config,roll,remaining)
    return math.clamp(1-remaining/math.max(0.01,Journey.duration(config,roll)),0,1)
end
return Journey
