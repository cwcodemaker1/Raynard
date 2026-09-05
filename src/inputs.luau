function Section:AddIconButton(configuration)
    configuration = configuration or {}
    local app = self.App
    local row = self:_Row(configuration.Height or app.Config.Layout.ButtonHeight)
    local button = create("TextButton", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.Color or app.Config.Colors.Control, BorderSizePixel = 0, Text = "", AutoButtonColor = false})
    corner(button, app.Config.Radius.Button)
    local image = create("ImageLabel", {Parent = button, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(configuration.IconSize or 20, configuration.IconSize or 20), BackgroundTransparency = 1, Image = imageId(configuration.Icon), ImageColor3 = configuration.IconColor or app.Config.Colors.Text})
    local label = valueLabel(button, app, configuration.Text or "Icon Button", UDim2.fromOffset(40, 0), UDim2.new(1, -50, 1, 0))
    label.Font = app.Config.Fonts.Medium
    local id = app:_MakeId("IconButton", configuration.Id)
    local control = self:_Control(id, "IconButton", configuration.Text or "Icon Button", row, configuration)
    control._textSetter = function(text) label.Text = text end
    control:_Connect(button.Activated, function()
        if control.Disabled then return end
        self:_Emit(control, "IconButtonPressed", true, nil)
        app:_Callback(configuration.Callback, control)
    end)
    function control:SetIcon(icon) image.Image = imageId(icon) return self end
    function control:SetIconColor(color) image.ImageColor3 = color return self end
    return app:_Register(control)
end

function Section:AddHoldButton(configuration)
    configuration = configuration or {}
    local app = self.App
    local required = tonumber(configuration.HoldTime) or 1
    local row = self:_Row(configuration.Height or app.Config.Layout.ButtonHeight)
    local button = create("TextButton", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.Color or app.Config.Colors.Control, BorderSizePixel = 0, Text = configuration.Text or "Hold", TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Medium, AutoButtonColor = false})
    corner(button, app.Config.Radius.Button)
    local fill = create("Frame", {Parent = button, Size = UDim2.fromScale(0, 1), BackgroundColor3 = configuration.Accent or app.Config.Colors.Accent2, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 0})
    corner(fill, app.Config.Radius.Button)
    local id = app:_MakeId("HoldButton", configuration.Id)
    local control = self:_Control(id, "HoldButton", configuration.Text or "Hold", row, configuration)
    local holding = false
    local started = 0
    local heartbeat
    local function stop(completed)
        holding = false
        if heartbeat then heartbeat:Disconnect() heartbeat = nil end
        fill.Size = UDim2.fromScale(0, 1)
        if completed then
            self:_Emit(control, "HoldCompleted", required, nil)
            app:_Callback(configuration.Callback, control)
        else
            self:_Emit(control, "HoldCancelled", 0, nil)
        end
    end
    control:_Connect(button.InputBegan, function(input)
        if control.Disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            holding = true
            started = os.clock()
            heartbeat = RunService.Heartbeat:Connect(function()
                if not holding then return end
                local elapsed = os.clock() - started
                fill.Size = UDim2.fromScale(clamp(elapsed / required, 0, 1), 1)
                if elapsed >= required then stop(true) end
            end)
        end
    end)
    control:_Connect(button.InputEnded, function(input)
        if holding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then stop(false) end
    end)
    control._textSetter = function(text) button.Text = text end
    return app:_Register(control)
end

function Section:AddDoubleClickButton(configuration)
    configuration = configuration or {}
    local app = self.App
    local interval = tonumber(configuration.Interval) or 0.35
    local row = self:_Row(configuration.Height or app.Config.Layout.ButtonHeight)
    local button = create("TextButton", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.Color or app.Config.Colors.Control, BorderSizePixel = 0, Text = configuration.Text or "Double click", TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Medium, AutoButtonColor = false})
    corner(button, app.Config.Radius.Button)
    local last = -math.huge
    local id = app:_MakeId("DoubleClickButton", configuration.Id)
    local control = self:_Control(id, "DoubleClickButton", configuration.Text or "Double click", row, configuration)
    control:_Connect(button.Activated, function()
        if control.Disabled then return end
        local now = os.clock()
        if now - last <= interval then
            last = -math.huge
            self:_Emit(control, "DoubleClicked", true, nil)
            app:_Callback(configuration.Callback, control)
        else
            last = now
            self:_Emit(control, "FirstClick", true, nil)
        end
    end)
    control._textSetter = function(text) button.Text = text end
    return app:_Register(control)
end

function Section:AddStepper(configuration)
    configuration = configuration or {}
    local app = self.App
    local minimum = tonumber(configuration.Min) or 0
    local maximum = tonumber(configuration.Max) or 100
    local step = tonumber(configuration.Step) or 1
    local value = stepValue(tonumber(configuration.Default) or minimum, minimum, maximum, step)
    local row = self:_Row(configuration.Height or 42)
    local label = valueLabel(row, app, configuration.Text or "Value", UDim2.fromOffset(0, 0), UDim2.new(1, -190, 1, 0))
    local box = create("Frame", {Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(180, 34), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0})
    corner(box, app.Config.Radius.Control)
    local minus = create("TextButton", {Parent = box, Size = UDim2.fromOffset(36, 34), BackgroundTransparency = 1, Text = "-", TextColor3 = app.Config.Colors.Text, TextSize = 18, Font = app.Config.Fonts.Bold})
    local plus = create("TextButton", {Parent = box, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(36, 34), BackgroundTransparency = 1, Text = "+", TextColor3 = app.Config.Colors.Text, TextSize = 18, Font = app.Config.Fonts.Bold})
    local display = valueLabel(box, app, value, UDim2.fromOffset(36, 0), UDim2.new(1, -72, 1, 0))
    display.TextXAlignment = Enum.TextXAlignment.Center
    display.Font = app.Config.Fonts.Medium
    local id = app:_MakeId("Stepper", configuration.Id)
    local control = self:_Control(id, "Stepper", configuration.Text or "Value", row, configuration)
    local function set(newValue, silent)
        newValue = tonumber(newValue)
        if not newValue then return value end
        local previous = value
        value = stepValue(newValue, minimum, maximum, step)
        display.Text = (configuration.Prefix or "") .. formatNumber(value, step) .. (configuration.Suffix or "")
        if not silent and previous ~= value then self:_Emit(control, "StepperChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end
    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control:_Connect(minus.Activated, function() if not control.Disabled then set(value - step) end end)
    control:_Connect(plus.Activated, function() if not control.Disabled then set(value + step) end end)
    set(value, true)
    return app:_Register(control)
end

function Section:AddRangeSlider(configuration)
    configuration = configuration or {}
    local app = self.App
    local minimum = tonumber(configuration.Min) or 0
    local maximum = tonumber(configuration.Max) or 100
    local step = tonumber(configuration.Step) or 1
    local low = stepValue(tonumber(configuration.Low or configuration.DefaultLow) or minimum, minimum, maximum, step)
    local high = stepValue(tonumber(configuration.High or configuration.DefaultHigh) or maximum, minimum, maximum, step)
    if low > high then low, high = high, low end
    local row = self:_Row(configuration.Height or 68)
    local label = valueLabel(row, app, configuration.Text or "Range", UDim2.fromOffset(0, 0), UDim2.new(1, -160, 0, 24))
    local display = valueLabel(row, app, "", UDim2.new(1, -155, 0, 0), UDim2.fromOffset(155, 24))
    display.TextXAlignment = Enum.TextXAlignment.Right
    display.TextColor3 = app.Config.Colors.Accent
    local track = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Active = true})
    corner(track, 4)
    local fill = create("Frame", {Parent = track, BackgroundColor3 = configuration.Accent or app.Config.Colors.Accent, BorderSizePixel = 0})
    corner(fill, 4)
    local lowKnob = create("Frame", {Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = configuration.Accent or app.Config.Colors.Accent, BorderSizePixel = 0})
    corner(lowKnob, 8)
    local highKnob = lowKnob:Clone() highKnob.Parent = track
    local id = app:_MakeId("RangeSlider", configuration.Id)
    local control = self:_Control(id, "RangeSlider", configuration.Text or "Range", row, configuration)
    local dragging = nil
    local function alpha(v) return maximum == minimum and 0 or clamp((v - minimum) / (maximum - minimum), 0, 1) end
    local function render()
        local a1, a2 = alpha(low), alpha(high)
        lowKnob.Position = UDim2.fromScale(a1, 0.5)
        highKnob.Position = UDim2.fromScale(a2, 0.5)
        fill.Position = UDim2.fromScale(a1, 0)
        fill.Size = UDim2.fromScale(a2 - a1, 1)
        display.Text = formatNumber(low, step) .. " - " .. formatNumber(high, step)
    end
    local function get() return {Low = low, High = high} end
    local function set(newValue, silent)
        if type(newValue) ~= "table" then return get() end
        local previous = get()
        local nl = tonumber(newValue.Low or newValue[1]) or low
        local nh = tonumber(newValue.High or newValue[2]) or high
        nl = stepValue(nl, minimum, maximum, step)
        nh = stepValue(nh, minimum, maximum, step)
        if nl > nh then nl, nh = nh, nl end
        low, high = nl, nh
        render()
        if not silent and (previous.Low ~= low or previous.High ~= high) then self:_Emit(control, "RangeChanged", get(), previous) app:_Callback(configuration.Callback, get(), control) end
        return get()
    end
    local function fromX(x)
        if control.Disabled or track.AbsoluteSize.X <= 0 then return end
        local a = clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local target = stepValue(minimum + (maximum - minimum) * a, minimum, maximum, step)
        if dragging == "Low" then low = math.min(target, high) else high = math.max(target, low) end
        local current = get() render() self:_Emit(control, "RangeChanged", current, nil) app:_Callback(configuration.Callback, current, control)
    end
    control._getter = get
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control:_Connect(track.InputBegan, function(input)
        if control.Disabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local x = input.Position.X
            local a = clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local target = minimum + (maximum - minimum) * a
            dragging = math.abs(target - low) <= math.abs(target - high) and "Low" or "High"
            fromX(x)
        end
    end)
    control:_Connect(UserInputService.InputChanged, function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then fromX(input.Position.X) end end)
    control:_Connect(UserInputService.InputEnded, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = nil end end)
    render()
    return app:_Register(control)
end

function Section:AddPasswordBox(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = tostring(configuration.Default or "")
    local revealed = configuration.Revealed == true
    local row = self:_Row(configuration.Height or app.Config.Layout.TextboxHeight)
    local label = valueLabel(row, app, configuration.Text or "Password", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local box = create("TextBox", {Parent = row, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, -42, 0, 34), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = value, PlaceholderText = configuration.Placeholder or "Password", PlaceholderColor3 = app.Config.Colors.Text2, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left})
    corner(box, app.Config.Radius.Control)
    create("UIPadding", {Parent = box, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)})
    local reveal = create("TextButton", {Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 27), Size = UDim2.fromOffset(36, 34), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = revealed and "Hide" or "Show", TextColor3 = app.Config.Colors.Text2, TextSize = 10, Font = app.Config.Fonts.Medium})
    corner(reveal, app.Config.Radius.Control)
    local id = app:_MakeId("PasswordBox", configuration.Id)
    local control = self:_Control(id, "PasswordBox", configuration.Text or "Password", row, configuration)
    local focused = false
    local function render()
        if focused or revealed then box.Text = value else box.Text = string.rep(configuration.MaskCharacter or "*", #value) end
        reveal.Text = revealed and "Hide" or "Show"
    end
    local function set(newValue, silent)
        local previous = value
        value = tostring(newValue or "")
        render()
        if not silent and previous ~= value then self:_Emit(control, "PasswordChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end
    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    function control:SetRevealed(state) revealed = state == true render() return self end
    control:_Connect(box.Focused, function() focused = true box.Text = value box.CursorPosition = #value + 1 end)
    control:_Connect(box.FocusLost, function() focused = false set(box.Text) render() end)
    control:_Connect(reveal.Activated, function() if not control.Disabled then revealed = not revealed render() end end)
    render()
    return app:_Register(control)
end

Section.AddTokenBox = Section.AddPasswordBox

function Section:AddSearchBox(configuration)
    configuration = configuration or {}
    configuration.Text = configuration.Text or "Search"
    configuration.Placeholder = configuration.Placeholder or "Search..."
    configuration.Live = true
    local userCallback = configuration.Callback
    configuration.Callback = function(value, control)
        self.App:_Emit("SearchChanged", control.Id, value)
        if userCallback then userCallback(value, control) end
    end
    return self:AddTextbox(configuration)
end

function Section:AddCodeBox(configuration)
    configuration = configuration or {}
    configuration.Text = configuration.Text or "Code"
    configuration.MultiLine = true
    configuration.Monospace = true
    configuration.Height = configuration.Height or 180
    return self:AddTextbox(configuration)
end

function Section:_AddValidatedInput(configuration, kind, validator, formatter)
    configuration = configuration or {}
    local app = self.App
    local original = configuration.Callback
    local control
    configuration.Callback = function(value, c)
        local valid, normalized = validator(value)
        if normalized ~= nil and normalized ~= value then c:Set(normalized, true) value = normalized end
        app:_Emit(kind .. "Validation", c.Id, valid, {Text = value})
        if original then original(value, valid, c) end
    end
    control = self:AddTextbox(configuration)
    control.Kind = kind
    function control:IsValid()
        local valid = validator(self:Get())
        return valid == true
    end
    if formatter then
        function control:Format()
            local formatted = formatter(self:Get())
            if formatted then self:Set(formatted) end
            return self
        end
    end
    return control
end

function Section:AddURLBox(configuration)
    configuration = configuration or {} configuration.Text = configuration.Text or "URL"
    return self:_AddValidatedInput(configuration, "URLBox", function(value)
        value = tostring(value or "")
        return value == "" or value:match("^https?://[%w%-%._~:/%?#%[%]@!$&'()*+,;=%%]+$") ~= nil
    end)
end

function Section:AddEmailBox(configuration)
    configuration = configuration or {} configuration.Text = configuration.Text or "Email"
    return self:_AddValidatedInput(configuration, "EmailBox", function(value)
        value = tostring(value or "")
        return value == "" or value:match("^[%w%._%%+%-]+@[%w%.%-]+%.[%a]+$") ~= nil
    end)
end

function Section:AddIPBox(configuration)
    configuration = configuration or {} configuration.Text = configuration.Text or "IP Address"
    return self:_AddValidatedInput(configuration, "IPBox", function(value)
        value = tostring(value or "")
        if value == "" then return true end
        local a, b, c, d = value:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
        if not a then return false end
        for _, part in ipairs({a, b, c, d}) do if tonumber(part) > 255 then return false end end
        return true
    end)
end

function Section:AddPortInput(configuration)
    configuration = configuration or {} configuration.Text = configuration.Text or "Port" configuration.Default = configuration.Default or 80 configuration.Min = 0 configuration.Max = 65535
    return self:AddNumberbox(configuration)
end

function Section:AddPercentInput(configuration)
    configuration = configuration or {} configuration.Text = configuration.Text or "Percent" configuration.Default = configuration.Default or 0 configuration.Min = configuration.Min or 0 configuration.Max = configuration.Max or 100
    local c = self:AddNumberbox(configuration)
    c.Kind = "PercentInput"
    return c
end

function Section:AddTagInput(configuration)
    configuration = configuration or {}
    local app = self.App
    local tags = shallowArrayCopy(configuration.Default or {})
    local row = self:_Row(configuration.Height or 104)
    local label = valueLabel(row, app, configuration.Text or "Tags", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local input = create("TextBox", {Parent = row, Position = UDim2.fromOffset(0, 27), Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = "", PlaceholderText = configuration.Placeholder or "Type a tag and press Enter", PlaceholderColor3 = app.Config.Colors.Text2, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left})
    corner(input, app.Config.Radius.Control)
    create("UIPadding", {Parent = input, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)})
    local holder = create("ScrollingFrame", {Parent = row, Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder})
    local id = app:_MakeId("TagInput", configuration.Id)
    local control = self:_Control(id, "TagInput", configuration.Text or "Tags", row, configuration)
    local chips = {}
    local function copyTags() return shallowArrayCopy(tags) end
    local function emit(previous)
        self:_Emit(control, "TagsChanged", copyTags(), previous)
        app:_Callback(configuration.Callback, copyTags(), control)
    end
    local function render()
        for _, chip in ipairs(chips) do chip:Destroy() end
        table.clear(chips)
        for index, tag in ipairs(tags) do
            local text = tostring(tag)
            local width = math.max(55, math.min(180, #text * 8 + 28))
            local chip = create("TextButton", {Parent = holder, Size = UDim2.fromOffset(width, 28), BackgroundColor3 = app.Config.Colors.Accent2, BorderSizePixel = 0, Text = text .. "  x", TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Medium, AutoButtonColor = false})
            corner(chip, 999)
            table.insert(chips, chip)
            control:_Connect(chip.Activated, function()
                if control.Disabled then return end
                local previous = copyTags()
                table.remove(tags, index)
                render() emit(previous)
            end)
        end
    end
    local function addTag(text)
        text = tostring(text or ""):match("^%s*(.-)%s*$")
        if text == "" then return end
        if configuration.MaxTags and #tags >= configuration.MaxTags then return end
        if configuration.Unique ~= false then for _, tag in ipairs(tags) do if string.lower(tostring(tag)) == string.lower(text) then return end end end
        local previous = copyTags()
        table.insert(tags, text)
        render() emit(previous)
    end
    local function set(values, silent)
        local previous = copyTags()
        tags = shallowArrayCopy(values or {})
        render()
        if not silent then emit(previous) end
        return copyTags()
    end
    control._getter = copyTags
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    function control:Add(value) addTag(value) return self end
    function control:Remove(value)
        local previous = copyTags()
        for i = #tags, 1, -1 do if tostring(tags[i]) == tostring(value) then table.remove(tags, i) end end
        render() emit(previous) return self
    end
    function control:Clear() return self:Set({}) end
    control:_Connect(input.FocusLost, function(enter) if enter and not control.Disabled then addTag(input.Text) input.Text = "" end end)
    render()
    return app:_Register(control)
end

function Section:AddChipGroup(configuration)
    configuration = configuration or {}
    local app = self.App
    local options = configuration.Options or {}
    local selected = configuration.Default
    local row = self:_Row(configuration.Height or 70)
    local label = valueLabel(row, app, configuration.Text or "Options", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local holder = create("ScrollingFrame", {Parent = row, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new()})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
    local id = app:_MakeId("ChipGroup", configuration.Id)
    local control = self:_Control(id, "ChipGroup", configuration.Text or "Options", row, configuration)
    local buttons = {}
    local function render()
        for option, button in pairs(buttons) do
            local active = option == selected
            button.BackgroundColor3 = active and app.Config.Colors.Accent2 or app.Config.Colors.Control
            button.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
        end
    end
    local function set(value, silent)
        local previous = selected
        selected = value
        render()
        if not silent and previous ~= selected then self:_Emit(control, "ChipSelected", selected, previous) app:_Callback(configuration.Callback, selected, control) end
        return selected
    end
    for _, option in ipairs(options) do
        local item = option
        local text = tostring(item)
        local button = create("TextButton", {Parent = holder, Size = UDim2.fromOffset(math.max(60, #text * 8 + 24), 30), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = text, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Medium, AutoButtonColor = false})
        corner(button, 999)
        buttons[item] = button
        control:_Connect(button.Activated, function() if not control.Disabled then set(item) end end)
    end
    control._getter = function() return selected end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = render
    render()
    return app:_Register(control)
end
