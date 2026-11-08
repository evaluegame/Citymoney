-- Visual faults and departing recipients must not stop authoritative turns.
local Publisher={}
Publisher.__index=Publisher
function Publisher.new(adapter)
    return setmetatable({adapter=adapter,dirty=false,failures=0,retryAt=0,reports={}},Publisher)
end
function Publisher:report(kind)
    local now=self.adapter.clock()
    if not self.reports[kind] or now-self.reports[kind]>=10 then
        self.reports[kind]=now
        if self.adapter.report then self.adapter.report(kind) end
    end
end
function Publisher:_sync(state)
    local now=self.adapter.clock()
    if self.dirty and now<self.retryAt then return false end
    local ok=pcall(self.adapter.sync,state)
    if ok then self.dirty=false;self.failures=0;self.retryAt=0
    else
        self.dirty=true;self.failures=math.min(4,self.failures+1)
        self.retryAt=now+2^(self.failures-1)
        self:report("world")
    end
    return ok
end
function Publisher:publish(state,players,payload)
    self:_sync(state)
    for _,player in ipairs(players) do
        local ok=pcall(function() self.adapter.send(player,payload(player.UserId)) end)
        if not ok then self:report("snapshot") end
    end
end
function Publisher:retry(state)
    if self.dirty then return self:_sync(state) end
    return true
end
return Publisher
