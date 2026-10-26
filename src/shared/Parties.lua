local runtimeScript=getfenv().script
local Lobby=runtimeScript and require(runtimeScript.Parent.Lobby) or require("./Lobby")
local Parties={}
Parties.__index=Parties
function Parties.new(config) return setmetatable({config=config,groups={},membership={}},Parties) end
function Parties:get(id) return self.groups[self.membership[id]] end
function Parties:add(id,name)
    if self:get(id) then return self:get(id) end
    local party=Lobby.new(self.config);party:join(id,name)
    self.groups[id],self.membership[id]=party,id
    return party
end
function Parties:remove(id)
    local party=self:get(id)
    if not party then return end
    local old=party:hostId()
    party:leave(id);self.membership[id]=nil;self.groups[old]=nil
    if #party.members>0 then
        local leader=party:hostId();self.groups[leader]=party
        for _,entry in ipairs(party.members) do self.membership[entry.id]=leader end
    end
end
function Parties:join(id,leader)
    local old,target=self:get(id),self:get(leader)
    if not old or not target or target:hostId()~=leader then return false,"That party leader is no longer in this lobby." end
    if old==target then return true end
    if #old.members>1 then return false,"Leave your existing party before joining a friend." end
    if #target.members>=4 then return false,"That party already has four players." end
    local member=old:member(id)
    self:remove(id);target:join(id,member.name);target:setReady(id,false)
    self.membership[id]=leader
    return true
end
function Parties:leave(id)
    local party=self:get(id)
    local member=party and party:member(id)
    if not member then return false,"You are not in a party." end
    local name=member.name
    self:remove(id);self:add(id,name)
    return true
end
function Parties:combine(roster)
    for _,user in ipairs(roster) do self:remove(user.id) end
    local party=Lobby.new(self.config)
    party.seats,party.fillBots,party.attackMode=#roster,false,"destroy"
    local leader=roster[1].id
    for _,user in ipairs(roster) do
        party:join(user.id,user.name)
        local member=party:member(user.id)
        member.colorIndex,member.ready=user.colorIndex,true
        self.membership[user.id]=leader
    end
    self.groups[leader]=party
    return party
end
return Parties
