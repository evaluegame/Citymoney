local Publisher=require('../src/server/Publisher')
local Engine=require('../src/shared/Engine')
local Config=require('../src/shared/Config')
local passed=0
local function test(name,callback)
 local ok,message=pcall(callback);assert(ok,'FAIL '..name..': '..tostring(message));passed=passed+1;print('PASS '..name)
end
local function harness()
 local c={now=0,syncs={},sent={},reports={},failWorld=false}
 c.publisher=Publisher.new({clock=function() return c.now end,
  sync=function(state) table.insert(c.syncs,state);if c.failWorld then error('visual failure') end end,
  send=function(player,payload) if c.failUser==player.UserId then error('recipient left') end;table.insert(c.sent,{id=player.UserId,data=payload}) end,
  report=function(kind) table.insert(c.reports,kind) end})
 return c
end
local players={{UserId=1},{UserId=2},{UserId=3}}
test('a world failure still delivers the authoritative state to every player',function()
 local c=harness();c.failWorld=true;local state={cash=1500}
 c.publisher:publish(state,players,function() return state end)
 assert(#c.sent==3 and c.publisher.dirty and c.sent[1].data==state)
end)
test('a departing snapshot recipient cannot block other players',function()
 local c=harness();c.failUser=2
 c.publisher:publish({},players,function(id) return {id=id} end)
 assert(#c.sent==2 and c.sent[1].id==1 and c.sent[2].id==3)
end)
test('one failed player payload does not discard the remaining snapshots',function()
 local c=harness()
 c.publisher:publish({},players,function(id) if id==1 then error('payload not ready') end;return {id=id} end)
 assert(#c.sent==2 and c.sent[1].id==2 and c.sent[2].id==3)
end)
test('visual retries back off instead of rebuilding on every request',function()
 local c=harness();c.failWorld=true;c.publisher:publish({},players,function() return {} end)
 for _=1,30 do c.publisher:retry({}) end
 assert(#c.syncs==1)
 for _,time in ipairs({1,3,7,15,23}) do c.now=time;c.publisher:retry({}) end
 assert(#c.syncs==6 and c.publisher.retryAt==31)
end)
test('a recovered renderer uses the latest state rather than replaying an old action',function()
 local c=harness();c.failWorld=true;c.publisher:publish({cash=1500},players,function() return {} end)
 c.failWorld=false;c.now=1;local latest={cash=1200}
 assert(c.publisher:retry(latest));assert(c.syncs[2]==latest and not c.publisher.dirty)
end)
test('healthy worlds do not rebuild between publications',function()
 local c=harness();c.publisher:publish({},players,function() return {} end)
 for time=1,20 do c.now=time;assert(c.publisher:retry({})) end
 assert(#c.syncs==1)
end)
test('repeated failures produce bounded diagnostics without exposing raw errors',function()
 local c=harness();for time=0,29 do c.now=time;c.publisher:report('clock') end
 assert(#c.reports==3);for _,report in ipairs(c.reports) do assert(report=='clock') end
end)
test('publication failure cannot charge a home purchase twice or rewind its turn',function()
 local c=harness();local e=Engine.new(Config);assert(e:start({{id=1,name='One'},{id=2,name='Two'}}))
 e:current().position=2;e:land(e:current());assert(e:act(1,'Buy',2,1,1))
 local cash=e:current().cash;local phase=e.state.phase;c.failWorld=true
 c.publisher:publish(e.state,players,function(id) return e:view(id) end)
 c.failWorld=false;c.now=1;assert(c.publisher:retry(e.state))
 assert(e:current().cash==cash and e.state.phase==phase and e.state.properties[2].level==1)
end)
print('\n'..passed..' publication recovery cases passed.')
