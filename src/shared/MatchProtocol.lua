-- Testable multi-party reservation protocol. Only the server supplies adapters.
local runtimeScript=getfenv().script
local Queue=runtimeScript and require(runtimeScript.Parent.QueuePlanner) or require("./QueuePlanner")
local Protocol={}
function Protocol.create(config,selected,map: any,tickets: any,adapter: any)
    local claim=adapter.guid()
    local held={}
    local seats=0
    for _,entry in ipairs(selected) do seats=seats+#entry.value.users end
    if seats~=2 and seats~=4 then return nil end
    local ticket
    local ok=pcall(function()
        for _,entry in ipairs(selected) do
            local record=map:UpdateAsync(entry.key,function(current,sort)
                if Queue.valid(current,seats,adapter.now()) and not current.cancelled then current.claim=claim;current.claimUntil=adapter.now()+40;return current,sort end
                return nil
            end,90)
            if not record or record.claim~=claim then error("Party already claimed") end
            table.insert(held,{key=entry.key,value=record})
        end
        local users=Queue.roster(held,#config.playerColors)
        if not users or #users~=seats then error("Invalid roster") end
        local code,privateId=adapter.reserve()
        ticket={id=claim,seats=seats,users=users,code=code,privateId=privateId,status="preparing",created=adapter.now()}
        tickets:SetAsync(claim,ticket,180,adapter.now())
        for _,entry in ipairs(held) do
            local record=map:UpdateAsync(entry.key,function(current,sort)
                if current and not current.cancelled and current.claim==claim then current.matchId=claim;return current,sort end
                return nil
            end,150)
            if not record or record.matchId~=claim or record.cancelled then error("Party left during reservation") end
        end
        ticket.status="ready";tickets:SetAsync(claim,ticket,180,adapter.now())
    end)
    if not ok then
        pcall(function() tickets:RemoveAsync(claim) end)
        for _,entry in ipairs(held) do
            pcall(function()
                map:UpdateAsync(entry.key,function(current,sort)
                    if current and current.claim==claim then current.claim=nil;current.claimUntil=nil;current.matchId=nil;return current,sort end
                    return nil
                end,90)
            end)
        end
        return nil
    end
    return ticket
end
function Protocol.recover(map: any,key,record,ticket,now)
    if not record or not record.matchId or (record.claimUntil or 0)>now or (ticket and ticket.status=="ready") then return false end
    local matchId=record.matchId
    map:UpdateAsync(key,function(current,sort)
        if current and current.matchId==matchId and (current.claimUntil or 0)<=now and not current.cancelled then
            current.matchId,current.claim,current.claimUntil=nil,nil,nil
            current.updated=now
            return current,sort
        end
        return nil
    end,90)
    return true
end
return Protocol
