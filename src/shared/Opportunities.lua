-- Guaranteed choices on every second City News visit. No paid/random rewards.
local runtimeScript=getfenv().script
local Tactics=runtimeScript and require(runtimeScript.Parent.Tactics) or require("./Tactics")
local Offers={}
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
    return not reward.card or (player.cards[reward.card] or 0)<config.cardLimit
end
function Offers.act(engine: any,id,request: any)
    local state,config=engine.state,engine.config
    local player=engine:current()
    if state.status~="playing" or not player or not player.alive or player.id~=id then return false,"Choose an opportunity during your own turn." end
    local pending=state.pendingOffer
    if state.phase~="offer" or not pending then return false,"There is no opportunity waiting." end
    if type(request)~="table" or request.turn~=state.turnCount or request.turn~=pending.turn or request.seq~=pending.seq then return false,"That opportunity expired. Review the current choices." end
    if type(request.option)~="number" or request.option%1~=0 then return false,"Choose one of the two rewards." end
    local definition=config.opportunities[pending.definition]
    local reward=definition.choices[request.option]
    if not reward then return false,"Choose one of the two rewards." end
    if not Offers.available(config,player,reward) then return false,"Your hand is full for this card. Take the cash instead." end
    if reward.card then Tactics.grant(engine,player,reward.card,1) else player.cash=player.cash+reward.cash end
    state.lastOpportunity={seq=pending.seq,actorId=id,name=definition.name,reward=reward.label,card=reward.card or false,amount=reward.cash or 0}
    state.pendingOffer=false;state.phase="end"
    engine:log(player.name.." chose "..reward.label.." from "..definition.name.."!")
    Tactics.refresh(engine)
    return true
end
function Offers.botChoice(engine: any,id)
    local pending=engine.state.pendingOffer
    local player=engine:player(id)
    if not pending or not player or pending.actorId~=id then return nil end
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
