local Config=require("../src/shared/Config")
local Engine=require("../src/shared/Engine")
local Lobby=require("../src/shared/Lobby")
local Parties=require("../src/shared/Parties")
local Queue=require("../src/shared/QueuePlanner")
local Protocol=require("../src/shared/MatchProtocol")
local passed=0
local function check(value) assert(value,"Expected true") end
local function equal(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function test(name,callback)
    local ok,message=pcall(callback);if not ok then error("FAIL "..name..": "..tostring(message),0) end
    passed=passed+1;print("PASS "..name)
end
local function record(key,seats,ids)
    local users={}
    for _,id in ipairs(ids) do table.insert(users,{id=id,name="User "..id,colorIndex=1}) end
    return {key=key,value={id=key,seats=seats,users=users,updated=100,joined=50,job="job-"..key}}
end
local function copy(value: any): any
    if type(value)~="table" then return value end
    local result={};for key,entry in pairs(value) do result[key]=copy(entry) end;return result
end
local function backend(entries)
    local map: any={rows={},sort={},updates=0}
    for _,entry in ipairs(entries) do map.rows[entry.key]=copy(entry.value);map.sort[entry.key]=entry.value.joined end
    function map:UpdateAsync(key,transform,ttl)
        self.updates=self.updates+1
        if self.hook then self.hook(self,key,self.updates) end
        if self.failUpdate==self.updates then error("Injected queue outage") end
        local result,sort=transform(copy(self.rows[key]),self.sort[key])
        if result==nil then return nil end
        self.rows[key],self.sort[key]=copy(result),sort or self.sort[key]
        return copy(result)
    end
    local tickets: any={rows={},sets=0,history={}}
    function tickets:SetAsync(key,value,ttl,sort)
        self.sets=self.sets+1
        if self.failSet==self.sets then error("Injected ticket outage") end
        self.rows[key]=copy(value);table.insert(self.history,value.status)
    end
    function tickets:RemoveAsync(key) self.rows[key]=nil end
    local calls={reserve=0,guid=0}
    local adapter={now=function() return 100 end,guid=function() calls.guid=calls.guid+1;return "match-"..calls.guid end,
        reserve=function() calls.reserve=calls.reserve+1;return "test-access-code","private-test" end}
    return map,tickets,adapter,calls
end

test("host can choose exactly 2 or 4 seats and outsiders cannot configure",function()
    local lobby=Lobby.new(Config);lobby:join(1,"Leader");lobby:join(2,"Friend")
    check(not lobby:configure(2,"seats",4));check(not lobby:configure(1,"seats",3))
    check(lobby:configure(1,"seats",4));equal(lobby.seats,4);equal(lobby.attackMode,"destroy")
end)
test("human-only practice waits for ready players and bot fill is explicit",function()
    local lobby=Lobby.new(Config);lobby:join(1,"Leader");lobby:join(2,"Friend")
    lobby:configure(1,"bots",false);check(not lobby:buildRoster(1))
    lobby:setReady(2,true);local humans=lobby:buildRoster(1);equal(#humans,2);check(not humans[2].bot)
    lobby:configure(1,"seats",4);check(not lobby:buildRoster(1))
    lobby:configure(1,"bots",true);local mixed=lobby:buildRoster(1);equal(#mixed,4);check(mixed[3].bot and mixed[4].bot)
end)
test("color choices stay unique and carry into the game",function()
    local lobby=Lobby.new(Config);lobby:join(1,"Leader");lobby:join(2,"Friend")
    check(not lobby:setColor(2,1));check(lobby:setColor(1,4));lobby:setReady(2,true)
    local roster=lobby:buildRoster(1);local engine=Engine.new(Config)
    check(engine:start(roster));equal(engine:player(1).colorIndex,4)
    check(not engine:start(roster))
end)
test("duplicate requested match colors are rejected",function()
    local e=Engine.new(Config)
    check(not e:start({{id=1,name="One",colorIndex=2},{id=2,name="Two",colorIndex=2}}))
    equal(e.state.status,"lobby")
end)
test("invited friends join a separate party and confirm readiness",function()
    local parties=Parties.new(Config);parties:add(1,"Captain");parties:add(2,"Friend");parties:add(3,"Solo")
    check(parties:join(2,1));equal(parties:get(2),parties:get(1));equal(#parties:get(1).members,2)
    check(not parties:get(2):member(2).ready);equal(#parties:get(3).members,1)
end)
test("parties cap at four and handle leader disconnects",function()
    local parties=Parties.new(Config)
    for id=1,5 do parties:add(id,"User "..id) end
    for id=2,4 do check(parties:join(id,1)) end
    check(not parties:join(5,1));parties:remove(1)
    equal(parties:get(3):hostId(),2);equal(parties.groups[1],nil)
end)
test("leaving a party creates an independent ready solo party",function()
    local parties=Parties.new(Config);parties:add(1,"Captain");parties:add(2,"Friend");parties:join(2,1)
    check(parties:leave(2));equal(parties:get(2):hostId(),2);check(parties:get(2):member(2).ready)
    equal(#parties:get(1).members,1)
end)
test("completed matches combine participants without losing unique colors",function()
    local parties=Parties.new(Config);for id=1,4 do parties:add(id,"User "..id) end
    parties:join(2,1);parties:join(4,3)
    local roster={{id=1,name="One",colorIndex=4},{id=2,name="Two",colorIndex=2},{id=3,name="Three",colorIndex=3},{id=4,name="Four",colorIndex=1}}
    local party=parties:combine(roster);equal(#party.members,4);equal(party.seats,4)
    for _,user in ipairs(roster) do equal(parties:get(user.id),party);equal(party:member(user.id).colorIndex,user.colorIndex) end
end)
test("2-player queue packs two solo players",function()
    local selected=Queue.select({record("a",2,{1}),record("b",2,{2})},2,100)
    equal(#selected,2);equal(#Queue.roster(selected,6),2)
end)
test("4-player queue keeps two friend pairs together",function()
    local selected=Queue.select({record("a",4,{1,2}),record("b",4,{3,4})},4,100)
    equal(#selected,2);equal(#selected[1].value.users,2);equal(#selected[2].value.users,2)
end)
test("a party of three waits for a solo and is never split",function()
    check(not Queue.select({record("a",4,{1,2,3})},4,100))
    local selected=Queue.select({record("a",4,{1,2,3}),record("b",4,{4})},4,100)
    equal(#selected[1].value.users,3)
end)
test("2- and 4-player queues cannot mix",function()
    check(not Queue.select({record("a",2,{1,2})},4,100))
    check(not Queue.select({record("a",4,{1,2})},2,100))
end)
test("stale, cancelled, claimed and committed parties are excluded",function()
    local a,b,c,d=record("a",2,{1}),record("b",2,{2}),record("c",2,{3}),record("d",2,{4})
    a.value.updated=0;b.value.cancelled=true;c.value.claim="other";c.value.claimUntil=150;d.value.matchId="ready"
    check(not Queue.select({a,b,c,d},2,100))
end)
test("expired uncommitted claims can match again",function()
    local a,b=record("a",2,{1}),record("b",2,{2});a.value.claim="old";a.value.claimUntil=90
    check(Queue.select({a,b},2,100))
end)
test("duplicate user records cannot put one user in two match seats",function()
    check(not Queue.select({record("a",2,{1}),record("b",2,{1})},2,100))
end)
test("independent party color collisions are resolved for the match",function()
    local entries={record("a",4,{1,2}),record("b",4,{3,4})};local roster=Queue.roster(entries,6);local seen={}
    for _,user in ipairs(roster) do check(not seen[user.colorIndex]);seen[user.colorIndex]=true end
    equal(roster[1].colorIndex,1);check(not Queue.roster(entries,2))
end)
test("fragmented parties do not block other exact-size matches",function()
    local selected=Queue.select({record("old",4,{1,2,3}),record("pair-a",4,{4,5}),record("pair-b",4,{6,7})},4,100)
    equal(selected[1].key,"pair-a");equal(selected[2].key,"pair-b")
end)
test("match tickets become ready only after every party is committed",function()
    local entries={record("a",2,{1}),record("b",2,{2})};local map,tickets,adapter,calls=backend(entries)
    local ticket=Protocol.create(Config,entries,map,tickets,adapter)
    check(ticket and ticket.status=="ready");equal(calls.reserve,1)
    equal(tickets.history[1],"preparing");equal(tickets.history[2],"ready")
    equal(map.rows.a.matchId,ticket.id);equal(map.rows.b.matchId,ticket.id)
end)
test("competing matchmakers cannot reserve the same party twice",function()
    local entries={record("a",2,{1}),record("b",2,{2})};local map,tickets,adapter,calls=backend(entries)
    local first=Protocol.create(Config,entries,map,tickets,adapter);check(first)
    check(not Protocol.create(Config,entries,map,tickets,adapter));equal(calls.reserve,1)
    equal(tickets.rows[first.id].status,"ready")
end)
test("a queue outage releases already acquired claims",function()
    local entries={record("a",2,{1}),record("b",2,{2})};local map,tickets,adapter,calls=backend(entries)
    map.failUpdate=2
    check(not Protocol.create(Config,entries,map,tickets,adapter));equal(map.rows.a.claim,nil);equal(calls.reserve,0)
end)
test("rollback never clears another matchmaker's claim",function()
    local entries={record("a",2,{1}),record("b",2,{2})};local map,tickets,adapter=backend(entries)
    map.rows.b.claim,map.rows.b.claimUntil="competitor",200
    check(not Protocol.create(Config,entries,map,tickets,adapter));equal(map.rows.a.claim,nil);equal(map.rows.b.claim,"competitor")
end)
test("reservation failures keep party order and leave no match ticket",function()
    local entries={record("a",2,{1}),record("b",2,{2})};local map,tickets,adapter=backend(entries)
    adapter.reserve=function() error("Injected Roblox reservation failure") end
    check(not Protocol.create(Config,entries,map,tickets,adapter));equal(map.rows.a.claim,nil);equal(map.rows.b.claim,nil)
    equal(map.sort.a,50);equal(next(tickets.rows),nil)
end)
test("a cancellation during commit rolls back partial match assignments",function()
    local entries={record("a",2,{1}),record("b",2,{2})};local map,tickets,adapter=backend(entries)
    map.hook=function(self,key,count) if count==4 then self.rows.b.cancelled=true end end
    check(not Protocol.create(Config,entries,map,tickets,adapter));equal(map.rows.a.matchId,nil)
    equal(map.rows.a.claim,nil);check(map.rows.b.cancelled);equal(next(tickets.rows),nil)
end)
test("failed final ticket writes never expose a ready match",function()
    local entries={record("a",2,{1}),record("b",2,{2})};local map,tickets,adapter=backend(entries)
    tickets.failSet=2
    check(not Protocol.create(Config,entries,map,tickets,adapter));equal(map.rows.a.matchId,nil);equal(map.rows.b.matchId,nil)
    equal(next(tickets.rows),nil);equal(#tickets.history,1)
end)
test("orphaned preparing tickets recover without stealing ready matches",function()
    local entries={record("a",2,{1})};local map=backend(entries)
    map.rows.a.matchId,map.rows.a.claim,map.rows.a.claimUntil="orphan","orphan",90
    check(Protocol.recover(map,"a",copy(map.rows.a),{status="preparing"},100));equal(map.rows.a.matchId,nil);equal(map.rows.a.updated,100)
    map.rows.a.matchId,map.rows.a.claimUntil="live",90
    check(not Protocol.recover(map,"a",copy(map.rows.a),{status="ready"},100));equal(map.rows.a.matchId,"live")
end)
print("\n"..passed.." party/matchmaking tests passed.")
