-- Checkout presentation only. Server-side pass ownership grants paid styles.
local runtimeScript=getfenv().script
local Cosmetics=runtimeScript and require(runtimeScript.Parent.Cosmetics) or require("./Cosmetics")
local Shop={}
function Shop.price(info:any)
    if type(info)~="table" or info.IsForSale~=true then return nil end
    local price=info.PriceInRobux
    if type(price)~="number" or price~=price or price<0 or price>9007199254740991 or price%1~=0 then return nil end
    return price
end
function Shop.label(price:number)
    if price==0 then return "Unlock Club · FREE" end
    local formatted=string.format("%.0f",price)
    while true do local nextValue,count=string.gsub(formatted,"^(%d+)(%d%d%d)","%1,%2");formatted=nextValue;if count==0 then break end end
    return "Unlock Club · R$ "..formatted
end
function Shop.action(profile,selected,product,prompting,awaiting)
    if not Cosmetics.find(selected) then return "Choose a collection",nil end
    if profile.loading then return "Loading collection…",nil end
    if prompting then return "Complete Roblox checkout…",nil end
    if profile.purchasePending or awaiting=="checking" then return "Verifying with Roblox…",nil end
    if Cosmetics.allowed(selected,profile.ownsPass,profile.studio) then
        if profile.styleId==selected then return "Equipped ✓",nil end
        return profile.studio and "Equip in Studio preview" or ("Equip "..Cosmetics.get(selected).name),"equip"
    end
    if awaiting=="delayed" then return "Verify my purchase","restore" end
    if profile.passId==0 then return "Club pass coming soon",nil end
    if product.passId~=profile.passId or product.state=="loading" or product.state=="idle" then return "Checking Robux price…",nil end
    if product.state=="failed" then return "Retry Robux price","retry" end
    if not product.forSale then return "Pass not on sale",nil end
    if product.price==nil then return "Retry Robux price","retry" end
    return Shop.label(product.price),"purchase"
end
return Shop
