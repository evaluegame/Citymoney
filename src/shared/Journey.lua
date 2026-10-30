-- Shared timeline for the dice, board movement, result reveal and turn clock.
local Journey={}
function Journey.duration(config,roll)
    if not roll then return 0 end
    return config.diceSeconds+math.clamp(roll.steps or 0,0,12)*(config.stepSeconds or 0.18)+0.15
end
function Journey.progress(config,roll,remaining)
    return math.clamp(1-remaining/math.max(0.01,Journey.duration(config,roll)),0,1)
end
return Journey
