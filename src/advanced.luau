
function Section:AddColorSwatches(configuration)
    configuration = configuration or {}
    local app = self.App
    local colors = configuration.Colors or {Color3.fromRGB(255,80,80), Color3.fromRGB(80,200,120), Color3.fromRGB(90,150,255), Color3.fromRGB(230,180,70)}
    local value = configuration.Default or colors[1]
    local row = self:_Row(configuration.Height or 70)
    local label = valueLabel(row, app, configuration.Text or "Colors", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local holder = create("ScrollingFrame", {Parent = row, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new()})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7)})
    local id = app:_MakeId("ColorSwatches", configuration.Id)
    local control = self:_Control(id, "ColorSwatches", configuration.Text or "Colors", row, configuration)
    local buttons = {}
    local function render()
        for color, button in pairs(buttons) do
            local s = button:FindFirstChildOfClass("UIStroke")
            if s then s.Color = color == value and app.Config.Colors.Text or app.Config.Colors.Border s.Thickness = color == value and 2 or 1 end
        end
    end
    local function set(newValue, silent)
        if typeof(newValue) ~= "Color3" then return value end
        local previous = value value = newValue render()
        if not silent and previous ~= value then self:_Emit(control, "SwatchChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end
    for _, color in ipairs(colors) do
        local c = color
        local button = create("TextButton", {Parent = holder, Size = UDim2.fromOffset(30, 30), BackgroundColor3 = c, BorderSizePixel = 0, Text = "", AutoButtonColor = false}) corner(button, 999) stroke(button, app.Config.Colors.Border, 1, 0) buttons[c] = button
        control:_Connect(button.Activated, function() if not control.Disabled then set(c) end end)
    end
    control._getter = function() return value end control._setter = set control._textSetter = function(text) label.Text = text end render()
    return app:_Register(control)
end

function Section:AddFontSelector(configuration)
    configuration = configuration or {}
    local fonts = configuration.Fonts or {
        Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold, Enum.Font.Roboto, Enum.Font.RobotoMono,
        Enum.Font.SourceSans, Enum.Font.SourceSansBold, Enum.Font.Arial, Enum.Font.ArialBold, Enum.Font.Code,
    }
    local original = configuration.Callback
    configuration.Text = configuration.Text or "Font"
    configuration.Options = fonts
    configuration.Display = function(font) return typeof(font) == "EnumItem" and font.Name or tostring(font) end
    configuration.Callback = function(font, control) if original then original(font, control) end end
    local control = self:AddDropdown(configuration) control.Kind = "FontSelector" return control
end

function Section:AddEnumSelector(configuration)
    configuration = configuration or {}
    local enumType = configuration.Enum
    local options = configuration.Options
    if not options and enumType and type(enumType.GetEnumItems) == "function" then options = enumType:GetEnumItems() end
    options = options or {}
    local original = configuration.Callback
    configuration.Options = options
    configuration.Text = configuration.Text or "Enum"
    configuration.Display = function(item) return typeof(item) == "EnumItem" and item.Name or tostring(item) end
    configuration.Callback = function(item, control) if original then original(item, control) end end
    local control = self:AddDropdown(configuration) control.Kind = "EnumSelector" return control
end

----------------------------------------------------------------
-- VECTOR INPUT HELPER
----------------------------------------------------------------

function Section:_AddVectorInput(configuration, dimensions, kind)
    configuration = configuration or {}
    local app = self.App
    local default = configuration.Default
    local values = {}
    local names = dimensions == 2 and {"X", "Y"} or {"X", "Y", "Z"}
    for i, name in ipairs(names) do
        if typeof(default) == "Vector2" or typeof(default) == "Vector3" then values[i] = default[name] else values[i] = tonumber(type(default) == "table" and (default[name] or default[i])) or 0 end
    end
    local row = self:_Row(configuration.Height or 66)
    local label = valueLabel(row, app, configuration.Text or kind, UDim2.new(), UDim2.new(1, 0, 0, 22))
    local holder = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)})
    local id = app:_MakeId(kind, configuration.Id)
    local control = self:_Control(id, kind, configuration.Text or kind, row, configuration)
    local boxes = {}
    local function result() return dimensions == 2 and Vector2.new(values[1], values[2]) or Vector3.new(values[1], values[2], values[3]) end
    local function set(newValue, silent)
        local previous = result()
        for i, name in ipairs(names) do
            if typeof(newValue) == "Vector2" or typeof(newValue) == "Vector3" then values[i] = tonumber(newValue[name]) or values[i] elseif type(newValue) == "table" then values[i] = tonumber(newValue[name] or newValue[i]) or values[i] end
            if boxes[i] then boxes[i].Text = tostring(values[i]) end
        end
        local current = result()
        if not silent and previous ~= current then self:_Emit(control, kind .. "Changed", current, previous) app:_Callback(configuration.Callback, current, control) end
        return current
    end
    for i, name in ipairs(names) do
        local wrapper = create("Frame", {Parent = holder, Size = UDim2.new(1 / dimensions, -4, 1, 0), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0}) corner(wrapper, app.Config.Radius.Control)
        local prefix = valueLabel(wrapper, app, name, UDim2.fromOffset(7, 0), UDim2.fromOffset(18, 34)) prefix.TextColor3 = app.Config.Colors.Accent prefix.Font = app.Config.Fonts.Bold
        local box = create("TextBox", {Parent = wrapper, Position = UDim2.fromOffset(25, 0), Size = UDim2.new(1, -29, 1, 0), BackgroundTransparency = 1, Text = tostring(values[i]), TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Mono, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left}) boxes[i] = box
        control:_Connect(box.FocusLost, function() if control.Disabled then return end local previous = result() values[i] = tonumber(box.Text) or values[i] box.Text = tostring(values[i]) local current = result() if previous ~= current then self:_Emit(control, kind .. "Changed", current, previous) app:_Callback(configuration.Callback, current, control) end end)
    end
    control._getter = result control._setter = set control._textSetter = function(text) label.Text = text end
    return app:_Register(control)
end

function Section:AddVector2Input(configuration) return self:_AddVectorInput(configuration, 2, "Vector2Input") end
function Section:AddVector3Input(configuration) return self:_AddVectorInput(configuration, 3, "Vector3Input") end

function Section:AddUDimInput(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Default or UDim.new(0, 0)
    local row = self:_Row(configuration.Height or 66)
    local label = valueLabel(row, app, configuration.Text or "UDim", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local holder = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1})
    local scaleBox = create("TextBox", {Parent = holder, Size = UDim2.new(0.5, -3, 1, 0), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = tostring(value.Scale), PlaceholderText = "Scale", TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Mono, ClearTextOnFocus = false}) corner(scaleBox, app.Config.Radius.Control)
    local offsetBox = scaleBox:Clone() offsetBox.Parent = holder offsetBox.Position = UDim2.new(0.5, 3, 0, 0) offsetBox.Text = tostring(value.Offset) offsetBox.PlaceholderText = "Offset"
    local id = app:_MakeId("UDimInput", configuration.Id)
    local control = self:_Control(id, "UDimInput", configuration.Text or "UDim", row, configuration)
    local function render() scaleBox.Text = tostring(value.Scale) offsetBox.Text = tostring(value.Offset) end
    local function set(newValue, silent)
        if typeof(newValue) ~= "UDim" then return value end local previous = value value = newValue render()
        if not silent and previous ~= value then self:_Emit(control, "UDimChanged", value, previous) app:_Callback(configuration.Callback, value, control) end return value
    end
    local function commit() set(UDim.new(tonumber(scaleBox.Text) or value.Scale, tonumber(offsetBox.Text) or value.Offset)) end
    control._getter = function() return value end control._setter = set control._textSetter = function(text) label.Text = text end
    control:_Connect(scaleBox.FocusLost, commit) control:_Connect(offsetBox.FocusLost, commit)
    return app:_Register(control)
end


function Section:AddUDim2Input(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Default or UDim2.new()
    local row = self:_Row(configuration.Height or 98)
    local label = valueLabel(row, app, configuration.Text or "UDim2", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local fields = {{"XS", value.X.Scale}, {"XO", value.X.Offset}, {"YS", value.Y.Scale}, {"YO", value.Y.Offset}}
    local holder = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1})
    local id = app:_MakeId("UDim2Input", configuration.Id)
    local control = self:_Control(id, "UDim2Input", configuration.Text or "UDim2", row, configuration)
    local boxes = {}
    for i, data in ipairs(fields) do
        local x = (i - 1) % 2 local y = math.floor((i - 1) / 2)
        local wrapper = create("Frame", {Parent = holder, Position = UDim2.new(x * 0.5, x * 3, 0, y * 32), Size = UDim2.new(0.5, -3, 0, 28), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0}) corner(wrapper, app.Config.Radius.Control)
        local prefix = valueLabel(wrapper, app, data[1], UDim2.fromOffset(6, 0), UDim2.fromOffset(25, 28)) prefix.TextColor3 = app.Config.Colors.Accent prefix.TextSize = app.Config.TextSizes.Tiny
        local box = create("TextBox", {Parent = wrapper, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1, Text = tostring(data[2]), TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Mono, ClearTextOnFocus = false}) boxes[i] = box
    end
    local function render() boxes[1].Text = tostring(value.X.Scale) boxes[2].Text = tostring(value.X.Offset) boxes[3].Text = tostring(value.Y.Scale) boxes[4].Text = tostring(value.Y.Offset) end
    local function set(newValue, silent)
        if typeof(newValue) ~= "UDim2" then return value end local previous = value value = newValue render()
        if not silent and previous ~= value then self:_Emit(control, "UDim2Changed", value, previous) app:_Callback(configuration.Callback, value, control) end return value
    end
    local function commit() set(UDim2.new(tonumber(boxes[1].Text) or value.X.Scale, tonumber(boxes[2].Text) or value.X.Offset, tonumber(boxes[3].Text) or value.Y.Scale, tonumber(boxes[4].Text) or value.Y.Offset)) end
    control._getter = function() return value end control._setter = set control._textSetter = function(text) label.Text = text end
    for _, box in ipairs(boxes) do control:_Connect(box.FocusLost, commit) end
    return app:_Register(control)
end

----------------------------------------------------------------
-- RGB INPUT
----------------------------------------------------------------

function Section:AddRGBInput(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Default or Color3.new(1, 1, 1)
    local row = self:_Row(configuration.Height or 66)
    local label = valueLabel(row, app, configuration.Text or "RGB", UDim2.new(), UDim2.new(1, -40, 0, 22))
    local preview = create("Frame", {Parent = row, AnchorPoint = Vector2.new(1,0), Position = UDim2.new(1,0,0,0), Size = UDim2.fromOffset(30,22), BackgroundColor3 = value, BorderSizePixel = 0}) corner(preview, 4)
    local holder = create("Frame", {Parent = row, Position = UDim2.fromOffset(0,28), Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1}) create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6)})
    local id = app:_MakeId("RGBInput", configuration.Id)
    local control = self:_Control(id, "RGBInput", configuration.Text or "RGB", row, configuration)
    local boxes = {}
    local function components() return math.round(value.R*255), math.round(value.G*255), math.round(value.B*255) end
    for i, name in ipairs({"R","G","B"}) do
        local wrapper = create("Frame", {Parent = holder, Size = UDim2.new(1/3,-4,1,0), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0}) corner(wrapper, app.Config.Radius.Control)
        local prefix = valueLabel(wrapper, app, name, UDim2.fromOffset(6,0), UDim2.fromOffset(18,34)) prefix.TextColor3 = i==1 and Color3.fromRGB(255,100,100) or (i==2 and Color3.fromRGB(100,255,130) or Color3.fromRGB(100,150,255)) prefix.Font = app.Config.Fonts.Bold
        local box = create("TextBox", {Parent = wrapper, Position = UDim2.fromOffset(24,0), Size = UDim2.new(1,-28,1,0), BackgroundTransparency = 1, Text = "", TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Mono, ClearTextOnFocus = false}) boxes[i]=box
    end
    local function render() local r,g,b=components() boxes[1].Text=tostring(r) boxes[2].Text=tostring(g) boxes[3].Text=tostring(b) preview.BackgroundColor3=value end
    local function set(newValue, silent)
        if typeof(newValue) ~= "Color3" then return value end local previous=value value=newValue render()
        if not silent and previous~=value then self:_Emit(control,"RGBChanged",value,previous) app:_Callback(configuration.Callback,value,control) end return value
    end
    local function commit() set(Color3.fromRGB(clamp(tonumber(boxes[1].Text) or 0,0,255),clamp(tonumber(boxes[2].Text) or 0,0,255),clamp(tonumber(boxes[3].Text) or 0,0,255))) end
    control._getter=function() return value end control._setter=set control._textSetter=function(text) label.Text=text end
    for _, box in ipairs(boxes) do control:_Connect(box.FocusLost,commit) end render()
    return app:_Register(control)
end


----------------------------------------------------------------
-- INSTANCE INFO
----------------------------------------------------------------

function Section:AddInstanceInfo(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Instance or configuration.Default
    local row = self:_Row(configuration.Height or 92)
    local box = create("Frame", {Parent = row, Size = UDim2.fromScale(1,1), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0}) corner(box,app.Config.Radius.Control)
    local nameLabel=valueLabel(box,app,"No instance",UDim2.fromOffset(10,8),UDim2.new(1,-20,0,22)) nameLabel.Font=app.Config.Fonts.Bold
    local classLabel=valueLabel(box,app,"",UDim2.fromOffset(10,32),UDim2.new(1,-20,0,20)) classLabel.TextColor3=app.Config.Colors.Accent
    local pathLabel=valueLabel(box,app,"",UDim2.fromOffset(10,54),UDim2.new(1,-20,0,28)) pathLabel.TextColor3=app.Config.Colors.Text2 pathLabel.TextSize=app.Config.TextSizes.Tiny
    local id=app:_MakeId("InstanceInfo",configuration.Id)
    local control=self:_Control(id,"InstanceInfo",configuration.Text or "Instance",row,configuration)
    local function pathFor(instance)
        if typeof(instance)~="Instance" then return "" end
        local parts={} local current=instance
        while current and current~=game do table.insert(parts,1,current.Name) current=current.Parent end
        return "game."..table.concat(parts,".")
    end
    local function render()
        if typeof(value)=="Instance" then nameLabel.Text=value.Name classLabel.Text=value.ClassName pathLabel.Text=pathFor(value) else nameLabel.Text="No instance" classLabel.Text="" pathLabel.Text="" end
    end
    local function set(newValue,silent) local previous=value if newValue~=nil and typeof(newValue)~="Instance" then return value end value=newValue render() if not silent and previous~=value then self:_Emit(control,"InstanceChanged",value,previous) app:_Callback(configuration.Callback,value,control) end return value end
    control._getter=function() return value end control._setter=set
    function control:GetPath() return pathLabel.Text end
    render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- PROPERTY GRID
----------------------------------------------------------------

function Section:AddPropertyGrid(configuration)
    configuration=configuration or {}
    local app=self.App
    local data=configuration.Properties or configuration.Default or {}
    local row=self:_Row(configuration.Height or 260)
    local holder=create("ScrollingFrame",{Parent=row,Size=UDim2.fromScale(1,1),BackgroundColor3=app.Config.Colors.Background2,BorderSizePixel=0,ScrollBarThickness=app.Config.Layout.ScrollbarThickness,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()}) corner(holder,app.Config.Radius.Control)
    create("UIListLayout",{Parent=holder,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder}) create("UIPadding",{Parent=holder,PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4)})
    local id=app:_MakeId("PropertyGrid",configuration.Id)
    local control=self:_Control(id,"PropertyGrid",configuration.Text or "Properties",row,configuration)
    local generated={}
    local function pairsSorted(tbl) local keys={} for k in pairs(tbl or {}) do table.insert(keys,k) end table.sort(keys,function(a,b)return tostring(a)<tostring(b)end) return keys end
    local function render()
        for _,c in ipairs(generated) do c:Destroy() end table.clear(generated)
        for _,key in ipairs(pairsSorted(data)) do
            local value=data[key]
            local line=create("Frame",{Parent=holder,Size=UDim2.new(1,-8,0,30),BackgroundColor3=app.Config.Colors.Control,BorderSizePixel=0}) corner(line,app.Config.Radius.Control) table.insert(generated,line)
            local k=valueLabel(line,app,key,UDim2.fromOffset(8,0),UDim2.new(0.42,-8,1,0)) k.TextColor3=app.Config.Colors.Text2
            local v=valueLabel(line,app,value,UDim2.new(0.42,4,0,0),UDim2.new(0.58,-12,1,0)) v.TextXAlignment=Enum.TextXAlignment.Right v.Font=app.Config.Fonts.Mono v.TextSize=app.Config.TextSizes.Secondary
        end
    end
    control._getter=function() return data end control._setter=function(newData) data=newData or {} render() return data end
    function control:SetProperty(key,value) data[key]=value render() self.App:_Emit("PropertyChanged",self.Id,value,{Key=key}) return self end
    function control:GetProperty(key) return data[key] end
    render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- NOTIFICATION FEED
----------------------------------------------------------------

function Section:AddNotificationFeed(configuration)
    configuration=configuration or {}
    local app=self.App
    local items=shallowArrayCopy(configuration.Items or {})
    local row=self:_Row(configuration.Height or 240)
    local holder=create("ScrollingFrame",{Parent=row,Size=UDim2.fromScale(1,1),BackgroundColor3=app.Config.Colors.Background2,BorderSizePixel=0,ScrollBarThickness=app.Config.Layout.ScrollbarThickness,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()}) corner(holder,app.Config.Radius.Control)
    create("UIListLayout",{Parent=holder,Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder}) create("UIPadding",{Parent=holder,PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5)})
    local id=app:_MakeId("NotificationFeed",configuration.Id)
    local control=self:_Control(id,"NotificationFeed",configuration.Text or "Notifications",row,configuration)
    local generated={}
    local function render()
        for _,c in ipairs(generated) do c:Destroy() end table.clear(generated)
        for index,item in ipairs(items) do
            local frame=create("Frame",{Parent=holder,Size=UDim2.new(1,-10,0,configuration.ItemHeight or 60),BackgroundColor3=app.Config.Colors.Control,BorderSizePixel=0}) corner(frame,app.Config.Radius.Control) table.insert(generated,frame)
            local titleText=type(item)=="table" and (item.Title or item.Text or "Notification") or tostring(item)
            local bodyText=type(item)=="table" and (item.Body or item.Description or item.Message or "") or ""
            local title=valueLabel(frame,app,titleText,UDim2.fromOffset(9,5),UDim2.new(1,-18,0,22)) title.Font=app.Config.Fonts.Medium
            local body=valueLabel(frame,app,bodyText,UDim2.fromOffset(9,27),UDim2.new(1,-18,0,24)) body.TextColor3=app.Config.Colors.Text2 body.TextSize=app.Config.TextSizes.Secondary
        end
    end
    control._getter=function() return shallowArrayCopy(items) end control._setter=function(newItems) items=shallowArrayCopy(newItems or {}) render() return shallowArrayCopy(items) end
    function control:Push(item) table.insert(items,1,item) if configuration.MaxItems and #items>configuration.MaxItems then table.remove(items) end render() self.App:_Emit("FeedItemAdded",self.Id,item) return self end
    function control:Clear() table.clear(items) render() return self end
    render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- HOTKEY HINT
----------------------------------------------------------------

function Section:AddHotkeyHint(configuration)
    configuration=configuration or {}
    local app=self.App
    local key=configuration.Key or configuration.Default or Enum.KeyCode.Unknown
    local row=self:_Row(configuration.Height or 34)
    local label=valueLabel(row,app,configuration.Text or "Shortcut",UDim2.new(),UDim2.new(1,-120,1,0))
    local badge=create("TextLabel",{Parent=row,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(110,26),BackgroundColor3=app.Config.Colors.Control,BorderSizePixel=0,Text=bindName(key),TextColor3=app.Config.Colors.Text,TextSize=app.Config.TextSizes.Secondary,Font=app.Config.Fonts.Mono}) corner(badge,app.Config.Radius.Control)
    local id=app:_MakeId("HotkeyHint",configuration.Id)
    local control=self:_Control(id,"HotkeyHint",configuration.Text or "Shortcut",row,configuration)
    control._getter=function() return key end control._setter=function(newKey) if typeof(newKey)=="EnumItem" then key=newKey badge.Text=bindName(key) end return key end control._textSetter=function(text) label.Text=text end
    return app:_Register(control)
end

----------------------------------------------------------------
-- ACTION ROW
----------------------------------------------------------------

function Section:AddActionRow(configuration)
    configuration=configuration or {}
    local app=self.App
    local row=self:_Row(configuration.Height or 58)
    local title=valueLabel(row,app,configuration.Text or "Action",UDim2.fromOffset(0,4),UDim2.new(1,-130,0,22)) title.Font=app.Config.Fonts.Medium
    local subtitle=valueLabel(row,app,configuration.Description or "",UDim2.fromOffset(0,27),UDim2.new(1,-130,0,20)) subtitle.TextColor3=app.Config.Colors.Text2 subtitle.TextSize=app.Config.TextSizes.Secondary
    local button=create("TextButton",{Parent=row,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(configuration.ButtonWidth or 120,34),BackgroundColor3=configuration.Color or app.Config.Colors.Control,BorderSizePixel=0,Text=configuration.ButtonText or "Action",TextColor3=app.Config.Colors.Text,TextSize=app.Config.TextSizes.Secondary,Font=app.Config.Fonts.Medium,AutoButtonColor=false}) corner(button,app.Config.Radius.Button)
    local id=app:_MakeId("ActionRow",configuration.Id)
    local control=self:_Control(id,"ActionRow",configuration.Text or "Action",row,configuration)
    control._textSetter=function(text) title.Text=text end
    function control:SetDescription(text) subtitle.Text=tostring(text or "") return self end
    function control:SetButtonText(text) button.Text=tostring(text or "") return self end
    control:_Connect(button.Activated,function() if not control.Disabled then self:_Emit(control,"ActionPressed",true,nil) app:_Callback(configuration.Callback,control) end end)
    return app:_Register(control)
end

----------------------------------------------------------------
-- TOGGLE BUTTON
----------------------------------------------------------------

function Section:AddToggleButton(configuration)
    configuration=configuration or {}
    local app=self.App
    local value=configuration.Default==true
    local row=self:_Row(configuration.Height or app.Config.Layout.ButtonHeight)
    local button=create("TextButton",{Parent=row,Size=UDim2.fromScale(1,1),BackgroundColor3=app.Config.Colors.Control,BorderSizePixel=0,Text="",TextColor3=app.Config.Colors.Text,TextSize=app.Config.TextSizes.Control,Font=app.Config.Fonts.Medium,AutoButtonColor=false}) corner(button,app.Config.Radius.Button)
    local id=app:_MakeId("ToggleButton",configuration.Id)
    local control=self:_Control(id,"ToggleButton",configuration.Text or "Toggle Button",row,configuration)
    local function render() button.Text=value and (configuration.OnText or configuration.Text or "On") or (configuration.OffText or configuration.Text or "Off") button.BackgroundColor3=value and (configuration.OnColor or app.Config.Colors.Accent2) or (configuration.OffColor or app.Config.Colors.Control) end
    local function set(newValue,silent) local previous=value value=newValue==true render() if not silent and previous~=value then self:_Emit(control,"ToggleButtonChanged",value,previous) app:_Callback(configuration.Callback,value,control) end return value end
    control._getter=function() return value end control._setter=set control._textSetter=function(text) configuration.Text=text render() end
    control:_Connect(button.Activated,function() if not control.Disabled then set(not value) end end) render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- TRI-STATE TOGGLE
----------------------------------------------------------------

function Section:AddTriStateToggle(configuration)
    configuration=configuration or {}
    local app=self.App
    local states=configuration.States or {"Off","Auto","On"}
    local index=clamp(tonumber(configuration.DefaultIndex) or 1,1,#states)
    local row=self:_Row(configuration.Height or 40)
    local label=valueLabel(row,app,configuration.Text or "Mode",UDim2.new(),UDim2.new(1,-130,1,0))
    local button=create("TextButton",{Parent=row,AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,0,0.5,0),Size=UDim2.fromOffset(120,32),BackgroundColor3=app.Config.Colors.Control,BorderSizePixel=0,Text="",TextColor3=app.Config.Colors.Text,TextSize=app.Config.TextSizes.Secondary,Font=app.Config.Fonts.Medium,AutoButtonColor=false}) corner(button,app.Config.Radius.Control)
    local id=app:_MakeId("TriStateToggle",configuration.Id)
    local control=self:_Control(id,"TriStateToggle",configuration.Text or "Mode",row,configuration)
    local function render() button.Text=tostring(states[index]) button.BackgroundColor3=index==#states and app.Config.Colors.Accent2 or app.Config.Colors.Control end
    local function set(value,silent)
        local previous=states[index]
        if type(value)=="number" then index=clamp(math.floor(value),1,#states) else for i,state in ipairs(states) do if state==value or tostring(state)==tostring(value) then index=i break end end end
        render() local current=states[index]
        if not silent and previous~=current then self:_Emit(control,"TriStateChanged",current,previous) app:_Callback(configuration.Callback,current,index,control) end return current
    end
    control._getter=function() return states[index] end control._setter=set control._textSetter=function(text) label.Text=text end
    control:_Connect(button.Activated,function() if not control.Disabled then index=(index%#states)+1 local current=states[index] render() self:_Emit(control,"TriStateChanged",current,nil) app:_Callback(configuration.Callback,current,index,control) end end) render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- DATE INPUT
----------------------------------------------------------------

function Section:AddDateInput(configuration)
    configuration=configuration or {} configuration.Text=configuration.Text or "Date" configuration.Placeholder=configuration.Placeholder or "YYYY-MM-DD"
    return self:_AddValidatedInput(configuration,"DateInput",function(value)
        value=tostring(value or "") if value=="" then return true end local y,m,d=value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$") if not y then return false end y,m,d=tonumber(y),tonumber(m),tonumber(d) return m>=1 and m<=12 and d>=1 and d<=31
    end)
end

----------------------------------------------------------------
-- TIME INPUT
----------------------------------------------------------------

function Section:AddTimeInput(configuration)
    configuration=configuration or {} configuration.Text=configuration.Text or "Time" configuration.Placeholder=configuration.Placeholder or "HH:MM"
    return self:_AddValidatedInput(configuration,"TimeInput",function(value)
        value=tostring(value or "") if value=="" then return true end local h,m=value:match("^(%d%d?):(%d%d)$") if not h then return false end h,m=tonumber(h),tonumber(m) return h>=0 and h<=23 and m>=0 and m<=59
    end)
end

----------------------------------------------------------------
-- GRADIENT PREVIEW
----------------------------------------------------------------

function Section:AddGradientPreview(configuration)
    configuration=configuration or {}
    local app=self.App
    local colors=configuration.Colors or {app.Config.Colors.Accent2,app.Config.Colors.Accent}
    local row=self:_Row(configuration.Height or 70)
    local label=valueLabel(row,app,configuration.Text or "Gradient",UDim2.new(),UDim2.new(1,0,0,22))
    local preview=create("Frame",{Parent=row,Position=UDim2.fromOffset(0,30),Size=UDim2.new(1,0,0,32),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0}) corner(preview,app.Config.Radius.Control)
    local gradient=Instance.new("UIGradient") gradient.Parent=preview
    local id=app:_MakeId("GradientPreview",configuration.Id)
    local control=self:_Control(id,"GradientPreview",configuration.Text or "Gradient",row,configuration)
    local function render()
        local points={} local count=math.max(#colors,1)
        for i,color in ipairs(colors) do table.insert(points,ColorSequenceKeypoint.new((i-1)/math.max(count-1,1),color)) end
        if #points==1 then table.insert(points,ColorSequenceKeypoint.new(1,points[1].Value)) end
        gradient.Color=ColorSequence.new(points) gradient.Rotation=configuration.Rotation or 0
    end
    control._getter=function() return shallowArrayCopy(colors) end control._setter=function(newColors) colors=shallowArrayCopy(newColors or {}) render() return shallowArrayCopy(colors) end control._textSetter=function(text) label.Text=text end
    function control:SetRotation(rotation) gradient.Rotation=tonumber(rotation) or 0 return self end
    render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- DISCLOSURE / ACCORDION ROW
----------------------------------------------------------------

function Section:AddDisclosure(configuration)
    configuration=configuration or {}
    local app=self.App
    local open=configuration.Open==true
    local closedHeight=38 local openHeight=configuration.Height or 112
    local row=self:_Row(open and openHeight or closedHeight)
    local header=create("TextButton",{Parent=row,Size=UDim2.new(1,0,0,34),BackgroundColor3=app.Config.Colors.Control,BorderSizePixel=0,Text="",AutoButtonColor=false}) corner(header,app.Config.Radius.Control)
    local arrow=valueLabel(header,app,open and "v" or ">",UDim2.fromOffset(8,0),UDim2.fromOffset(20,34)) arrow.TextXAlignment=Enum.TextXAlignment.Center
    local title=valueLabel(header,app,configuration.Text or "Details",UDim2.fromOffset(32,0),UDim2.new(1,-40,1,0)) title.Font=app.Config.Fonts.Medium
    local body=valueLabel(row,app,configuration.Content or configuration.Description or "",UDim2.fromOffset(8,42),UDim2.new(1,-16,0,openHeight-48)) body.TextWrapped=true body.TextYAlignment=Enum.TextYAlignment.Top body.TextColor3=app.Config.Colors.Text2 body.Visible=open
    local id=app:_MakeId("Disclosure",configuration.Id)
    local control=self:_Control(id,"Disclosure",configuration.Text or "Details",row,configuration)
    local function set(value,silent) local previous=open open=value==true body.Visible=open arrow.Text=open and "v" or ">" row.Size=UDim2.new(1,0,0,open and openHeight or closedHeight) if not silent and previous~=open then self:_Emit(control,"DisclosureChanged",open,previous) app:_Callback(configuration.Callback,open,control) end return open end
    control._getter=function() return open end control._setter=set control._textSetter=function(text) title.Text=text end
    function control:SetContent(text) body.Text=tostring(text or "") return self end
    control:_Connect(header.Activated,function() if not control.Disabled then set(not open) end end)
    return app:_Register(control)
end

----------------------------------------------------------------
-- MINI TABS
----------------------------------------------------------------

function Section:AddMiniTabs(configuration)
    configuration=configuration or {}
    local app=self.App
    local tabs=configuration.Tabs or {}
    local active=configuration.Default or (tabs[1] and (tabs[1].Name or tabs[1].Text or tabs[1]))
    local row=self:_Row(configuration.Height or 220)
    local tabBar=create("Frame",{Parent=row,Size=UDim2.new(1,0,0,34),BackgroundColor3=app.Config.Colors.Control,BorderSizePixel=0}) corner(tabBar,app.Config.Radius.Control)
    create("UIListLayout",{Parent=tabBar,FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,3)})
    local content=create("Frame",{Parent=row,Position=UDim2.fromOffset(0,40),Size=UDim2.new(1,0,1,-40),BackgroundTransparency=1})
    local id=app:_MakeId("MiniTabs",configuration.Id)
    local control=self:_Control(id,"MiniTabs",configuration.Text or "Tabs",row,configuration)
    local pages={} local buttons={}
    local function select(name,silent)
        local previous=active active=name
        for n,page in pairs(pages) do page.Visible=n==active end
        for n,button in pairs(buttons) do button.BackgroundTransparency=n==active and 0 or 1 button.BackgroundColor3=app.Config.Colors.Accent2 end
        if not silent and previous~=active then self:_Emit(control,"MiniTabChanged",active,previous) app:_Callback(configuration.Callback,active,control) end
        return active
    end
    local function addTab(tabData,index)
        local name=type(tabData)=="table" and tostring(tabData.Name or tabData.Text or index) or tostring(tabData)
        local button=create("TextButton",{Parent=tabBar,Size=UDim2.new(1/math.max(#tabs,1),-3,1,0),BackgroundColor3=app.Config.Colors.Accent2,BackgroundTransparency=1,BorderSizePixel=0,Text=name,TextColor3=app.Config.Colors.Text,TextSize=app.Config.TextSizes.Secondary,Font=app.Config.Fonts.Medium,AutoButtonColor=false}) corner(button,app.Config.Radius.Control) buttons[name]=button
        local page=create("Frame",{Parent=content,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false}) pages[name]=page
        create("UIListLayout",{Parent=page,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder}) create("UIPadding",{Parent=page,PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4)})
        local proxy=setmetatable({App=app,Tab=self.Tab,Name=name,Id=control.Id.."_"..name,Frame=page,Header=nil,Controls={},Collapsible=false,Collapsed=false},Section)
        if type(tabData)=="table" and type(tabData.Build)=="function" then app:_Callback(tabData.Build,proxy) end
        control:_Connect(button.Activated,function() if not control.Disabled then select(name) end end)
        return proxy
    end
    control.Pages={}
    for index,tabData in ipairs(tabs) do control.Pages[index]=addTab(tabData,index) end
    control._getter=function() return active end control._setter=select
    function control:GetPage(name) for i,tabData in ipairs(tabs) do local n=type(tabData)=="table" and tostring(tabData.Name or tabData.Text or i) or tostring(tabData) if n==name then return self.Pages[i] end end end
    if active then select(active,true) end
    return app:_Register(control)
end



----------------------------------------------------------------
-- V5: EXTENSIBILITY / THEMES / HISTORY / BINDINGS
----------------------------------------------------------------

