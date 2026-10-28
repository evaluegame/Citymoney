-- Pure profile and entitlement logic. Only the server provides these adapters.
local runtimeScript=getfenv().script
local Cosmetics=runtimeScript and require(runtimeScript.Parent.Cosmetics) or require("./Cosmetics")
local Profiles={}
Profiles.__index=Profiles
function Profiles.new(config,adapter: any)
    return setmetatable({config=config,adapter=adapter,records={}},Profiles)
end
function Profiles:begin(id)
    local record={preferred="classic",styleId="classic",effects=true,ownsPass=false,loading=true,dirty=false,revision=0,status="Loading your collection…",stamp=0}
    self.records[id]=record
    return record
end
function Profiles:load(id,record)
    if self.records[id]~=record then return end
    local readOK,saved=true,nil
    if not self.adapter.studio then readOK,saved=pcall(self.adapter.read,id) end
    local ownsOK,owns=true,false
    local passId=Cosmetics.passId(self.config)
    if passId>0 and not self.adapter.studio then ownsOK,owns=pcall(self.adapter.owns,id,passId) end
    if self.records[id]~=record then return end
    local preferences=Cosmetics.normalize(readOK and saved or nil)
    record.preferred,record.effects=preferences.styleId,preferences.effects
    record.ownsPass=ownsOK and owns==true
    record.styleId=Cosmetics.allowed(record.preferred,record.ownsPass,self.adapter.studio) and record.preferred or "classic"
    record.loading=false
    record.status=not ownsOK and "Could not verify your pass. Use Check ownership to retry." or (not readOK and "Saved style is unavailable. You can still play and choose a style." or "")
end
function Profiles:select(id,styleId: any,effects: any)
    local record=self.records[id]
    if not record or record.loading then return false,"Your collection is loading. Try again shortly." end
    if not Cosmetics.find(styleId) or type(effects)~="boolean" then return false,"Choose a valid style and effects setting." end
    if not Cosmetics.allowed(styleId,record.ownsPass,self.adapter.studio) then return false,"The Waterfront Club pass unlocks this style." end
    if record.preferred==styleId and record.effects==effects then return true end
    record.preferred,record.styleId,record.effects=styleId,styleId,effects
    record.revision=record.revision+1;record.dirty=true
    record.stamp=math.max(self.adapter.now(),record.stamp+1)
    record.status=""
    return true
end
function Profiles:refresh(id)
    local record=self.records[id]
    if not record or record.loading then return false,"Your collection is loading." end
    local passId=Cosmetics.passId(self.config)
    if passId==0 then return false,"The Club pass is not available for sale yet." end
    if self.adapter.studio then return true end
    local ok,owns=pcall(self.adapter.owns,id,passId)
    if self.records[id]~=record then return false,"You left this server." end
    if not ok then record.status="Roblox could not verify ownership. Try Check ownership again.";return false,record.status end
    record.ownsPass=owns==true
    record.styleId=Cosmetics.allowed(record.preferred,record.ownsPass,false) and record.preferred or "classic"
    record.status=record.ownsPass and "Your Club collection is unlocked." or "You do not own the Club pass yet."
    return true
end
function Profiles:purchaseFinished(id,passId,purchased)
    if Cosmetics.passId(self.config)==0 or passId~=Cosmetics.passId(self.config) or purchased~=true then return false end
    return self:refresh(id)
end
function Profiles:saveRecord(id,record)
    if not record or not record.dirty or record.saving or record.loading then return true end
    if self.adapter.studio then record.dirty=false;record.status="Studio preview · preferences last for this test session.";return true end
    record.saving=true
    local revision=record.revision
    local data={version=1,styleId=record.preferred,effects=record.effects,updatedAt=record.stamp}
    local ok=pcall(self.adapter.save,id,data)
    record.saving=false
    if ok and record.revision==revision then record.dirty=false end
    record.status=ok and (record.dirty and "Saving your latest style…" or "Style saved for your next visit.") or "Style equipped. Saving is delayed; the server will retry."
    return ok
end
function Profiles:save(id) return self:saveRecord(id,self.records[id]) end
function Profiles:detach(id)
    local record=self.records[id];self.records[id]=nil
    return record
end
function Profiles:visual(id)
    local record=self.records[id]
    return record and record.styleId or "classic",not record or record.effects
end
function Profiles:snapshot(id)
    local record=self.records[id]
    return {styleId=record and record.styleId or "classic",effects=not record or record.effects,ownsPass=record and record.ownsPass or false,
        loading=not record or record.loading,studio=self.adapter.studio==true,passId=Cosmetics.passId(self.config),
        status=record and record.status or "Loading your collection…",saving=record and (record.saving==true or record.dirty) or false}
end
return Profiles
