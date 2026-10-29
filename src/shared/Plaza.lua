-- Predictable festival offers and a fixed-price card market, all in game cash.
local runtimeScript=getfenv().script
local Tactics=runtimeScript and require(runtimeScript.Parent.Tactics) or require("./Tactics")
local Plaza={}
function Plaza.festival(config,state)
    local index=math.floor(math.max(0,state.turnCount-1)/config.festivalTurns)%#config.festivals+1
    return config.festivals[index],config.festivalTurns-math.max(0,state.turnCount-1)%config.festivalTurns,index
end
function Plaza.act(engine,id,request: any)
    local state,config=engine.state,engine.config
    local player=engine:current()
    if state.status~="playing" or not player or player.id~=id or not player.alive then return false,"Visit the plaza during your turn." end
    if type(request)~="table" or request.turn~=state.turnCount then return false,"That plaza offer expired. Open it again." end
    if state.phase~="roll" then return false,"Use the city plaza before rolling your dice." end
    if state.plazaUsed then return false,"You can make one plaza purchase per turn." end
    if request.shop=="market" then
        local cost=type(request.kind)=="string" and config.cityMarket[request.kind]
        if not cost then return false,"Choose a card from the market." end
        if (player.cards[request.kind] or 0)>=config.cardLimit then return false,"Your hand already holds the maximum of this card." end
        if player.cash<cost then return false,"This card costs $"..cost.." in game cash." end
        player.cash=player.cash-cost;Tactics.grant(engine,player,request.kind,1)
        engine:log(player.name.." bought "..config.cardDefinitions[request.kind].name.." from City Market for $"..cost..".")
    elseif request.shop=="festival" then
        local offer=Plaza.festival(config,state)
        if request.festivalId~=offer.id then return false,"The festival changed. Review the current offer." end
        local index=request.tile
        if type(index)~="number" or index%1~=0 or not config.tiles[index] or config.tiles[index].kind~="property" then return false,"Choose one of your homes." end
        local property=state.properties[index]
        if property.ownerId~=id then return false,"Festival offers apply to your own homes." end
        if offer.kind=="boost" and (property.boost or 0)>0 then return false,"This home already has a rent boost." end
        if offer.kind=="shield" and property.shield then return false,"This home already has a shield." end
        if offer.kind=="repair" and property.level>=config.maxLevel then return false,"This home is already fully upgraded." end
        if player.cash<offer.cost then return false,"This festival offer costs $"..offer.cost.." in game cash." end
        player.cash=player.cash-offer.cost
        if offer.kind=="boost" then property.boost=config.rentBoostPayments
        elseif offer.kind=="shield" then property.shield=true
        else property.level=property.level+1;player.stats.upgrades=player.stats.upgrades+1 end
        state.lastAction={seq=(state.lastAction and state.lastAction.seq or 0)+1,kind=offer.kind,tile=index,actorId=id,targetId=id,blocked=false,amount=offer.cost}
        engine:log(player.name.." joined "..offer.name.." at "..config.tiles[index].name.." for $"..offer.cost..".")
    else return false,"Choose City Market or the festival." end
    state.plazaUsed=true;Tactics.refresh(engine)
    return true
end
function Plaza.botMove(engine,id)
    local state=engine.state
    local player=engine:current()
    if state.status~="playing" or not player or player.id~=id or not player.alive or state.phase~="roll" or state.plazaUsed then return nil end
    local offer=Plaza.festival(engine.config,state)
    if player.cash<offer.cost+450 then return nil end
    local target,value=nil,-1
    for index,property in ipairs(state.properties) do
        local valid=property.ownerId==id and (offer.kind~="boost" or (property.boost or 0)==0)
            and (offer.kind~="shield" or not property.shield) and (offer.kind~="repair" or property.level<engine.config.maxLevel and engine.config.tiles[index].upgrade>offer.cost)
        if valid and engine:rent(index)>value then target,value=index,engine:rent(index) end
    end
    if target then return {shop="festival",tile=target,turn=state.turnCount,festivalId=offer.id} end
    return nil
end
return Plaza
