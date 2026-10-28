local Config=require("../src/shared/Config")
local Cosmetics=require("../src/shared/Cosmetics")
local Profiles=require("../src/shared/CosmeticProfiles")
local Architecture=require("../src/shared/Architecture")
local Engine=require("../src/shared/Engine")
local passed=0
local function check(value,message) assert(value,message or "Expected true") end
local function equal(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function test(name,callback)
    local ok,message=pcall(callback);if not ok then error("FAIL "..name..": "..tostring(message),0) end
    passed=passed+1;print("PASS "..name)
end
local function system(studio,passId)
    local config=table.clone(Config);config.clubPassId=passId==nil and 12345 or passId
    local backend={saved={},owners={},writes=0,reads=0,checks=0,clock=1000,failRead=false,failSave=false,failOwns=false}
    local adapter={studio=studio==true,now=function() backend.clock=backend.clock+1;return backend.clock end,
        read=function(id) backend.reads=backend.reads+1;if backend.failRead then error("offline") end;return backend.saved[id] end,
        owns=function(id,idOfPass) backend.checks=backend.checks+1;equal(idOfPass,12345);if backend.failOwns then error("offline") end;return backend.owners[id]==true end,
        save=function(id,data) if backend.failSave then error("offline") end;backend.saved[id]=table.clone(data);backend.writes=backend.writes+1 end}
    local profiles=Profiles.new(config,adapter)
    return profiles,backend,adapter
end
local function load(p,id) local record=p:begin(id or 1);p:load(id or 1,record);return record end
test("catalogue contains one free and three paid visual collections",function()
    local ids,free,premium={},0,0
    for _,style in ipairs(Cosmetics.styles) do
        check(not ids[style.id]);ids[style.id]=true
        for _,field in ipairs({"accent","trim","glass","stone","door","light","dice","pip"}) do check(string.match(style[field],"^%x%x%x%x%x%x$")) end
        if style.premium then premium=premium+1 else free=free+1 end
    end
    equal(free,1);equal(premium,3)
end)
test("unconfigured and malformed pass IDs never enable sales",function()
    equal(Cosmetics.passId({}),0)
    for _,id in ipairs({0,-1,0/0,math.huge,1.5,"12345",{}}) do equal(Cosmetics.passId({clubPassId=id}),0) end
    equal(Cosmetics.passId({clubPassId=12345}),12345)
end)
test("classic is available without a pass while paid styles require verified ownership",function()
    check(Cosmetics.allowed("classic",false,false))
    for _,id in ipairs({"gilded","aurora","rose"}) do check(not Cosmetics.allowed(id,false,false));check(Cosmetics.allowed(id,true,false)) end
    check(not Cosmetics.allowed("unknown",true,true))
end)
test("an unconfigured live pass cannot be bypassed using saved or transferred premium selections",function()
    local p,b=system(false,0);b.owners[1]=true;b.saved[1]={styleId="gilded"};load(p)
    equal(b.checks,0);equal(p:visual(1),"classic");equal(p:snapshot(1).passId,0)
    check(not p:select(1,"aurora",true));check(not p:purchaseFinished(1,0,true))
    check(not p:refresh(1));check(p:select(1,"classic",false))
end)
test("Studio previews make no ownership, storage or purchase calls",function()
    local p,b=system(true);load(p)
    check(p:select(1,"gilded",true));check(p:save(1))
    equal(b.reads,0);equal(b.checks,0);equal(b.writes,0)
    equal(p:snapshot(1).ownsPass,false);check(p:snapshot(1).studio)
end)
test("loading profiles reject edits until verified data is ready",function()
    local p=system();local r=p:begin(1)
    check(not p:select(1,"classic",false));check(p:snapshot(1).loading)
    p:load(1,r);check(p:select(1,"classic",false))
end)
test("saved premium selections cannot unlock an unowned pass",function()
    local p,b=system();b.saved[1]={styleId="gilded",effects=false};load(p)
    equal(p:visual(1),"classic");equal(p:snapshot(1).ownsPass,false);equal(p:snapshot(1).effects,false)
    check(not p:select(1,"gilded",true));equal(b.writes,0)
end)
test("verified owners restore their selected collection on a new server",function()
    local p,b=system();b.owners[1]=true;b.saved[1]={styleId="rose",effects=false};load(p)
    equal(p:visual(1),"rose");check(p:snapshot(1).ownsPass);equal(p:snapshot(1).effects,false)
end)
test("ownership outages fail closed without blocking ordinary play",function()
    local p,b=system();b.failOwns=true;b.saved[1]={styleId="aurora"};load(p)
    equal(p:visual(1),"classic");check(not p:snapshot(1).loading)
    check(not p:select(1,"aurora",true));check(p:select(1,"classic",false))
    b.failOwns=false;b.owners[1]=true;check(p:refresh(1));check(p:select(1,"aurora",true))
end)
test("storage outages preserve play and do not write default profiles automatically",function()
    local p,b=system();b.failRead=true;load(p);check(p:save(1));equal(b.writes,0)
    check(p:select(1,"classic",false));check(p:save(1));equal(b.writes,1)
end)
test("cancelled and unrelated purchases never grant Club access",function()
    local p,b=system();load(p);b.owners[1]=true
    check(not p:purchaseFinished(1,999,true));check(not p:purchaseFinished(1,12345,false))
    equal(p:snapshot(1).ownsPass,false);equal(b.checks,1)
end)
test("successful purchase events still require a server ownership check",function()
    local p,b=system();load(p)
    p:purchaseFinished(1,12345,true);check(not p:snapshot(1).ownsPass)
    b.owners[1]=true;check(p:purchaseFinished(1,12345,true));check(p:select(1,"gilded",true))
end)
test("a failed ownership refresh retains previously verified access",function()
    local p,b=system();b.owners[1]=true;load(p);check(p:select(1,"rose",true))
    b.failOwns=true;check(not p:refresh(1));check(p:snapshot(1).ownsPass);equal(p:visual(1),"rose")
end)
test("explicit revocation falls back safely and restoration recovers the preferred style",function()
    local p,b=system();b.owners[1]=true;load(p);check(p:select(1,"aurora",true))
    b.owners[1]=false;check(p:refresh(1));equal(p:visual(1),"classic")
    b.owners[1]=true;check(p:refresh(1));equal(p:visual(1),"aurora")
end)
test("malformed selections and effect values never change a profile",function()
    local p,b=system();b.owners[1]=true;load(p)
    for _,id in ipairs({"unknown",false,12,{}}) do check(not p:select(1,id,true)) end
    for _,fx in ipairs({"false",0,{}}) do check(not p:select(1,"gilded",fx)) end
    equal(p:visual(1),"classic");check(not p.records[1].dirty)
end)
test("saved preferences contain appearance only and ownership is never persisted",function()
    local p,b=system();b.owners[1]=true;load(p);check(p:select(1,"gilded",false));check(p:save(1))
    local saved=b.saved[1];equal(saved.styleId,"gilded");equal(saved.effects,false);equal(saved.version,1)
    equal(saved.ownsPass,nil);equal(saved.cash,nil);equal(saved.cards,nil)
end)
test("failed saves stay dirty and retry without losing the equipped collection",function()
    local p,b=system();b.owners[1]=true;load(p);check(p:select(1,"aurora",true))
    b.failSave=true;check(not p:save(1));check(p.records[1].dirty);equal(p:visual(1),"aurora")
    b.failSave=false;check(p:save(1));check(not p.records[1].dirty);equal(b.saved[1].styleId,"aurora")
end)
test("a preference change during a yielding save remains pending for the next write",function()
    local p,b,a=system();b.owners[1]=true;load(p);check(p:select(1,"gilded",true))
    local save=a.save;a.save=function(id,data) save(id,data);check(p:select(id,"rose",false)) end
    check(p:save(1));check(p.records[1].dirty);equal(p:visual(1),"rose");equal(b.saved[1].styleId,"gilded")
    a.save=save;check(p:save(1));equal(b.saved[1].styleId,"rose");check(not p.records[1].dirty)
end)
test("late loads and ownership responses cannot overwrite a rejoined player's profile",function()
    local p,_,a=system();local old=p:begin(1)
    a.read=function() p:detach(1);p:begin(1);return {styleId="gilded"} end
    p:load(1,old);check(p.records[1]~=old);check(p.records[1].loading)
    a.read=function() return nil end;p:load(1,p.records[1])
    a.owns=function() p:detach(1);p:begin(1);return true end
    check(not p:refresh(1));check(not p.records[1].ownsPass)
end)
test("detached profiles can flush their final preference without affecting a new session",function()
    local p,b=system();b.owners[1]=true;load(p);check(p:select(1,"rose",false))
    local old=p:detach(1);load(p);check(p:saveRecord(1,old));equal(b.saved[1].styleId,"rose")
    equal(p:visual(1),"classic")
end)
test("all premium plots preserve ownership markers, doors and valid geometry",function()
    for _,style in ipairs(Cosmetics.styles) do
        for index,tile in ipairs(Config.tiles) do if tile.kind=="property" then
            for level=0,3 do
                local entries=Architecture.property(Config,index,"Owner","FFBE55",level,0,nil,style.id)
                local flags,door,decor=0,false,0
                for _,entry in ipairs(entries) do
                    if entry.name=="OwnershipBorder" or entry.name=="OwnerFlag" then equal(entry.color,"FFBE55");flags=flags+1 end
                    if entry.door then door=true;equal(entry.size[1],2.8) end
                    if string.sub(entry.name,1,4)=="Club" then decor=decor+1;check(entry.canCollide==false) end
                    equal(entry.tileIndex,index)
                    for _,n in ipairs(entry.size) do check(n>0 and n<math.huge) end
                    for _,n in ipairs(entry.position) do check(n==n and math.abs(n)<1000) end
                end
                equal(flags,5);check(door)
                check(style.premium and decor>15 and decor<40 or not style.premium and decor==0)
            end
        end end
    end
end)
test("unowned lots never receive premium houses or ornaments",function()
    for _,style in ipairs(Cosmetics.styles) do
        local entries=Architecture.property(Config,2,false,"FFBE55",0,0,nil,style.id)
        for _,entry in ipairs(entries) do check(not entry.door);check(string.sub(entry.name,1,4)~="Club") end
    end
end)
test("cosmetic selection leaves game cash, rent, cards and turn untouched",function()
    local e=Engine.new(Config);check(e:start({{id=1,name="One"},{id=2,name="Two"}}))
    e.state.properties[2].ownerId=1;e.state.properties[2].level=2
    local rent,cash,turn,card=e:rent(2),e:player(1).cash,e.state.turnCount,e:player(1).cards.demolish
    local p,b=system();b.owners[1]=true;load(p)
    for _,style in ipairs(Cosmetics.styles) do check(p:select(1,style.id,true));check(p:save(1)) end
    equal(e:rent(2),rent);equal(e:player(1).cash,cash);equal(e.state.turnCount,turn);equal(e:player(1).cards.demolish,card)
    equal(e.state.properties[2].styleId,nil)
end)
print("\n"..passed.." cosmetics/ownership/profile tests passed, including all 256 plot/style/level combinations.")
