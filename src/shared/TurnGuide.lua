-- Presentation only: the server's journey and decision state owns every action.
local runtimeScript=getfenv().script
local Journey=runtimeScript and require(runtimeScript.Parent.Journey) or require("./Journey")
local Guide={labels={"1  ROLL","2  MOVE","3  CHOOSE","4  NEXT"}}
function Guide.stage(config,data,now)
    local state=data and data.game
    if not state or state.status~="playing" then return 0 end
    local roll=state.lastRoll
    if roll and roll.turn==state.turnCount then
        local phase=Journey.phase(config,roll,data.journeyUntil,now,data.diceEndsAt,data.moveAt)
        if phase=="dice" or phase=="result" then return 1 end
        if phase=="move" then return 2 end
    end
    if state.phase=="buy" or state.phase=="offer" then return 3 end
    return state.phase=="end" and 4 or 1
end
function Guide.tip(config,state,id)
    local me
    for _,entry in ipairs(state.players or {}) do if entry.id==id then me=entry end end
    if not me then return "Watch the city, or join your next match." end
    if me.cash<180 then return "Keep cash for rent. Sell a home if you need funds." end
    local homes=0
    for _,property in ipairs(state.properties or {}) do if property.ownerId==id then homes=homes+1 end end
    if homes==0 then return "Your first home starts on an empty property." end
    if me.cards then
        for _,kind in ipairs(config.cardTypes) do
            if (me.cards[kind] or 0)>0 then return "Cards and upgrades are optional before you roll." end
        end
    end
    return "Complete a district pair to double its base rent."
end
return Guide
