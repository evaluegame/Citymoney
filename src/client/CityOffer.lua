local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Offers=require(shared.Opportunities)
local View={}
View.__index=View
function View.new(ui)
 local self=setmetatable({ui=ui,seen=nil,pending=nil,error=nil},View)
 local C=ui.colors
 self.shade,self.card=ui.overlay(520,554)
 self.shade.Name="OpportunityOverlay"
 self.header=ui.text(self.card,"CITY OPPORTUNITY",24,17,380,24,13,C.green,true)
 self.title=ui.text(self.card,"Choose your reward.",24,51,420,40,27,C.ink,true)
 ui.button(self.card,"X",452,17,44,44,C.paper,function() if not self.pending then self.shade.Visible=false end end)
 self.description=ui.text(self.card,"",24,99,472,54,16,C.muted)
 self.choices={}
 for index=1,3 do
  local button=ui.button(self.card,"",24,170+(index-1)*145,472,132,C.paper,function() self:choose(index) end)
  local icon=ui.frame(button,16,29,66,66,index==1 and C.gold or C.green)
  local glyph=ui.text(icon,index==1 and "$" or "CARD",0,0,66,66,index==1 and 34 or 17,index==1 and C.ink or C.white,true)
  glyph.TextXAlignment=Enum.TextXAlignment.Center
  local title=ui.text(button,"",104,14,346,32,23,C.ink,true)
  local detail=ui.text(button,"",104,52,346,45,16,C.muted)
  local hint=ui.text(button,"CHOOSE THIS >",104,101,346,22,14,C.green,true)
  self.choices[index]={button=button,title=title,detail=detail,hint=hint,icon=icon,glyph=glyph}
 end
 self.status=ui.text(self.card,"",24,463,472,27,15,C.green,true)
 self.note=ui.text(self.card,"No cost. If time runs out, cash is chosen automatically.",24,500,472,34,14,C.muted)
 self.skip=ui.button(self.card,"CONTINUE WITHOUT CARD",284,500,212,44,C.paper,function() self:choose(0) end)
 self.skip.Name="SkipCardReward";self.skip.TextSize=12;self.skip.Visible=false
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
 local definition=Offers.definition(ui.config,data.game)
 local cardSpace=data.game.pendingOffer.kind=="cardSpace"
 local extra=math.max(0,#definition.choices-2)*145
 self.card.Size=UDim2.fromOffset(520,554+extra)
 self.header.Text=cardSpace and "FREE CARD SPACE" or "CITY OPPORTUNITY"
 self.status.Position=UDim2.fromOffset(24,463+extra)
 self.note.Position,self.note.Size=UDim2.fromOffset(24,500+extra),UDim2.fromOffset(cardSpace and 250 or 472,34)
 self.note.Text=cardSpace and "Free card. On timeout, an available card is collected automatically." or "No cost. If time runs out, cash is chosen automatically."
 self.note.TextSize=cardSpace and 12 or 14
 self.skip.Position,self.skip.Visible=UDim2.fromOffset(284,500+extra),cardSpace
 ui.available(self.skip,not self.pending,C.paper)
 self.title.Text=definition.name;self.description.Text=definition.description
 for index,row in ipairs(self.choices) do
  local reward=definition.choices[index]
  row.button.Visible=reward~=nil
  if reward then
   local allowed=Offers.available(ui.config,player,reward)
   ui.available(row.button,allowed and not self.pending,C.paper)
   row.title.Text,row.detail.Text=reward.label,reward.detail
   row.glyph.Text=cardSpace and "FREE" or (index==1 and "$" or "CARD")
   row.glyph.TextSize=cardSpace and 17 or (index==1 and 34 or 17)
   row.hint.Text=allowed and (cardSpace and "COLLECT CARD >" or "CHOOSE THIS >") or (cardSpace and "HAND FULL · CHOOSE ANOTHER OR CONTINUE" or "HAND FULL · TAKE CASH INSTEAD")
   row.hint.TextSize=cardSpace and 11 or 14
   row.hint.TextColor3=allowed and C.green or C.red
  end
 end
 local seconds=math.max(0,math.ceil(data.deadline-workspace:GetServerTimeNow()))
 self.status.Text=self.error or (self.pending and "Confirming your reward..." or ("Your choice · "..seconds.." seconds left"))
 self.status.TextColor3=self.error and C.red or C.green
end
return View
