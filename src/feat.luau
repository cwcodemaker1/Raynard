local function v5copy(t) local r={} for k,v in pairs(t or {}) do r[k]=type(v)=="table" and deepCopy(v) or v end return r end
local function v5array(t) local r={} for i,v in ipairs(t or {}) do r[i]=v end return r end

function Library:RegisterComponent(name,factory)
    assert(type(name)=="string" and name~="","component name required")
    assert(type(factory)=="function","component factory must be a function")
    self._components=self._components or {} self._components[name]=factory self:_Emit("ComponentRegistered",name,true) return self
end
function Library:UnregisterComponent(name) self._components=self._components or {} self._components[name]=nil return self end
function Library:GetComponents() self._components=self._components or {} local r={} for n in pairs(self._components) do table.insert(r,n) end table.sort(r) return r end
function Section:AddComponent(name,configuration) local f=self.App._components and self.App._components[name] assert(f,"Unknown component: "..tostring(name)) return f(self,configuration or {}) end

function Section:AddCustom(configuration)
    configuration=configuration or {} local app=self.App local state=configuration.Default
    local row=self:_Row(configuration.Height or 90)
    local container=create("Frame",{Parent=row,Size=UDim2.fromScale(1,1),BackgroundColor3=configuration.BackgroundColor or app.Config.Colors.Control,BackgroundTransparency=configuration.BackgroundTransparency or 0,BorderSizePixel=0,ClipsDescendants=configuration.ClipsDescendants==true})
    if configuration.Corner~=false then corner(container,configuration.Radius or app.Config.Radius.Control) end
    local kind=configuration.Kind or "Custom" local id=app:_MakeId(kind,configuration.Id) local c=self:_Control(id,kind,configuration.Text or kind,row,configuration)
    c.Container=container
    c._getter=function() return state end
    c._setter=function(v,silent) local p=state state=v if configuration.Render then app:_Callback(configuration.Render,container,state,c,self) end if not silent and p~=v then self:_Emit(c,configuration.EventType or (kind.."Changed"),v,p) app:_Callback(configuration.Callback,v,c) end return state end
    function c:Create(className,props) props=props or {} props.Parent=props.Parent or container return create(className,props) end
    function c:GetContainer() return container end
    function c:Emit(eventType,value,extra) app:_Emit(eventType or "CustomEvent",self.Id,value,extra) return self end
    if configuration.Build then local ok,res=pcall(configuration.Build,container,c,app,self) if ok then c.BuildResult=res else app:_Emit("CustomBuildError",c.Id,tostring(res)) end end
    if configuration.Render then app:_Callback(configuration.Render,container,state,c,self) end
    return app:_Register(c)
end
function Section:AddRawGui(configuration) configuration=configuration or {} configuration.Kind=configuration.Kind or "RawGui" return self:AddCustom(configuration) end

function Library:RegisterTheme(name,theme) self._themes=self._themes or {} self._themes[tostring(name)]=deepCopy(theme or {}) return self end
function Library:GetTheme(name) self._themes=self._themes or {} local t=self._themes[tostring(name)] return t and deepCopy(t) or nil end
function Library:GetThemes() self._themes=self._themes or {} local r={} for n in pairs(self._themes) do table.insert(r,n) end table.sort(r) return r end
function Library:ApplyTheme(nameOrTheme)
    local theme=type(nameOrTheme)=="string" and self:GetTheme(nameOrTheme) or nameOrTheme
    if type(theme)~="table" then return false end
    local oldColors=deepCopy(self.Config.Colors or {})
    self.Config=deepMerge(self.Config,theme)
    local newColors=self.Config.Colors or {}
    local function mapColor(color)
        if typeof(color)~="Color3" then return color end
        for name,oldColor in pairs(oldColors) do
            if typeof(oldColor)=="Color3" and color==oldColor and typeof(newColors[name])=="Color3" then return newColors[name] end
        end
        return color
    end
    if self.Gui then
        for _,object in ipairs(self.Gui:GetDescendants()) do
            if object:IsA("GuiObject") then
                object.BackgroundColor3=mapColor(object.BackgroundColor3)
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then object.TextColor3=mapColor(object.TextColor3) end
                if object:IsA("ImageLabel") or object:IsA("ImageButton") then object.ImageColor3=mapColor(object.ImageColor3) end
            elseif object:IsA("UIStroke") then
                object.Color=mapColor(object.Color)
            end
        end
    end
    self:_Emit("ThemeApplied","Theme",nameOrTheme)
    return true
end
function Library:SetAccent(color)
    if typeof(color)=="Color3" then
        self:ApplyTheme({Colors={Accent=color}})
        self:_Emit("AccentChanged","Theme",color)
    end
    return self
end
function Library:SetUIScale(scale) scale=clamp(tonumber(scale) or 1,.5,2.5) local s=self.Main:FindFirstChild("RaynardScale") if not s then s=Instance.new("UIScale") s.Name="RaynardScale" s.Parent=self.Main end s.Scale=scale self._uiScale=scale return self end
function Library:GetUIScale() return self._uiScale or 1 end
function Library:SetReducedMotion(v) self._reducedMotion=v==true self.Config.Animation.Enabled=not self._reducedMotion return self end
function Library:GetReducedMotion() return self._reducedMotion==true end
function Library:SetTextScale(scale) scale=clamp(tonumber(scale) or 1,.6,2) for _,o in ipairs(self.Gui:GetDescendants()) do if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then local b=o:GetAttribute("RaynardBaseText") or o.TextSize o:SetAttribute("RaynardBaseText",b) o.TextSize=math.max(8,math.floor(b*scale+.5)) end end self._textScale=scale return self end
function Library:GetTextScale() return self._textScale or 1 end

function Library:Snapshot(name) self._history=self._history or {} self._redo={} table.insert(self._history,{Name=name or "Snapshot",State=self:ExportState()}) while #self._history>(self.Config.HistoryLimit or 50) do table.remove(self._history,1) end return self end
function Library:Undo() self._history=self._history or {} self._redo=self._redo or {} local s=table.remove(self._history) if not s then return false end table.insert(self._redo,{Name="Redo",State=self:ExportState()}) self:ImportState(s.State,true) return true end
function Library:Redo() self._history=self._history or {} self._redo=self._redo or {} local s=table.remove(self._redo) if not s then return false end table.insert(self._history,{Name="Undo",State=self:ExportState()}) self:ImportState(s.State,true) return true end
function Library:ClearHistory() self._history={} self._redo={} return self end
function Library:GetHistory() return v5array(self._history or {}) end
function Library:SetDefaultState(state) self._defaultState=deepCopy(state or self:ExportState()) return self end
function Library:ResetState(silent) if not self._defaultState then return false end self:ImportState(deepCopy(self._defaultState),silent) return true end
function Library:WatchControl(id,fn) return self.Feedback:Connect(function(p) if p.Id==id then fn(p.Value,p) end end) end
function Library:BindControls(source,target,transform) self._bindings=self._bindings or {} local k=tostring(source)..">"..tostring(target) if self._bindings[k] then self._bindings[k]:Disconnect() end self._bindings[k]=self:WatchControl(source,function(v,p) if transform then local ok,r=pcall(transform,v,p) if ok then v=r end end self:SetValue(target,v,true) end) return self._bindings[k] end
function Library:UnbindControls(source,target) local k=tostring(source)..">"..tostring(target) local c=self._bindings and self._bindings[k] if c then c:Disconnect() self._bindings[k]=nil end return self end
function Library:AddDependency(source,target,configuration) configuration=configuration or {} local c=self:GetControl(target) if not c then return nil end local function apply(v) local pass=configuration.Predicate and configuration.Predicate(v) or (configuration.Equals~=nil and v==configuration.Equals or v==true) if configuration.Mode=="Disabled" then c:SetDisabled(not pass) else c:SetVisible(pass) end end apply(self:GetValue(source)) return self:WatchControl(source,apply) end
function Library:CreateGroup(name,ids) self._groups=self._groups or {} local g={App=self,Name=tostring(name),Ids=v5array(ids)} function g:Add(id)table.insert(self.Ids,id)return self end function g:SetDisabled(v)for _,id in ipairs(self.Ids)do local c=self.App:GetControl(id)if c then c:SetDisabled(v)end end return self end function g:SetVisible(v)for _,id in ipairs(self.Ids)do local c=self.App:GetControl(id)if c then c:SetVisible(v)end end return self end function g:GetValues()local r={}for _,id in ipairs(self.Ids)do r[id]=self.App:GetValue(id)end return r end self._groups[g.Name]=g return g end
function Library:GetGroup(name) return self._groups and self._groups[tostring(name)] or nil end
function Library:RegisterLocale(code,data) self._locales=self._locales or {} self._locales[tostring(code)]=deepCopy(data or {}) return self end
function Library:SetLocale(code) self._locale=tostring(code) self:_Emit("LocaleChanged","Locale",self._locale) return self end
function Library:GetLocale() return self._locale end
function Library:Translate(key,fallback) local l=self._locales and self._locales[self._locale or ""] return l and l[key]~=nil and tostring(l[key]) or tostring(fallback or key) end
function Library:GetViewportSize() local c=workspace.CurrentCamera return c and c.ViewportSize or Vector2.zero end
function Library:FocusControl(id) local c=self:GetControl(id) if not c or not c.Root then return false end for _,d in ipairs(c.Root:GetDescendants()) do if d:IsA("TextBox") then d:CaptureFocus() return true end end return false end

function Control:SetMetadata(k,v) self._metadata=self._metadata or {} self._metadata[k]=v return self end
function Control:GetMetadata(k) self._metadata=self._metadata or {} return k~=nil and self._metadata[k] or self._metadata end
function Control:AddTag(t) self._tags=self._tags or {} self._tags[tostring(t)]=true return self end
function Control:RemoveTag(t) if self._tags then self._tags[tostring(t)]=nil end return self end
function Control:HasTag(t) return self._tags and self._tags[tostring(t)]==true or false end
function Control:GetTags() local r={} for t in pairs(self._tags or {}) do table.insert(r,t) end table.sort(r) return r end
function Control:Flash(color,duration) if self.Root and self.Root:IsA("GuiObject") then local old=self.Root.BackgroundColor3 self.Root.BackgroundColor3=color or self.App.Config.Colors.Accent task.delay(duration or .15,function()if self.Root and self.Root.Parent then self.Root.BackgroundColor3=old end end)end return self end
function Control:SetZIndex(z) if self.Root then if self.Root:IsA("GuiObject")then self.Root.ZIndex=z end for _,d in ipairs(self.Root:GetDescendants())do if d:IsA("GuiObject")then d.ZIndex=z end end end return self end

function Section:AddColumns(configuration)
    configuration=configuration or {} local app=self.App local n=math.max(1,math.floor(configuration.Columns or 2)) local row=self:_Row(configuration.Height or 180) local h=create("Frame",{Parent=row,Size=UDim2.fromScale(1,1),BackgroundTransparency=1}) create("UIListLayout",{Parent=h,FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,configuration.Spacing or 8)}) local id=app:_MakeId("Columns",configuration.Id) local c=self:_Control(id,"Columns",configuration.Text or "Columns",row,configuration) c.Columns={}
    for i=1,n do local f=create("Frame",{Parent=h,Size=UDim2.new(1/n,-8,1,0),BackgroundColor3=app.Config.Colors.Control,BorderSizePixel=0})corner(f,app.Config.Radius.Control)create("UIListLayout",{Parent=f,Padding=UDim.new(0,6)})create("UIPadding",{Parent=f,PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)})local p=setmetatable({App=app,Tab=self.Tab,Name="Column"..i,Id=id.."_"..i,Frame=f,Header=nil,Controls={},Collapsible=false,Collapsed=false},Section)c.Columns[i]=p local b=configuration.Builders and configuration.Builders[i]if b then app:_Callback(b,p,i,c)end end
    c._getter=function()return c.Columns end function c:GetColumn(i)return self.Columns[i]end return app:_Register(c)
end
function Section:AddTwoColumn(configuration) configuration=configuration or {} configuration.Columns=2 return self:AddColumns(configuration) end
function Section:AddCard(configuration) configuration=configuration or {} configuration.Kind="Card" configuration.Height=configuration.Height or 120 return self:AddCustom(configuration) end
function Section:AddPanel(configuration) configuration=configuration or {} configuration.Kind="Panel" return self:AddCard(configuration) end
function Section:AddGroupBox(configuration) configuration=configuration or {} configuration.Kind="GroupBox" return self:AddCard(configuration) end
function Section:AddScrollArea(configuration) configuration=configuration or {} configuration.Kind="ScrollArea" configuration.Height=configuration.Height or 220 return self:AddCustom(configuration) end
function Section:AddToolbar(configuration) configuration=configuration or {} local c=self:AddButtonGroup(configuration) c.Kind="Toolbar" return c end

function Section:AddDualList(configuration)
    configuration=configuration or {} local selected=v5array(configuration.Selected or configuration.Default or {}) local available=v5array(configuration.Items or {}) local c=self:AddMultiDropdown({Id=configuration.Id,Text=configuration.Text or "Transfer",Options=available,Default=selected,Height=configuration.Height,Callback=configuration.Callback}) c.Kind="DualList" function c:SetAvailable(v)self:SetOptions(v,true)return self end return c
end
function Section:AddTransferList(configuration) local c=self:AddDualList(configuration)c.Kind="TransferList"return c end
function Section:AddReorderList(configuration) configuration=configuration or {} local items=v5array(configuration.Items or {}) local c=self:AddList({Id=configuration.Id,Text=configuration.Text or "Reorder",Items=items,Height=configuration.Height,Callback=configuration.Callback}) c.Kind="ReorderList" function c:Move(fromIndex,toIndex)local a=self:GetItems()fromIndex=clamp(math.floor(fromIndex),1,#a)toIndex=clamp(math.floor(toIndex),1,#a)local item=table.remove(a,fromIndex)table.insert(a,toIndex,item)self:SetItems(a,true)self.App:_Emit("ReorderChanged",self.Id,a)return self end function c:MoveUp(i)return self:Move(i,i-1)end function c:MoveDown(i)return self:Move(i,i+1)end return c end
function Section:AddGridSelect(configuration) configuration=configuration or {} local c=self:AddSegmented({Id=configuration.Id,Text=configuration.Text or "Grid select",Options=configuration.Items or configuration.Options or {},Default=configuration.Default,Callback=configuration.Callback,Height=configuration.Height})c.Kind="GridSelect"return c end
function Section:AddCardSelect(configuration)local c=self:AddGridSelect(configuration)c.Kind="CardSelect"return c end
function Section:AddImageSelect(configuration) configuration=configuration or {} local c=self:AddList({Id=configuration.Id,Text=configuration.Text or "Images",Items=configuration.Items or {},Height=configuration.Height or 220,Display=function(v)return type(v)=="table" and tostring(v.Name or v.Text or v.Image)or tostring(v)end,Callback=configuration.Callback})c.Kind="ImageSelect"return c end
function Section:AddImageGallery(configuration)local c=self:AddImageSelect(configuration)c.Kind="ImageGallery"return c end

function Section:AddCFrameInput(configuration)
    configuration=configuration or {} local value=configuration.Default or CFrame.new() local text=configuration.Text or "CFrame" local c=self:AddTextbox({Id=configuration.Id,Text=text,Default="0, 0, 0, 0, 0, 0",Placeholder="x, y, z, rx, ry, rz",Callback=function(s,ctrl)local a={}for n in tostring(s):gmatch("[-+]?[%d%.]+")do table.insert(a,tonumber(n))end if #a>=6 then value=CFrame.new(a[1],a[2],a[3])*CFrame.Angles(math.rad(a[4]),math.rad(a[5]),math.rad(a[6])) if configuration.Callback then configuration.Callback(value,ctrl)end end end})c.Kind="CFrameInput"local old=c._setter c._getter=function()return value end c._setter=function(v,silent)if typeof(v)=="CFrame"then value=v local x,y,z=v.Position.X,v.Position.Y,v.Position.Z local rx,ry,rz=v:ToOrientation()old(string.format("%g, %g, %g, %g, %g, %g",x,y,z,math.deg(rx),math.deg(ry),math.deg(rz)),silent)end return value end return c
end
function Section:AddNumberRangeInput(configuration) configuration=configuration or {} local d=configuration.Default or NumberRange.new(0,1) local c=self:AddRangeSlider({Id=configuration.Id,Text=configuration.Text or "Range",Min=configuration.Min or 0,Max=configuration.Max or 100,Low=d.Min,High=d.Max,Step=configuration.Step,Callback=configuration.Callback})c.Kind="NumberRangeInput"local old=c._getter c._getter=function()local v=old()if type(v)=="table"then return NumberRange.new(v.Low or v[1] or 0,v.High or v[2] or 0)end return v end return c end
function Section:AddEditableList(configuration) configuration=configuration or {} local c=self:AddList(configuration)c.Kind="EditableList"function c:Insert(item,index)local a=self:GetItems()table.insert(a,index or (#a+1),item)self:SetItems(a,true)return self end function c:RemoveAt(index)local a=self:GetItems()table.remove(a,index)self:SetItems(a,true)return self end function c:Replace(index,item)local a=self:GetItems()a[index]=item self:SetItems(a,true)return self end return c end
function Section:AddArrayEditor(configuration)local c=self:AddEditableList(configuration)c.Kind="ArrayEditor"return c end
function Section:AddEditableTable(configuration)configuration=configuration or {}local c=self:AddTable(configuration)c.Kind="EditableTable"function c:EditCell(row,key,value)local rows=self:GetRows()if type(rows[row])=="table"then rows[row][key]=value self:SetRows(rows)return true end return false end function c:AddRow(v)local r=self:GetRows()table.insert(r,v)self:SetRows(r)return self end function c:RemoveRow(i)local r=self:GetRows()table.remove(r,i)self:SetRows(r)return self end return c end
function Section:AddSortableTable(configuration)configuration=configuration or {}local c=self:AddTable(configuration)c.Kind="SortableTable"function c:SortBy(key,ascending)local r=self:GetRows()table.sort(r,function(a,b)local av=type(a)=="table"and a[key]or a local bv=type(b)=="table"and b[key]or b if ascending==false then return tostring(av)>tostring(bv)end return tostring(av)<tostring(bv)end)self:SetRows(r)return self end return c end
function Section:AddFilterableTable(configuration)
    configuration=configuration or {}
    local source=configuration.Rows or {}
    local c=self:AddTable(configuration)
    c.Kind="FilterableTable"
    c.SourceRows=source
    local function rowText(row)
        if type(row)~="table" then return tostring(row) end
        local parts={}
        for k,v in pairs(row) do
            parts[#parts+1]=tostring(k)
            parts[#parts+1]=tostring(v)
        end
        return table.concat(parts," ")
    end
    function c:Filter(q)
        q=string.lower(tostring(q or ""))
        local r={}
        for _,row in ipairs(self.SourceRows) do
            if q=="" or string.find(string.lower(rowText(row)),q,1,true) then r[#r+1]=row end
        end
        self:SetRows(r)
        return self
    end
    return c
end
function Section:AddQueue(configuration)configuration=configuration or {}local c=self:AddList(configuration)c.Kind="Queue"function c:Enqueue(v)local a=self:GetItems()table.insert(a,v)self:SetItems(a,true)return self end function c:Dequeue()local a=self:GetItems()local v=table.remove(a,1)self:SetItems(a,true)return v end function c:Peek()return self:GetItems()[1]end return c end
function Section:AddLeaderboard(configuration)configuration=configuration or {}local rows=configuration.Rows or {}table.sort(rows,function(a,b)return(type(a)=="table"and tonumber(a.Score)or 0)>(type(b)=="table"and tonumber(b.Score)or 0)end)for i,r in ipairs(rows)do if type(r)=="table"then r.Rank=i end end configuration.Rows=rows configuration.Columns=configuration.Columns or {{Name="#",Key="Rank"},{Name="Name",Key="Name"},{Name="Score",Key="Score"}}local c=self:AddTable(configuration)c.Kind="Leaderboard"return c end
function Section:AddKanban(configuration)configuration=configuration or {}local cols=configuration.Columns or {{Name="Todo",Items={}},{Name="Doing",Items={}},{Name="Done",Items={}}}local builders={}for i,col in ipairs(cols)do builders[i]=function(s)s:AddHeader(col.Name or tostring(i))for _,item in ipairs(col.Items or {})do s:AddLabel(tostring(item))end end end local c=self:AddColumns({Id=configuration.Id,Text=configuration.Text,Columns=#cols,Builders=builders,Height=configuration.Height or 260})c.Kind="Kanban"return c end

function Section:AddLiveValue(configuration)configuration=configuration or {}local getter=configuration.Getter or function()return configuration.Default end local c=self:AddKeyValue({Id=configuration.Id,Text=configuration.Text or "Live",Default=configuration.Default})c.Kind="LiveValue"local alive=true task.spawn(function()while alive and c.Root and c.Root.Parent do local ok,v=pcall(getter,c)if ok then c:Set(v,true)end task.wait(math.max(.05,tonumber(configuration.Interval)or .25))end end)local old=c.Destroy function c:Destroy()alive=false old(self)end return c end
function Section:AddPlayerCount(configuration)configuration=configuration or {}configuration.Text=configuration.Text or "Players"configuration.Getter=function()return #Players:GetPlayers()end local c=self:AddLiveValue(configuration)c.Kind="PlayerCount"return c end
function Section:AddServerUptime(configuration)configuration=configuration or {}local start=os.clock()configuration.Text=configuration.Text or "Uptime"configuration.Getter=function()local s=math.floor(os.clock()-start)return string.format("%02d:%02d:%02d",math.floor(s/3600),math.floor(s%3600/60),s%60)end local c=self:AddLiveValue(configuration)c.Kind="ServerUptime"return c end
function Section:AddFrameTime(configuration)configuration=configuration or {}local dt=0 configuration.Text=configuration.Text or "Frame time"configuration.Getter=function()return string.format("%.2f ms",dt*1000)end local c=self:AddLiveValue(configuration)c.Kind="FrameTime"local con=RunService.RenderStepped:Connect(function(v)dt=v end)table.insert(c._connections,con)return c end
function Section:AddPingMeter(configuration)configuration=configuration or {}local Stats=game:GetService("Stats")configuration.Text=configuration.Text or "Ping"configuration.Getter=function()local ok,v=pcall(function()return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()end)return ok and v or "N/A"end local c=self:AddLiveValue(configuration)c.Kind="PingMeter"return c end
function Section:AddPropertyWatcher(configuration)configuration=configuration or {}local i=configuration.Instance local p=configuration.Property or "Name"configuration.Text=configuration.Text or p configuration.Getter=function()if not i then return "<nil>"end local ok,v=pcall(function()return i[p]end)return ok and tostring(v)or "<error>"end local c=self:AddLiveValue(configuration)c.Kind="PropertyWatcher"return c end

function Section:AddThemeSelector(configuration)configuration=configuration or {}configuration.Options=configuration.Options or self.App:GetThemes()local cb=configuration.Callback configuration.Callback=function(v,c)self.App:ApplyTheme(v)if cb then cb(v,c)end end local c=self:AddDropdown(configuration)c.Kind="ThemeSelector"return c end
function Section:AddPresetSelector(configuration)configuration=configuration or {}configuration.Options=configuration.Options or self.App:GetPresets()local cb=configuration.Callback configuration.Callback=function(v,c)self.App:ApplyPreset(v)if cb then cb(v,c)end end local c=self:AddDropdown(configuration)c.Kind="PresetSelector"return c end
function Section:AddUIScaleSlider(configuration)configuration=configuration or {}configuration.Min=configuration.Min or .5 configuration.Max=configuration.Max or 2 configuration.Step=configuration.Step or .05 configuration.Default=configuration.Default or self.App:GetUIScale()configuration.Text=configuration.Text or "UI scale"local cb=configuration.Callback configuration.Callback=function(v,c)self.App:SetUIScale(v)if cb then cb(v,c)end end local c=self:AddSlider(configuration)c.Kind="UIScaleSlider"return c end
function Section:AddTextScaleSlider(configuration)configuration=configuration or {}configuration.Min=configuration.Min or .7 configuration.Max=configuration.Max or 1.6 configuration.Step=configuration.Step or .05 configuration.Default=configuration.Default or self.App:GetTextScale()configuration.Text=configuration.Text or "Text scale"local cb=configuration.Callback configuration.Callback=function(v,c)self.App:SetTextScale(v)if cb then cb(v,c)end end local c=self:AddSlider(configuration)c.Kind="TextScaleSlider"return c end
function Section:AddReducedMotionToggle(configuration)configuration=configuration or {}configuration.Text=configuration.Text or "Reduced motion"configuration.Default=self.App:GetReducedMotion()local cb=configuration.Callback configuration.Callback=function(v,c)self.App:SetReducedMotion(v)if cb then cb(v,c)end end local c=self:AddToggle(configuration)c.Kind="ReducedMotionToggle"return c end
function Section:AddUndoButton(configuration)configuration=configuration or {}configuration.Text=configuration.Text or "Undo"configuration.Callback=function()self.App:Undo()end local c=self:AddButton(configuration)c.Kind="UndoButton"return c end
function Section:AddRedoButton(configuration)configuration=configuration or {}configuration.Text=configuration.Text or "Redo"configuration.Callback=function()self.App:Redo()end local c=self:AddButton(configuration)c.Kind="RedoButton"return c end
function Section:AddResetButton(configuration)configuration=configuration or {}configuration.Text=configuration.Text or "Reset"configuration.Callback=function()self.App:ResetState(false)end local c=self:AddButton(configuration)c.Kind="ResetButton"return c end
function Section:AddCommandPalette(configuration)configuration=configuration or {}configuration.Options=self.App:GetCommands()configuration.Display=function(v)return v.Name..(v.Description~=""and(" - "..v.Description)or"")end local cb=configuration.Callback configuration.Callback=function(v,c)if type(v)=="table"then self.App:RunCommand(v.Name)end if cb then cb(v,c)end end local c=self:AddSearchDropdown(configuration)c.Kind="CommandPalette"return c end
function Section:AddControlSearch(configuration)configuration=configuration or {}configuration.Options=self.App:FindControls("")configuration.Display=function(v)return v.Id.." ["..v.Kind.."]"end local c=self:AddSearchDropdown(configuration)c.Kind="ControlSearch"return c end
function Section:AddStateDebugger(configuration)configuration=configuration or {}configuration.Text=configuration.Text or "State"configuration.Code=tostring(self.App:ExportState())local c=self:AddCodeBox({Id=configuration.Id,Text=configuration.Text,Default=configuration.Code,Height=configuration.Height or 160})c.Kind="StateDebugger"c:SetDisabled(true)return c end

function Section:AddPlayerMultiSelect(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or Players:GetPlayers()
    local c=self:AddMultiDropdown(configuration) c.Kind="PlayerMultiSelect" return c
end
function Section:AddTeamSelector(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or game:GetService("Teams"):GetTeams()
    local c=self:AddDropdown(configuration) c.Kind="TeamSelector" return c
end
function Section:AddTeamMultiSelect(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or game:GetService("Teams"):GetTeams()
    local c=self:AddMultiDropdown(configuration) c.Kind="TeamMultiSelect" return c
end
function Section:AddInstanceSelector(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or configuration.Instances or {}
    configuration.Display=configuration.Display or function(v)return typeof(v)=="Instance" and v:GetFullName() or tostring(v)end
    local c=self:AddDropdown(configuration)c.Kind="InstanceSelector"return c
end
function Section:AddInstanceMultiSelect(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or configuration.Instances or {}
    local c=self:AddMultiDropdown(configuration)c.Kind="InstanceMultiSelect"return c
end
function Section:AddMonthSelector(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or {"January","February","March","April","May","June","July","August","September","October","November","December"}
    local c=self:AddDropdown(configuration)c.Kind="MonthSelector"return c
end
function Section:AddDaySelector(configuration)
    configuration=configuration or {} if not configuration.Options then configuration.Options={} for i=1,31 do configuration.Options[i]=i end end
    local c=self:AddDropdown(configuration)c.Kind="DaySelector"return c
end
function Section:AddYearSelector(configuration)
    configuration=configuration or {} if not configuration.Options then configuration.Options={} for y=configuration.StartYear or 2000,configuration.EndYear or 2050 do table.insert(configuration.Options,y)end end
    local c=self:AddDropdown(configuration)c.Kind="YearSelector"return c
end
function Section:AddTimezoneSelector(configuration)
    configuration=configuration or {} if not configuration.Options then configuration.Options={} for h=-12,14 do table.insert(configuration.Options,string.format("UTC%+d",h))end end
    local c=self:AddDropdown(configuration)c.Kind="TimezoneSelector"return c
end
function Section:AddCountrySelector(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or configuration.Countries or {"United States","Canada","Mexico","United Kingdom","France","Germany","Spain","Italy","Brazil","Japan","South Korea","China","India","Australia"}
    local c=self:AddSearchDropdown(configuration)c.Kind="CountrySelector"return c
end
function Section:AddEmojiPicker(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or configuration.Items or {"😀","😃","😎","🤖","🔥","✅","❌","⭐","❤️","⚡","🎮","🛠️"}
    local c=self:AddSegmented(configuration)c.Kind="EmojiPicker"return c
end
function Section:AddSymbolPicker(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or configuration.Items or {"✓","×","+","−","→","←","↑","↓","★","●","◆","■","▲"}
    local c=self:AddSegmented(configuration)c.Kind="SymbolPicker"return c
end
function Section:AddConfirmButton(configuration)
    configuration=configuration or {} local app=self.App local callback=configuration.Callback
    local buttonConfig=deepCopy(configuration) buttonConfig.Callback=function() app:Confirm({Title=configuration.ConfirmTitle or configuration.Text or "Confirm",Text=configuration.ConfirmText or "Are you sure?",ConfirmText=configuration.YesText or "Confirm",CancelText=configuration.NoText or "Cancel",Callback=function(result)if result and callback then callback(result)end end}) end
    local c=self:AddButton(buttonConfig)c.Kind="ConfirmButton"return c
end
function Section:AddPromptButton(configuration)
    configuration=configuration or {} local app=self.App local callback=configuration.Callback
    local buttonConfig=deepCopy(configuration) buttonConfig.Callback=function() app:Prompt({Title=configuration.PromptTitle or configuration.Text or "Input",Text=configuration.PromptText or "Enter a value",Placeholder=configuration.Placeholder,Default=configuration.Default,Callback=function(result)if result~=nil and callback then callback(result)end end}) end
    local c=self:AddButton(buttonConfig)c.Kind="PromptButton"return c
end
function Section:AddModalButton(configuration)local c=self:AddConfirmButton(configuration)c.Kind="ModalButton"return c end
function Section:AddDropdownButton(configuration)
    configuration=configuration or {} configuration.Options=configuration.Options or configuration.Actions or {}
    configuration.Display=configuration.Display or function(v)return type(v)=="table" and tostring(v.Text or v.Name or v.Id or "Action") or tostring(v)end
    local user=configuration.Callback configuration.Callback=function(action,c)if type(action)=="table"and type(action.Callback)=="function"then action.Callback(action,c)end if user then user(action,c)end end
    local c=self:AddDropdown(configuration)c.Kind="DropdownButton"return c
end

local V5FeatureSpecs = {
    MultilineBox={Target="AddTextbox",Defaults={MultiLine=true,Height=130}},
    IntegerInput={Target="AddNumberbox",Defaults={}},
    FloatInput={Target="AddNumberbox",Defaults={}},
    PositiveNumberInput={Target="AddNumberbox",Defaults={Min=0}},
    HexInput={Target="AddTextbox",Defaults={}},
    BinaryInput={Target="AddTextbox",Defaults={}},
    AssetIdInput={Target="AddNumberbox",Defaults={Min=0}},
    UserIdInput={Target="AddNumberbox",Defaults={Min=0}},
    UsernameInput={Target="AddTextbox",Defaults={}},
    PhoneInput={Target="AddTextbox",Defaults={}},
    CurrencyInput={Target="AddNumberbox",Defaults={}},
    DistanceInput={Target="AddNumberbox",Defaults={}},
    SpeedInput={Target="AddNumberbox",Defaults={}},
    AngleInput={Target="AddNumberbox",Defaults={}},
    DegreesInput={Target="AddNumberbox",Defaults={}},
    RadiansInput={Target="AddNumberbox",Defaults={}},
    DurationInput={Target="AddNumberbox",Defaults={Min=0}},
    MaskedInput={Target="AddPasswordBox",Defaults={}},
    PINInput={Target="AddNumberbox",Defaults={Min=0}},
    OTPInput={Target="AddNumberbox",Defaults={Min=0}},
    PatternInput={Target="AddTextbox",Defaults={}},
    TransparencyInput={Target="AddSlider",Defaults={Min=0,Max=1,Step=0.01}},
    CornerRadiusInput={Target="AddSlider",Defaults={Min=0,Max=50}},
    StrokeWidthInput={Target="AddSlider",Defaults={Min=0,Max=10,Step=0.1}},
    LatitudeInput={Target="AddSlider",Defaults={Min=-90,Max=90,Step=0.0001}},
    LongitudeInput={Target="AddSlider",Defaults={Min=-180,Max=180,Step=0.0001}},
    VolumeInput={Target="AddSlider",Defaults={Min=0,Max=1,Step=0.01}},
    BrightnessInput={Target="AddSlider",Defaults={Min=0,Max=1,Step=0.01}},
    OpacityInput={Target="AddSlider",Defaults={Min=0,Max=1,Step=0.01}},
    ZoomInput={Target="AddSlider",Defaults={Min=0.1,Max=10,Step=0.1}},
    FOVInput={Target="AddSlider",Defaults={Min=1,Max=120,Step=1}},
    SensitivityInput={Target="AddSlider",Defaults={Min=0.01,Max=10,Step=0.01}},
    DragValue={Target="AddSlider",Defaults={}},
    NudgeControl={Target="AddStepper",Defaults={}},
    Autocomplete={Target="AddSearchDropdown",Defaults={}},
    Combobox={Target="AddSearchDropdown",Defaults={}},
    SortableList={Target="AddReorderList",Defaults={}},
    CardSelect={Target="AddGridSelect",Defaults={}},
    PlayerMultiSelect={Target="AddMultiDropdown",Defaults={}},
    TeamSelector={Target="AddDropdown",Defaults={}},
    TeamMultiSelect={Target="AddMultiDropdown",Defaults={}},
    EnumMultiSelect={Target="AddMultiDropdown",Defaults={}},
    InstanceSelector={Target="AddDropdown",Defaults={}},
    InstanceMultiSelect={Target="AddMultiDropdown",Defaults={}},
    KeySelector={Target="AddEnumSelector",Defaults={Enum=Enum.KeyCode}},
    MouseButtonSelector={Target="AddDropdown",Defaults={}},
    InputTypeSelector={Target="AddEnumSelector",Defaults={Enum=Enum.UserInputType}},
    MonthSelector={Target="AddDropdown",Defaults={}},
    DaySelector={Target="AddDropdown",Defaults={}},
    YearSelector={Target="AddDropdown",Defaults={}},
    TimezoneSelector={Target="AddDropdown",Defaults={}},
    CountrySelector={Target="AddSearchDropdown",Defaults={}},
    MaterialSelector={Target="AddEnumSelector",Defaults={Enum=Enum.Material}},
    BrickColorSelector={Target="AddDropdown",Defaults={}},
    DataGrid={Target="AddTable",Defaults={}},
    TableEditor={Target="AddEditableTable",Defaults={}},
    ArrayEditor={Target="AddEditableList",Defaults={}},
    DictionaryEditor={Target="AddEditableList",Defaults={}},
    Inspector={Target="AddPropertyGrid",Defaults={}},
    HistoryViewer={Target="AddList",Defaults={}},
    EventLog={Target="AddLogConsole",Defaults={}},
    TaskList={Target="AddChecklist",Defaults={}},
    Scoreboard={Target="AddLeaderboard",Defaults={}},
    InventoryGrid={Target="AddGridSelect",Defaults={}},
    SlotGrid={Target="AddGridSelect",Defaults={}},
    Matrix={Target="AddTable",Defaults={}},
    LabeledValue={Target="AddKeyValue",Defaults={}},
    Timestamp={Target="AddKeyValue",Defaults={}},
    DurationLabel={Target="AddKeyValue",Defaults={}},
    DeltaStat={Target="AddStatCard",Defaults={}},
    ReadOnlyField={Target="AddKeyValue",Defaults={}},
    ObjectPath={Target="AddKeyValue",Defaults={}},
    DeviceIndicator={Target="AddKeyValue",Defaults={}},
    ViewportSize={Target="AddKeyValue",Defaults={}},
    KeyCodeViewer={Target="AddKeyValue",Defaults={}},
    Hero={Target="AddCallout",Defaults={}},
    ProfileCard={Target="AddPlayerCard",Defaults={}},
    AvatarStack={Target="AddPlayerList",Defaults={Height=120}},
    IconLabel={Target="AddLabel",Defaults={}},
    Pill={Target="AddStatus",Defaults={}},
    Quote={Target="AddCallout",Defaults={}},
    Alert={Target="AddCallout",Defaults={}},
    EmptyState={Target="AddCallout",Defaults={}},
    CodePreview={Target="AddCodeBox",Defaults={}},
    JSONViewer={Target="AddCodeBox",Defaults={}},
    LuaTableViewer={Target="AddCodeBox",Defaults={}},
    StatusLight={Target="AddStatus",Defaults={}},
    TrafficLight={Target="AddStatus",Defaults={}},
    BatteryIndicator={Target="AddMeter",Defaults={Min=0,Max=100}},
    SignalStrength={Target="AddMeter",Defaults={Min=0,Max=5}},
    HealthBar={Target="AddProgress",Defaults={}},
    XPBar={Target="AddProgress",Defaults={}},
    StepIndicator={Target="AddPagination",Defaults={}},
    CircularGauge={Target="AddMeter",Defaults={}},
    ProgressRing={Target="AddMeter",Defaults={}},
    Marquee={Target="AddLabel",Defaults={}},
    Ticker={Target="AddLabel",Defaults={}},
    Carousel={Target="AddImage",Defaults={}},
    ViewportPart={Target="AddViewportModel",Defaults={}},
    ViewportInstance={Target="AddViewportModel",Defaults={}},
    MaterialPreview={Target="AddViewportModel",Defaults={}},
    PaletteEditor={Target="AddColorSwatches",Defaults={}},
    ColorHistory={Target="AddColorSwatches",Defaults={}},
    IconPicker={Target="AddImageSelect",Defaults={}},
    EmojiPicker={Target="AddGridSelect",Defaults={}},
    SymbolPicker={Target="AddGridSelect",Defaults={}},
    AreaChart={Target="AddLineChart",Defaults={}},
    Histogram={Target="AddBarChart",Defaults={}},
    MiniBarChart={Target="AddBarChart",Defaults={Height=90}},
    GaugeChart={Target="AddMeter",Defaults={}},
    RadialProgress={Target="AddMeter",Defaults={}},
    BulletChart={Target="AddProgress",Defaults={}},
    DonutChart={Target="AddBarChart",Defaults={}},
    PieChart={Target="AddBarChart",Defaults={}},
    StackedBarChart={Target="AddBarChart",Defaults={}},
    ScatterPlot={Target="AddLineChart",Defaults={}},
    CurveEditor={Target="AddLineChart",Defaults={}},
    GradientEditor={Target="AddGradientPreview",Defaults={}},
    ThemePreview={Target="AddColorSwatches",Defaults={}},
    ResponsivePreview={Target="AddLiveValue",Defaults={}},
    SafeAreaIndicator={Target="AddKeyValue",Defaults={}},
    FocusTracker={Target="AddLiveValue",Defaults={}},
    DropdownButton={Target="AddDropdown",Defaults={}},
    SplitButton={Target="AddButtonGroup",Defaults={}},
    ContextMenuButton={Target="AddDropdown",Defaults={}},
    ConfirmButton={Target="AddButton",Defaults={}},
    PromptButton={Target="AddButton",Defaults={}},
    ModalButton={Target="AddButton",Defaults={}},
    Wizard={Target="AddMiniTabs",Defaults={}},
    NavigationList={Target="AddList",Defaults={}},
    PageHeader={Target="AddCallout",Defaults={}},
    SectionIndex={Target="AddList",Defaults={}},
    ShortcutList={Target="AddTable",Defaults={}},
    KeyboardTester={Target="AddKeybind",Defaults={}},
    MouseTester={Target="AddKeybind",Defaults={}},
    InputMonitor={Target="AddLogConsole",Defaults={}},
    EditableLabel={Target="AddTextbox",Defaults={}},
    InlineEdit={Target="AddTextbox",Defaults={}},
    CopyField={Target="AddTextbox",Defaults={}},
    SearchResults={Target="AddSearchableList",Defaults={}},
    FilterChips={Target="AddChipGroup",Defaults={}},
    SortSelector={Target="AddDropdown",Defaults={}},
    PageSizeSelector={Target="AddDropdown",Defaults={Options={10,25,50,100,250}}},
    AccentPicker={Target="AddColorPicker",Defaults={}},
    HighContrastToggle={Target="AddToggle",Defaults={}},
    ControlManager={Target="AddTable",Defaults={}},
    AttributeViewer={Target="AddPropertyGrid",Defaults={}},
    AttributeEditor={Target="AddPropertyGrid",Defaults={}},
    TagViewer={Target="AddList",Defaults={}},
    EventCounter={Target="AddKeyValue",Defaults={}},
    HeartbeatIndicator={Target="AddStatus",Defaults={}},
    LiveText={Target="AddLiveValue",Defaults={}},
    LiveNumber={Target="AddLiveValue",Defaults={}},
    LiveProgress={Target="AddProgress",Defaults={}},
    PollingLabel={Target="AddLiveValue",Defaults={}},
    PriorityInput={Target="AddDropdown",Defaults={Options={"Low","Normal","High","Critical"}}},
    AlignmentSelector={Target="AddDropdown",Defaults={Options={"Left","Center","Right"}}},
    OrientationSelector={Target="AddDropdown",Defaults={Options={"Horizontal","Vertical"}}},
    DirectionSelector={Target="AddDropdown",Defaults={Options={"Up","Down","Left","Right","Forward","Backward"}}},
    YesNoSelector={Target="AddDropdown",Defaults={Options={"Yes","No"}}},
    OnOffSelector={Target="AddDropdown",Defaults={Options={"On","Off"}}},
    BooleanSelector={Target="AddDropdown",Defaults={Options={true,false}}},
    PermissionSelector={Target="AddMultiDropdown",Defaults={Options={"Read","Write","Execute","Admin"}}},
    RoleSelector={Target="AddDropdown",Defaults={Options={"Viewer","Member","Moderator","Admin","Owner"}}},
    QualitySelector={Target="AddDropdown",Defaults={Options={"Low","Medium","High","Ultra"}}},
    ResolutionSelector={Target="AddDropdown",Defaults={Options={"1280x720","1920x1080","2560x1440","3840x2160"}}},
    AspectRatioSelector={Target="AddDropdown",Defaults={Options={"4:3","16:9","16:10","21:9","1:1"}}},
    RefreshRateSelector={Target="AddDropdown",Defaults={Options={30,60,75,120,144,165,240}}},
    UnitSelector={Target="AddDropdown",Defaults={Options={"Studs","Meters","Feet","Pixels","Percent"}}},
    ModeSelector={Target="AddDropdown",Defaults={Options={"Normal","Compact","Advanced","Custom"}}},
    StateSelector={Target="AddDropdown",Defaults={Options={"Idle","Running","Paused","Stopped","Error"}}},
    SeveritySelector={Target="AddDropdown",Defaults={Options={"Debug","Info","Warning","Error","Critical"}}},
    StatusSelector={Target="AddDropdown",Defaults={Options={"Offline","Online","Away","Busy"}}},
    SortDirectionSelector={Target="AddDropdown",Defaults={Options={"Ascending","Descending"}}},
    ComparisonSelector={Target="AddDropdown",Defaults={Options={"Equal","Not Equal","Greater","Less","Contains"}}},
    OperatorSelector={Target="AddDropdown",Defaults={Options={"+","-","*","/","%","^"}}},
    EasingStyleSelector={Target="AddEnumSelector",Defaults={Enum=Enum.EasingStyle}},
    EasingDirectionSelector={Target="AddEnumSelector",Defaults={Enum=Enum.EasingDirection}},
    FontWeightSelector={Target="AddDropdown",Defaults={Options={"Regular","Medium","Semibold","Bold"}}},
    TextAlignmentSelector={Target="AddEnumSelector",Defaults={Enum=Enum.TextXAlignment}},
    VerticalAlignmentSelector={Target="AddEnumSelector",Defaults={Enum=Enum.TextYAlignment}},
    ScaleTypeSelector={Target="AddEnumSelector",Defaults={Enum=Enum.ScaleType}},
    AutomaticSizeSelector={Target="AddEnumSelector",Defaults={Enum=Enum.AutomaticSize}},
    FillDirectionSelector={Target="AddEnumSelector",Defaults={Enum=Enum.FillDirection}},
    SortOrderSelector={Target="AddEnumSelector",Defaults={Enum=Enum.SortOrder}},
    InfoCard={Target="AddCallout",Defaults={}},
    WarningCard={Target="AddCallout",Defaults={}},
    ErrorCard={Target="AddCallout",Defaults={}},
    SuccessCard={Target="AddCallout",Defaults={}},
    NumberCard={Target="AddStatCard",Defaults={}},
    MetricCard={Target="AddStatCard",Defaults={}},
    KPI={Target="AddStatCard",Defaults={}},
    CounterCard={Target="AddStatCard",Defaults={}},
    MiniProgress={Target="AddProgress",Defaults={}},
    LoadingBar={Target="AddProgress",Defaults={}},
    CompletionBar={Target="AddProgress",Defaults={}},
    CapacityBar={Target="AddProgress",Defaults={}},
    ToggleRow={Target="AddToggle",Defaults={}},
    SwitchRow={Target="AddToggle",Defaults={}},
    BooleanToggle={Target="AddToggle",Defaults={}},
    FeatureToggle={Target="AddToggle",Defaults={}},
    ActionButton={Target="AddButton",Defaults={}},
    DangerButton={Target="AddButton",Defaults={}},
    PrimaryButton={Target="AddButton",Defaults={}},
    SecondaryButton={Target="AddButton",Defaults={}},
    SearchInput={Target="AddSearchBox",Defaults={}},
    PasswordInput={Target="AddPasswordBox",Defaults={}},
    CodeInput={Target="AddCodeBox",Defaults={}},
    EmailInput={Target="AddEmailBox",Defaults={}},
    URLInput={Target="AddURLBox",Defaults={}},
    IPAddressInput={Target="AddIPBox",Defaults={}},
    PortSelector={Target="AddPortInput",Defaults={}},
    PercentageInput={Target="AddPercentInput",Defaults={}},
    TagsEditor={Target="AddTagInput",Defaults={}},
    ChoiceChips={Target="AddChipGroup",Defaults={}},
    StarRating={Target="AddRating",Defaults={}},
    TimelineView={Target="AddTimeline",Defaults={}},
    TreeExplorer={Target="AddTreeView",Defaults={}},
    ConsoleView={Target="AddLogConsole",Defaults={}},
    PropertyInspector={Target="AddPropertyGrid",Defaults={}},
    NotificationsList={Target="AddNotificationFeed",Defaults={}},
    PlayerSelector={Target="AddPlayerPicker",Defaults={}},
    PlayersList={Target="AddPlayerList",Defaults={}},
    LanguagePicker={Target="AddLanguageSelector",Defaults={}},
    ColorSelector={Target="AddColorPicker",Defaults={}},
    FontPicker={Target="AddFontSelector",Defaults={}},
    Vector2Editor={Target="AddVector2Input",Defaults={}},
    Vector3Editor={Target="AddVector3Input",Defaults={}},
    UDimEditor={Target="AddUDimInput",Defaults={}},
    UDim2Editor={Target="AddUDim2Input",Defaults={}},
    RGBEditor={Target="AddRGBInput",Defaults={}},
    ModelPreview={Target="AddViewportModel",Defaults={}},
    AvatarPreview={Target="AddAvatarViewport",Defaults={}},
    ColorPalette={Target="AddColorSwatches",Defaults={}},
    GradientViewer={Target="AddGradientPreview",Defaults={}},
    LineGraph={Target="AddLineChart",Defaults={}},
    BarGraph={Target="AddBarChart",Defaults={}},
    MiniGraph={Target="AddSparkline",Defaults={}},
    ColorHeatmap={Target="AddHeatmap",Defaults={}},
    PerformanceFPS={Target="AddFPSMeter",Defaults={}},
    PerformanceMemory={Target="AddMemoryMeter",Defaults={}},
    Timer={Target="AddCountdown",Defaults={}},
    DigitalClock={Target="AddClock",Defaults={}},
    Spinner={Target="AddLoadingSpinner",Defaults={}},
    SkeletonLoader={Target="AddSkeleton",Defaults={}},
    AccordionPanel={Target="AddDisclosure",Defaults={}},
    NestedTabs={Target="AddMiniTabs",Defaults={}},
}
for feature,spec in pairs(V5FeatureSpecs) do
    local method="Add"..feature
    if Section[method]==nil then
        Section[method]=function(self,configuration)
            configuration=deepMerge(spec.Defaults or {},configuration or {})
            local target=self[spec.Target]
            assert(type(target)=="function","Missing target control "..tostring(spec.Target))
            local c=target(self,configuration)
            if c then c.Kind=feature end
            return c
        end
    end
end

Section.AddCustomControl=Section.AddCustom
Section.AddRaw=Section.AddRawGui
Section.AddContainer=Section.AddPanel
Section.AddColumnsLayout=Section.AddColumns
Section.AddAutoComplete=Section.AddAutocomplete
Section.AddTransfer=Section.AddTransferList
Section.AddReorder=Section.AddReorderList
Section.AddGridPicker=Section.AddGridSelect
Section.AddCards=Section.AddCardSelect
Section.AddImages=Section.AddImageGallery
Section.AddDataGridEditor=Section.AddEditableTable
Section.AddListEditor=Section.AddEditableList
Section.AddTasks=Section.AddTaskList
Section.AddBoard=Section.AddKanban
Section.AddRankings=Section.AddLeaderboard
Section.AddGallery=Section.AddImageGallery
Section.AddLive=Section.AddLiveValue
Section.AddTelemetry=Section.AddLiveValue
Section.AddPreset=Section.AddPresetSelector
Section.AddTheme=Section.AddThemeSelector
Section.AddCommands=Section.AddCommandPalette

function Library:GetFeatureCatalog()
    local result = {}
    for name, fn in pairs(Section) do
        if type(fn) == "function" and string.sub(name, 1, 3) == "Add" then
            table.insert(result, name)
        end
    end
    table.sort(result)
    return result
end

function Library:GetFeatureInfo(name)
    name = tostring(name or "")
    local featureName = string.gsub(name, "^Add", "")
    local spec = V5FeatureSpecs and V5FeatureSpecs[featureName] or nil

    local result = {
        Name = name,
        Exists = type(Section[name]) == "function",
        Dynamic = spec ~= nil,
    }

    if spec then
        result.Target = spec.Target
        result.Defaults = deepCopy(spec.Defaults or {})
    else
        result.Target = name
        result.Defaults = {}
    end

    return result
end

function Library:GetFrameworkCatalog()
    local result = {}
    for name, fn in pairs(Library) do
        if type(fn) == "function" and string.sub(name, 1, 1) ~= "_" then
            table.insert(result, name)
        end
    end
    table.sort(result)
    return result
end

function Library:GetControlCatalog()
    local result = {}
    for name, fn in pairs(Control) do
        if type(fn) == "function" and string.sub(name, 1, 1) ~= "_" then
            table.insert(result, name)
        end
    end
    table.sort(result)
    return result
end

function Library:GetTabCatalog()
    local result = {}
    for name, fn in pairs(Tab) do
        if type(fn) == "function" and string.sub(name, 1, 1) ~= "_" then
            table.insert(result, name)
        end
    end
    table.sort(result)
    return result
end

function Library:GetSectionCatalog()
    local result = {}
    for name, fn in pairs(Section) do
        if type(fn) == "function" and string.sub(name, 1, 1) ~= "_" then
            table.insert(result, name)
        end
    end
    table.sort(result)
    return result
end

function Library:GetAPICounts()
    return {
        Features = #self:GetFeatureCatalog(),
        Framework = #self:GetFrameworkCatalog(),
        Controls = #self:GetControlCatalog(),
        Tabs = #self:GetTabCatalog(),
        Sections = #self:GetSectionCatalog(),
    }
end
