-- Camera decisions use the same authoritative journey clock as board movement.
local runtimeScript=getfenv().script
local Journey=runtimeScript and require(runtimeScript.Parent.Journey) or require("./Journey")
local Actors=runtimeScript and require(runtimeScript.Parent.Actors) or require("./Actors")
local Follow={}
function Follow.key(roll) return roll and (tostring(roll.turn)..":"..tostring(roll.seq)) or "" end
function Follow.plan(config,state,arrival,now,suppressed,reduced)
    local roll=state and state.lastRoll
    if reduced or not roll or state.status~="playing" or roll.turn~=state.turnCount or (roll.steps or 0)<=0 or not arrival or arrival<=0 or Follow.key(roll)==suppressed then return nil end
    local resident,seat
    for index,p in ipairs(state.players) do if p.id==roll.actorId then resident,seat=p,index;break end end
    if not resident or not resident.alive or resident.position~=roll.to then return nil end
    local moveAt=arrival-Journey.duration(config,roll)+config.diceSeconds
    if now<moveAt-0.3 or now>arrival+0.65 then return nil end
    local position=Actors.travel(config,roll,seat,now-moveAt)
    return {id=resident.id,seat=seat,position=position,key=Follow.key(roll)}
end
function Follow.framing(position)
    local x,_,z=table.unpack(position)
    -- Look outward from the city: the resident is in front of the houses.
    local yaw=math.atan2(-x,-z)
    return {min={x-12,1,z-12},max={x+12,16,z+12},target={x,4,z}},yaw,math.rad(38)
end
return Follow
