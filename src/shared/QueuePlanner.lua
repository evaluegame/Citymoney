-- Exact-size party packing, unique match colors and queue record validation.
local Queue={}
function Queue.valid(record,seats,now)
    if type(record)~="table" or record.seats~=seats or type(record.users)~="table" or #record.users<1 or #record.users>seats then return false end
    if type(record.updated)~="number" or now-record.updated>60 or record.matchId then return false end
    if record.cancelled or (record.claim and (record.claimUntil or 0)>now) then return false end
    local seen={}
    for _,user in ipairs(record.users) do
        if type(user.id)~="number" or user.id%1~=0 or seen[user.id] then return false end
        seen[user.id]=true
    end
    return true
end
function Queue.select(entries,seats,now)
    local candidates={}
    for _,entry in ipairs(entries) do if Queue.valid(entry.value,seats,now) then table.insert(candidates,entry) end end
    local function fill(from,remaining,selected,users)
        if remaining==0 then return selected end
        for i=from,#candidates do
            local entry=candidates[i]
            if #entry.value.users<=remaining then
                local duplicate=false
                for _,user in ipairs(entry.value.users) do if users[user.id] then duplicate=true end end
                if not duplicate then
                    local nextUsers=table.clone(users)
                    for _,user in ipairs(entry.value.users) do nextUsers[user.id]=true end
                    local nextSelected=table.clone(selected);table.insert(nextSelected,entry)
                    local result=fill(i+1,remaining-#entry.value.users,nextSelected,nextUsers)
                    if result then return result end
                end
            end
        end
        return nil
    end
    return fill(1,seats,{}, {})
end
function Queue.roster(selected,colorCount)
    local roster,used={},{}
    for _,entry in ipairs(selected) do
        for _,user in ipairs(entry.value.users) do
            local color=user.colorIndex
            if type(color)~="number" or color%1~=0 or color<1 or color>colorCount or used[color] then color=1;while used[color] do color=color+1 end end
            if color>colorCount then return nil end
            used[color]=true
            table.insert(roster,{id=user.id,name=user.name,colorIndex=color})
        end
    end
    return roster
end
return Queue
