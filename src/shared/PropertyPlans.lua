-- Shared quotes keep the selector and authoritative server prices identical.
local Plans = {}

function Plans.isLevel(config, value: any)
    return type(value)=="number" and value==value and value%1==0 and value>=0 and value<=config.maxLevel
end

function Plans.purchaseCost(config, index, level: any)
    local tile=config.tiles[index]
    if not tile or tile.kind~="property" or not Plans.isLevel(config,level) then return nil end
    return tile.price+level*tile.upgrade
end

function Plans.upgradeCost(config, index, current: any, target: any)
    local tile=config.tiles[index]
    if not tile or tile.kind~="property" or not Plans.isLevel(config,current) or not Plans.isLevel(config,target) or target<=current then return nil end
    return (target-current)*tile.upgrade
end

function Plans.projectedRent(config, state, id, index, level)
    local tile=config.tiles[index]
    if not tile or tile.kind~="property" or not Plans.isLevel(config,level) then return 0 end
    local amount=tile.rent*config.rentMultipliers[level+1]
    if level==0 then
        local complete=true
        for other,entry in ipairs(config.tiles) do
            if other~=index and entry.group==tile.group and state.properties[other].ownerId~=id then complete=false end
        end
        if complete then amount=amount*2 end
    end
    return amount
end

function Plans.options(config, state, id, index, mode)
    local property,tile=state.properties[index],config.tiles[index]
    if not property or not tile or tile.kind~="property" or (mode~="buy" and mode~="upgrade") then return {} end
    local player
    for _,entry in ipairs(state.players) do if entry.id==id then player=entry end end
    if not player then return {} end
    local options={}
    for level=0,config.maxLevel do
        local cost
        if mode=="buy" then cost=Plans.purchaseCost(config,index,level)
        else cost=Plans.upgradeCost(config,index,property.level,level) end
        table.insert(options, { level=level, name=config.homeNames[level+1], description=config.homeDescriptions[level+1],
            cost=cost or 0, available=cost~=nil, affordable=cost~=nil and player.cash>=cost,
            remaining=player.cash-(cost or 0), rent=Plans.projectedRent(config,state,id,index,level),
            current=mode=="upgrade" and property.level==level })
    end
    return options
end
return Plans
