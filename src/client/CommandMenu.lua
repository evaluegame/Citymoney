local P=require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").Presentation)
local Command={}
Command.__index=Command
function Command.new(ui)
    local self=setmetatable({ui=ui},Command)
    local C=ui.colors
    self.button=ui.button(ui.root,"MENU",20,620,154,46,C.card,function() self.shade.Visible=not self.shade.Visible end)
    self.button.Name="CityMenuButton"
    self.shade,self.card=ui.overlay(490,510)
    ui.text(self.card,"CITYMONEY",24,19,260,20,12,C.green,true)
    ui.text(self.card,"Everything in one place.",24,46,420,40,26,C.ink,true)
    ui.button(self.card,"DAY / NIGHT",300,18,126,26,C.paper,function() self.shade.Visible=false;ui.switchLight() end).TextSize=10
    ui.button(self.card,"X",438,20,32,44,C.paper,function() self.shade.Visible=false end)
    local commands={
        {"PLAY TOGETHER","Online, friends or practice",function() ui.openMatch() end},
        {"CARDS & GOALS","Play a card or claim a reward",function() ui.openGoals() end},
        {"CITY EVENTS","Festival, market and news",function() ui.openCity() end},
        {"YOUR PROPERTIES","Upgrade, set rent or visit",function() ui.openHomes() end},
        {"STYLE STUDIO","House and dice cosmetics",function() ui.openStyles() end},
        {"HOW TO PLAY","Learn the three easy steps",function() ui.openHelp() end},
    }
    for index,item in ipairs(commands) do
        local x,y=24+((index-1)%2)*225,110+math.floor((index-1)/2)*112
        local tile=ui.button(self.card,"",x,y,217,100,C.paper,function() self.shade.Visible=false;item[3]() end)
        ui.frame(tile,14,14,30,5,index==3 and C.gold or C.green)
        ui.text(tile,item[1],14,31,190,26,16,C.ink,true)
        ui.text(tile,item[2],14,62,190,29,13,C.muted)
    end
    ui.text(self.card,"Turns move on automatically. Just roll, choose, and play.",24,456,442,30,13,C.muted)
    self.quick=ui.frame(ui.root,20,410,154,144,C.card)
    self.quick.Name="QuickActions"
    self.events=ui.button(self.quick,"EVENTS",8,8,138,40,C.green,function() ui.openCity() end)
    self.events.Name="OpenEvents"
    self.cards=ui.button(self.quick,"CARDS & GOALS",8,56,138,36,C.paper,function() ui.openGoals() end)
    self.cards.Name="OpenCards"
    self.homes=ui.button(self.quick,"MY HOMES",8,100,138,36,C.paper,function() ui.openHomes() end)
    self.homes.Name="OpenHomes"
    return self
end
function Command:isOpen() return self.shade.Visible end
function Command:resize(layout,rosterHeight)
    local r=layout.menu
    self.button.Position,self.button.Size=UDim2.fromOffset(r[1],r[2]),UDim2.fromOffset(r[3],r[4])
    local q=P.shortcuts(layout,rosterHeight)
    self.quick.Position,self.quick.Size=UDim2.fromOffset(q[1],q[2]),UDim2.fromOffset(q[3],q[4])
    local buttons={self.events,self.cards,self.homes}
    for i,button in ipairs(buttons) do
        if layout.compact then
            local w=(q[3]-16)/3
            button.Position,button.Size=UDim2.fromOffset((i-1)*(w+8),0),UDim2.fromOffset(w,64)
            button.TextSize=17
        else
            button.Position,button.Size=UDim2.fromOffset(8,8+(i-1)*44),UDim2.fromOffset(138,40)
            button.TextSize=14
        end
    end
end
return Command
