--!nocheck
-- Headless GUI integration adapter. It cannot replace Roblox rendering/playtests.
return function(sources,width,height)
    local requests,scheduled={}, {}
    local now=100
    local function signal()
        local s={callbacks={}}
        function s:Connect(callback) table.insert(self.callbacks,callback);return {Disconnect=function() end} end
        function s:Fire(...) for _,callback in ipairs(table.clone(self.callbacks)) do callback(...) end end
        function s:Wait() return 0.016 end
        return s
    end
    local function vector(x,y,z)
        local v={X=x or 0,Y=y or 0,Z=z or 0}
        return setmetatable(v,{
            __add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end,
            __sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end,
            __mul=function(a,b) if type(a)=="number" then a,b=b,a end;return vector(a.X*b,a.Y*b,a.Z*b) end,
            __div=function(a,b) return vector(a.X/b,a.Y/b,a.Z/b) end,
            __index=function(a,key)
                if key=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
                if key=="Unit" then return a/a.Magnitude end
                if key=="Lerp" then return function(self,b,t) return self+(b-self)*t end end
                return nil
            end,
        })
    end
    local function dim(s,o) return {Scale=s or 0,Offset=o or 0} end
    local function dimensions(xs,xo,ys,yo)
        return setmetatable({X=dim(xs,xo),Y=dim(ys,yo)},{__add=function(a,b) return dimensions(a.X.Scale+b.X.Scale,a.X.Offset+b.X.Offset,a.Y.Scale+b.Y.Scale,a.Y.Offset+b.Y.Offset) end})
    end
    local function color(r,g,b) return {R=r or 0,G=g or 0,B=b or 0} end
    local color3={new=color,fromRGB=function(r,g,b) return color(r/255,g/255,b/255) end,fromHex=function(hex) return color(tonumber(string.sub(hex,1,2),16)/255,tonumber(string.sub(hex,3,4),16)/255,tonumber(string.sub(hex,5,6),16)/255) end}
    local cfMethods={}
    local function cf(x,y,z) return setmetatable({Position=type(x)=="table" and x or vector(x,y,z)}, {__index=cfMethods,__mul=function(a,b) return cf(a.Position+b.Position) end}) end
    function cfMethods:Lerp(b,t) return cf(self.Position:Lerp(b.Position,t)) end
    function cfMethods:VectorToObjectSpace(v) return v end
    function cfMethods:ToObjectSpace(b) return cf(b.Position-self.Position) end
    local cfApi={new=cf,Angles=function() return cf(0,0,0) end,lookAt=function(p) return cf(p) end,fromMatrix=function(p) return cf(p) end}
    local enum=setmetatable({},{__index=function(a,key)
        local value=setmetatable({},{__index=function(t,name) local item={Name=name};rawset(t,name,item);return item end});rawset(a,key,value);return value
    end})
    local methods={}
    local pointer={Target=nil}
    local guiClasses={Frame=true,TextLabel=true,TextButton=true,ImageLabel=true,ImageButton=true,ScrollingFrame=true,ViewportFrame=true}
    local signals={Activated=true,MouseEnter=true,MouseLeave=true,MouseButton1Down=true,MouseButton1Up=true,DescendantAdded=true,RenderStepped=true,InputBegan=true,InputChanged=true,TouchTapInWorld=true,OnClientEvent=true,PromptGamePassPurchaseFinished=true}
    local absolute
    local creationOrder=0
    local function node(class,name)
        creationOrder=creationOrder+1
        local object={_props={ClassName=class,Name=name or class,Size=dimensions(0,100,0,100),Position=dimensions(0,0,0,0),AnchorPoint=vector(),Visible=true,Enabled=true,Active=true,ZIndex=1,BackgroundTransparency=0,Text="",TextSize=14,Font=enum.Font.Gotham,TextColor3=color(0,0,0),BackgroundColor3=color(1,1,1)},_children={},_signals={},_attrs={}}
        object._props.TextXAlignment=class=="TextButton" and enum.TextXAlignment.Center or enum.TextXAlignment.Left
        object._props.creationOrder=creationOrder
        return setmetatable(object,{
            __index=function(self,key)
                if methods[key] then return methods[key] end
                if key=="AbsoluteSize" then local _,size=absolute(self);return size end
                if key=="AbsolutePosition" then local pos=absolute(self);return pos end
                if signals[key] then if not self._signals[key] then self._signals[key]=signal() end;return self._signals[key] end
                if self._props[key]~=nil then return self._props[key] end
                for _,child in ipairs(self._children) do if child.Name==key then return child end end
                return nil
            end,
            __newindex=function(self,key,value)
                if key=="Parent" then
                    local old=self._props.Parent
                    if old then local i=table.find(old._children,self);if i then table.remove(old._children,i) end end
                    self._props.Parent=value
                    if value then
                        table.insert(value._children,self)
                        local ancestor=value
                        while ancestor do if ancestor._signals.DescendantAdded then ancestor._signals.DescendantAdded:Fire(self) end;ancestor=ancestor.Parent end
                    end
                else self._props[key]=value end
            end,
        })
    end
    function methods:GetChildren() return table.clone(self._children) end
    function methods:GetDescendants() local all={};for _,c in ipairs(self._children) do table.insert(all,c);for _,child in ipairs(c:GetDescendants()) do table.insert(all,child) end end;return all end
    function methods:FindFirstChild(name,recurse) for _,c in ipairs(self._children) do if c.Name==name then return c end end;if recurse then for _,c in ipairs(self._children) do local got=c:FindFirstChild(name,true);if got then return got end end end;return nil end
    function methods:WaitForChild(name) return assert(self:FindFirstChild(name),"Missing child "..name.." under "..self.Name) end
    function methods:FindFirstChildOfClass(class) for _,c in ipairs(self._children) do if c.ClassName==class then return c end end;return nil end
    function methods:IsA(class) return self.ClassName==class or class=="GuiObject" and guiClasses[self.ClassName] or class=="BasePart" and self.ClassName=="Part" end
    function methods:Destroy() self.Parent=nil;self._props.Visible=false;self:ClearAllChildren() end
    function methods:ClearAllChildren() for _,c in ipairs(self:GetChildren()) do c:Destroy() end end
    function methods:SetAttribute(key,value) self._attrs[key]=value end
    function methods:GetAttribute(key) return self._attrs[key] end
    function methods:GetPropertyChangedSignal(key) self._signals[key]=self._signals[key] or signal();return self._signals[key] end
    function methods:GetBoundingBox() return cf(0,10,0),vector(20,20,20) end
    function methods:GetServerTimeNow() return now end
    function methods:GetMouse() return pointer end
    function methods:FireServer(...) table.insert(requests,{...}) end
    function methods:ScreenPointToRay(x,y) local t=math.tan(math.rad(36)/2);return {Origin=vector(),Direction=vector((2*x/width-1)*t*width/height,(1-2*y/height)*t,-1).Unit} end
    function methods:SetCoreGuiEnabled() end
    absolute=function(object)
        if object.ClassName=="ScreenGui" or not object.Parent then return vector(),vector(width,height,0),1 end
        local parentPos,parentSize,parentScale=absolute(object.Parent)
        local own=object:FindFirstChildOfClass("UIScale");local ownScale=own and own.Scale or 1
        local size=vector((parentSize.X*object.Size.X.Scale+object.Size.X.Offset*parentScale)*ownScale,(parentSize.Y*object.Size.Y.Scale+object.Size.Y.Offset*parentScale)*ownScale)
        local pos=vector(parentPos.X+parentSize.X*object.Position.X.Scale+object.Position.X.Offset*parentScale-size.X*object.AnchorPoint.X,parentPos.Y+parentSize.Y*object.Position.Y.Scale+object.Position.Y.Offset*parentScale-size.Y*object.AnchorPoint.Y)
        return pos,size,parentScale*ownScale
    end
    local services={}
    for _,name in ipairs({"Players","ReplicatedStorage","RunService","UserInputService","Lighting","StarterGui","TweenService","SocialService","HttpService","MarketplaceService"}) do services[name]=node("Service",name) end
    function services.TweenService:Create(object,_info,properties) return {Play=function() for key,value in pairs(properties) do object[key]=value end end} end
    function services.RunService:IsStudio() return true end
    local game={PlaceId=0,JobId="mock",GetService=function(_,name) return assert(services[name],name) end}
    local player=node("Player","Avery");player.UserId=1;player.DisplayName="Avery";services.Players.LocalPlayer=player
    local playerGui=node("PlayerGui","PlayerGui");playerGui.Parent=player
    local shared=node("Folder","Citymoney");shared.Parent=services.ReplicatedStorage
    local main=node("LocalScript","CitymoneyClient")
    for path in pairs(sources) do
        if path~="src/client/init.client.lua" then
            local m=node("ModuleScript",string.match(path,"([^/]+)%.lua$"));m._props.source=path
            m.Parent=string.find(path,"src/shared/",1,true) and shared or main
        end
    end
    local remotes=node("Folder","Remotes");remotes.Parent=shared
    for _,name in ipairs({"Action","Snapshot","Feedback"}) do local remote=node("RemoteEvent",name);remote.Parent=remotes end
    local workspace=node("Workspace","Workspace");workspace.CurrentCamera=node("Camera","Camera");workspace.CurrentCamera.ViewportSize=vector(width,height);workspace.CurrentCamera.CFrame=cf()
    local board=node("Folder","CitymoneyBoard");board.Parent=workspace
    local env={game=game,workspace=workspace,Instance={new=node},Enum=enum,Vector2={new=vector,zero=vector()},Vector3={new=vector,zero=vector()},
        Color3=color3,CFrame=cfApi,UDim={new=dim},UDim2={new=dimensions,fromOffset=function(x,y) return dimensions(0,x,0,y) end,fromScale=function(x,y) return dimensions(x,0,y,0) end},
        TweenInfo={new=function(...) return {...} end},task={spawn=function(callback) table.insert(scheduled,{at=math.huge,callback=callback}) end,delay=function(time,callback) table.insert(scheduled,{at=now+time,callback=callback}) end,wait=function() return 0.016 end}}
    local cache={}
    local function load(module)
        if cache[module] then return cache[module] end
        local source=assert(sources[module.source or "src/client/init.client.lua"])
        local scope=setmetatable({script=module},{__index=env})
        local fn=assert(loadstring(source,"@"..(module.source or "client")));setfenv(fn,scope)
        local value=fn();cache[module]=value;return value
    end
    setmetatable(env,{__index=getfenv()});env.require=load
    load(main)
    local Engine=load(shared.Engine);local Config=load(shared.Config)
    local engine=Engine.new(Config)
    local roster={{id=1,name="Avery"},{id=2,name="Riley"},{id=3,name="Jamie"},{id=4,name="Morgan"}}
    assert(engine:start(roster))
    for _,asset in ipairs({{2,1,0},{8,2,1},{14,3,2},{23,4,3}}) do local p=engine.state.properties[asset[1]];p.ownerId,p.level=asset[2],asset[3] end
    local members={};for i,p in ipairs(roster) do table.insert(members,{id=p.id,name=p.name,colorIndex=i,ready=true}) end
    local data={game=engine:view(1),lobby=members,hostId=1,lobbyConfig={seats=4,fillBots=true,attackMode="destroy"},
        matchmaking={mode="lobby",queued=false,status="Studio local matchmaking",studio=true},club={styleId="classic",ownsPass=false,loading=false,studio=true,passId=0,effects=true,status=""},
        styles={},deadline=155,handoffAt=0,serverTime=100,revision=1,visitors={}}
    remotes.Snapshot.OnClientEvent:Fire(data)
    services.RunService.RenderStepped:Fire(0.016)
    local gui=playerGui:WaitForChild("Citymoney");local root=gui:WaitForChild("Frame"):WaitForChild("CityRoot")
    local function visible(o) while o do if o.Visible==false or o.Enabled==false then return false end;o=o.Parent end;return true end
    local function findText(text)
        for _,object in ipairs(gui:GetDescendants()) do if object.Text==text and visible(object) then return object end end
        error("Missing visible text: "..text)
    end
    local function inside(o)
        local p,s=absolute(o)
        assert(p.X>=-0.1 and p.Y>=-0.1 and p.X+s.X<=width+0.1 and p.Y+s.Y<=height+0.1,"Cropped "..o.Name)
    end
    for _,name in ipairs({"Header","TurnDock","CityMenuButton","CameraDock"}) do inside(root:WaitForChild(name)) end
    local permanent=0
    for _,child in ipairs(root:GetChildren()) do if child.ClassName=="TextButton" and visible(child) then permanent=permanent+1 end end
    assert(permanent==1,"Main screen should have one menu launcher")
    findText("ROLL DICE").Activated:Fire();assert(requests[#requests][1]=="Roll","Roll button did not send a roll")
    local target=node("Part","Tile2");target.Parent=board;target:SetAttribute("TileIndex",2);pointer.Target=target
    services.UserInputService.InputChanged:Fire({UserInputType=enum.UserInputType.MouseMovement,Position=vector(width*0.76,height*0.69)},false)
    services.RunService.RenderStepped:Fire(0.016)
    assert(root:FindFirstChild("PropertyHover").Visible,"Property hover did not appear")
    inside(root:FindFirstChild("PropertyHover"))
    local elements={}
    local function hex(c) return string.format("%02x%02x%02x",math.floor(c.R*255+0.5),math.floor(c.G*255+0.5),math.floor(c.B*255+0.5)) end
    local function export(parent)
        local children=parent:GetChildren();table.sort(children,function(a,b) if a.ZIndex==b.ZIndex then return a.creationOrder<b.creationOrder end;return (a.ZIndex or 1)<(b.ZIndex or 1) end)
        for _,o in ipairs(children) do if visible(o) then
            if guiClasses[o.ClassName] then
                local p,s,scale=absolute(o);local corner=o:FindFirstChildOfClass("UICorner")
                local stroke=o:FindFirstChildOfClass("UIStroke")
                table.insert(elements,{class=o.ClassName,name=o.Name,x=p.X,y=p.Y,w=s.X,h=s.Y,text=o.Text or "",size=(o.TextSize or 14)*scale,bg=hex(o.BackgroundColor3),fg=hex(o.TextColor3),alpha=1-(o.BackgroundTransparency or 0),font=o.Font and o.Font.Name or "Gotham",wrap=o.TextWrapped==true,align=o.TextXAlignment and o.TextXAlignment.Name or "Left",corner=corner and (corner.CornerRadius.Scale*math.min(s.X,s.Y)+corner.CornerRadius.Offset*scale) or 0,
                    stroke=stroke and {color=hex(stroke.Color or color(0.8,0.85,0.9)),alpha=1-(stroke.Transparency or 0),width=(stroke.Thickness or 1)*scale} or false})
            end
            export(o)
        end end
    end
    export(gui)
    local function menu(label)
        root.CityMenuButton.Activated:Fire()
        services.RunService.RenderStepped:Fire(0.016)
        local item=findText(label);item.Parent.Activated:Fire()
        services.RunService.RenderStepped:Fire(0.016)
    end
    menu("CARDS & GOALS");findText("Cards & challenges")
    findText("×").Activated:Fire()
    menu("CITY EVENTS");findText("Something is happening.")
    findText("Back").Activated:Fire()
    menu("YOUR PROPERTIES");findText("Your collection")
    local property=findText("Copper Lane");property.Parent.Activated:Fire()
    services.RunService.RenderStepped:Fire(0.016)
    assert(root:FindFirstChild("PropertyHover").Visible==false)
    local P=load(shared.Presentation);local Fit=load(shared.BoardCamera)
    local layout=P.layout(width,height);local r=P.board(layout,false)
    local camera=Fit.fit(width,height,{r[1]*layout.scale,r[2]*layout.scale,r[3]*layout.scale,r[4]*layout.scale},P.defaultYaw,P.defaultElevation,1,Fit.cityBounds(Config,load(shared.Architecture),engine.state))
    return {width=width,height=height,elements=elements,camera=camera,requests=#requests,checks=8}
end
