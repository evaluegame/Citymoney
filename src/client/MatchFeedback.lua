local shared=game:GetService("ReplicatedStorage"):WaitForChild("Citymoney")
local Layout=require(shared.Layout)
local Motion=require(script.Parent.Motion)
local Feedback={}
Feedback.__index=Feedback
local function resident(state,id)
 for _,p in ipairs(state.players) do if p.id==id then return p end end
 return nil
end
function Feedback.new(ui)
 local self=setmetatable({ui=ui,untilTime=0,journey=nil},Feedback)
 local C=ui.colors
 self.card=ui.frame(ui.root,300,92,480,100,C.card)
 self.card.Name,self.card.ZIndex,self.card.Visible="MatchMoment",14,false
 self.icon=ui.frame(self.card,14,18,64,64,C.green)
 self.badge=ui.text(self.icon,"GO!",0,0,64,64,25,C.white,true);self.badge.TextXAlignment=Enum.TextXAlignment.Center
 self.title=ui.text(self.card,"",94,14,370,30,22,C.ink,true)
 self.detail=ui.text(self.card,"",94,48,370,40,14,C.muted)
 for _,object in ipairs(self.card:GetDescendants()) do if object:IsA("GuiObject") then object.ZIndex=15 end end
 return self
end
function Feedback:show(title,detail,badge,tint,seconds,celebrate)
 self.ui.hideToast()
 self.title.Text,self.detail.Text,self.badge.Text=title,detail,badge
 self.icon.BackgroundColor3=tint or self.ui.colors.green
 self.badge.TextSize=#badge<=2 and 30 or 17
 self.untilTime=workspace:GetServerTimeNow()+(seconds or 3)
 self.card.Visible=true
 if self.animation then self.animation:Cancel() end
 if self.basePosition then self.card.Position=self.basePosition end
 self.animation=Motion.pop(self.card,self.ui.root)
 if celebrate then Motion.burst(self.card,self.ui.root,self.icon.BackgroundColor3) end
end
function Feedback:hide()
 self.untilTime=0;self.card.Visible=false
end
function Feedback:observe(data,old)
 local state=data.game
 if state.status~="playing" then self.journey=nil;self.card.Visible=false;self.untilTime=0;return end
 if not old or old.game.status~="playing" then
  self.journey=nil
  if old then self:show("YOUR CITY STARTS HERE","Roll, build homes, and outsmart the table.","GO!",self.ui.colors.green,2.5) end
  return
 end
 local roll=state.lastRoll
 if roll and roll.seq>(old.game.lastRoll and old.game.lastRoll.seq or 0) then
  self.journey={turn=roll.turn,roll=roll,state=state,untilTime=data.journeyUntil or workspace:GetServerTimeNow()}
  -- The HUD presents the dice phases. Keep the route and walking residents
  -- clear instead of covering the top of the board with a large roll banner.
  self.ui.hideToast()
  self:hide()
 end
 local action=state.lastAction
 if action and action.seq>(old.game.lastAction and old.game.lastAction.seq or 0) then
  local actor=resident(state,action.actorId)
  local name=self.ui.config.tiles[action.tile].name
  local titles={demolish=action.blocked and "SHIELD SAVED THE HOUSE!" or "DEMOLITION!",repair=(action.amount or 0)>0 and "HOME UPGRADED!" or "FREE HOME UPGRADE!",boost="RENT BOOST ACTIVATED",shield="HOME PROTECTED",collect="RENT DEMAND!"}
  local title=titles[action.kind]
  local detail=(actor and actor.name or "A resident").." · "..name
  if action.kind=="collect" then detail=(actor and actor.name or "A resident").." collected $"..action.amount.." using "..name.."." end
  if title then self:show(title,detail,"CARD",self.ui.colors.green,3,action.kind~="demolish") end
 end
 local opportunity=state.lastOpportunity
 if opportunity and opportunity.seq>(old.game.lastOpportunity and old.game.lastOpportunity.seq or 0) then
  local actor=resident(state,opportunity.actorId)
  self:show("CITY REWARD!",(actor and actor.name or "A resident").." chose "..opportunity.reward..".",opportunity.card and "CARD" or "+$",self.ui.colors.green,3,true)
 end
 local me,before=resident(state,self.ui.id),resident(old.game,self.ui.id)
 if me and before and me.completedChallenges>before.completedChallenges then
  local cardAdded=false
  for kind,count in pairs(me.cards) do if count>(before.cards[kind] or 0) then cardAdded=true end end
  self:show("GOAL COMPLETE!","+$"..before.challenge.reward..(cardAdded and " and a card." or ".").." Your next goal is ready.","WIN",self.ui.colors.green,3.5,true)
 end
end
function Feedback:landing(journey)
 local s,roll,config=journey.state,journey.roll,self.ui.config
 local actor=resident(s,roll.actorId)
 local tile=config.tiles[roll.landedTile or actor.position]
 local title,badge="CITY NEWS","NEWS"
 if not actor.alive then title,badge="OUT OF CASH","CITY"
 elseif tile.kind=="property" then
  local p=s.properties[roll.landedTile or actor.position]
  title,badge=not p.ownerId and "YOUR NEXT HOME?" or (p.ownerId==actor.id and "WELCOME HOME!" or "RENT PAID"),"HOME"
 elseif tile.kind=="start" then title,badge="PAYDAY AT CITY GATE!","+$"
 elseif tile.kind=="park" then title,badge="A CARD FOR YOUR NEXT MOVE","CARD"
 elseif tile.kind=="tax" then title,badge="CITY TAX","TAX"
 elseif tile.kind=="detention" then title,badge="A DETOUR TO DETENTION","CITY"
 elseif tile.kind=="visit" then title,badge="JUST VISITING","CITY"
 elseif s.pendingOffer then title,badge="CHOOSE YOUR REWARD!","PICK" end
 self:show(title,roll.summary or tile.name,badge,Color3.fromHex(config.playerColors[actor.colorIndex]),3.5,tile.kind=="start" or tile.kind=="park")
end
function Feedback:update(data,layout,blocked)
 if not layout then return end
 if self.journey and data.game.lastRoll and data.game.lastRoll.seq==self.journey.roll.seq and data.game.turnCount==self.journey.turn then
  self.journey.untilTime=data.journeyUntil or self.journey.untilTime
 end
 if self.journey and workspace:GetServerTimeNow()>=self.journey.untilTime then
  local journey=self.journey;self.journey=nil
  if data.game.status=="playing" and data.game.turnCount==journey.turn then self:landing(journey) end
 end
 local rect=Layout.board(layout,false)
 local width=math.min(480,rect[3]-24)
 local key=rect[1]..":"..rect[2]..":"..width
 if self.layoutKey~=key then
  self.layoutKey=key
  if self.animation then self.animation:Cancel();self.animation=nil end
  self.card.Position,self.card.Size=UDim2.fromOffset(rect[1]+(rect[3]-width)/2,rect[2]+8),UDim2.fromOffset(width,100)
  self.basePosition=self.card.Position
 end
 self.title.Size,self.detail.Size=UDim2.fromOffset(width-110,30),UDim2.fromOffset(width-110,40)
 self.card.Visible=not blocked and workspace:GetServerTimeNow()<self.untilTime and data.game.status=="playing"
end
return Feedback
