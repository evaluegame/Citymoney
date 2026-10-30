local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Offers=require(shared.Opportunities)
local View={}
View.__index=View
function View.new(ui)
 local self=setmetatable({ui=ui,seen=nil,pending=nil,error=nil},View)
 local C=ui.colors
 self.shade,self.card=ui.overlay(520,554)
 self.shade.Name="OpportunityOverlay"
 ui.text(self.card,"CITY OPPORTUNITY",24,17,380,24,13,C.green,true)
 self.title=ui.text(self.card,"Choose your reward.",24,51,420,40,27,C.ink,true)
 ui.button(self.card,"X",452,17,44,44,C.paper,function() if not self.pending then self.shade.Visible=false end end)
 self.description=ui.text(self.card,"",24,99,472,54,16,C.muted)
 self.choices={}
 for index=1,2 do
  local button=ui.button(self.card,"",24,170+(index-1)*145,472,132,C.paper,function() self:choose(index) end)
  local icon=ui.frame(button,16,29,66,66,index==1 and C.gold or C.green)
  local glyph=ui.text(icon,index==1 and "$" or "CARD",0,0,66,66,index==1 and 34 or 17,index==1 and C.ink or C.white,true)
  glyph.TextXAlignment=Enum.TextXAlignment.Center
  local title=ui.text(button,"",104,14,346,32,23,C.ink,true)
  local detail=ui.text(button,"",104,52,346,45,16,C.muted)
  local hint=ui.text(button,"CHOOSE THIS >",104,101,346,22,14,C.green,true)
  self.choices[index]={button=button,title=title,detail=detail,hint=hint}
 end
 self.status=ui.text(self.card,"",24,463,472,27,15,C.green,true)
 ui.text(self.card,"No cost. If time runs out, cash is chosen automatically.",24,500,472,34,14,C.muted)
 return self
end
function View:isOpen() return self.shade.Visible end
function View:valid(data)
 local s=data and data.game
 return s and s.status=="playing" and s.phase=="offer" and s.pendingOffer and s.pendingOffer.actorId==self.ui.id
end
function View:open()
 local data=self.ui.data()
 if not self:valid(data) then return end
 if workspace:GetServerTimeNow()<(data.journeyUntil or 0) then return end
 self.ui.closePanels();self.shade.Visible=true;self:render(data)
end
function View:update(data)
 if not self:valid(data) then self.seen=nil;self.pending=nil;self.shade.Visible=false;return end
 local p=data.game.pendingOffer
 local key=p.turn..":"..p.seq
 if self.seen~=key and workspace:GetServerTimeNow()>=(data.journeyUntil or 0) then
  self.seen=key;self.error=nil;self:open()
 end
 if self.shade.Visible then self:render(data) end
end
function View:choose(index)
 local data=self.ui.data()
 if self.pending or not self:valid(data) then return end
 if self.ui.send("Offer",Offers.request(data.game,index)) then self.pending=data.game.pendingOffer.seq;self.error=nil;self:render(data) end
end
function View:feedback(message)
 if self.shade.Visible then self.pending=nil;self.error=message;self:render(self.ui.data()) end
end
function View:render(data)
 if not self.shade.Visible then return end
 if not self:valid(data) then self.shade.Visible=false;self.pending=nil;return end
 local ui,C=self.ui,self.ui.colors
 local player
 for _,p in ipairs(data.game.players) do if p.id==ui.id then player=p end end
 local definition=ui.config.opportunities[data.game.pendingOffer.definition]
 self.title.Text=definition.name;self.description.Text=definition.description
 for index,row in ipairs(self.choices) do
  local reward=definition.choices[index];local allowed=Offers.available(ui.config,player,reward)
  ui.available(row.button,allowed and not self.pending,C.paper)
  row.title.Text,row.detail.Text=reward.label,reward.detail
  row.hint.Text=allowed and "CHOOSE THIS >" or "HAND FULL · TAKE CASH INSTEAD"
  row.hint.TextColor3=allowed and C.green or C.red
 end
 local seconds=math.max(0,math.ceil(data.deadline-workspace:GetServerTimeNow()))
 self.status.Text=self.error or (self.pending and "Confirming your reward..." or ("Your choice · "..seconds.." seconds left"))
 self.status.TextColor3=self.error and C.red or C.green
end
return View
