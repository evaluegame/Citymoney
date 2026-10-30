local Command={}
Command.__index=Command
function Command.new(ui)
    local self=setmetatable({ui=ui},Command)
    local C=ui.colors
    self.button=ui.button(ui.root,"MENU",20,620,154,46,C.card,function() self.shade.Visible=not self.shade.Visible end)
    self.button.Name="CityMenuButton"
    self.shade,self.card=ui.overlay(490,498)
    ui.text(self.card,"YOUR CITY",24,19,400,20,10,C.green,true)
    ui.text(self.card,"What is your next move?",24,46,420,40,25,C.ink,true)
    ui.button(self.card,"DAY / NIGHT",300,18,126,26,C.paper,function() self.shade.Visible=false;ui.switchLight() end).TextSize=10
    ui.button(self.card,"X",438,20,28,28,C.paper,function() self.shade.Visible=false end)
    local commands={
        {"PLAY TOGETHER","2 / 4 players, friends & practice","01",function() ui.openMatch() end},
        {"CARDS & GOALS","Your hand and challenges","02",function() ui.openGoals() end},
        {"CITY EVENTS","Market, festivals and news","03",function() ui.openCity() end},
        {"YOUR PROPERTIES","Inspect, upgrade and visit","04",function() ui.openHomes() end},
        {"STYLE STUDIO","Preview your Club collection","05",function() ui.openStyles() end},
        {"HOW TO PLAY","Rules and controls","06",function() ui.openHelp() end},
    }
    for index,item in ipairs(commands) do
        local x,y=24+((index-1)%2)*225,110+math.floor((index-1)/2)*108
        local tile=ui.button(self.card,"",x,y,217,96,C.paper,function() self.shade.Visible=false;item[4]() end)
        ui.text(tile,item[3],14,10,180,24,20,C.green,true)
        ui.text(tile,item[1],14,40,190,20,12,C.ink,true)
        ui.text(tile,item[2],14,65,190,19,10,C.muted)
    end
    ui.text(self.card,"Tip: finish your upgrades and city business before rolling.",24,448,442,30,12,C.muted)
    return self
end
function Command:isOpen() return self.shade.Visible end
function Command:resize(layout)
    local r=layout.menu
    self.button.Position,self.button.Size=UDim2.fromOffset(r[1],r[2]),UDim2.fromOffset(r[3],r[4])
end
return Command
