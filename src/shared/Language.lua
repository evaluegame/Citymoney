-- One independent language context per client; replicated game data stays English.
local runtimeScript=getfenv().script
local Thai=runtimeScript and require(runtimeScript.Parent.Thai) or require("./Thai")
local Language={}
local Context={}
Context.__index=Context
function Language.resolve(value:any):string
    if type(value)~="string" then return "en-us" end
    value=string.lower(string.gsub(value,"_","-"))
    return (value=="th" or string.sub(value,1,3)=="th-") and "th-th" or "en-us"
end
function Language.read(service:any,player:any):string
    local ok,value=pcall(function() return service.RobloxLocaleId end)
    if ok and type(value)=="string" and value~="" then return value end
    ok,value=pcall(function() return player.LocaleId end)
    return ok and type(value)=="string" and value~="" and value or "en-us"
end
function Language.new(value:any)
    return setmetatable({locale=Language.resolve(value),cache={},cacheCount=0,records=setmetatable({},{__mode="k"})},Context)
end
function Context:text(value:string):string
    if self.locale~="th-th" then return value end
    if self.cache[value]~=nil then return self.cache[value] end
    local result=Thai.text(value)
    if self.cacheCount>=512 then self.cache={};self.cacheCount=0 end
    self.cache[value]=result;self.cacheCount=self.cacheCount+1
    return result
end
function Context:scene(entries)
    local result={}
    for _,entry in ipairs(entries) do
        local copy=table.clone(entry)
        if copy.text then copy.text=self:text(copy.text) end
        table.insert(result,copy)
    end
    return result
end
function Context:shortName(index:number,source:string):string
    return self.locale=="th-th" and (Thai.shortNames[index] or Thai.text(source)) or source
end
function Context:tileCaption(index:number,source:string):string
    local name,value=string.match(source,"^([^\n]+)\n(.*)$")
    return name and (self:shortName(index,name).."\n"..self:text(value)) or self:text(source)
end
function Context:_apply(object:any,record:any)
    local enabled=not object:GetAttribute("PlayerName") and (not record.world or object:GetAttribute("CitymoneyText")==true)
    local tile=object:GetAttribute("CitymoneyTile")
    record.display=enabled and (tile and self:tileCaption(tile,record.source) or self:text(record.source)) or record.source
    if object.Text~=record.display then
        record.changing=true;object.Text=record.display;record.changing=false
    end
end
function Context:setLocale(value:any):boolean
    local locale=Language.resolve(value)
    if locale==self.locale then return false end
    self.locale=locale
    for object,record in pairs(self.records) do
        if object.Parent then self:_apply(object,record) end
    end
    return true
end
function Context:watch(root:any,world:boolean?)
    local function bind(object:any)
        if self.records[object] or not (object:IsA("TextLabel") or object:IsA("TextButton")) then return end
        object.AutoLocalize=false
        local record={source=object.Text,display=object.Text,changing=false,world=world==true}
        self.records[object]=record
        object:GetPropertyChangedSignal("Text"):Connect(function()
            if record.changing or object.Text==record.display then return end
            record.source=object.Text;self:_apply(object,record)
        end)
        for _,attribute in ipairs({"PlayerName","CitymoneyText"}) do
            object:GetAttributeChangedSignal(attribute):Connect(function() self:_apply(object,record) end)
        end
        self:_apply(object,record)
    end
    for _,object in ipairs(root:GetDescendants()) do bind(object) end
    root.DescendantAdded:Connect(bind)
end
function Context:follow(service:any,player:any)
    local function update() self:setLocale(Language.read(service,player)) end
    update()
    -- The Roblox account/app language takes priority over the device language.
    for _,pair in ipairs({{service,"RobloxLocaleId"},{player,"LocaleId"}}) do
        if pair[1] then pair[1]:GetPropertyChangedSignal(pair[2]):Connect(update) end
    end
end
return Language
