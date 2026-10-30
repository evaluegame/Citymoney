local Config=require('../src/shared/Config')
local Journey=require('../src/shared/Journey')
local Flow=require('../src/shared/TurnFlow')
local passed=0
local function check(v,message) assert(v,message or 'Expected true') end
local function equal(a,b) check(a==b,tostring(a)..' ~= '..tostring(b)) end
local function near(a,b) check(math.abs(a-b)<1e-6) end
local function test(name,callback)
 local ok,message=pcall(callback);if not ok then error('FAIL '..name..': '..tostring(message),0) end
 passed=passed+1;print('PASS '..name)
end
local function state(steps)
 return {status='playing',turnCount=1,turn=1,phase='end',lastRoll={seq=1,turn=1,steps=steps or 6}}
end
test('dice, settled result and movement occupy separate timeline phases',function()
 local s=state();local f=Flow.new(Config);f:observe(s,100)
 equal(Journey.phase(Config,s.lastRoll,f.journeyUntil,100,f.diceEndsAt,f.moveAt),'dice')
 equal(Journey.phase(Config,s.lastRoll,f.journeyUntil,f.diceEndsAt,f.diceEndsAt,f.moveAt),'result')
 equal(Journey.phase(Config,s.lastRoll,f.journeyUntil,f.moveAt-0.001,f.diceEndsAt,f.moveAt),'result')
 equal(Journey.phase(Config,s.lastRoll,f.journeyUntil,f.moveAt,f.diceEndsAt,f.moveAt),'move')
 equal(Journey.phase(Config,s.lastRoll,f.journeyUntil,f.journeyUntil,f.diceEndsAt,f.moveAt),'done')
end)
test('every roll reserves a readable settled-dice pause before its first space',function()
 for steps=0,12 do
  local s=state(steps);local f=Flow.new(Config);f:observe(s,0)
  near(f.moveAt-f.diceEndsAt,0.4)
  check(f.journeyUntil>=Config.diceSeconds+0.4+steps*Config.stepSeconds)
  check(not f:allows(s,'End',f.moveAt-0.001))
 end
end)
test('late physical dice completion shifts movement, arrival and handoff together',function()
 local s=state();local f=Flow.new(Config);f:observe(s,100)
 local arrival,handoff,deadline=f.journeyUntil,f.handoffAt,f.deadline
 check(f:diceSettled(s,1,102));near(f.moveAt,102.4)
 near(f.journeyUntil-arrival,0.9);near(f.handoffAt-handoff,0.9);near(f.deadline-deadline,0.9)
 equal(f:due(s,handoff),nil);equal(f:due(s,f.handoffAt),'End')
end)
test('late dice completion preserves the full purchase and reward decision clocks',function()
 for _,phase in ipairs({'buy','offer'}) do
  local s=state();s.phase=phase;local f=Flow.new(Config);f:observe(s,100)
  check(f:diceSettled(s,1,103));near(f.deadline-f.journeyUntil,Config.turnSeconds)
  for _,command in ipairs({'Buy','Skip','Offer','End'}) do check(not f:allows(s,command,f.journeyUntil-0.01)) end
 end
end)
test('duplicate dice notifications and ordinary refreshes cannot postpone a turn',function()
 local s=state();local f=Flow.new(Config);f:observe(s,100);check(f:diceSettled(s,1,102))
 local arrival,handoff=f.journeyUntil,f.handoffAt
 check(not f:diceSettled(s,1,104));f:observe(s,105)
 equal(f.journeyUntil,arrival);equal(f.handoffAt,handoff)
end)
test('early reduced-motion settlement retains the same minimum result timeline',function()
 local s=state();local f=Flow.new(Config);f:observe(s,100)
 local arrival=f.journeyUntil;check(not f:diceSettled(s,1,100))
 near(f.diceEndsAt,101.1);near(f.moveAt,101.5);equal(f.journeyUntil,arrival)
end)
test('old, cancelled and finished dice cannot alter a different turn',function()
 local s=state();local f=Flow.new(Config);f:observe(s,100);check(not f:diceSettled(s,2,110))
 s.turnCount=2;check(not f:diceSettled(s,1,110));f:observe(s,110)
 equal(f.moveAt,0);equal(f.diceEndsAt,0)
 s.status='finished';check(not f:diceSettled(s,1,120))
end)
print('\n'..passed..' dice-result-before-movement cases passed.')
