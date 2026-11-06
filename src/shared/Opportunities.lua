-- Free landing rewards: card spaces and every second City News visit.
local runtimeScript=getfenv().script
local Tactics=runtimeScript and require(runtimeScript.Parent.Tactics) or require("./Tactics")
local Offers={}
function Offers.definition(config,state)
    local pending=state.pendingOffer
    if not pending then return nil end
    if pending.kind=="cardSpace" then
        local tile=config.tiles[pending.tile]
        local choices={}
        for _,kind in ipairs(tile.cardChoices) do
            local card=config.cardDefinitions[kind]
            local detail=card.description
            if kind=="demolish" then
                detail=state.rules and state.rules.attackMode=="downgrade" and "Choose a rival's home. Remove one level; cottages return to the city." or "Choose a rival's home. Demolish it and return the plot to the city."
            end
            table.insert(choices,{label=card.name,detail=detail,card=kind})
        end
        return {name=tile.name,description="You landed on a card space. Choose one free card for your hand.",choices=choices}
    end
    return config.opportunities[pending.definition]
end
function Offers.openCardSpace(engine,player,index)
    local state=engine.state
    state.offerSeq=(state.offerSeq or 0)+1
    state.pendingOffer={seq=state.offerSeq,kind="cardSpace",tile=index,actorId=player.id,turn=state.turnCount}
    state.phase="offer"
    engine:log(player.name.." landed on "..engine.config.tiles[index].name..". Collect a free card!")
end
function Offers.open(engine: any,player: any)
    local every=engine.config.opportunityEvery or 0
    if every<1 or player.stats.news%every~=0 or not engine.config.opportunities or #engine.config.opportunities==0 then return false end
    local state=engine.state
    state.offerSeq=(state.offerSeq or 0)+1
    local seat=1
    for index,resident in ipairs(state.players) do if resident.id==player.id then seat=index;break end end
    local index=(math.floor(player.stats.news/every)+seat-2)%#engine.config.opportunities+1
    state.pendingOffer={seq=state.offerSeq,definition=index,actorId=player.id,turn=state.turnCount}
    state.phase="offer"
    engine:log(player.name.." discovered "..engine.config.opportunities[index].name..". Choose cash or a tactical card!")
    return true
end
function Offers.request(state,option)
    local pending=state.pendingOffer
    if not pending then return nil end
    return {seq=pending.seq,turn=pending.turn,option=option}
end
function Offers.available(config,player,reward)
    return reward~=nil and (not reward.card or (player.cards[reward.card] or 0)<config.cardLimit)
end
function Offers.timeoutRequest(config,state)
    local pending=state.pendingOffer
    if not pending then return nil end
    if pending.kind~="cardSpace" then return Offers.request(state,1) end
    local player
    for _,entry in ipairs(state.players) do if entry.id==pending.actorId then player=entry end end
    if player then
        for index,reward in ipairs(Offers.definition(config,state).choices) do
            if Offers.available(config,player,reward) then return Offers.request(state,index) end
        end
    end
    return Offers.request(state,0)
end
function Offers.act(engine: any,id,request: any)
    local state,config=engine.state,engine.config
    local player=engine:current()
    if state.status~="playing" or not player or not player.alive or player.id~=id then return false,"Choose an opportunity during your own turn." end
    local pending=state.pendingOffer
    if state.phase~="offer" or not pending then return false,"There is no opportunity waiting." end
    if type(request)~="table" or request.turn~=state.turnCount or request.turn~=pending.turn or request.seq~=pending.seq then return false,"That opportunity expired. Review the current choices." end
    if type(request.option)~="number" or request.option%1~=0 then return false,"Choose one of the listed rewards." end
    if request.option==0 and pending.kind=="cardSpace" then
        state.pendingOffer=false;state.phase="end"
        engine:log(player.name.." continued without collecting a card.")
        return true
    end
    local definition=Offers.definition(config,state)
    local reward=definition.choices[request.option]
    if not reward then return false,"Choose one of the listed rewards." end
    if not Offers.available(config,player,reward) then return false,pending.kind=="cardSpace" and "Your hand is full for this card. Choose another or continue without a card." or "Your hand is full for this card. Take the cash instead." end
    if reward.card then Tactics.grant(engine,player,reward.card,1) else player.cash=player.cash+reward.cash end
    state.lastOpportunity={seq=pending.seq,actorId=id,name=definition.name,reward=reward.label,card=reward.card or false,amount=reward.cash or 0,fromCardSpace=pending.kind=="cardSpace",tile=pending.tile or false}
    state.pendingOffer=false;state.phase="end"
    engine:log(player.name.." chose "..reward.label.." from "..definition.name.."!")
    Tactics.refresh(engine)
    return true
end
function Offers.botChoice(engine: any,id)
    local pending=engine.state.pendingOffer
    local player=engine:player(id)
    if not pending or not player or pending.actorId~=id then return nil end
    if pending.kind=="cardSpace" then
        local best,score=nil,-1
        for index,reward in ipairs(Offers.definition(engine.config,engine.state).choices) do
            if Offers.available(engine.config,player,reward) then
                local value=0
                for _,property in ipairs(engine.state.properties) do
                    if property.ownerId==id and (reward.card=="collect" or reward.card=="repair" and property.level<engine.config.maxLevel or reward.card=="shield" and not property.shield or reward.card=="boost" and property.boost==0) then value=value+2 end
                    if reward.card=="demolish" and property.ownerId and property.ownerId~=id then value=value+3 end
                end
                if value>score then best,score=index,value end
            end
        end
        return Offers.request(engine.state,best or 0)
    end
    local reward=engine.config.opportunities[pending.definition].choices[2]
    local takeCard=false
    if player.cash>=450 and Offers.available(engine.config,player,reward) then
        for _,property in ipairs(engine.state.properties) do
            if property.ownerId==id and ((reward.card=="repair" and property.level<engine.config.maxLevel) or (reward.card=="shield" and not property.shield) or reward.card=="collect" or (reward.card=="boost" and property.boost==0)) then takeCard=true end
            if reward.card=="demolish" and property.ownerId and property.ownerId~=id then takeCard=true end
        end
    end
    return Offers.request(engine.state,takeCard and 2 or 1)
end
return Offers
