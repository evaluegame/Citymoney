-- Platform-independent party settings and unique ownership colors.
local Lobby={}
Lobby.__index=Lobby
function Lobby.new(config)
    return setmetatable({ config=config, members={}, seats=2, fillBots=true, attackMode="destroy" },Lobby)
end
function Lobby:member(id)
    for _,entry in ipairs(self.members) do if entry.id==id then return entry end end
    return nil
end
function Lobby:hostId() return self.members[1] and self.members[1].id or false end
function Lobby:join(id,name)
    if self:member(id) then return false,"Already joined." end
    local color=1
    while color<=#self.config.playerColors do
        local used=false
        for _,entry in ipairs(self.members) do if entry.colorIndex==color then used=true end end
        if not used then break end
        color=color+1
    end
    table.insert(self.members,{ id=id,name=name,colorIndex=color<=#self.config.playerColors and color or false,ready=#self.members==0 })
    return true
end
function Lobby:leave(id)
    for index,entry in ipairs(self.members) do if entry.id==id then table.remove(self.members,index);return end end
end
function Lobby:configure(id,field,value)
    if self:hostId()~=id then return false,"Only the host can change match settings." end
    if field=="seats" and (value==2 or value==4) then self.seats=value
    elseif field=="bots" and type(value)=="boolean" then self.fillBots=value
    elseif field=="attack" and (value=="downgrade" or value=="destroy") then self.attackMode=value
    else return false,"Choose a valid match setting." end
    return true
end
function Lobby:setReady(id,value)
    local entry=self:member(id)
    if not entry or type(value)~="boolean" then return false,"Choose ready or not ready." end
    entry.ready=value;return true
end
function Lobby:setColor(id,value)
    local entry=self:member(id)
    if not entry or type(value)~="number" or value%1~=0 or value<1 or value>#self.config.playerColors then return false,"Choose a player color." end
    for _,other in ipairs(self.members) do if other.id~=id and other.colorIndex==value then return false,"That color is already taken." end end
    entry.colorIndex=value;return true
end
function Lobby:buildRoster(id)
    if self:hostId()~=id then return nil,"Only the host can start the match." end
    if not self.members[1].ready then return nil,"The host must be ready first." end
    local roster,used={},{}
    for _,entry in ipairs(self.members) do
        if entry.ready and #roster<self.seats then
            local color=entry.colorIndex
            if not color or used[color] then return nil,"A resident still needs an available color." end
            used[color]=true
            table.insert(roster,{id=entry.id,name=entry.name,colorIndex=color})
        end
    end
    if #roster<self.seats and not self.fillBots then return nil,"Waiting for "..(self.seats-#roster).." more ready player(s). Invite friends, or enable bots." end
    local bot=1
    while #roster<self.seats do
        local color=1
        while used[color] do color=color+1 end
        used[color]=true
        table.insert(roster,{id=self.config.botId.."-"..bot,name="City Bot "..bot,bot=true,colorIndex=color})
        bot=bot+1
    end
    return roster
end
function Lobby:snapshot()
    return {seats=self.seats,fillBots=self.fillBots,attackMode=self.attackMode,hostId=self:hostId(),members=self.members}
end
return Lobby
