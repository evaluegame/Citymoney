local P=require(game:GetService("ReplicatedStorage"):WaitForChild("Citymoney").Presentation)
local Tween=game:GetService("TweenService")
local Goal={}
Goal.__index=Goal
function Goal.new(ui)
 local self=setmetatable({ui=ui,ratio=nil,pending=nil},Goal)
 local C=ui.colors
 self.button=ui.button(ui.root,"",20,566,154,80,C.card,function() self:activate() end)
 self.button.Name="GoalProgress"
 self.button.Visible=false
 self.tag=ui.text(self.button,"YOUR GOAL",10,5,134,16,10,C.green,true)
 self.name=ui.text(self.button,"",10,22,134,34,14,C.ink,true)
 self.detail=ui.text(self.button,"",10,58,134,14,11,C.muted)
 self.track=ui.frame(self.button,10,73,134,3,C.paper)
 self.fill=Instance.new("Frame");self.fill.Size,self.fill.BackgroundColor3,self.fill.BorderSizePixel,self.fill.Parent=UDim2.fromScale(0,1),C.green,0,self.track
 return self
end
function Goal:activate()
 if self.pending then return end
 local data=self.ui.data()
 if not data then return end
 local me
 for _,p in ipairs(data.game.players) do if p.id==self.ui.id then me=p end end
 local current=data.game.players[data.game.turn]
 if me and me.challenge.ready and current and current.id==me.id and not data.game.challengeClaimed and not self.pending then
  if self.ui.send("Claim",nil,nil,data.game.turnCount) then self.pending=data.game.turnCount;self:render(data,self.layout,self.rosterHeight,self.walking) end
 else self.ui.openGoals() end
end
function Goal:feedback() self.pending=nil;self:render(self.ui.data(),self.layout,self.rosterHeight,self.walking) end
function Goal:render(data,layout,rosterHeight,walking)
 if not layout or not data then return end
 self.layout,self.rosterHeight,self.walking=layout,rosterHeight,walking
 local s,C=data.game,self.ui.colors
 local me
 for _,p in ipairs(s.players) do if p.id==self.ui.id then me=p end end
 self.button.Visible=s.status=="playing" and me and me.alive and not walking or false
 if not self.button.Visible then return end
 if s.challengeClaimed or self.pending~=s.turnCount then self.pending=nil end
 local goal=me.challenge
 local current=s.players[s.turn]
 local myTurn=current and current.id==me.id
 local ready=goal.ready and not s.challengeClaimed
 local cardSpace=false
 for _,kind in ipairs(self.ui.config.cardTypes) do if (me.cards[kind] or 0)<self.ui.config.cardLimit then cardSpace=true end end
 local ratio=math.clamp(goal.progress/math.max(1,goal.target),0,1)
 self.button.BackgroundColor3=ready and C.gold or C.card
 self.button.Active=workspace:GetServerTimeNow()>=(data.journeyUntil or 0) and not self.pending
 self.tag.Text=ready and (myTurn and "TAP TO CLAIM" or "REWARD READY") or "YOUR NEXT GOAL"
 self.name.Text=ready and ("Claim $"..goal.reward..(cardSpace and " + card" or "")) or goal.name
 self.detail.Text=self.pending and "CLAIMING..." or (ready and (myTurn and "You earned it!" or "Claim on your turn") or (goal.progress.." / "..goal.target.." · $"..goal.reward))
 local r=P.goal(layout,rosterHeight)
 self.button.Position,self.button.Size=UDim2.fromOffset(r[1],r[2]),UDim2.fromOffset(r[3],r[4])
 if layout.compact then
  self.tag.Position,self.tag.Size,self.tag.TextSize=UDim2.fromOffset(12,5),UDim2.fromOffset(r[3]-180,17),12
  self.name.Position,self.name.Size,self.name.TextSize=UDim2.fromOffset(12,23),UDim2.fromOffset(r[3]-180,25),17
  self.detail.Position,self.detail.Size,self.detail.TextSize=UDim2.fromOffset(r[3]-158,17),UDim2.fromOffset(146,30),16
  self.track.Position,self.track.Size=UDim2.fromOffset(12,53),UDim2.fromOffset(r[3]-24,5)
 else
  self.tag.Position,self.tag.Size,self.tag.TextSize=UDim2.fromOffset(10,5),UDim2.fromOffset(134,16),10
  self.name.Position,self.name.Size,self.name.TextSize=UDim2.fromOffset(10,22),UDim2.fromOffset(134,34),14
  self.detail.Position,self.detail.Size,self.detail.TextSize=UDim2.fromOffset(10,58),UDim2.fromOffset(134,14),11
  self.track.Position,self.track.Size=UDim2.fromOffset(10,73),UDim2.fromOffset(134,3)
 end
 if self.ratio~=ratio then
  self.ratio=ratio
  if self.ui.root:GetAttribute("ReducedMotion") then self.fill.Size=UDim2.fromScale(ratio,1)
  else Tween:Create(self.fill,TweenInfo.new(0.3,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(ratio,1)}):Play() end
 end
end
return Goal
