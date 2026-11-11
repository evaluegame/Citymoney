-- A read-only recap of the authoritative match, never a second scoring system.
local runtimeScript=getfenv().script
local Plans=runtimeScript and require(runtimeScript.Parent.PropertyPlans) or require("./PropertyPlans")
local Recap={}
function Recap.build(config,state)
    local rows={}
    for seat,person in ipairs(state.players or {}) do
        local stats=person.stats or {}
        local row={id=person.id,name=person.name,colorIndex=person.colorIndex or seat,seat=seat,
            winner=person.id==state.winnerId,alive=person.alive,cash=person.cash,netWorth=person.cash,
            homes=0,levels=0,rent=stats.rent or 0,builds=stats.upgrades or 0,
            tactics=stats.tactics or 0,goals=person.completedChallenges or 0}
        for index,property in ipairs(state.properties or {}) do
            if property.ownerId==person.id then
                row.homes=row.homes+1;row.levels=row.levels+property.level
                row.netWorth=row.netWorth+Plans.investment(config,index,property.level,property.rentTier)
            end
        end
        table.insert(rows,row)
    end
    table.sort(rows,function(a,b)
        if a.winner~=b.winner then return a.winner end
        if a.alive~=b.alive then return a.alive end
        return a.netWorth>b.netWorth or (a.netWorth==b.netWorth and a.seat<b.seat)
    end)
    local awards={}
    for _,definition in ipairs({{"CITY BUILDER","builds"},{"RENT LEADER","rent"},{"STRATEGIST","tactics"}}) do
        local best
        for _,row in ipairs(rows) do
            if row[definition[2]]>0 and (not best or row[definition[2]]>best[definition[2]]) then best=row end
        end
        if best then table.insert(awards,{title=definition[1],id=best.id,name=best.name,value=best[definition[2]]}) end
    end
    return {rows=rows,awards=awards,winner=rows[1] and rows[1].winner and rows[1] or nil}
end
return Recap
