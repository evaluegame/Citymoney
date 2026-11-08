--!nocheck
-- Headless GUI integration adapter. It cannot replace Roblox rendering/playtests.
return function(sources,width,height,localeId)
    local Language=require('../src/shared/Language')
    localeId=localeId or 'th-th'
    local expected=Language.new(localeId)
    local function t(value) return expected:text(value) end
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
    local function cf(x,y,z,...) return setmetatable({Position=type(x)=="table" and x or vector(x,y,z),rotation=select('#',...)==9 and {...} or nil}, {__index=cfMethods,__mul=function(a,b) return cf(a.Position+b.Position) end}) end
    function cfMethods:Lerp(b,t)
        local result=cf(self.Position:Lerp(b.Position,t))
        for _,axis in ipairs({"right","up","back"}) do result[axis]=self[axis] and b[axis] and self[axis]:Lerp(b[axis],t).Unit or b[axis] end
        return result
    end
    function cfMethods:VectorToObjectSpace(v)
        if not self.right then return v end
        local function dot(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
        return vector(dot(v,self.right),dot(v,self.up),dot(v,self.back))
    end
    function cfMethods:VectorToWorldSpace(v) return self.right and self.right*v.X+self.up*v.Y+self.back*v.Z or v end
    function cfMethods:ToObjectSpace(b) return cf(b.Position-self.Position) end
    local cfApi={new=cf,Angles=function() return cf(0,0,0) end,lookAt=function(p,target)
        local back=(p-target).Unit;local right=vector(back.Z,0,-back.X).Unit
        local up=vector(back.Y*right.Z-back.Z*right.Y,back.Z*right.X-back.X*right.Z,back.X*right.Y-back.Y*right.X)
        local result=cf(p);result.right,result.up,result.back=right,up,back;return result
    end,fromMatrix=function(p,r,u,b) local result=cf(p);result.right,result.up,result.back=r,u,b;return result end}
    local enum=setmetatable({},{__index=function(a,key)
                local value=setmetatable({},{__index=function(t,name) local item={Name=name,Value=key=="RenderPriority" and name=="Camera" and 200 or 0};rawset(t,name,item);return item end});rawset(a,key,value);return value
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
        object._props.ClipsDescendants=class=="ScrollingFrame"
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
                        local added={self};for _,child in ipairs(self:GetDescendants()) do table.insert(added,child) end
                        local ancestor=value
                        while ancestor do
                            if ancestor._signals.DescendantAdded then for _,child in ipairs(added) do ancestor._signals.DescendantAdded:Fire(child) end end
                            ancestor=ancestor.Parent
                        end
                    end
                else
                    local old=self._props[key];self._props[key]=value
                    if old~=value and self._signals[key] then self._signals[key]:Fire() end
                end
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
    function methods:SetAttribute(key,value)
        local old=self._attrs[key];self._attrs[key]=value
        if old~=value and self._signals['attribute:'..key] then self._signals['attribute:'..key]:Fire() end
    end
    function methods:GetAttribute(key) return self._attrs[key] end
    function methods:GetAttributeChangedSignal(key) return self:GetPropertyChangedSignal('attribute:'..key) end
    function methods:GetPropertyChangedSignal(key) self._signals[key]=self._signals[key] or signal();return self._signals[key] end
    function methods:GetBoundingBox()
        local lo,hi=vector(math.huge,math.huge,math.huge),vector(-math.huge,-math.huge,-math.huge)
        local count=0
        for _,part in ipairs(self:GetDescendants()) do if part:IsA("BasePart") and part.CFrame then
            local p,s=part.CFrame.Position,part.Size;count=count+1
            lo=vector(math.min(lo.X,p.X-s.X/2),math.min(lo.Y,p.Y-s.Y/2),math.min(lo.Z,p.Z-s.Z/2))
            hi=vector(math.max(hi.X,p.X+s.X/2),math.max(hi.Y,p.Y+s.Y/2),math.max(hi.Z,p.Z+s.Z/2))
        end end
        if count==0 then return cf(0,10,0),vector(20,20,20) end
        return cf((lo+hi)/2),hi-lo
    end
    function methods:GetServerTimeNow() return now end
    function methods:GetMouse() return pointer end
    function methods:FireServer(...) table.insert(requests,{...}) end
    function methods:ScreenPointToRay(x,y) local t=math.tan(math.rad(self.FieldOfView or 36)/2);return {Origin=self.CFrame.Position,Direction=self.CFrame:VectorToWorldSpace(vector((2*x/width-1)*t*width/height,(1-2*y/height)*t,-1)).Unit} end
    function methods:WorldToScreenPoint(point)
        local p=self.CFrame:VectorToObjectSpace(point-self.CFrame.Position)
        local depth=-p.Z;local t=math.tan(math.rad(self.FieldOfView or 36)/2)
        local screen=vector((p.X/(depth*t*width/height)+1)*width/2,(1-p.Y/(depth*t))*height/2,depth)
        return screen,depth>0 and screen.X>=0 and screen.X<=width and screen.Y>=0 and screen.Y<=height
    end
    function methods:SetCoreGuiEnabled() end
    function methods:Raycast() return pointer.Target and {Instance=pointer.Target} end
    absolute=function(object)
        if object.ClassName=="ScreenGui" or not object.Parent then return vector(),vector(width,height,0),1 end
        local parentPos,parentSize,parentScale=absolute(object.Parent)
        local own=object:FindFirstChildOfClass("UIScale");local ownScale=own and own.Scale or 1
        local size=vector((parentSize.X*object.Size.X.Scale+object.Size.X.Offset*parentScale)*ownScale,(parentSize.Y*object.Size.Y.Scale+object.Size.Y.Offset*parentScale)*ownScale)
        local pos=vector(parentPos.X+parentSize.X*object.Position.X.Scale+object.Position.X.Offset*parentScale-size.X*object.AnchorPoint.X,parentPos.Y+parentSize.Y*object.Position.Y.Scale+object.Position.Y.Offset*parentScale-size.Y*object.AnchorPoint.Y)
        if object.Parent.ClassName=="ScrollingFrame" then pos=pos-(object.Parent.CanvasPosition or vector())*parentScale end
        return pos,size,parentScale*ownScale
    end
    local services={}
    for _,name in ipairs({"Players","ReplicatedStorage","RunService","UserInputService","Lighting","StarterGui","TweenService","SocialService","HttpService","MarketplaceService","LocalizationService"}) do services[name]=node("Service",name) end
    services.LocalizationService.RobloxLocaleId=localeId
    services.LocalizationService.SystemLocaleId=localeId=='th-th' and 'en-us' or 'th-th'
    function services.TweenService:Create(object,_info,properties) return {Play=function() for key,value in pairs(properties) do object[key]=value end end,Cancel=function() end} end
    function services.RunService:IsStudio() return true end
    function services.RunService:BindToRenderStep(_name,_priority,callback) self.RenderStepped:Connect(callback) end
    local game={PlaceId=0,JobId="mock",GetService=function(_,name) return assert(services[name],name) end}
    local player=node("Player","Avery");player.UserId=1;player.DisplayName="Avery";services.Players.LocalPlayer=player
    player.LocaleId=services.LocalizationService.SystemLocaleId
    function services.Players:GetPlayerByUserId(id) return id==1 and player or nil end
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
    for index=1,24 do
        local tile=node("Part","Tile"..index);tile.Parent=board
        local plate=node("Part","DeedPlate"..index);plate.Parent=board
        local caption=node("SurfaceGui","Caption");caption.Parent=plate
    end
    local env={game=game,workspace=workspace,Instance={new=node},Enum=enum,Vector2={new=vector,zero=vector()},Vector3={new=vector,zero=vector()},
        Color3=color3,CFrame=cfApi,UDim={new=dim},UDim2={new=dimensions,fromOffset=function(x,y) return dimensions(0,x,0,y) end,fromScale=function(x,y) return dimensions(x,0,y,0) end},
        RaycastParams={new=function() return {} end},TweenInfo={new=function(...) return {...} end},task={spawn=function(callback) table.insert(scheduled,{at=math.huge,callback=callback}) end,delay=function(time,callback) table.insert(scheduled,{at=now+time,callback=callback}) end,wait=function() return 0.016 end}}
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
    local function advance(seconds)
        now=now+seconds
        local ready={}
        for i=#scheduled,1,-1 do if scheduled[i].at<=now then table.insert(ready,table.remove(scheduled,i).callback) end end
        for _,callback in ipairs(ready) do callback() end
    end
    local function runSpawned()
        local work={}
        for i=#scheduled,1,-1 do if scheduled[i].at==math.huge then table.insert(work,table.remove(scheduled,i).callback) end end
        for _,callback in ipairs(work) do callback() end
    end
    local bootRequests=#requests
    advance(3.1);advance(3.1)
    assert(#requests>=bootRequests+2 and requests[#requests][1]=='Sync','A missing initial snapshot leaves the client stuck')
    local Engine=load(shared.Engine);local Config=load(shared.Config)
    local engine=Engine.new(Config)
    local roster={{id=1,name="Avery"},{id=2,name="Riley"},{id=3,name="Jamie"},{id=4,name="Morgan"}}
    assert(engine:start(roster))
    for _,asset in ipairs({{2,1,0},{8,2,1},{14,3,2},{23,4,3}}) do local p=engine.state.properties[asset[1]];p.ownerId,p.level=asset[2],asset[3] end
    load(shared.Tactics).refresh(engine)
    local members={};for i,p in ipairs(roster) do table.insert(members,{id=p.id,name=p.name,colorIndex=i,ready=true}) end
    local data={lobby=members,hostId=1,lobbyConfig={seats=4,fillBots=true,attackMode="destroy"},
        matchmaking={mode="lobby",queued=false,status="Studio local matchmaking",studio=true},club={styleId="classic",ownsPass=false,loading=false,studio=true,passId=0,effects=true,status=""},
        styles={},deadline=now+55,handoffAt=0,serverTime=now,revision=0,visitors={}}
    local function publish()
        data=table.clone(data)
        data.revision=data.revision+1;data.game=engine:view(1)
        remotes.Snapshot.OnClientEvent:Fire(data)
        services.RunService.RenderStepped:Fire(0.016)
    end
    publish()
    local gui=playerGui:WaitForChild("Citymoney");local root=gui:WaitForChild("Frame"):WaitForChild("CityRoot")
    local probe=node("TextLabel","ThaiProbe");probe.Text="ROLL DICE";probe.Parent=root
    assert(probe.Text==t("ROLL DICE"),"New controls do not follow the Roblox language")
    probe.Text="Choose your home level";assert(probe.Text==t("Choose your home level"),"Dynamic captions are not localized")
    local nativeParts=load(shared.Scene).populate({{name='LanguageSign',position={0,2,0},size={5,1,3},color='FFFFFF',text="Ready's home"}},board)
    local worldText=nativeParts[1].Caption.TextLabel
    assert(worldText:GetAttribute('CitymoneyText') and worldText.Text==t("Ready's home"),'Scene signs do not follow this client language')
    local originalState=engine.state;local originalCash=engine:player(1).cash
    local rawWorldName=node('TextLabel','UntranslatedResidentName');rawWorldName.Text='Ready';rawWorldName.Parent=board
    local input=node('TextBox','UserInput');input.Text='Ready';input.Parent=root
    for _,newLocale in ipairs({localeId=='th-th' and 'en-us' or 'th-th',localeId}) do
        services.LocalizationService.RobloxLocaleId=newLocale;expected:setLocale(newLocale)
        services.RunService.RenderStepped:Fire(0.016)
        assert(probe.Text==t('Choose your home level'),'Changing language lost the original UI source')
        assert(worldText.Text==t("Ready's home"),'Changing language lost the original world source')
        assert(root.TurnDock.PrimaryAction.Text==t('ROLL DICE'),'The main action did not switch languages')
        assert(rawWorldName.Text=='Ready' and input.Text=='Ready','Localization changed a player name or player input')
    end
    worldText.Text='FESTIVAL\n$80';assert(worldText.Text==t('FESTIVAL\n$80'),'A replicated update ignored the client language')
    assert(engine.state==originalState and engine:player(1).cash==originalCash,'Language switching changed the match')
    nativeParts[1]:Destroy()
    rawWorldName:Destroy();input:Destroy()
    local nativeScene=load(shared.Scene)
    local nativeNew=env.Instance.new
    local staged
    env.Instance.new=function(class) local object=nativeNew(class);if class=='Model' then staged=object end;return object end
    local ok=pcall(nativeScene.model,{{name='GoodPart',size={2,2,2},position={0,0,0},color='FFFFFF'},{name='BadPart',size={2,2,2},color='FFFFFF'}},'IncompleteHouse',board)
    env.Instance.new=nativeNew
    assert(not ok and staged and not staged.Parent and #staged:GetChildren()==0 and not board:FindFirstChild('IncompleteHouse'),'A failed model leaves a partial house in the world')
    local complete=nativeScene.model({{name='CompleteSign',size={2,2,2},position={0,2,0},color='FFFFFF',text='CITY NEWS'}},'CompleteHouse',board)
    assert(complete.CompleteSign.Caption.TextLabel.Text==t('CITY NEWS'),'A staged model misses per-player localization')
    complete:Destroy()
    probe:Destroy()
    local nameProbe=node("TextLabel","NameProbe");nameProbe.Text="Ready";nameProbe:SetAttribute("PlayerName",true);nameProbe.Parent=root
    assert(nameProbe.Text=="Ready","A player name was translated as a menu command");nameProbe:Destroy()
    local function visible(o) while o do if o.Visible==false or o.Enabled==false then return false end;o=o.Parent end;return true end
    local untranslated={}
    local function luminance(c)
        local function linear(v) return v<=0.04045 and v/12.92 or ((v+0.055)/1.055)^2.4 end
        return linear(c.R)*0.2126+linear(c.G)*0.7152+linear(c.B)*0.0722
    end
    local function findText(text)
        text=t(text)
        local found
        for _,object in ipairs(gui:GetDescendants()) do if visible(object) and object.Text then
            if object.Text~='' and (object.TextTransparency or 0)<0.05 then
                local background=object
                while background and (background.BackgroundTransparency or 0)>0.1 do background=background.Parent end
                if background and background.BackgroundColor3 then
                    local a,b=luminance(object.TextColor3),luminance(background.BackgroundColor3)
                    assert((math.max(a,b)+0.05)/(math.min(a,b)+0.05)>=4.5,'Unreadable text contrast: '..object.Text)
                end
            end
            local remainder=object.Text
            for _,allowed in ipairs({'Avery','Riley','Jamie','Morgan','Roblox','Robux','Studio'}) do remainder=string.gsub(remainder,allowed,'') end
            if expected.locale=='th-th' and string.find(remainder,'%a%a%a+') then untranslated[object.Text]=true end
            if expected.locale=='en-us' then
                for _,cp in utf8.codes(remainder) do if cp>=0x0e00 and cp<=0x0e7f then untranslated[object.Text]=true;break end end
            end
            if object.Text==text then found=object end
        end end
        if found then return found end
        error("Missing visible text: "..text)
    end
    local function inside(o)
        local p,s=absolute(o)
        assert(p.X>=-0.1 and p.Y>=-0.1 and p.X+s.X<=width+0.1 and p.Y+s.Y<=height+0.1,"Cropped "..o.Name)
    end
    local function click(text)
        local object=findText(text)
        if object.ClassName~="TextButton" then object=object.Parent end
        object.Activated:Fire();services.RunService.RenderStepped:Fire(0.016)
        return object
    end
    local function menu(label) root.CityMenuButton.Activated:Fire();click(label) end
    local function hex(c) return string.format("%02x%02x%02x",math.floor(c.R*255+0.5),math.floor(c.G*255+0.5),math.floor(c.B*255+0.5)) end
    local function viewportData(viewport)
        local camera=viewport.CurrentCamera
        if not camera or not camera.CFrame or not camera.CFrame.right then return nil end
        local parts={}
        for _,part in ipairs(viewport:GetDescendants()) do if part:IsA("BasePart") then
            local p,s=part.CFrame.Position,part.Size
            table.insert(parts,{name=part.Name,position={p.X,p.Y,p.Z},size={s.X,s.Y,s.Z},color=hex(part.Color),
                rotation=part.CFrame.rotation or {1,0,0,0,1,0,0,0,1},shape=part.Shape and part.Shape.Name or "Block",material=part.Material and part.Material.Name or "SmoothPlastic",transparency=part.Transparency or 0})
        end end
        local _,size=absolute(viewport)
        local function values(v) return {v.X,v.Y,v.Z} end
        return {scene=parts,width=math.floor(size.X+0.5),height=math.floor(size.Y+0.5),camera={position=values(camera.CFrame.Position),right=values(camera.CFrame.right),up=values(camera.CFrame.up),back=values(camera.CFrame.back),fov=camera.FieldOfView}}
    end
    local function export()
        local elements={}
        local function clipBounds(object)
            local left,top,right,bottom=0,0,width,height
            local ancestor,clipped=object.Parent,false
            while ancestor do
                if ancestor.ClipsDescendants then
                    local p,s=absolute(ancestor);clipped=true
                    left,top=math.max(left,p.X),math.max(top,p.Y)
                    right,bottom=math.min(right,p.X+s.X),math.min(bottom,p.Y+s.Y)
                end
                ancestor=ancestor.Parent
            end
            return clipped and {x=left,y=top,w=math.max(0,right-left),h=math.max(0,bottom-top)} or nil
        end
        local function walk(parent)
            local children=parent:GetChildren();table.sort(children,function(a,b) if a.ZIndex==b.ZIndex then return a.creationOrder<b.creationOrder end;return (a.ZIndex or 1)<(b.ZIndex or 1) end)
            for _,o in ipairs(children) do if visible(o) then
                if guiClasses[o.ClassName] then
                    local p,s,scale=absolute(o);local corner=o:FindFirstChildOfClass("UICorner");local stroke=o:FindFirstChildOfClass("UIStroke")
                    table.insert(elements,{class=o.ClassName,name=o.Name,x=p.X,y=p.Y,w=s.X,h=s.Y,clip=clipBounds(o),text=o.Text or "",textAlpha=1-(o.TextTransparency or 0),rotation=o.Rotation or 0,size=(o.TextSize or 14)*scale,bg=hex(o.BackgroundColor3),fg=hex(o.TextColor3),alpha=1-(o.BackgroundTransparency or 0),font=o.Font and o.Font.Name or "Gotham",wrap=o.TextWrapped==true,align=o.TextXAlignment and o.TextXAlignment.Name or "Left",corner=corner and (corner.CornerRadius.Scale*math.min(s.X,s.Y)+corner.CornerRadius.Offset*scale) or 0,viewport=o.ClassName=="ViewportFrame" and viewportData(o) or nil,
                        stroke=stroke and {color=hex(stroke.Color or color(0.8,0.85,0.9)),alpha=1-(stroke.Transparency or 0),width=(stroke.Thickness or 1)*scale} or false})
                end
                walk(o)
            end end
        end
        walk(gui);return elements
    end
    local P=load(shared.Presentation);local Fit=load(shared.BoardCamera)
    local Actors,Journey=load(shared.Actors),load(shared.Journey)
    local layout=P.layout(width,height);local r=P.board(layout,false)
    local function camera()
        local yaw,elevation=P.viewAngles(root:GetAttribute("ViewMode"),0)
        local bounds=root:GetAttribute("ViewMode")=="city" and load(shared.CityScenery).bounds() or Fit.cityBounds(Config,load(shared.Architecture))
        return Fit.fit(width,height,{r[1]*layout.scale,r[2]*layout.scale,r[3]*layout.scale,r[4]*layout.scale},yaw,elevation,1,bounds)
    end
    local views={}
    local function pose(resident,seat)
        local roll=engine.state.lastRoll
        if roll and roll.turn==engine.state.turnCount and resident.id==roll.actorId and resident.position==roll.to and data.journeyUntil and now<data.journeyUntil then
            local elapsed=now-(data.moveAt or (data.journeyUntil-Journey.duration(Config,roll)+Journey.beforeMove(Config)))
            return Actors.travel(Config,roll,seat,elapsed)
        end
        return Actors.pose(resident.position,seat)
    end
    local function scene()
        local A,B,D=load(shared.Architecture),load(shared.Board),load(shared.Dice)
        local entries={}
        for _,entry in ipairs(B.generate(Config)) do
            local parcel=entry.tileIndex and Config.tiles[entry.tileIndex].kind=="property" and not entry.boardSpace
            local die=entry.name=="DiceBody" or entry.name=="DiceShell" or entry.name=="DiceEdge" or entry.name=="DiceCorner" or string.match(entry.name,"^Pip%d$")
            if not parcel and not die then
                if entry.name=="DeedPlate"..tostring(entry.tileIndex) then
                    entry.text=board:WaitForChild(entry.name):WaitForChild("Caption").Enabled and B.caption(Config,entry.tileIndex,engine.state) or nil
                end
                table.insert(entries,entry)
            end
        end
        for index,tile in ipairs(Config.tiles) do if tile.kind=="property" then
            local property=engine.state.properties[index];local owner
            for _,p in ipairs(engine.state.players) do if p.id==property.ownerId then owner=p end end
            for _,entry in ipairs(A.property(Config,index,owner and owner.name or false,owner and Config.playerColors[owner.colorIndex] or Config.groups[tile.group].color,property.level,property.paint,property,"classic")) do table.insert(entries,entry) end
        end end
        local dice=engine.state.lastRoll and engine.state.lastRoll.values or {1,6}
        for side,value in ipairs(dice) do for _,entry in ipairs(D.preview(value,side)) do table.insert(entries,entry) end end
        for seat,resident in ipairs(engine.state.players) do if resident.alive then
            local p,yaw=pose(resident,seat)
            for _,entry in ipairs(Actors.preview(Config.playerColors[resident.colorIndex],p,yaw)) do table.insert(entries,entry) end
        end end
        return expected:scene(entries)
    end
    local function capture(name)
        local figures={}
        for seat,resident in ipairs(engine.state.players) do if resident.alive then
            local figure=node("Model","Figure_"..resident.id);figure.Parent=board;table.insert(figures,figure)
            local p=pose(resident,seat)
            local torso=node("Part","Torso");torso.Position=vector(table.unpack(p));torso.Parent=figure
            local head=node("Part","Head");head.Position=torso.Position+vector(0,1.28*Actors.heightScale,0);head.Parent=figure
        end end
        services.RunService.RenderStepped:Fire(0.016);views[name]={elements=export(),camera=camera(),scene=scene()}
        for _,figure in ipairs(figures) do figure:Destroy() end
        services.RunService.RenderStepped:Fire(0.016)
    end
    for _,name in ipairs({"Header","TurnDock","CityMenuButton","CameraDock","QuickActions","GoalProgress"}) do inside(root:WaitForChild(name)) end
    for _,die in ipairs({root.TurnDock.RollDieA,root.TurnDock.RollDieB}) do local _,s=absolute(die);assert(s.X>=50 and s.Y>=50,"Dice are too small to tap") end
    if layout.compact then
        for _,button in ipairs({root.QuickActions.OpenEvents,root.QuickActions.OpenCards,root.QuickActions.OpenHomes}) do
            local _,s=absolute(button);assert(s.Y>=44 and s.X>=44,"Shortcut is too small for touch")
        end
    end
    local function checkDeeds()
        for index=1,24 do
            local badge=root:WaitForChild("DeedLabel"..index)
            assert(badge.Visible,"Missing top-view space "..index);inside(badge)
            assert(not board:WaitForChild("DeedPlate"..index):WaitForChild("Caption").Enabled,"Duplicate floor caption in top view")
            local p,s=absolute(badge)
            assert(badge.ClipsDescendants and badge.TextScaled,"Names can escape their space")
            local Spaces=load(shared.BoardSpaces)
            local projected=Spaces.project(index,function(point)
                local screen=workspace.CurrentCamera:WorldToScreenPoint(vector(table.unpack(point)))
                return {screen.X,screen.Y}
            end)
            assert(math.abs(s.X-projected.width)<0.01 and math.abs(s.Y-projected.height)<0.01,"A badge extends beyond its reserved area")
            for other=index+1,24 do
                local p2,s2=absolute(root:WaitForChild("DeedLabel"..other))
                local overlapX=math.min(p.X+s.X,p2.X+s2.X)-math.max(p.X,p2.X)
                local overlapY=math.min(p.Y+s.Y,p2.Y+s2.Y)-math.max(p.Y,p2.Y)
                assert(overlapX<=0 or overlapY<=0,"Map badges overlap: "..index.." and "..other)
            end
        end
    end
    assert(root:GetAttribute("ViewMode")=="table","Play did not start in top view")
    checkDeeds()
    capture("main")
    local figure=node("Model","Figure_2");figure.Parent=board
    local head=node("Part","Head");head.Parent=figure
    local spot=load(shared.BoardSpaces).label(3);head.Position=vector(table.unpack(spot))
    services.RunService.RenderStepped:Fire(0.016)
    assert(not root.DeedLabel3.Visible and board.DeedPlate3.Caption.Enabled,"A map label covers the pawn")
    figure:Destroy();services.RunService.RenderStepped:Fire(0.016);checkDeeds()
    player.Character=node("Model","Character")
    local realHead=node("Part","Head");realHead.Parent=player.Character
    spot=load(shared.BoardSpaces).label(2);realHead.Position=vector(table.unpack(spot))
    local loadingFigure=node("Model","Figure_1");loadingFigure.Parent=board
    local loadingHead=node("Part","Head");loadingHead.Parent=loadingFigure
    spot=load(shared.BoardSpaces).label(5);loadingHead.Position=vector(table.unpack(spot))
    services.RunService.RenderStepped:Fire(0.016)
    assert(root.DeedLabel2.Visible and not root.DeedLabel5.Visible,"A loading avatar hides the moving fallback figure")
    loadingFigure:Destroy();player.Character:SetAttribute("CitymoneyPrepared",true)
    services.RunService.RenderStepped:Fire(0.016)
    assert(not root.DeedLabel2.Visible,"A map label covers a real player's avatar")
    realHead.LocalTransparencyModifier=1;services.RunService.RenderStepped:Fire(0.016)
    assert(realHead.LocalTransparencyModifier==0,"The local avatar remains hidden after the camera controller")
    spot=load(shared.BoardSpaces).label(5);realHead.Position=vector(table.unpack(spot))
    services.RunService.RenderStepped:Fire(0.016)
    assert(root.DeedLabel2.Visible and not root.DeedLabel5.Visible,"Labels do not follow the moving avatar")
    player.Character:Destroy();player.Character=nil;services.RunService.RenderStepped:Fire(0.016);checkDeeds()
    -- Exercise real camera/label adapters, including projection and reset.
    data.club.effects=false
    root.CameraDock.TableView.Activated:Fire();services.RunService.RenderStepped:Fire(0.016)
    assert(root:GetAttribute("ViewMode")=="city" and root.CameraDock.TableView.Text==t("Board view"))
    for index=1,24 do
        assert(not root["DeedLabel"..index].Visible,"Top-view badge remained in 3D view")
        assert(board["DeedPlate"..index].Caption.Enabled,"3D floor caption did not return")
    end
    root:SetAttribute("Rotate",2);root:SetAttribute("Zoom",1.4)
    root.CameraDock.Fit.Activated:Fire();services.RunService.RenderStepped:Fire(0.016)
    assert(root:GetAttribute("ViewMode")=="table","Fit did not reset the readable view")
    local fixedCamera=workspace.CurrentCamera.CFrame
    assert(not root.CameraDock:FindFirstChild("ZoomIn") and not root.CameraDock:FindFirstChild("ZoomOut"),"Zoom controls remain visible")
    services.UserInputService.InputChanged:Fire({UserInputType=enum.UserInputType.MouseWheel,Position=vector(0,0,4)},false)
    services.RunService.RenderStepped:Fire(0.016)
    assert(workspace.CurrentCamera.CFrame==fixedCamera,"Mouse wheel zooms the board")
    checkDeeds()
    root.DeedLabel3.Activated:Fire();services.RunService.RenderStepped:Fire(0.016)
    findText("Brick Courtyard");assert(root.PropertyCard.Visible,"Map label did not open the full property card")
    assert(workspace.CurrentCamera.CFrame==fixedCamera,"Property inspection zooms the board")
    root.CameraDock.Fit.Activated:Fire();services.RunService.RenderStepped:Fire(0.016)
    assert(not root.PropertyCard.Visible,"Fit did not close the property inspector");checkDeeds()
    root.DeedLabel4.Activated:Fire();findText("Collect cards on the board.");click("X")
    data.club.effects=true
    click("ROLL DICE");assert(requests[#requests][1]=="Roll","Roll button did not send a roll");advance(0.3)
    local target=node("Part","Tile2");target.Parent=board;target:SetAttribute("TileIndex",2);pointer.Target=target
    services.UserInputService.InputChanged:Fire({UserInputType=enum.UserInputType.MouseMovement,Position=vector(width*0.76,height*0.59)},false)
    services.RunService.RenderStepped:Fire(0.016)
    assert(root.PropertyHover.Visible,"Property hover did not appear");inside(root.PropertyHover)
    target:SetAttribute("TileIndex",nil);target:SetAttribute("Interaction","festival")
    services.UserInputService.TouchTapInWorld:Fire(vector(width*0.7,height*0.55),false)
    findText("Join the festival.");findText("JOIN FESTIVAL · $80")
    click("X")
    root.QuickActions.OpenEvents.Activated:Fire();findText("Choose an event.");capture("events")
    local requestsBeforeCards=#requests
    click("CARD SPACES");findText("Collect cards on the board.");findText("FREE · up to 3 each · scroll for all 5 cards")
    local cardRows=findText("Demolition permit").Parent.Parent
    assert(cardRows.ClipsDescendants and cardRows.CanvasSize.Y.Offset==350,"The five-card list does not clip or scroll")
    cardRows.CanvasPosition=vector(0,156)
    local rowPos,rowSize=absolute(findText("Renovation grant").Parent);local listPos,listSize=absolute(cardRows)
    assert(rowPos.Y>=listPos.Y and rowPos.Y+rowSize.Y<=listPos.Y+listSize.Y,"The final card is unreachable by scrolling")
    cardRows.CanvasPosition=vector()
    capture("card-guide")
    click("VIEW CARDS & GOALS");findText("Cards & challenges")
    assert(#requests==requestsBeforeCards,"Card-space information sends a purchase request")
    click("×")
    local request
    advance(0.3)
    engine.state.turn=2;publish();root.QuickActions.OpenEvents.Activated:Fire();click("FESTIVAL")
    assert(findText("BROWSE FOR NEXT TURN").Active==false,"Off-turn event purchase is enabled");click("CLOSE")
    engine.state.turn=1;engine.state.plazaUsed=false;engine.state.properties[3].ownerId=1;publish()
    root.QuickActions.OpenEvents.Activated:Fire();click("FESTIVAL")
    assert(findText("CHOOSE A HOME").Active==false,"Several eligible homes need an explicit choice")
    click("Brick Courtyard");click("JOIN FESTIVAL · $80")
    request=requests[#requests];assert(request[1]=="Plaza" and request[2].tile==3,"Festival target was not the chosen home")
    assert(engine:act(1,"Plaza",request[2]));publish();advance(0.3)
    findText("Claim $140 + card");root.GoalProgress.Activated:Fire()
    request=requests[#requests];assert(request[1]=="Claim" and request[4]==engine.state.turnCount,"Goal shortcut did not claim the earned reward")
    assert(engine:act(1,request[1],request[2],request[3],request[4]));publish();findText("GOAL COMPLETE!");inside(root.MatchMoment)
    assert(not root.NoticeToast.Visible and not root.PropertyHover.Visible,"Old notifications cover the reward moment")
    capture("reward");advance(0.3)
    root.QuickActions.OpenCards.Activated:Fire();findText("Cards & challenges");inside(findText("Cards & challenges").Parent);click("×")
    menu("CITY EVENTS");findText("Choose an event.");click("X")
    root.QuickActions.OpenHomes.Activated:Fire();findText("Your collection");inside(root.PropertyCollection)
    click("Copper Lane");inside(root.PropertyCard)
    assert(root.PropertyHover.Visible==false)
    click("Upgrade options");findText("Choose your upgrade");inside(findText("Choose your upgrade").Parent)
    assert(not root.PropertyCard.Visible and not root.PropertyCollection.Visible,"Property panels stack behind the chooser")
    click("L2 · Garden villa");click("Upgrade to Garden villa · $120")
    request=requests[#requests];assert(request[1]=="Upgrade" and request[2]==2 and request[3]==2)
    assert(engine:act(1,request[1],request[2],request[3],request[4]));publish();advance(0.3)
    assert(workspace.CurrentCamera.CFrame==fixedCamera,"Upgrades zoom the board")
    engine.state.phase="buy";engine.state.pendingTile=5;publish();advance(0.3);services.RunService.RenderStepped:Fire(0.016)
    findText("Choose your home level");click("L1 · Townhouse");click("Buy Townhouse · $220")
    request=requests[#requests];assert(request[1]=="Buy" and request[2]==5 and request[3]==1)
    assert(engine:act(1,request[1],request[2],request[3],request[4]));publish();advance(0.3)
    engine.state.phase="buy";engine.state.pendingTile=6;publish();advance(0.3);click("Back");click("SKIP")
    assert(requests[#requests][1]=="Skip");assert(engine:act(1,"Skip"));assert(not engine.state.properties[6].ownerId)
    advance(0.3)
    -- The dice finish, their result stays visible, then separate board steps
    -- begin. All three phases use one fixed camera, including delayed snapshots.
    data.club.effects=true;engine.state.phase="roll";engine:player(1).position=13;engine.random=function(low) return low end
    assert(engine:act(1,"Roll"))
    data.diceEndsAt=now+Config.diceSeconds;data.moveAt=now+Journey.beforeMove(Config)
    data.journeyUntil=now+Journey.duration(Config,engine.state.lastRoll);data.handoffAt=data.journeyUntil+4;data.deadline=data.journeyUntil+55
    publish();assert(root.TurnDock.PrimaryAction.Text==t("ROLLING...") and not root.TurnDock.PrimaryAction.Active);assert(root.TurnDock.RollDieA.Active==false)
    assert(not root.MatchMoment.Visible,"A large roll banner hides the walking route")
    assert(not root.NoticeToast.Visible and not root.PropertyHover.Visible,"Old notices cover the dice and walking route")
    assert(workspace.CurrentCamera.CFrame==fixedCamera,"Rolling zooms the camera")
    advance(0.7);services.RunService.RenderStepped:Fire(0.016)
    -- A late server dice-completion message extends the whole presentation.
    data.diceEndsAt=data.diceEndsAt+0.3;data.moveAt=data.moveAt+0.3
    data.journeyUntil=data.journeyUntil+0.3;data.handoffAt=data.handoffAt+0.3;data.deadline=data.deadline+0.3;publish()
    advance(data.diceEndsAt-now+0.2);services.RunService.RenderStepped:Fire(0.016)
    findText("GET READY...");findText("YOU ROLLED 2")
    local before=Actors.pose(engine.state.lastRoll.from,1)
    local held=pose(engine:player(1),1)
    for axis=1,3 do assert(math.abs(before[axis]-held[axis])<1e-6,"The pawn moves before the settled result is shown") end
    assert(root.TurnDock.RollDieA.Rotation==0 and root.TurnDock.RollDieB.Rotation==0,"The HUD dice keep tumbling after their result")
    capture("result")
    advance(data.moveAt-now+0.3);services.RunService.RenderStepped:Fire(0.016)
    assert(findText("ON THE MOVE...").Active==false)
    assert(workspace.CurrentCamera.CFrame==fixedCamera,"Movement zooms the camera")
    local moving=pose(engine:player(1),1);assert(math.abs(moving[1]-before[1])+math.abs(moving[3]-before[3])>1,"The pawn never leaves its starting space")
    capture("walking")
    advance(data.journeyUntil-now+0.1);services.RunService.RenderStepped:Fire(0.016)
    assert(workspace.CurrentCamera.CFrame==fixedCamera,"Arrival zooms the camera")
    if engine.state.phase=="buy" then click("Back");click("SKIP");assert(engine:act(1,"Skip"));publish() end
    data.club.effects=false;data.diceEndsAt=nil;data.moveAt=nil
    -- A waiting opportunity opens only when its token reaches the news space.
    engine:player(1).stats.news=1;engine:player(1).position=16;engine:land(engine:player(1))
    data.journeyUntil=now+2;data.deadline=now+57;publish()
    assert(root.OpportunityOverlay.Visible==false,"Choice opened before movement finished")
    advance(2.1);services.RunService.RenderStepped:Fire(0.016)
    findText("Builder's Deal");inside(findText("Builder's Deal").Parent);capture("opportunity")
    click("X");click("CHOOSE REWARD");findText("Builder's Deal")
    click("Renovation card");request=requests[#requests]
    assert(request[1]=="Offer" and request[2].option==2)
    assert(engine:act(1,"Offer",request[2]));publish();findText("CITY REWARD!");advance(0.3)
    engine:player(1).stats.news=1;engine:player(1).cards.repair=3;engine:land(engine:player(1));data.journeyUntil=0;publish()
    findText("HAND FULL · TAKE CASH INSTEAD");local count=#requests
    click("Renovation card");assert(#requests==count,"A full hand still sent a card request")
    click("Take $90");request=requests[#requests];assert(engine:act(1,"Offer",request[2]));publish();advance(0.3)
    engine.state.turn=2;engine:player(2).stats.news=1;engine:player(2).position=16;engine:land(engine:player(2));publish()
    assert(root.OpportunityOverlay.Visible==false,"Another player's reward opened for this client")
    assert(engine:act(2,"Offer",load(shared.Opportunities).request(engine.state,1)));publish()
    advance(0.3)
    engine.state.turn=1;engine:player(1).position=4
    for _,kind in ipairs(Config.tiles[4].cardChoices) do engine:player(1).cards[kind]=1 end
    engine:land(engine:player(1))
    data.journeyUntil=now+2;data.deadline=now+57;publish()
    assert(not root.OpportunityOverlay.Visible,"Card collection opens before movement finishes")
    advance(2.1);services.RunService.RenderStepped:Fire(0.016)
    findText("FREE CARD SPACE");findText("TACTIC CARDS");findText("Demolition permit");findText("Property shield");findText("Renovation grant")
    inside(findText("TACTIC CARDS").Parent);capture("card-space")
    click("X");click("COLLECT CARD");findText("FREE CARD SPACE")
    local cardsBefore=engine:player(1).cards.shield;local cashBefore=engine:player(1).cash
    click("Property shield");request=requests[#requests]
    assert(request[1]=="Offer" and request[2].option==2)
    assert(engine:act(1,"Offer",request[2]));publish();findText("CARD COLLECTED!")
    assert(engine:player(1).cards.shield==cardsBefore+1 and engine:player(1).cash==cashBefore,"Collecting a free card changed the cash balance")
    advance(0.3)
    for _,kind in ipairs(Config.tiles[4].cardChoices) do engine:player(1).cards[kind]=3 end
    engine:land(engine:player(1));data.journeyUntil=0;publish();services.RunService.RenderStepped:Fire(0.016)
    local fullCount=#requests;click("Demolition permit");assert(#requests==fullCount,"A full card type still sends a request")
    root.OpportunityOverlay:WaitForChild("Frame"):WaitForChild("SkipCardReward").Activated:Fire()
    request=requests[#requests];assert(request[1]=="Offer" and request[2].option==0)
    assert(engine:act(1,"Offer",request[2]));publish();advance(0.3)
    engine:player(1).position=22;engine:player(1).cards.boost=1;engine:land(engine:player(1));publish();services.RunService.RenderStepped:Fire(0.016)
    findText("RENT CARDS");findText("Rent demand");findText("Rent boost");capture("rent-card-space")
    click("Rent boost");request=requests[#requests];assert(engine:act(1,"Offer",request[2]));publish();advance(0.3)
    assert(engine:player(1).cards.boost==2)
    engine=Engine.new(Config);data.lobby={members[1]};data.lobbyConfig.seats=2;publish()
    assert(root.QuickActions.Visible==false,"Match shortcuts appear before a game starts")
    click("PLAY NOW");click("4 PLAYERS")
    assert(requests[#requests][1]=="Seats" and requests[#requests][2]==4)
    data.lobbyConfig.seats=4;publish();advance(0.3)
    local queue=findText("PLAY ONLINE · 4 PLAYERS");assert(queue.Active,"Solo host cannot start matchmaking");queue.Activated:Fire()
    assert(requests[#requests][1]=="Queue");advance(0.3)
    capture("lobby");inside(findText("Play together").Parent)
    click("SETTINGS");findText("Practice settings");inside(findText("Practice settings").Parent);click("×")
    click("PRACTICE WITH BOTS");assert(requests[#requests][1]=="Start","Practice requires extra setup")
    advance(0.3)
    menu("COSMETIC SHOP")
    local shop=root.CosmeticShopOverlay.CosmeticShop
    inside(shop)
    findText("Equip in Studio preview")
    for _,name in ipairs({"ClubCheckout","RestoreClub","CosmeticMotion","Collection_classic","Collection_gilded","Collection_aurora","Collection_rose"}) do
        local shopControl=shop:WaitForChild(name);inside(shopControl)
        local _,s=absolute(shopControl);assert(s.Y>=44 and s.X>=44,"Shop controls are too small to tap: "..name)
    end
    capture("shop-studio")
    click("Equip in Studio preview");assert(requests[#requests][1]=="Style" and requests[#requests][2].styleId=="gilded")
    advance(0.3)
    local prompts,priceCalls={},0
    local priceInfo={IsForSale=true,PriceInRobux=149}
    local failInfo,failPrompt=false,false
    function services.MarketplaceService:GetProductInfoAsync(id,kind)
        assert(id==12345 and kind==enum.InfoType.GamePass);priceCalls=priceCalls+1
        if failInfo then error("Controlled product lookup failure") end
        return priceInfo
    end
    function services.MarketplaceService:PromptGamePassPurchase(buyer,id)
        assert(buyer==player and id==12345)
        if failPrompt then error("Controlled prompt failure") end
        table.insert(prompts,id)
    end
    data.club={styleId="classic",ownsPass=false,loading=false,studio=false,passId=0,effects=true,status=""};publish()
    findText("Club pass coming soon");assert(not shop.ClubCheckout.Active)
    data.club=table.clone(data.club);data.club.passId=12345;publish();runSpawned()
    local function serverCheckout(purchased)
        data.club=table.clone(data.club)
        data.club.checkoutSequence=(data.club.checkoutSequence or 0)+1
        data.club.checkoutResult=purchased and "checking" or "cancelled"
        publish()
    end
    findText("Unlock Club · R$ 149");capture("shop-robux")
    click("Unlock Club · R$ 149");shop.ClubCheckout.Activated:Fire()
    assert(#prompts==1 and not shop.ClubCheckout.Active,"Repeated clicks reopen Roblox checkout")
    services.MarketplaceService.PromptGamePassPurchaseFinished:Fire(player,999,false)
    assert(not shop.ClubCheckout.Active,"Another pass completion changed this purchase")
    services.MarketplaceService.PromptGamePassPurchaseFinished:Fire(player,12345,false)
    assert(not shop.ClubCheckout.Active,"A local event drives checkout state without server confirmation")
    serverCheckout(false)
    assert(shop.ClubCheckout.Active and not data.club.ownsPass,"Cancelling granted Club access")
    click("Unlock Club · R$ 149")
    services.MarketplaceService.PromptGamePassPurchaseFinished:Fire(player,12345,true)
    assert(not data.club.ownsPass,"A local completion event granted ownership")
    serverCheckout(true)
    findText("Verifying with Roblox…");assert(not shop.ClubCheckout.Active)
    assert(not data.club.ownsPass,"A local completion event granted ownership")
    data.club=table.clone(data.club);data.club.checkoutResult="delayed";publish()
    findText("Verify my purchase");advance(12.1);findText("Verify my purchase")
    local promptsBefore=#prompts;click("Verify my purchase")
    assert(requests[#requests][1]=="ClubRefresh" and #prompts==promptsBefore,"Verification opened another checkout")
    advance(0.3);data.club=table.clone(data.club);data.club.ownsPass=true;publish()
    assert(requests[#requests][1]=="Style" and requests[#requests][2].styleId=="gilded","A verified purchase did not equip the previewed collection")
    data.club=table.clone(data.club);data.club.styleId="gilded";publish();findText("Equipped ✓")
    capture("shop-owned")
    advance(0.3);shop.Collection_aurora.Activated:Fire();click("Equip Aurora Residence")
    assert(requests[#requests][1]=="Style" and requests[#requests][2].styleId=="aurora")
    data.club=table.clone(data.club);data.club.ownsPass=false;data.club.styleId="classic";publish();advance(0.3)
    failInfo=true;click("Check ownership");runSpawned();findText("Retry Robux price")
    promptsBefore=#prompts;click("Retry Robux price");runSpawned();assert(#prompts==promptsBefore)
    failInfo=false;click("Retry Robux price");runSpawned();findText("Unlock Club · R$ 149")
    failPrompt=true;click("Unlock Club · R$ 149");assert(shop.ClubCheckout.Active and #prompts==promptsBefore)
    failPrompt=false
    advance(0.3);click("Unlock Club · R$ 149")
    data.club=table.clone(data.club);data.club.ownsPass=true;publish()
    serverCheckout(true)
    assert(shop.ClubCheckout.Text~=t("Verifying with Roblox…"),"A late completion hides an already verified purchase")
    assert(priceCalls>=3,"The retry did not request fresh Roblox product information")
    local staleRequests=#requests;advance(13)
    assert(#requests>staleRequests and requests[#requests][1]=='Sync','A stale client never refreshes the authoritative snapshot')
    publish()
    local missing={};for value in pairs(untranslated) do table.insert(missing,value) end;table.sort(missing)
    if #missing>0 then for _,value in ipairs(missing) do print('UNTRANSLATED: '..value) end end
    assert(#missing==0,"Untranslated game captions: "..#missing)
    return {width=width,height=height,elements=views.main.elements,camera=views.main.camera,views=views,requests=#requests}
end
