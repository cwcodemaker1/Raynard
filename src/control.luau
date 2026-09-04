-- Raynard fragment: 20_controls_standard.luau
-- Loaded by parser.luau; do not execute this fragment alone.

function Section:AddLabel(configuration)
    if type(configuration) == "string" then configuration = {Text = configuration} end
    configuration = configuration or {}
    local row = self:_Row(configuration.Height or 24)
    local label = create("TextLabel", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = configuration.Text or "Label",
        TextColor3 = configuration.Color or self.App.Config.Colors.Text2, TextSize = configuration.TextSize or self.App.Config.TextSizes.Control,
        Font = configuration.Font or self.App.Config.Fonts.Normal, TextWrapped = configuration.Wrapped ~= false, RichText = configuration.RichText == true,
        TextXAlignment = configuration.Alignment or Enum.TextXAlignment.Left, TextYAlignment = configuration.VerticalAlignment or Enum.TextYAlignment.Center})
    local id = self.App:_MakeId("Label", configuration.Id)
    local control = self:_Control(id, "Label", configuration.Text or "Label", row, configuration)
    control._getter = function() return label.Text end
    control._setter = function(value) label.Text = tostring(value) return label.Text end
    control._textSetter = function(text) label.Text = text end
    return self.App:_Register(control)
end

function Section:AddParagraph(configuration)
    if type(configuration) == "string" then configuration = {Text = configuration} end
    configuration = configuration or {}
    configuration.Height = configuration.Height or 60
    configuration.VerticalAlignment = Enum.TextYAlignment.Top
    configuration.Wrapped = true
    return self:AddLabel(configuration)
end

function Section:AddHeader(configuration)
    if type(configuration) == "string" then configuration = {Text = configuration} end
    configuration = configuration or {}
    configuration.Height = configuration.Height or 28
    configuration.Font = configuration.Font or self.App.Config.Fonts.Bold
    configuration.TextSize = configuration.TextSize or self.App.Config.TextSizes.Section + 1
    configuration.Color = configuration.Color or self.App.Config.Colors.Text
    return self:AddLabel(configuration)
end

function Section:AddDivider(configuration)
    configuration = configuration or {}
    local row = self:_Row(configuration.Height or 9)
    create("Frame", {Parent = row, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, configuration.Thickness or 1),
        BackgroundColor3 = configuration.Color or self.App.Config.Colors.Border, BackgroundTransparency = configuration.Transparency or 0, BorderSizePixel = 0})
    return row
end

function Section:AddSpacer(height) return self:_Row(height or 10) end

function Section:AddCallout(configuration)
    configuration = configuration or {}
    local app = self.App
    local kind = configuration.Type or "Info"
    local accent = app.Config.Colors.Info
    if kind == "Success" then accent = app.Config.Colors.Success elseif kind == "Warning" then accent = app.Config.Colors.Warning elseif kind == "Danger" or kind == "Error" then accent = app.Config.Colors.Danger end
    local row = self:_Row(configuration.Height or 72)
    local box = create("Frame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0})
    corner(box, app.Config.Radius.Control)
    create("Frame", {Parent = box, Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0})
    create("TextLabel", {Parent = box, Position = UDim2.fromOffset(13, 7), Size = UDim2.new(1, -22, 0, 20), BackgroundTransparency = 1,
        Text = configuration.Title or kind, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Bold, TextXAlignment = Enum.TextXAlignment.Left})
    create("TextLabel", {Parent = box, Position = UDim2.fromOffset(13, 28), Size = UDim2.new(1, -22, 1, -34), BackgroundTransparency = 1,
        Text = configuration.Text or "", TextColor3 = app.Config.Colors.Text2, TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Normal,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
    return row
end

function Section:AddButton(configuration)
    if type(configuration) == "string" then configuration = {Text = configuration} end
    configuration = configuration or {}
    local app = self.App
    local row = self:_Row(configuration.Height or app.Config.Layout.ButtonHeight)
    local normal = configuration.Color or app.Config.Colors.Control
    local hover = configuration.HoverColor or app.Config.Colors.ControlHover

    local button = create("TextButton", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = normal, BackgroundTransparency = app.Config.Transparency.Control,
        BorderSizePixel = 0, Text = configuration.Text or "Button", TextColor3 = configuration.TextColor or app.Config.Colors.Text,
        TextSize = configuration.TextSize or app.Config.TextSizes.Control, Font = configuration.Font or app.Config.Fonts.Medium, AutoButtonColor = false})
    corner(button, configuration.Radius or app.Config.Radius.Button)
    if app.Config.Stroke.Enabled and configuration.Stroke ~= false then stroke(button, app.Config.Colors.Border, 1, app.Config.Stroke.Transparency) end

    local id = app:_MakeId("Button", configuration.Id)
    local control = self:_Control(id, "Button", configuration.Text or "Button", row, configuration)

    local function render()
        button.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or normal
        button.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or (configuration.TextColor or app.Config.Colors.Text)
    end

    control._disabledRenderer = render
    control._textSetter = function(text) button.Text = text end

    function control:Press()
        if self.Disabled then return end
        app:_Emit("ButtonPressed", self.Id, true, {Label = self.Label, Kind = self.Kind, Tab = self.Root.Parent.Name})
        app:_Callback(configuration.Callback, self)
    end

    control:_Connect(button.Activated, function() control:Press() end)
    control:_Connect(button.MouseEnter, function()
        if not control.Disabled and app.Config.Behavior.Hover then app:_Tween(button, app.Config.Animation.Fast, {BackgroundColor3 = hover}) end
    end)
    control:_Connect(button.MouseLeave, render)
    render()
    return app:_Register(control)
end

function Section:AddButtonGroup(configuration)
    configuration = configuration or {}
    local app = self.App
    local definitions = configuration.Buttons or {}
    local row = self:_Row(configuration.Height or app.Config.Layout.ButtonHeight)
    local holder = create("Frame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = configuration.Alignment or Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, configuration.Spacing or 6), SortOrder = Enum.SortOrder.LayoutOrder})

    local id = app:_MakeId("ButtonGroup", configuration.Id)
    local control = self:_Control(id, "ButtonGroup", configuration.Text or "ButtonGroup", row, configuration)
    local buttons = {}

    for index, definition in ipairs(definitions) do
        local item = definition
        if type(item) == "string" then item = {Text = item} end
        local button = create("TextButton", {Parent = holder,
            Size = configuration.EqualWidth and UDim2.new(1 / math.max(#definitions, 1), -6, 1, 0) or UDim2.fromOffset(item.Width or 110, configuration.Height or app.Config.Layout.ButtonHeight),
            BackgroundColor3 = item.Color or app.Config.Colors.Control, BorderSizePixel = 0, Text = item.Text or ("Button " .. tostring(index)),
            TextColor3 = item.TextColor or app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Medium,
            AutoButtonColor = false, LayoutOrder = index})
        corner(button, app.Config.Radius.Button)
        table.insert(buttons, {Object = button, Config = item})

        control:_Connect(button.Activated, function()
            if control.Disabled then return end
            self:_Emit(control, "ButtonGroupPressed", item.Id or index, nil)
            app:_Callback(item.Callback or configuration.Callback, item.Id or index, item, control)
        end)
    end

    control._disabledRenderer = function()
        for _, data in ipairs(buttons) do
            data.Object.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or (data.Config.Color or app.Config.Colors.Control)
            data.Object.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or (data.Config.TextColor or app.Config.Colors.Text)
        end
    end
    control._disabledRenderer()
    return app:_Register(control)
end

function Section:AddToggle(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Default == true
    local row = self:_Row(configuration.Height or app.Config.Layout.ToggleHeight)

    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, -58, 1, 0), BackgroundTransparency = 1, Text = configuration.Text or "Toggle",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd})
    local track = create("Frame", {Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(46, 24),
        BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0})
    corner(track, 12)
    local knob = create("Frame", {Parent = track, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = app.Config.Colors.Text, BorderSizePixel = 0})
    corner(knob, 999)
    local hitbox = create("TextButton", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false})

    local id = app:_MakeId("Toggle", configuration.Id)
    local control = self:_Control(id, "Toggle", configuration.Text or "Toggle", row, configuration)

    local function render()
        label.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
        track.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or (value and (configuration.Accent or app.Config.Colors.Accent) or app.Config.Colors.Control)
        app:_Tween(knob, app.Config.Animation.Fast, {Position = value and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)})
    end

    local function set(newValue, silent)
        newValue = newValue == true
        local previous = value
        value = newValue
        render()
        if not silent and previous ~= value then
            self:_Emit(control, "ToggleChanged", value, previous)
            app:_Callback(configuration.Callback, value, control)
        end
        return value
    end

    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = render
    control:_Connect(hitbox.Activated, function() if not control.Disabled then set(not value) end end)
    render()
    return app:_Register(control)
end

Section.AddCheckbox = Section.AddToggle

function Section:AddSlider(configuration)
    configuration = configuration or {}
    local app = self.App
    local minimum = tonumber(configuration.Min) or 0
    local maximum = tonumber(configuration.Max) or 100
    if maximum < minimum then minimum, maximum = maximum, minimum end
    local step = tonumber(configuration.Step) or 1
    local value = stepValue(tonumber(configuration.Default) or minimum, minimum, maximum, step)
    local row = self:_Row(configuration.Height or app.Config.Layout.SliderHeight)

    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, -100, 0, 24), BackgroundTransparency = 1, Text = configuration.Text or "Slider",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local valueLabel = create("TextLabel", {Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(92, 24),
        BackgroundTransparency = 1, Text = "", TextColor3 = configuration.Accent or app.Config.Colors.Accent, TextSize = app.Config.TextSizes.Control,
        Font = app.Config.Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Right})
    local track = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 39), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = app.Config.Colors.Control,
        BorderSizePixel = 0, Active = true})
    corner(track, 4)
    local fill = create("Frame", {Parent = track, Size = UDim2.fromScale(0, 1), BackgroundColor3 = configuration.Accent or app.Config.Colors.Accent, BorderSizePixel = 0})
    corner(fill, 4)
    local knob = create("Frame", {Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = configuration.Accent or app.Config.Colors.Accent, BorderSizePixel = 0})
    corner(knob, 8)

    local id = app:_MakeId("Slider", configuration.Id)
    local control = self:_Control(id, "Slider", configuration.Text or "Slider", row, configuration)
    local dragging = false

    local function alpha()
        if maximum == minimum then return 0 end
        return clamp((value - minimum) / (maximum - minimum), 0, 1)
    end

    local function render()
        local a = alpha()
        fill.Size = UDim2.fromScale(a, 1)
        knob.Position = UDim2.fromScale(a, 0.5)
        valueLabel.Text = (configuration.Prefix or "") .. formatNumber(value, step) .. (configuration.Suffix or "")
        label.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
        track.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or app.Config.Colors.Control
        local activeColor = control.Disabled and app.Config.Colors.TextDisabled or (configuration.Accent or app.Config.Colors.Accent)
        fill.BackgroundColor3 = activeColor
        knob.BackgroundColor3 = activeColor
    end

    local function set(newValue, silent)
        newValue = tonumber(newValue)
        if not newValue then return value end
        newValue = stepValue(newValue, minimum, maximum, step)
        local previous = value
        value = newValue
        render()
        if not silent and previous ~= value then
            self:_Emit(control, "SliderChanged", value, previous)
            app:_Callback(configuration.Callback, value, control)
        end
        return value
    end

    local function fromX(x)
        if control.Disabled or track.AbsoluteSize.X <= 0 then return end
        local a = clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        set(minimum + (maximum - minimum) * a)
    end

    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = render
    control:_Connect(track.InputBegan, function(input)
        if control.Disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true fromX(input.Position.X) end
    end)
    control:_Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromX(input.Position.X) end
    end)
    control:_Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    render()
    return app:_Register(control)
end

function Section:AddTextbox(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = tostring(configuration.Default or "")
    local row = self:_Row(configuration.Height or (configuration.MultiLine and 122 or app.Config.Layout.TextboxHeight))

    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Text",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local box = create("TextBox", {Parent = row, Position = UDim2.fromOffset(0, 27), Size = configuration.MultiLine and UDim2.new(1, 0, 1, -30) or UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = value, PlaceholderText = configuration.Placeholder or "",
        PlaceholderColor3 = app.Config.Colors.Text2, TextColor3 = app.Config.Colors.Text, TextSize = configuration.TextSize or app.Config.TextSizes.Control,
        Font = configuration.Monospace and app.Config.Fonts.Mono or app.Config.Fonts.Normal, ClearTextOnFocus = configuration.ClearOnFocus == true,
        MultiLine = configuration.MultiLine == true, TextWrapped = configuration.MultiLine == true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = configuration.MultiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center})
    corner(box, app.Config.Radius.Control)
    if app.Config.Stroke.Enabled then stroke(box, app.Config.Colors.Border, 1, 0) end
    create("UIPadding", {Parent = box, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), PaddingTop = configuration.MultiLine and UDim.new(0, 7) or UDim.new(), PaddingBottom = configuration.MultiLine and UDim.new(0, 7) or UDim.new()})

    local id = app:_MakeId("Textbox", configuration.Id)
    local control = self:_Control(id, "Textbox", configuration.Text or "Text", row, configuration)

    local function normalize(newValue)
        if configuration.Numeric then
            local n = tonumber(newValue)
            if not n then return value end
            if configuration.Min then n = math.max(n, configuration.Min) end
            if configuration.Max then n = math.min(n, configuration.Max) end
            return tostring(n)
        end
        newValue = tostring(newValue or "")
        if configuration.MaxLength and #newValue > configuration.MaxLength then newValue = newValue:sub(1, configuration.MaxLength) end
        return newValue
    end

    local function render()
        if box.Text ~= value then box.Text = value end
        box.TextEditable = not control.Disabled
        box.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or app.Config.Colors.Control
        box.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
        label.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
    end

    local function set(newValue, silent)
        newValue = normalize(newValue)
        local previous = value
        value = newValue
        render()
        if not silent and previous ~= value then
            self:_Emit(control, "TextboxChanged", configuration.ReturnNumber and tonumber(value) or value, configuration.ReturnNumber and tonumber(previous) or previous)
            app:_Callback(configuration.Callback, configuration.ReturnNumber and tonumber(value) or value, control)
        end
        return configuration.ReturnNumber and tonumber(value) or value
    end

    control._getter = function() return configuration.ReturnNumber and tonumber(value) or value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = render
    control:_Connect(box.FocusLost, function(enter)
        if control.Disabled then return end
        set(box.Text)
        if enter then
            app:_Callback(configuration.EnterCallback, control:Get(), control)
            self:_Emit(control, "TextboxEnter", control:Get(), nil)
        end
    end)
    if configuration.Live then control:_Connect(box:GetPropertyChangedSignal("Text"), function() if not control.Disabled then set(box.Text) end end) end
    render()
    return app:_Register(control)
end

function Section:AddNumberbox(configuration)
    configuration = configuration or {}
    configuration.Numeric = true
    configuration.ReturnNumber = true
    return self:AddTextbox(configuration)
end

function Section:AddDropdown(configuration)
    configuration = configuration or {}
    local app = self.App
    local options = configuration.Options or {}
    local value = configuration.Default
    local row = self:_Row(configuration.Height or app.Config.Layout.DropdownHeight)

    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Dropdown",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local selector = create("TextButton", {Parent = row, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = app.Config.Colors.Control,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false})
    corner(selector, app.Config.Radius.Control)
    local selectedText = create("TextLabel", {Parent = selector, Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1,
        Text = value ~= nil and tostring(value) or (configuration.Placeholder or "Select..."), TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control,
        Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    local arrow = create("TextLabel", {Parent = selector, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(22, 34),
        BackgroundTransparency = 1, Text = "v", TextColor3 = app.Config.Colors.Text2, TextSize = 11, Font = app.Config.Fonts.Normal})
    local list = create("ScrollingFrame", {Parent = row, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = app.Config.Colors.Background2,
        BorderSizePixel = 0, Visible = false, ScrollBarThickness = 3, ScrollBarImageColor3 = app.Config.Colors.Scrollbar, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(), ZIndex = 40})
    corner(list, app.Config.Radius.Control)
    create("UIListLayout", {Parent = list, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})

    local id = app:_MakeId("Dropdown", configuration.Id)
    local control = self:_Control(id, "Dropdown", configuration.Text or "Dropdown", row, configuration)
    local open = false
    local itemButtons = {}

    local function display(item)
        if type(configuration.Display) == "function" then
            local ok, result = pcall(configuration.Display, item)
            if ok then return tostring(result) end
        end
        return tostring(item)
    end

    local function setOpen(state)
        if control.Disabled then state = false end
        open = state == true
        list.Visible = open
        arrow.Text = open and "^" or "v"
        if open then
            local h = math.min(#options * 35 + 8, configuration.MaxHeight or 190)
            list.Size = UDim2.new(1, 0, 0, h)
            row.Size = UDim2.new(1, 0, 0, 64 + h)
        else
            list.Size = UDim2.new(1, 0, 0, 0)
            row.Size = UDim2.new(1, 0, 0, configuration.Height or app.Config.Layout.DropdownHeight)
        end
    end

    local function render()
        selectedText.Text = value ~= nil and display(value) or (configuration.Placeholder or "Select...")
        selector.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or app.Config.Colors.Control
        label.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
    end

    local function set(newValue, silent)
        local previous = value
        value = newValue
        render()
        if not silent and previous ~= value then
            self:_Emit(control, "DropdownChanged", value, previous)
            app:_Callback(configuration.Callback, value, control)
        end
        return value
    end

    local function rebuild()
        for _, button in ipairs(itemButtons) do button:Destroy() end
        table.clear(itemButtons)
        for _, option in ipairs(options) do
            local item = option
            local choice = create("TextButton", {Parent = list, Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0,
                Text = display(item), TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, AutoButtonColor = false, ZIndex = 41})
            corner(choice, app.Config.Radius.Control)
            table.insert(itemButtons, choice)
            control:_Connect(choice.Activated, function() if not control.Disabled then set(item) setOpen(false) end end)
        end
        if open then setOpen(true) end
    end

    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = function() render() if control.Disabled then setOpen(false) end end
    function control:SetOptions(newOptions, keepValue) options = newOptions or {} if not keepValue then value = nil end rebuild() render() return self end
    function control:GetOptions() return options end
    function control:SetOpen(state) setOpen(state) return self end
    control:_Connect(selector.Activated, function() if not control.Disabled then setOpen(not open) end end)
    rebuild()
    render()
    return app:_Register(control)
end

function Section:AddSearchDropdown(configuration)
    configuration = configuration or {}
    local app = self.App
    local options = configuration.Options or {}
    local value = configuration.Default
    local row = self:_Row(configuration.Height or 94)

    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Search",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local box = create("TextBox", {Parent = row, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = app.Config.Colors.Control,
        BorderSizePixel = 0, Text = "", PlaceholderText = configuration.Placeholder or "Search...", PlaceholderColor3 = app.Config.Colors.Text2,
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left})
    corner(box, app.Config.Radius.Control)
    create("UIPadding", {Parent = box, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)})
    local selected = create("TextLabel", {Parent = row, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1,
        Text = value ~= nil and ("Selected: " .. tostring(value)) or "Nothing selected", TextColor3 = app.Config.Colors.Text2, TextSize = app.Config.TextSizes.Secondary,
        Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local list = create("ScrollingFrame", {Parent = row, Position = UDim2.fromOffset(0, 94), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = app.Config.Colors.Background2,
        BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false, ZIndex = 40})
    corner(list, app.Config.Radius.Control)
    create("UIListLayout", {Parent = list, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})

    local id = app:_MakeId("SearchDropdown", configuration.Id)
    local control = self:_Control(id, "SearchDropdown", configuration.Text or "Search", row, configuration)
    local itemButtons = {}

    local function display(item)
        if type(configuration.Display) == "function" then
            local ok, result = pcall(configuration.Display, item)
            if ok then return tostring(result) end
        end
        return tostring(item)
    end

    local function set(newValue, silent)
        local previous = value
        value = newValue
        selected.Text = value ~= nil and ("Selected: " .. display(value)) or "Nothing selected"
        if not silent and previous ~= value then self:_Emit(control, "SearchDropdownChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end

    local function rebuild(query)
        for _, b in ipairs(itemButtons) do b:Destroy() end
        table.clear(itemButtons)
        query = string.lower(query or "")
        local matchesCount = 0
        for _, option in ipairs(options) do
            local item = option
            local text = display(item)
            if query ~= "" and string.find(string.lower(text), query, 1, true) then
                matchesCount += 1
                local choice = create("TextButton", {Parent = list, Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = app.Config.Colors.Control,
                    BorderSizePixel = 0, Text = text, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control,
                    Font = app.Config.Fonts.Normal, AutoButtonColor = false, ZIndex = 41})
                corner(choice, app.Config.Radius.Control)
                table.insert(itemButtons, choice)
                control:_Connect(choice.Activated, function()
                    if control.Disabled then return end
                    set(item)
                    box.Text = ""
                    list.Visible = false
                    list.Size = UDim2.new(1, 0, 0, 0)
                    row.Size = UDim2.new(1, 0, 0, configuration.Height or 94)
                end)
            end
        end
        if matchesCount > 0 then
            local h = math.min(matchesCount * 35 + 8, configuration.MaxHeight or 180)
            list.Visible = true
            list.Size = UDim2.new(1, 0, 0, h)
            row.Size = UDim2.new(1, 0, 0, 94 + h)
        else
            list.Visible = false
            list.Size = UDim2.new(1, 0, 0, 0)
            row.Size = UDim2.new(1, 0, 0, configuration.Height or 94)
        end
    end

    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = function() box.TextEditable = not control.Disabled box.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or app.Config.Colors.Control end
    function control:SetOptions(newOptions) options = newOptions or {} rebuild(box.Text) return self end
    control:_Connect(box:GetPropertyChangedSignal("Text"), function() if not control.Disabled then rebuild(box.Text) end end)
    if value ~= nil then set(value, true) end
    return app:_Register(control)
end

function Section:AddMultiDropdown(configuration)
    configuration = configuration or {}
    local app = self.App
    local options = configuration.Options or {}
    local selected = {}
    for _, item in ipairs(configuration.Default or {}) do selected[item] = true end
    local row = self:_Row(configuration.Height or app.Config.Layout.DropdownHeight)

    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Multiple",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local selector = create("TextButton", {Parent = row, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = app.Config.Colors.Control,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false})
    corner(selector, app.Config.Radius.Control)
    local selectedText = create("TextLabel", {Parent = selector, Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1, Text = "",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    local arrow = create("TextLabel", {Parent = selector, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(22, 34),
        BackgroundTransparency = 1, Text = "v", TextColor3 = app.Config.Colors.Text2, TextSize = 11})
    local list = create("ScrollingFrame", {Parent = row, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = app.Config.Colors.Background2,
        BorderSizePixel = 0, Visible = false, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 40})
    corner(list, app.Config.Radius.Control)
    create("UIListLayout", {Parent = list, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})

    local id = app:_MakeId("MultiDropdown", configuration.Id)
    local control = self:_Control(id, "MultiDropdown", configuration.Text or "Multiple", row, configuration)
    local open = false
    local buttons = {}

    local function current()
        local out = {}
        for _, option in ipairs(options) do if selected[option] then table.insert(out, option) end end
        return out
    end

    local function renderText()
        local values = current()
        local parts = {}
        for _, item in ipairs(values) do table.insert(parts, tostring(item)) end
        selectedText.Text = #parts > 0 and table.concat(parts, ", ") or (configuration.Placeholder or "Select...")
    end

    local function setOpen(state)
        if control.Disabled then state = false end
        open = state == true
        list.Visible = open
        arrow.Text = open and "^" or "v"
        if open then
            local h = math.min(#options * 35 + 8, configuration.MaxHeight or 190)
            list.Size = UDim2.new(1, 0, 0, h)
            row.Size = UDim2.new(1, 0, 0, 64 + h)
        else
            list.Size = UDim2.new(1, 0, 0, 0)
            row.Size = UDim2.new(1, 0, 0, configuration.Height or app.Config.Layout.DropdownHeight)
        end
    end

    local rebuild
    rebuild = function()
        for _, b in ipairs(buttons) do b:Destroy() end
        table.clear(buttons)
        for _, option in ipairs(options) do
            local item = option
            local choice = create("TextButton", {Parent = list, Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = selected[item] and app.Config.Colors.Accent2 or app.Config.Colors.Control,
                BorderSizePixel = 0, Text = (selected[item] and "[x] " or "[ ] ") .. tostring(item), TextColor3 = app.Config.Colors.Text,
                TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 41})
            corner(choice, app.Config.Radius.Control)
            create("UIPadding", {Parent = choice, PaddingLeft = UDim.new(0, 8)})
            table.insert(buttons, choice)
            control:_Connect(choice.Activated, function()
                if control.Disabled then return end
                local previous = current()
                selected[item] = not selected[item]
                renderText()
                rebuild()
                local now = current()
                self:_Emit(control, "MultiDropdownChanged", now, previous)
                app:_Callback(configuration.Callback, now, control)
            end)
        end
    end

    local function set(newValues, silent)
        local previous = current()
        table.clear(selected)
        for _, item in ipairs(newValues or {}) do selected[item] = true end
        renderText()
        rebuild()
        local now = current()
        if not silent then self:_Emit(control, "MultiDropdownChanged", now, previous) app:_Callback(configuration.Callback, now, control) end
        return now
    end

    control._getter = current
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = function() selector.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or app.Config.Colors.Control if control.Disabled then setOpen(false) end end
    function control:SetOptions(newOptions, keepSelection) options = newOptions or {} if not keepSelection then table.clear(selected) end renderText() rebuild() return self end
    control:_Connect(selector.Activated, function() if not control.Disabled then setOpen(not open) end end)
    renderText()
    rebuild()
    return app:_Register(control)
end

function Section:AddRadioGroup(configuration)
    configuration = configuration or {}
    local app = self.App
    local options = configuration.Options or {}
    local value = configuration.Default
    local row = self:_Row(configuration.Height or (28 + #options * 34))
    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Choice",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local holder = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 1, -27), BackgroundTransparency = 1})
    create("UIListLayout", {Parent = holder, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})

    local id = app:_MakeId("Radio", configuration.Id)
    local control = self:_Control(id, "RadioGroup", configuration.Text or "Choice", row, configuration)
    local entries = {}

    local function render()
        for option, data in pairs(entries) do
            local active = option == value
            data.Circle.BackgroundColor3 = active and app.Config.Colors.Accent or app.Config.Colors.Control
            data.Dot.Visible = active
            data.Label.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
        end
    end

    local function set(newValue, silent)
        local previous = value
        value = newValue
        render()
        if not silent and previous ~= value then self:_Emit(control, "RadioChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end

    for _, option in ipairs(options) do
        local item = option
        local hit = create("TextButton", {Parent = holder, Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false})
        local circle = create("Frame", {Parent = hit, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0})
        corner(circle, 999)
        local dot = create("Frame", {Parent = circle, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = app.Config.Colors.AccentText, BorderSizePixel = 0, Visible = false})
        corner(dot, 999)
        local itemLabel = create("TextLabel", {Parent = hit, Position = UDim2.fromOffset(30, 0), Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1,
            Text = tostring(item), TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
        entries[item] = {Circle = circle, Dot = dot, Label = itemLabel}
        control:_Connect(hit.Activated, function() if not control.Disabled then set(item) end end)
    end

    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = render
    render()
    return app:_Register(control)
end

function Section:AddSegmented(configuration)
    configuration = configuration or {}
    local app = self.App
    local options = configuration.Options or {"One", "Two"}
    local value = configuration.Default or options[1]
    local row = self:_Row(configuration.Height or 66)
    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Mode",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local holder = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0})
    corner(holder, app.Config.Radius.Control)
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})

    local id = app:_MakeId("Segmented", configuration.Id)
    local control = self:_Control(id, "Segmented", configuration.Text or "Mode", row, configuration)
    local buttons = {}

    local function render()
        for option, button in pairs(buttons) do
            button.BackgroundTransparency = option == value and 0 or 1
            button.BackgroundColor3 = option == value and app.Config.Colors.Accent2 or app.Config.Colors.Control
            button.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
        end
    end

    local function set(newValue, silent)
        local previous = value
        value = newValue
        render()
        if not silent and previous ~= value then self:_Emit(control, "SegmentedChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end

    for index, option in ipairs(options) do
        local item = option
        local button = create("TextButton", {Parent = holder, Size = UDim2.new(1 / math.max(#options, 1), -3, 1, 0), BackgroundColor3 = app.Config.Colors.Accent2,
            BackgroundTransparency = 1, BorderSizePixel = 0, Text = tostring(item), TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control,
            Font = app.Config.Fonts.Medium, AutoButtonColor = false, LayoutOrder = index})
        corner(button, app.Config.Radius.Control)
        buttons[item] = button
        control:_Connect(button.Activated, function() if not control.Disabled then set(item) end end)
    end

    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = render
    render()
    return app:_Register(control)
end

function Section:AddProgress(configuration)
    configuration = configuration or {}
    local app = self.App
    local minimum = tonumber(configuration.Min) or 0
    local maximum = tonumber(configuration.Max) or 100
    local value = clamp(tonumber(configuration.Default) or minimum, minimum, maximum)
    local row = self:_Row(configuration.Height or app.Config.Layout.ProgressHeight)
    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, -90, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Progress",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local valueLabel = create("TextLabel", {Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(80, 22), BackgroundTransparency = 1,
        Text = "", TextColor3 = app.Config.Colors.Text2, TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Right, Visible = configuration.ShowValue ~= false})
    local bar = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 9), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0})
    corner(bar, 5)
    local fill = create("Frame", {Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = configuration.Color or app.Config.Colors.Accent, BorderSizePixel = 0})
    corner(fill, 5)

    local id = app:_MakeId("Progress", configuration.Id)
    local control = self:_Control(id, "Progress", configuration.Text or "Progress", row, configuration)
    local function render()
        local a = maximum == minimum and 0 or clamp((value - minimum) / (maximum - minimum), 0, 1)
        fill.Size = UDim2.fromScale(a, 1)
        valueLabel.Text = (configuration.Prefix or "") .. formatNumber(value, configuration.Step or 1) .. (configuration.Suffix or "")
    end
    local function set(newValue, silent)
        newValue = tonumber(newValue)
        if not newValue then return value end
        local previous = value
        value = clamp(newValue, minimum, maximum)
        render()
        if not silent and previous ~= value then self:_Emit(control, "ProgressChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end
    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    render()
    return app:_Register(control)
end

function Section:AddStatus(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Default or "Unknown"
    local row = self:_Row(configuration.Height or 34)
    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, -120, 1, 0), BackgroundTransparency = 1, Text = configuration.Text or "Status",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local badge = create("TextLabel", {Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(110, 26),
        BackgroundColor3 = configuration.Color or app.Config.Colors.Accent2, BorderSizePixel = 0, Text = tostring(value), TextColor3 = app.Config.Colors.Text,
        TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Medium, TextTruncate = Enum.TextTruncate.AtEnd})
    corner(badge, 999)

    local id = app:_MakeId("Status", configuration.Id)
    local control = self:_Control(id, "Status", configuration.Text or "Status", row, configuration)
    local function set(newValue, silent)
        local previous = value
        value = newValue
        badge.Text = tostring(value)
        if not silent and previous ~= value then self:_Emit(control, "StatusChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end
    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    function control:SetColor(color) badge.BackgroundColor3 = color return self end
    return app:_Register(control)
end

function Section:AddImage(configuration)
    if type(configuration) == "string" or type(configuration) == "number" then configuration = {Image = configuration} end
    configuration = configuration or {}
    local app = self.App
    local row = self:_Row(configuration.Height or 170)
    local className = configuration.Callback and "ImageButton" or "ImageLabel"
    local image = create(className, {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.BackgroundColor or app.Config.Colors.Control,
        BackgroundTransparency = configuration.BackgroundTransparency or 0, BorderSizePixel = 0, Image = imageId(configuration.Image),
        ImageColor3 = configuration.ImageColor or Color3.new(1, 1, 1), ImageTransparency = configuration.ImageTransparency or 0,
        ScaleType = configuration.ScaleType or Enum.ScaleType.Fit})
    corner(image, configuration.Radius or app.Config.Radius.Control)
    local id = app:_MakeId("Image", configuration.Id)
    local control = self:_Control(id, "Image", configuration.Text or "Image", row, configuration)
    control._getter = function() return image.Image end
    control._setter = function(value, silent)
        local previous = image.Image
        image.Image = imageId(value)
        if not silent and previous ~= image.Image then self:_Emit(control, "ImageChanged", image.Image, previous) end
        return image.Image
    end
    function control:SetImageColor(color) image.ImageColor3 = color return self end
    function control:SetImageTransparency(value) image.ImageTransparency = value return self end
    if image:IsA("ImageButton") then control:_Connect(image.Activated, function() if not control.Disabled then self:_Emit(control, "ImagePressed", image.Image, nil) app:_Callback(configuration.Callback, control) end end) end
    return app:_Register(control)
end

function Section:AddKeybind(configuration)
    configuration = configuration or {}
    local app = self.App
    local binding = configuration.Default or Enum.KeyCode.Unknown
    local capturing = false
    local row = self:_Row(configuration.Height or app.Config.Layout.KeybindHeight)

    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, -140, 1, 0), BackgroundTransparency = 1, Text = configuration.Text or "Keybind",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local button = create("TextButton", {Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(130, 32),
        BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = bindName(binding), TextColor3 = app.Config.Colors.Accent,
        TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Medium, AutoButtonColor = false})
    corner(button, app.Config.Radius.Control)

    local id = app:_MakeId("Keybind", configuration.Id)
    local control = self:_Control(id, "Keybind", configuration.Text or "Keybind", row, configuration)

    local function render()
        button.Text = capturing and "Press a key..." or bindName(binding)
        button.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or app.Config.Colors.Control
        label.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
    end

    local function set(newBinding, silent)
        if typeof(newBinding) ~= "EnumItem" then return binding end
        local previous = binding
        binding = newBinding
        render()
        if not silent and previous ~= binding then self:_Emit(control, "KeybindChanged", binding, previous) app:_Callback(configuration.Changed, binding, control) end
        return binding
    end

    control._getter = function() return binding end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = render
    control:_Connect(button.Activated, function() if not control.Disabled then capturing = true render() end end)
    control:_Connect(UserInputService.InputBegan, function(input, processed)
        if capturing then
            if input.KeyCode == Enum.KeyCode.Escape then capturing = false render() return end
            if input.UserInputType == Enum.UserInputType.Keyboard then capturing = false set(input.KeyCode) return end
            if configuration.AllowMouse ~= false and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3) then
                capturing = false
                set(input.UserInputType)
                return
            end
            return
        end
        if processed or control.Disabled then return end
        if configuration.IgnoreWhileTyping ~= false and UserInputService:GetFocusedTextBox() then return end
        if matches(input, binding) then
            self:_Emit(control, "KeybindTriggered", binding, nil)
            app:_Callback(configuration.Callback, binding, control)
        end
    end)
    render()
    return app:_Register(control)
end

function Section:AddPlayerCard(configuration)
    configuration = configuration or {}
    local app = self.App
    local player = configuration.Player or Players.LocalPlayer
    local row = self:_Row(configuration.Height or app.Config.Layout.PlayerCardHeight)
    local background = create("Frame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0})
    corner(background, app.Config.Radius.Control)
    if app.Config.Stroke.Enabled then stroke(background, app.Config.Colors.Border, 1, 0) end
    local avatar = create("ImageLabel", {Parent = background, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.fromOffset(54, 54),
        BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, Image = ""})
    corner(avatar, app.Config.Radius.Avatar)
    local displayName = create("TextLabel", {Parent = background, Position = UDim2.fromOffset(74, 13), Size = UDim2.new(1, -84, 0, 23), BackgroundTransparency = 1,
        Text = "", TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control + 1, Font = app.Config.Fonts.Bold, TextXAlignment = Enum.TextXAlignment.Left})
    local username = create("TextLabel", {Parent = background, Position = UDim2.fromOffset(74, 36), Size = UDim2.new(1, -84, 0, 20), BackgroundTransparency = 1,
        Text = "", TextColor3 = app.Config.Colors.Text2, TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})

    local id = app:_MakeId("PlayerCard", configuration.Id)
    local control = self:_Control(id, "PlayerCard", "Player", row, configuration)
    local function setPlayer(newPlayer, silent)
        if typeof(newPlayer) ~= "Instance" or not newPlayer:IsA("Player") then return player end
        local previous = player
        player = newPlayer
        displayName.Text = player.DisplayName
        username.Text = "@" .. player.Name
        local userId = player.UserId
        task.spawn(function()
            local ok, thumbnail = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            if ok and avatar.Parent and player and player.UserId == userId then avatar.Image = thumbnail end
        end)
        if not silent and previous ~= player then self:_Emit(control, "PlayerCardChanged", player, previous) end
        return player
    end
    control._getter = function() return player end
    control._setter = setPlayer
    setPlayer(player, true)
    return app:_Register(control)
end

function Section:AddPlayerPicker(configuration)
    configuration = configuration or {}
    local app = self.App
    local selectedPlayer = configuration.Default
    local row = self:_Row(configuration.Height or app.Config.Layout.DropdownHeight)
    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Player",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local selector = create("TextButton", {Parent = row, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = "", AutoButtonColor = false})
    corner(selector, app.Config.Radius.Control)
    local selectedText = create("TextLabel", {Parent = selector, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1,
        Text = configuration.Placeholder or "Select player...", TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})
    local arrow = create("TextLabel", {Parent = selector, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(22, 34),
        BackgroundTransparency = 1, Text = "v", TextColor3 = app.Config.Colors.Text2, TextSize = 11})
    local list = create("ScrollingFrame", {Parent = row, Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = app.Config.Colors.Background2,
        BorderSizePixel = 0, Visible = false, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 40})
    corner(list, app.Config.Radius.Control)
    create("UIListLayout", {Parent = list, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})

    local id = app:_MakeId("PlayerPicker", configuration.Id)
    local control = self:_Control(id, "PlayerPicker", configuration.Text or "Player", row, configuration)
    local open = false
    local itemButtons = {}

    local function resolve(value)
        if value == nil then return nil end
        if typeof(value) == "Instance" and value:IsA("Player") then return value end
        local text = string.lower(tostring(value))
        for _, player in ipairs(Players:GetPlayers()) do
            if tostring(player.UserId) == tostring(value) or string.lower(player.Name) == text or string.lower(player.DisplayName) == text then return player end
        end
        return nil
    end

    local function setOpen(state)
        if control.Disabled then state = false end
        open = state == true
        list.Visible = open
        arrow.Text = open and "^" or "v"
        if open then
            local h = math.min(#Players:GetPlayers() * 56 + 10, configuration.MaxHeight or 240)
            list.Size = UDim2.new(1, 0, 0, h)
            row.Size = UDim2.new(1, 0, 0, 64 + h)
        else
            list.Size = UDim2.new(1, 0, 0, 0)
            row.Size = UDim2.new(1, 0, 0, configuration.Height or app.Config.Layout.DropdownHeight)
        end
    end

    local function render()
        selectedText.Text = selectedPlayer and (selectedPlayer.DisplayName .. "  @" .. selectedPlayer.Name) or (configuration.Placeholder or "Select player...")
        selector.BackgroundColor3 = control.Disabled and app.Config.Colors.ControlDisabled or app.Config.Colors.Control
    end

    local function set(newValue, silent)
        local newPlayer = resolve(newValue)
        if newValue ~= nil and not newPlayer then return selectedPlayer end
        local previous = selectedPlayer
        selectedPlayer = newPlayer
        render()
        if not silent and previous ~= selectedPlayer then self:_Emit(control, "PlayerSelected", selectedPlayer, previous) app:_Callback(configuration.Callback, selectedPlayer, control) end
        return selectedPlayer
    end

    local function rebuild()
        for _, item in ipairs(itemButtons) do item:Destroy() end
        table.clear(itemButtons)
        local playerList = Players:GetPlayers()
        table.sort(playerList, function(a, b) return string.lower(a.DisplayName) < string.lower(b.DisplayName) end)
        for _, player in ipairs(playerList) do
            local currentPlayer = player
            if not configuration.ExcludeLocalPlayer or currentPlayer ~= Players.LocalPlayer then
                local choice = create("TextButton", {Parent = list, Size = UDim2.new(1, -10, 0, 52), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 41})
                corner(choice, app.Config.Radius.Control)
                table.insert(itemButtons, choice)
                local avatar = create("ImageLabel", {Parent = choice, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(40, 40),
                    BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, Image = "", ZIndex = 42})
                corner(avatar, app.Config.Radius.Avatar)
                create("TextLabel", {Parent = choice, Position = UDim2.fromOffset(55, 6), Size = UDim2.new(1, -62, 0, 20), BackgroundTransparency = 1,
                    Text = currentPlayer.DisplayName, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Medium,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42})
                create("TextLabel", {Parent = choice, Position = UDim2.fromOffset(55, 26), Size = UDim2.new(1, -62, 0, 18), BackgroundTransparency = 1,
                    Text = "@" .. currentPlayer.Name, TextColor3 = app.Config.Colors.Text2, TextSize = app.Config.TextSizes.Tiny + 1, Font = app.Config.Fonts.Normal,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42})
                local userId = currentPlayer.UserId
                task.spawn(function()
                    local ok, thumb = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                    if ok and avatar.Parent then avatar.Image = thumb end
                end)
                control:_Connect(choice.Activated, function() if not control.Disabled then set(currentPlayer) setOpen(false) end end)
            end
        end
        if open then setOpen(true) end
    end

    control._getter = function() return selectedPlayer end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = function() render() if control.Disabled then setOpen(false) end end
    function control:Refresh() rebuild() return self end
    control:_Connect(selector.Activated, function() if not control.Disabled then setOpen(not open) end end)
    control:_Connect(Players.PlayerAdded, rebuild)
    control:_Connect(Players.PlayerRemoving, function(player) if selectedPlayer == player then set(nil) end task.defer(rebuild) end)
    rebuild()
    if selectedPlayer then set(selectedPlayer, true) end
    render()
    return app:_Register(control)
end

function Section:AddPlayerList(configuration)
    configuration = configuration or {}
    local app = self.App
    local selectedPlayer = nil
    local row = self:_Row(configuration.Height or 260)
    local holder = create("ScrollingFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0,
        ScrollBarThickness = app.Config.Layout.ScrollbarThickness, ScrollBarImageColor3 = app.Config.Colors.Scrollbar, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()})
    corner(holder, app.Config.Radius.Control)
    create("UIListLayout", {Parent = holder, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = holder, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})

    local id = app:_MakeId("PlayerList", configuration.Id)
    local control = self:_Control(id, "PlayerList", configuration.Text or "Players", row, configuration)
    local entries = {}

    local function set(player, silent)
        if player ~= nil and (typeof(player) ~= "Instance" or not player:IsA("Player")) then return selectedPlayer end
        local previous = selectedPlayer
        selectedPlayer = player
        for target, button in pairs(entries) do button.BackgroundColor3 = target == selectedPlayer and app.Config.Colors.Accent2 or app.Config.Colors.Control end
        if not silent and previous ~= selectedPlayer then self:_Emit(control, "PlayerListSelected", selectedPlayer, previous) app:_Callback(configuration.Callback, selectedPlayer, control) end
        return selectedPlayer
    end

    local function rebuild()
        for _, button in pairs(entries) do button:Destroy() end
        table.clear(entries)
        local playerList = Players:GetPlayers()
        table.sort(playerList, function(a, b) return string.lower(a.DisplayName) < string.lower(b.DisplayName) end)
        for _, player in ipairs(playerList) do
            local currentPlayer = player
            if not configuration.ExcludeLocalPlayer or currentPlayer ~= Players.LocalPlayer then
                local button = create("TextButton", {Parent = holder, Size = UDim2.new(1, -12, 0, 50), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = "", AutoButtonColor = false})
                corner(button, app.Config.Radius.Control)
                entries[currentPlayer] = button
                local avatar = create("ImageLabel", {Parent = button, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 5, 0.5, 0), Size = UDim2.fromOffset(38, 38),
                    BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, Image = ""})
                corner(avatar, app.Config.Radius.Avatar)
                create("TextLabel", {Parent = button, Position = UDim2.fromOffset(52, 5), Size = UDim2.new(1, -58, 0, 20), BackgroundTransparency = 1,
                    Text = currentPlayer.DisplayName, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Medium, TextXAlignment = Enum.TextXAlignment.Left})
                create("TextLabel", {Parent = button, Position = UDim2.fromOffset(52, 25), Size = UDim2.new(1, -58, 0, 18), BackgroundTransparency = 1,
                    Text = "@" .. currentPlayer.Name, TextColor3 = app.Config.Colors.Text2, TextSize = app.Config.TextSizes.Tiny + 1, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
                local userId = currentPlayer.UserId
                task.spawn(function()
                    local ok, thumb = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                    if ok and avatar.Parent then avatar.Image = thumb end
                end)
                control:_Connect(button.Activated, function() if not control.Disabled then set(currentPlayer) end end)
            end
        end
        set(selectedPlayer, true)
    end

    control._getter = function() return selectedPlayer end
    control._setter = set
    function control:Refresh() rebuild() return self end
    control:_Connect(Players.PlayerAdded, rebuild)
    control:_Connect(Players.PlayerRemoving, function(player) if selectedPlayer == player then selectedPlayer = nil end task.defer(rebuild) end)
    rebuild()
    return app:_Register(control)
end


