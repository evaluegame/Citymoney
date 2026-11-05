local Marketplace=game:GetService("MarketplaceService")
local DataStore=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local Profiles=require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").CosmeticProfiles)
local Cosmetics=require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").Cosmetics)
local Club={}
Club.__index=Club
function Club.new(config,changed)
    local studio=RunService:IsStudio() or game.PlaceId==0
    local store=not studio and DataStore:GetDataStore("CitymoneyCosmetics_v1") or nil
    local self=setmetatable({changed=changed,lastCheck={},lastStyle={},departing={},closed=false},Club)
    self.profiles=Profiles.new(config,{
        studio=studio,now=function() return DateTime.now().UnixTimestampMillis end,
        owns=function(id,passId) return Marketplace:UserOwnsGamePassAsync(id,passId) end,
        read=function(id) return store:GetAsync(tostring(id)) end,
        save=function(id,data)
            store:UpdateAsync(tostring(id),function(previous)
                if type(previous)=="table" and type(previous.updatedAt)=="number" and previous.updatedAt>data.updatedAt then return nil end
                return data
            end)
        end,
    })
    Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
        if self.profiles.adapter.studio or passId~=Cosmetics.passId(config) or passId<=0 then return end
        local record=self.profiles.records[player.UserId]
        if not record then return end
        record.checkoutSequence=(record.checkoutSequence or 0)+1
        record.checkoutResult=purchased and "checking" or "cancelled"
        changed()
        if purchased then task.spawn(function() self:reconcile(player.UserId,passId) end) end
    end)
    task.spawn(function()
        while not self.closed do
            task.wait(20)
            for id,record in pairs(self.profiles.records) do
                if record.dirty and not record.saving then task.spawn(function() self.profiles:save(id);if self.profiles.records[id] then changed() end end) end
            end
        end
    end)
    game:BindToClose(function()
        self.closed=true
        local pending=0
        local records={}
        for id,record in pairs(self.profiles.records) do
            records[record]=id
        end
        for record,id in pairs(self.departing) do records[record]=id end
        for record,id in pairs(records) do
            if record.dirty then
                pending=pending+1
                task.spawn(function() self:flush(id,record,18);pending=pending-1 end)
            end
        end
        local untilTime=os.clock()+20
        while pending>0 and os.clock()<untilTime do task.wait(0.1) end
    end)
    return self
end
function Club:reconcile(id,passId)
    local record=self.profiles.records[id]
    if not record or record.purchasePending or self.profiles.adapter.studio or passId==0 or passId~=Cosmetics.passId(self.profiles.config) then return false end
    if record.ownsPass then record.checkoutResult="verified";self.changed();return true end
    record.purchasePending=true;record.status="Checking your Club purchase with Roblox…";self.changed()
    local readyBy=os.clock()+8
    while record.loading and self.profiles.records[id]==record and os.clock()<readyBy do task.wait(0.25) end
    for attempt=1,4 do
        if self.profiles.records[id]~=record then return false end
        self.profiles:purchaseFinished(id,passId,true)
        if record.ownsPass then break end
        if attempt<4 then task.wait(2^(attempt-1)) end
    end
    if self.profiles.records[id]~=record then return false end
    record.purchasePending=false
    record.checkoutResult=record.ownsPass and "verified" or "delayed"
    record.status=record.ownsPass and "Your Club collection is unlocked." or "Roblox has not confirmed this purchase yet. Use Check ownership to retry."
    self.changed()
    return record.ownsPass
end
function Club:add(player)
    local record=self.profiles:begin(player.UserId)
    task.spawn(function()
        self.profiles:load(player.UserId,record)
        if self.profiles.records[player.UserId]==record then
            -- Teleport preferences are untrusted. select rechecks ownership and fields.
            local ok,join=pcall(function() return player:GetJoinData() end)
            local transfer=ok and type(join.TeleportData)=="table" and join.TeleportData or {}
            local chosen=transfer.citymoneyStyle
            if type(transfer.citymoneyStyles)=="table" and #transfer.citymoneyStyles<=4 then
                for _,entry in ipairs(transfer.citymoneyStyles) do if type(entry)=="table" and entry.id==player.UserId then chosen=entry end end
            end
            if type(chosen)=="table" then self.profiles:select(player.UserId,chosen.styleId,chosen.effects) end
            self.changed()
            if record.dirty then task.delay(2,function() self.profiles:save(player.UserId) end) end
        end
    end)
end
function Club:remove(id)
    local record=self.profiles:detach(id);self.lastCheck[id],self.lastStyle[id]=nil,nil
    if record then
        self.departing[record]=id
        task.spawn(function() self:flush(id,record,8);self.departing[record]=nil end)
    end
end
function Club:flush(id,record,seconds)
    -- An in-flight write captures an earlier revision. Wait before the final save.
    local deadline=os.clock()+seconds
    while record and record.saving and os.clock()<deadline do task.wait(0.1) end
    self.profiles:saveRecord(id,record)
end
function Club:select(id,request)
    if type(request)~="table" then return false,"Choose a style first." end
    if self.lastStyle[id] and os.clock()-self.lastStyle[id]<0.8 then return false,"Please wait a moment before changing your style again." end
    local ok,message=self.profiles:select(id,request.styleId,request.effects)
    if ok then
        self.lastStyle[id]=os.clock()
        self.changed()
        task.delay(2,function() self.profiles:save(id);if self.profiles.records[id] then self.changed() end end)
    end
    return ok,message
end
function Club:refresh(id)
    if self.lastCheck[id] and os.clock()-self.lastCheck[id]<8 then return false,"Please wait a few seconds before checking again." end
    self.lastCheck[id]=os.clock()
    local ok,message=self.profiles:refresh(id);self.changed()
    return ok,message
end
function Club:snapshot(id) return self.profiles:snapshot(id) end
function Club:selection(id)
    local record=self.profiles.records[id]
    if not record or record.loading then return nil end
    return {styleId=record.styleId,effects=record.effects}
end
function Club:visual(id) return self.profiles:visual(id) end
function Club:styles()
    local result={}
    for id in pairs(self.profiles.records) do
        local styleId,effects=self:visual(id)
        table.insert(result,{id=id,styleId=styleId,effects=effects})
    end
    return result
end
return Club
