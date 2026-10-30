-- Server-owned tactical cards and claimable challenges; no Roblox dependencies.
local Tactics={}
function Tactics.resetProperty(property)
    property.ownerId,property.level,property.paint,property.shield,property.boost,property.rentTier=false,0,0,false,0,1
end
function Tactics.initialize(config,player,seat)
    player.cards={demolish=1,collect=1,boost=1,shield=1,repair=1}
    player.stats={upgrades=0,rent=0,passes=0,news=0,tactics=0,blocks=0}
    player.completedChallenges=0
    player.challengeIndex=(seat-1)%#config.challenges+1
    player.challengeBaseline=0
    player.challenge={id=config.challenges[player.challengeIndex].id,progress=0,ready=false}
end
function Tactics.metric(engine,player,id)
    if id=="homes" then
        local count=0
        for _,property in ipairs(engine.state.properties) do if property.ownerId==player.id then count=count+1 end end
        return count
    elseif id=="districts" then
        local count=0
        for group in pairs(engine.config.groups) do if engine:ownsGroup(player.id,group) then count=count+1 end end
        return count
    end
    return player.stats[id] or 0
end
function Tactics.refresh(engine)
    for _,player in ipairs(engine.state.players) do
        local definition=engine.config.challenges[player.challengeIndex]
        local metric=Tactics.metric(engine,player,definition.id)
        local progress=math.max(0,metric-(player.challengeBaseline or 0))
        player.challenge={id=definition.id,name=definition.name,description=definition.description,target=definition.target,
            reward=definition.reward,progress=math.min(progress,definition.target),ready=player.alive and progress>=definition.target}
    end
end
function Tactics.nextChallenge(engine,player)
    player.challengeIndex=player.challengeIndex%#engine.config.challenges+1
    local definition=engine.config.challenges[player.challengeIndex]
    player.challengeBaseline=(definition.id=="homes" or definition.id=="districts") and 0 or Tactics.metric(engine,player,definition.id)
end
function Tactics.grant(engine,player,kind,count)
    if not engine.config.cardDefinitions[kind] then return 0 end
    local previous=player.cards[kind] or 0
    player.cards[kind]=math.min(engine.config.cardLimit,previous+(count or 1))
    return player.cards[kind]-previous
end
function Tactics.draw(engine,player,count)
    local added=0
    for _=1,count or 1 do
        local available={}
        for _,kind in ipairs(engine.config.cardTypes) do if (player.cards[kind] or 0)<engine.config.cardLimit then table.insert(available,kind) end end
        if #available==0 then break end
        local kind=available[engine.random(1,#available)]
        added=added+Tactics.grant(engine,player,kind,1)
    end
    return added
end
function Tactics.claim(engine,player)
    Tactics.refresh(engine)
    if engine.state.challengeClaimed then return false,"You can claim one challenge each turn." end
    if not player.challenge.ready then return false,"Finish the challenge before claiming it." end
    player.cash=player.cash+player.challenge.reward
    player.completedChallenges=player.completedChallenges+1
    engine.state.challengeClaimed=true
    local added=Tactics.draw(engine,player,1)
    engine:log(player.name.." completed "..player.challenge.name.." and collected $"..player.challenge.reward..(added>0 and " plus a card!" or "! Their card hand is full."))
    Tactics.nextChallenge(engine,player)
    return true
end
function Tactics.swap(engine,player)
    if engine.state.challengeSwapped then return false,"You can change your challenge once each turn." end
    if player.cash<engine.config.challengeSwapCost then return false,"A new challenge costs $"..engine.config.challengeSwapCost.."." end
    player.cash=player.cash-engine.config.challengeSwapCost
    engine.state.challengeSwapped=true
    Tactics.nextChallenge(engine,player)
    engine:log(player.name.." chose a new challenge for $"..engine.config.challengeSwapCost..".")
    return true
end
function Tactics.play(engine,id,kind,index,targetId,turn)
    local state,config=engine.state,engine.config
    if state.status~="playing" then return false,"Start a match first." end
    local player=engine:current()
    if not player or player.id~=id or not player.alive then return false,"Play cards during your own turn." end
    if turn~=state.turnCount then return false,"That card selection expired. Choose a target again." end
    if state.actionUsed then return false,"You can play one tactical card per turn." end
    if type(kind)~="string" or not config.cardDefinitions[kind] then return false,"Choose a valid tactical card." end
    if (player.cards[kind] or 0)<1 then return false,"You do not have that card." end
    if type(index)~="number" or index%1~=0 or not config.tiles[index] or config.tiles[index].kind~="property" then return false,"Choose a property." end
    local property=state.properties[index]
    local owner=property.ownerId and engine:player(property.ownerId)
    if not owner or not owner.alive then return false,"Choose an owned property." end
    if kind=="demolish" then
        if property.ownerId==id then return false,"Choose an opponent's house for demolition." end
    elseif property.ownerId~=id then return false,"Choose one of your own properties." end
    local target
    if kind=="collect" then
        if type(targetId)~="number" and type(targetId)~="string" then return false,"Choose the opponent who must pay." end
        target=engine:player(targetId)
        if not target or not target.alive or target.id==id then return false,"Choose an active opponent to pay rent." end
    elseif kind=="shield" and property.shield then return false,"This home already has a shield."
    elseif kind=="boost" and (property.boost or 0)>0 then return false,"This home still has an active rent boost."
    elseif kind=="repair" and property.level>=config.maxLevel then return false,"This home is already fully upgraded." end
    player.cards[kind]=player.cards[kind]-1
    player.stats.tactics=player.stats.tactics+1
    state.actionUsed=true
    local event={seq=(state.lastAction and state.lastAction.seq or 0)+1,kind=kind,tile=index,actorId=id,targetId=target and target.id or property.ownerId,blocked=false,amount=0}
    state.lastAction=event
    local name=config.tiles[index].name
    if kind=="demolish" then
        if property.shield then
            property.shield=false;event.blocked=true;owner.stats.blocks=owner.stats.blocks+1
            engine:log(owner.name.."'s shield blocked demolition at "..name.."!")
        elseif (state.rules and state.rules.attackMode=="destroy") or property.level==0 then
            Tactics.resetProperty(property)
            engine:log(player.name.." demolished "..owner.name.."'s house at "..name..". The empty lot returns to the city.")
        else
            property.level=property.level-1
            engine:log(player.name.." removed one building level from "..owner.name.."'s "..name..".")
        end
    elseif kind=="collect" then
        local amount=math.min(config.demandCap,engine:rent(index)*config.demandMultiplier)
        engine:log(player.name.." demands $"..amount.." from "..target.name.." using "..name.."!")
        event.amount=engine:pay(target,amount,player,"rent")
        if event.amount>0 and (property.boost or 0)>0 then property.boost=property.boost-1 end
    elseif kind=="boost" then
        property.boost=config.rentBoostPayments
        engine:log(player.name.." boosted rent at "..name.." by 50% for the next two payments.")
    elseif kind=="shield" then
        property.shield=true
        engine:log(player.name.." protected "..name.." against its next demolition attempt.")
    elseif kind=="repair" then
        property.level=property.level+1;player.stats.upgrades=player.stats.upgrades+1
        engine:log(player.name.." used a renovation grant to upgrade "..name.." to level "..property.level.." for free.")
    end
    Tactics.refresh(engine)
    return true
end
function Tactics.botMove(engine,id)
    local player=engine:player(id)
    if not player or not player.alive or engine.state.actionUsed then return nil end
    local own,unshielded,repair,boost,rival,opponent
    local rentValue,repairValue,rivalValue=-1,-1,-1
    for index,property in ipairs(engine.state.properties) do
        if property.ownerId==id then
            local value=engine:rent(index)
            if value>rentValue then own,rentValue=index,value end
            if not property.shield and (not unshielded or property.level>engine.state.properties[unshielded].level) then unshielded=index end
            if property.level<engine.config.maxLevel and engine.config.tiles[index].rent>repairValue then repair,repairValue=index,engine.config.tiles[index].rent end
            if (property.boost or 0)==0 and (not boost or value>engine:rent(boost)) then boost=index end
        elseif property.ownerId and not property.shield then
            local value=engine.config.tiles[index].price+property.level*engine.config.tiles[index].upgrade
            if value>rivalValue then rival,rivalValue=index,value end
        end
    end
    for _,entry in ipairs(engine.state.players) do if entry.alive and entry.id~=id and (not opponent or entry.cash>opponent.cash) then opponent=entry end end
    local kind,index,target
    if repair and player.cards.repair>0 then kind,index="repair",repair
    elseif unshielded and engine.state.properties[unshielded].level>=2 and player.cards.shield>0 then kind,index="shield",unshielded
    elseif rival and player.cards.demolish>0 then kind,index="demolish",rival
    elseif own and opponent and player.cards.collect>0 then kind,index,target="collect",own,opponent.id
    elseif boost and player.cards.boost>0 then kind,index="boost",boost
    elseif unshielded and player.cards.shield>0 then kind,index="shield",unshielded end
    if kind then return {kind=kind,tile=index,targetId=target,turn=engine.state.turnCount} end
    return nil
end
return Tactics
