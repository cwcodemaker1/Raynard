-- Raynard fragment: 10_window_sections.luau
-- Loaded by parser.luau; do not execute this fragment alone.

local Control = {}
Control.__index = Control

function Control.new(app, id, kind, label, root)
    return setmetatable({
        App = app,
        Id = id,
        Kind = kind,
        Label = label,
        Root = root,
        Disabled = false,
        Visible = true,
        _connections = {},
        _getter = nil,
        _setter = nil,
        _textSetter = nil,
        _disabledRenderer = nil,
        _destroyed = false,
    }, Control)
end

function Control:_Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self._connections, c)
    return c
end

function Control:Get()
    return self._getter and self._getter() or nil
end

function Control:Set(value, silent)
    if self._setter then return self._setter(value, silent) end
end

function Control:SetText(text)
    self.Label = tostring(text)
    if self._textSetter then self._textSetter(self.Label) end
    return self
end

function Control:SetVisible(visible)
    self.Visible = visible == true
    if self.Root then self.Root.Visible = self.Visible end
    return self
end

function Control:SetDisabled(disabled)
    self.Disabled = disabled == true
    if self._disabledRenderer then self._disabledRenderer(self.Disabled) end
    return self
end

function Control:IsDisabled()
    return self.Disabled
end

function Control:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, c in ipairs(self._connections) do pcall(function() c:Disconnect() end) end
    table.clear(self._connections)
    if self.App and self.App.Controls[self.Id] == self then self.App.Controls[self.Id] = nil end
    if self.Root then self.Root:Destroy() end
end

local Tab = {}
Tab.__index = Tab
local Section = {}
Section.__index = Section

function Library.new(configuration)
    local localPlayer = Players.LocalPlayer
    if not localPlayer then error("Raynard must be created from a LocalScript/client context") end

    local self = setmetatable({}, Library)
    self.Config = deepMerge(DEFAULT, configuration or {})
    self.Title = self.Config.Title
    self.Subtitle = self.Config.Subtitle
    self.ToggleKey = self.Config.ToggleKey
    self.Feedback = Signal.new()
    self.Controls = {}
    self.Tabs = {}
    self.Sections = {}
    self._connections = {}
    self._idCounter = 0
    self._selectedTab = nil
    self._destroyed = false
    self._minimized = false
    self._maximized = false
    self._expandedSize = sizeUDim(self.Config.Window.Size)
    self._lastPosition = nil
    self._lastSize = nil

    local parent = self.Config.Parent or localPlayer:WaitForChild("PlayerGui")
    local gui = create("ScreenGui", {
        Name = self.Config.Name,
        Parent = parent,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = self.Config.DisplayOrder,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Enabled = self.Config.Window.StartVisible,
    })
    self.Gui = gui

    local main = create("Frame", {
        Name = "Window",
        Parent = gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = self.Config.Window.Position,
        Size = sizeUDim(self.Config.Window.Size),
        BackgroundColor3 = self.Config.Colors.Background,
        BackgroundTransparency = self.Config.Transparency.Window,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    corner(main, self.Config.Radius.Window)
    if self.Config.Stroke.Enabled then stroke(main, self.Config.Colors.Border, self.Config.Stroke.Thickness, self.Config.Stroke.Transparency) end
    self.Main = main

    local topbar = create("Frame", {
        Name = "Topbar",
        Parent = main,
        Size = UDim2.new(1, 0, 0, self.Config.Layout.TopbarHeight),
        BackgroundColor3 = self.Config.Colors.Background2,
        BackgroundTransparency = self.Config.Transparency.Topbar,
        BorderSizePixel = 0,
        Active = true,
    })
    self.Topbar = topbar

    self.TitleLabel = create("TextLabel", {
        Parent = topbar,
        Position = UDim2.fromOffset(14, 6),
        Size = UDim2.new(1, -150, 0, 21),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = self.Config.Colors.Text,
        TextSize = self.Config.TextSizes.Title,
        Font = self.Config.Fonts.Title,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    self.SubtitleLabel = create("TextLabel", {
        Parent = topbar,
        Position = UDim2.fromOffset(14, 27),
        Size = UDim2.new(1, -150, 0, 16),
        BackgroundTransparency = 1,
        Text = self.Subtitle,
        TextColor3 = self.Config.Colors.Text2,
        TextSize = self.Config.TextSizes.Subtitle,
        Font = self.Config.Fonts.Subtitle,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local buttons = create("Frame", {
        Parent = topbar,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(116, 32),
        BackgroundTransparency = 1,
    })
    create("UIListLayout", {Parent = buttons, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 6)})

    local function windowButton(name, text, visible)
        local b = create("TextButton", {
            Name = name,
            Parent = buttons,
            Size = UDim2.fromOffset(32, 30),
            BackgroundColor3 = self.Config.Colors.Control,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = self.Config.Colors.Text,
            TextSize = 14,
            Font = self.Config.Fonts.Medium,
            AutoButtonColor = false,
            Visible = visible,
        })
        corner(b, self.Config.Radius.Button)
        return b
    end

    self.MinimizeButton = windowButton("Minimize", "-", self.Config.Window.Minimizable)
    self.MaximizeButton = windowButton("Maximize", "[]", self.Config.Window.Maximizable)
    self.CloseButton = windowButton("Close", "X", self.Config.Window.Closable)

    local body = create("Frame", {
        Name = "Body",
        Parent = main,
        Position = UDim2.fromOffset(0, self.Config.Layout.TopbarHeight),
        Size = UDim2.new(1, 0, 1, -(self.Config.Layout.TopbarHeight + self.Config.Layout.StatusbarHeight)),
        BackgroundTransparency = 1,
    })
    self.Body = body

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Parent = body,
        Size = UDim2.new(0, self.Config.Layout.SidebarWidth, 1, 0),
        BackgroundColor3 = self.Config.Colors.Sidebar,
        BackgroundTransparency = self.Config.Transparency.Sidebar,
        BorderSizePixel = 0,
    })
    create("UIPadding", {Parent = sidebar, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    create("UIListLayout", {Parent = sidebar, Padding = UDim.new(0, self.Config.Layout.TabSpacing), SortOrder = Enum.SortOrder.LayoutOrder})
    self.Sidebar = sidebar
    self.TabContainer = sidebar

    local content = create("Frame", {
        Name = "Content",
        Parent = body,
        Position = UDim2.fromOffset(self.Config.Layout.SidebarWidth, 0),
        Size = UDim2.new(1, -self.Config.Layout.SidebarWidth, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    })
    self.Content = content

    local statusbar = create("Frame", {
        Name = "Statusbar",
        Parent = main,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, self.Config.Layout.StatusbarHeight),
        BackgroundColor3 = self.Config.Colors.Background2,
        BorderSizePixel = 0,
    })
    self.Statusbar = statusbar

    self.StatusLabel = create("TextLabel", {
        Parent = statusbar,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = self.Config.StatusText or "Ready",
        TextColor3 = self.Config.Colors.Text2,
        TextSize = self.Config.TextSizes.Status,
        Font = self.Config.Fonts.Normal,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local resizeGrip = create("TextButton", {
        Name = "ResizeGrip",
        Parent = main,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(self.Config.Layout.ResizeGrip, self.Config.Layout.ResizeGrip),
        BackgroundTransparency = 1,
        Text = "/",
        TextColor3 = self.Config.Colors.Text2,
        TextSize = 12,
        AutoButtonColor = false,
        Visible = self.Config.Window.Resizable,
        ZIndex = 20,
    })
    self.ResizeGrip = resizeGrip

    local notifications = create("Frame", {
        Name = "Notifications",
        Parent = gui,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.new(0, 320, 1, -28),
        BackgroundTransparency = 1,
    })
    create("UIListLayout", {Parent = notifications, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8)})
    self.Notifications = notifications

    local tooltip = create("TextLabel", {
        Name = "Tooltip",
        Parent = gui,
        Visible = false,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = self.Config.Colors.Tooltip,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = self.Config.Colors.Text,
        TextSize = self.Config.TextSizes.Secondary,
        Font = self.Config.Fonts.Normal,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1000,
    })
    create("UIPadding", {Parent = tooltip, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    corner(tooltip, self.Config.Radius.Tooltip)
    self.Tooltip = tooltip

    local dragging = false
    local dragStart = Vector2.zero
    local startPosition = main.Position
    self:_Track(topbar.InputBegan:Connect(function(input)
        if not self.Config.Window.Draggable or self._maximized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end))
    self:_Track(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))
    self:_Track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end))

    local resizing = false
    local resizeStart = Vector2.zero
    local resizeSize = Vector2.zero
    self:_Track(resizeGrip.InputBegan:Connect(function(input)
        if not self.Config.Window.Resizable or self._maximized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            resizeSize = main.AbsoluteSize
        end
    end))
    self:_Track(UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - resizeStart
            local minSize = self.Config.Window.MinSize
            local maxSize = self.Config.Window.MaxSize
            local width = clamp(resizeSize.X + delta.X, minSize.X, maxSize.X)
            local height = clamp(resizeSize.Y + delta.Y, minSize.Y, maxSize.Y)
            main.Size = UDim2.fromOffset(width, height)
            self._expandedSize = main.Size
            self:_Emit("WindowResized", "Window", Vector2.new(width, height))
        end
    end))
    self:_Track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
    end))

    self:_Track(self.MinimizeButton.Activated:Connect(function() self:SetMinimized(not self._minimized) end))
    self:_Track(self.MaximizeButton.Activated:Connect(function() self:SetMaximized(not self._maximized) end))
    self:_Track(self.CloseButton.Activated:Connect(function()
        if self.Config.Behavior.CloseDestroys then self:Destroy() else self:SetVisible(false) self:_Emit("WindowClosed", "Window", false) end
    end))

    self:_Track(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if self.Config.Behavior.IgnoreToggleWhileTyping and UserInputService:GetFocusedTextBox() then return end
        if matches(input, self.ToggleKey) then self:Toggle() end
    end))

    return self
end

function Library:_Track(connection)
    table.insert(self._connections, connection)
    return connection
end

function Library:_Tween(object, duration, props)
    if not self.Config.Animation.Enabled then
        for k, v in pairs(props) do object[k] = v end
        return nil
    end
    local tween = TweenService:Create(object, TweenInfo.new(duration or self.Config.Animation.Normal, self.Config.Animation.EasingStyle, self.Config.Animation.EasingDirection), props)
    tween:Play()
    return tween
end

function Library:_MakeId(kind, requested)
    if requested ~= nil then
        local id = tostring(requested)
        if self.Controls[id] then error("Duplicate UI control Id: " .. id) end
        return id
    end
    self._idCounter += 1
    return kind .. "_" .. tostring(self._idCounter)
end

function Library:_Register(control)
    self.Controls[control.Id] = control
    return control
end

function Library:_Callback(fn, ...)
    if type(fn) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        local ok, err = pcall(fn, table.unpack(args, 1, args.n))
        if not ok then warn("[Raynard Callback]", err) end
    end)
end

function Library:_Emit(eventType, id, value, extra)
    local packet = {Type = eventType, Id = id, Value = value, Window = self.Title, Time = os.clock()}
    if extra then for k, v in pairs(extra) do packet[k] = v end end
    self.Feedback:Fire(packet)
end

function Library:_AttachTooltip(guiObject, text)
    if not self.Config.Behavior.Tooltips or not text or text == "" then return end
    local active = false
    self:_Track(guiObject.MouseEnter:Connect(function()
        active = true
        self.Tooltip.Text = tostring(text)
        self.Tooltip.Visible = true
    end))
    self:_Track(guiObject.MouseLeave:Connect(function()
        active = false
        self.Tooltip.Visible = false
    end))
    self:_Track(UserInputService.InputChanged:Connect(function(input)
        if active and input.UserInputType == Enum.UserInputType.MouseMovement then
            self.Tooltip.Position = UDim2.fromOffset(input.Position.X + 14, input.Position.Y + 14)
        end
    end))
end

function Library:GetControl(id)
    return self.Controls[tostring(id)]
end

function Library:GetValue(id)
    local c = self:GetControl(id)
    return c and c:Get() or nil
end

function Library:SetValue(id, value, silent)
    local c = self:GetControl(id)
    if c then return c:Set(value, silent) end
end

function Library:SetVisible(visible)
    self.Gui.Enabled = visible == true
    self:_Emit("VisibilityChanged", "Window", self.Gui.Enabled)
    return self
end

function Library:IsVisible() return self.Gui.Enabled end
function Library:Toggle() return self:SetVisible(not self.Gui.Enabled) end

function Library:SetTitle(text)
    self.Title = tostring(text)
    self.TitleLabel.Text = self.Title
    return self
end

function Library:SetSubtitle(text)
    self.Subtitle = tostring(text)
    self.SubtitleLabel.Text = self.Subtitle
    return self
end

function Library:SetStatus(text, color)
    self.StatusLabel.Text = tostring(text)
    self.StatusLabel.TextColor3 = color or self.Config.Colors.Text2
    return self
end

function Library:SetPosition(position) self.Main.Position = position return self end
function Library:SetSize(size) self.Main.Size = sizeUDim(size) self._expandedSize = self.Main.Size return self end

function Library:Center()
    self.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Main.Position = UDim2.fromScale(0.5, 0.5)
    return self
end

function Library:SetMinimized(minimized)
    if not self.Config.Window.Minimizable then return self end
    self._minimized = minimized == true
    self.Body.Visible = not self._minimized
    self.Statusbar.Visible = not self._minimized
    self.ResizeGrip.Visible = self.Config.Window.Resizable and not self._minimized and not self._maximized
    if self._minimized then
        self._expandedSize = self.Main.Size
        self.Main.Size = UDim2.new(self.Main.Size.X.Scale, self.Main.Size.X.Offset, 0, self.Config.Layout.TopbarHeight)
    else
        self.Main.Size = self._expandedSize
    end
    self:_Emit("WindowMinimized", "Window", self._minimized)
    return self
end

function Library:SetMaximized(maximized)
    if not self.Config.Window.Maximizable then return self end
    maximized = maximized == true
    if maximized == self._maximized then return self end
    if maximized then
        self._lastPosition = self.Main.Position
        self._lastSize = self.Main.Size
        self.Main.AnchorPoint = Vector2.new(0, 0)
        self.Main.Position = UDim2.fromOffset(8, 8)
        self.Main.Size = UDim2.new(1, -16, 1, -16)
        self._maximized = true
        self.MaximizeButton.Text = "R"
        self.ResizeGrip.Visible = false
    else
        self.Main.AnchorPoint = Vector2.new(0.5, 0.5)
        self.Main.Position = self._lastPosition or self.Config.Window.Position
        self.Main.Size = self._lastSize or sizeUDim(self.Config.Window.Size)
        self._maximized = false
        self.MaximizeButton.Text = "[]"
        self.ResizeGrip.Visible = self.Config.Window.Resizable and not self._minimized
    end
    self:_Emit("WindowMaximized", "Window", self._maximized)
    return self
end

function Library:ExportState()
    local result = {}
    for id, control in pairs(self.Controls) do
        local ok, value = pcall(function() return control:Get() end)
        if ok and value ~= nil then result[id] = value end
    end
    return result
end

function Library:ImportState(state, silent)
    if type(state) ~= "table" then return self end
    for id, value in pairs(state) do
        local control = self.Controls[id]
        if control then pcall(function() control:Set(value, silent ~= false) end) end
    end
    self:_Emit("StateImported", "Window", state)
    return self
end

function Library:Notify(configuration)
    if not self.Config.Behavior.Notifications then return nil end
    if type(configuration) == "string" then configuration = {Text = configuration} end
    configuration = configuration or {}

    local kind = configuration.Type or "Info"
    local accent = self.Config.Colors.Info
    if kind == "Success" then accent = self.Config.Colors.Success
    elseif kind == "Warning" then accent = self.Config.Colors.Warning
    elseif kind == "Danger" or kind == "Error" then accent = self.Config.Colors.Danger end

    local toast = create("Frame", {
        Parent = self.Notifications,
        Size = UDim2.fromOffset(configuration.Width or 300, configuration.Height or 92),
        BackgroundColor3 = self.Config.Colors.Section,
        BorderSizePixel = 0,
    })
    corner(toast, self.Config.Radius.Section)
    if self.Config.Stroke.Enabled then stroke(toast, self.Config.Colors.Border, 1, 0) end
    create("Frame", {Parent = toast, Size = UDim2.new(0, 4, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0})
    create("TextLabel", {
        Parent = toast, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 22),
        BackgroundTransparency = 1, Text = configuration.Title or kind, TextColor3 = self.Config.Colors.Text,
        TextSize = self.Config.TextSizes.Control + 1, Font = self.Config.Fonts.Bold, TextXAlignment = Enum.TextXAlignment.Left,
    })
    create("TextLabel", {
        Parent = toast, Position = UDim2.fromOffset(14, 35), Size = UDim2.new(1, -28, 1, -45),
        BackgroundTransparency = 1, Text = configuration.Text or "", TextColor3 = self.Config.Colors.Text2,
        TextSize = self.Config.TextSizes.Control, Font = self.Config.Fonts.Normal, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    })

    local duration = tonumber(configuration.Duration) or 3
    task.delay(duration, function()
        if not toast.Parent then return end
        local tween = self:_Tween(toast, self.Config.Animation.Normal, {BackgroundTransparency = 1})
        if tween then tween.Completed:Wait() end
        if toast.Parent then toast:Destroy() end
    end)

    self:_Emit("Notification", "Notification", configuration.Text, {NotificationType = kind})
    return toast
end

function Library:_ModalBase(width, height)
    local overlay = create("TextButton", {
        Parent = self.Gui, Size = UDim2.fromScale(1, 1), BackgroundColor3 = self.Config.Colors.Overlay,
        BackgroundTransparency = self.Config.Transparency.Overlay, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 500,
    })
    local modal = create("Frame", {
        Parent = overlay, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(width or 400, height or 210), BackgroundColor3 = self.Config.Colors.Background2,
        BorderSizePixel = 0, ZIndex = 501,
    })
    corner(modal, self.Config.Radius.Modal)
    if self.Config.Stroke.Enabled then stroke(modal, self.Config.Colors.Border, 1, 0) end
    return overlay, modal
end

function Library:Confirm(configuration)
    configuration = configuration or {}
    local result = Signal.new()
    local overlay, modal = self:_ModalBase(configuration.Width or 400, configuration.Height or 210)

    create("TextLabel", {Parent = modal, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 26), BackgroundTransparency = 1,
        Text = configuration.Title or "Confirm", TextColor3 = self.Config.Colors.Text, TextSize = self.Config.TextSizes.Title, Font = self.Config.Fonts.Bold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 502})
    create("TextLabel", {Parent = modal, Position = UDim2.fromOffset(16, 48), Size = UDim2.new(1, -32, 1, -112), BackgroundTransparency = 1,
        Text = configuration.Text or "Are you sure?", TextColor3 = self.Config.Colors.Text2, TextSize = self.Config.TextSizes.Control,
        Font = self.Config.Fonts.Normal, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 502})

    local holder = create("Frame", {Parent = modal, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -14), Size = UDim2.new(1, -32, 0, 38), BackgroundTransparency = 1, ZIndex = 502})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8)})

    local function add(text, color)
        local b = create("TextButton", {Parent = holder, Size = UDim2.fromOffset(110, 36), BackgroundColor3 = color, BorderSizePixel = 0,
            Text = text, TextColor3 = self.Config.Colors.Text, TextSize = self.Config.TextSizes.Control, Font = self.Config.Fonts.Medium,
            AutoButtonColor = false, ZIndex = 503})
        corner(b, self.Config.Radius.Button)
        return b
    end

    local cancel = add(configuration.CancelText or "Cancel", self.Config.Colors.Control)
    local confirm = add(configuration.ConfirmText or "Confirm", configuration.ConfirmColor or self.Config.Colors.Accent2)
    local finished = false

    local function finish(value)
        if finished then return end
        finished = true
        result:Fire(value)
        self:_Callback(configuration.Callback, value)
        self:_Emit("ConfirmResult", configuration.Id or "Confirm", value)
        overlay:Destroy()
        task.defer(function() result:Destroy() end)
    end

    cancel.Activated:Connect(function() finish(false) end)
    confirm.Activated:Connect(function() finish(true) end)
    overlay.Activated:Connect(function() if configuration.ClickOutsideToClose ~= false then finish(false) end end)
    return result
end

function Library:Prompt(configuration)
    configuration = configuration or {}
    local result = Signal.new()
    local overlay, modal = self:_ModalBase(configuration.Width or 420, configuration.Height or 230)

    create("TextLabel", {Parent = modal, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 26), BackgroundTransparency = 1,
        Text = configuration.Title or "Input", TextColor3 = self.Config.Colors.Text, TextSize = self.Config.TextSizes.Title, Font = self.Config.Fonts.Bold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 502})
    create("TextLabel", {Parent = modal, Position = UDim2.fromOffset(16, 45), Size = UDim2.new(1, -32, 0, 36), BackgroundTransparency = 1,
        Text = configuration.Text or "", TextColor3 = self.Config.Colors.Text2, TextSize = self.Config.TextSizes.Control, Font = self.Config.Fonts.Normal,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 502})

    local box = create("TextBox", {Parent = modal, Position = UDim2.fromOffset(16, 88), Size = UDim2.new(1, -32, 0, 36), BackgroundColor3 = self.Config.Colors.Control,
        BorderSizePixel = 0, Text = tostring(configuration.Default or ""), PlaceholderText = configuration.Placeholder or "", PlaceholderColor3 = self.Config.Colors.Text2,
        TextColor3 = self.Config.Colors.Text, TextSize = self.Config.TextSizes.Control, Font = self.Config.Fonts.Normal, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 502})
    corner(box, self.Config.Radius.Control)
    create("UIPadding", {Parent = box, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)})

    local holder = create("Frame", {Parent = modal, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -14), Size = UDim2.new(1, -32, 0, 38), BackgroundTransparency = 1, ZIndex = 502})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 8)})

    local cancel = create("TextButton", {Parent = holder, Size = UDim2.fromOffset(100, 36), BackgroundColor3 = self.Config.Colors.Control, BorderSizePixel = 0,
        Text = configuration.CancelText or "Cancel", TextColor3 = self.Config.Colors.Text, TextSize = self.Config.TextSizes.Control, Font = self.Config.Fonts.Medium, AutoButtonColor = false, ZIndex = 503})
    corner(cancel, self.Config.Radius.Button)
    local submit = create("TextButton", {Parent = holder, Size = UDim2.fromOffset(100, 36), BackgroundColor3 = self.Config.Colors.Accent2, BorderSizePixel = 0,
        Text = configuration.SubmitText or "Submit", TextColor3 = self.Config.Colors.Text, TextSize = self.Config.TextSizes.Control, Font = self.Config.Fonts.Medium, AutoButtonColor = false, ZIndex = 503})
    corner(submit, self.Config.Radius.Button)

    local finished = false
    local function finish(value)
        if finished then return end
        finished = true
        result:Fire(value)
        self:_Callback(configuration.Callback, value)
        self:_Emit("PromptResult", configuration.Id or "Prompt", value)
        overlay:Destroy()
        task.defer(function() result:Destroy() end)
    end

    cancel.Activated:Connect(function() finish(nil) end)
    submit.Activated:Connect(function() finish(box.Text) end)
    box.FocusLost:Connect(function(enter) if enter and configuration.SubmitOnEnter ~= false then finish(box.Text) end end)
    task.defer(function() if box.Parent and configuration.AutoFocus ~= false then box:CaptureFocus() end end)
    return result
end

function Library:AddTab(configuration)
    if type(configuration) == "string" then configuration = {Name = configuration} end
    configuration = configuration or {}
    local name = configuration.Name or ("Tab " .. tostring(#self.Tabs + 1))

    local button = create("TextButton", {
        Parent = self.TabContainer, Size = UDim2.new(1, 0, 0, self.Config.Layout.TabHeight), BackgroundColor3 = self.Config.Colors.Control,
        BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = configuration.Order or (#self.Tabs + 1),
    })
    corner(button, self.Config.Radius.Button)

    local iconWidth = 0
    local icon
    if configuration.Icon then
        iconWidth = 28
        icon = create("ImageLabel", {Parent = button, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1, Image = imageId(configuration.Icon), ImageColor3 = self.Config.Colors.Text2})
    end

    local text = create("TextLabel", {Parent = button, Position = UDim2.fromOffset(10 + iconWidth, 0), Size = UDim2.new(1, -(16 + iconWidth), 1, 0),
        BackgroundTransparency = 1, Text = name, TextColor3 = self.Config.Colors.Text2, TextSize = self.Config.TextSizes.Tab, Font = self.Config.Fonts.Tab,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd})

    local page = create("ScrollingFrame", {
        Parent = self.Content, Position = UDim2.fromOffset(self.Config.Layout.PagePadding, self.Config.Layout.PagePadding),
        Size = UDim2.new(1, -(self.Config.Layout.PagePadding * 2), 1, -(self.Config.Layout.PagePadding * 2)), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = self.Config.Layout.ScrollbarThickness, ScrollBarImageColor3 = self.Config.Colors.Scrollbar,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
    })
    create("UIListLayout", {Parent = page, Padding = UDim.new(0, self.Config.Layout.SectionSpacing), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = page, PaddingRight = UDim.new(0, 4), PaddingBottom = UDim.new(0, 10)})

    local tab = setmetatable({App = self, Name = name, Id = tostring(configuration.Id or name), Button = button, TextLabel = text, Icon = icon, Page = page, Sections = {}, Visible = true}, Tab)
    table.insert(self.Tabs, tab)

    self:_Track(button.Activated:Connect(function() self:SelectTab(tab) end))
    self:_AttachTooltip(button, configuration.Tooltip)
    if self.Config.Behavior.AutoSelectFirstTab and #self.Tabs == 1 then self:SelectTab(tab) end
    return tab
end

function Library:SelectTab(target)
    local found
    if type(target) == "string" then
        for _, tab in ipairs(self.Tabs) do
            if tab.Name == target or tab.Id == target then found = tab break end
        end
    else
        found = target
    end
    if not found or not found.Visible then return nil end

    for _, tab in ipairs(self.Tabs) do
        local active = tab == found
        tab.Page.Visible = active
        tab.Button.BackgroundTransparency = active and 0 or 1
        tab.TextLabel.TextColor3 = active and self.Config.Colors.Accent or self.Config.Colors.Text2
        if tab.Icon then tab.Icon.ImageColor3 = active and self.Config.Colors.Accent or self.Config.Colors.Text2 end
    end
    self._selectedTab = found
    self:_Emit("TabSelected", found.Id, found.Name)
    return found
end

function Tab:SetVisible(visible)
    self.Visible = visible == true
    self.Button.Visible = self.Visible
    return self
end

function Tab:SetName(name)
    self.Name = tostring(name)
    self.TextLabel.Text = self.Name
    return self
end

function Tab:Select() self.App:SelectTab(self) return self end

function Tab:AddSection(configuration)
    if type(configuration) == "string" then configuration = {Name = configuration} end
    configuration = configuration or {}
    local app = self.App

    local frame = create("Frame", {
        Parent = self.Page, Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = configuration.Color or app.Config.Colors.Section, BackgroundTransparency = app.Config.Transparency.Section,
        BorderSizePixel = 0, LayoutOrder = configuration.Order or (#self.Sections + 1),
    })
    corner(frame, configuration.Radius or app.Config.Radius.Section)
    if app.Config.Stroke.Enabled and configuration.Stroke ~= false then stroke(frame, app.Config.Colors.Border, app.Config.Stroke.Thickness, app.Config.Stroke.Transparency) end
    create("UIPadding", {Parent = frame, PaddingTop = UDim.new(0, app.Config.Layout.SectionPadding), PaddingBottom = UDim.new(0, app.Config.Layout.SectionPadding),
        PaddingLeft = UDim.new(0, app.Config.Layout.SectionPadding), PaddingRight = UDim.new(0, app.Config.Layout.SectionPadding)})
    create("UIListLayout", {Parent = frame, Padding = UDim.new(0, app.Config.Layout.ControlSpacing), SortOrder = Enum.SortOrder.LayoutOrder})

    local header = create("TextButton", {Parent = frame, Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = -10000})
    local title = create("TextLabel", {Parent = header, Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = configuration.Name or "Section",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Section, Font = app.Config.Fonts.Section, TextXAlignment = Enum.TextXAlignment.Left})
    local collapse = create("TextLabel", {Parent = header, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(26, 26),
        BackgroundTransparency = 1, Text = "-", TextColor3 = app.Config.Colors.Text2, TextSize = 16, Font = app.Config.Fonts.Bold, Visible = configuration.Collapsible == true})

    local section = setmetatable({App = app, Tab = self, Name = configuration.Name or "Section", Id = tostring(configuration.Id or configuration.Name or ("Section_" .. tostring(#self.Sections + 1))),
        Frame = frame, Header = header, TitleLabel = title, CollapseIcon = collapse, Controls = {}, Collapsible = configuration.Collapsible == true, Collapsed = false}, Section)
    table.insert(self.Sections, section)
    table.insert(app.Sections, section)

    if section.Collapsible then app:_Track(header.Activated:Connect(function() section:SetCollapsed(not section.Collapsed) end)) end
    if configuration.StartCollapsed then task.defer(function() section:SetCollapsed(true) end) end
    return section
end

function Section:_Row(height)
    return create("Frame", {Parent = self.Frame, Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1})
end

function Section:_Control(id, kind, label, root, configuration)
    local control = Control.new(self.App, id, kind, label, root)
    table.insert(self.Controls, control)
    if configuration then
        if configuration.Visible == false then control:SetVisible(false) end
        if configuration.Disabled == true then control.Disabled = true end
        self.App:_AttachTooltip(root, configuration.Tooltip)
    end
    return control
end

function Section:_Emit(control, eventType, value, previous)
    self.App:_Emit(eventType, control.Id, value, {Previous = previous, Label = control.Label, Kind = control.Kind, Tab = self.Tab.Name, Section = self.Name})
end

function Section:SetName(name) self.Name = tostring(name) self.TitleLabel.Text = self.Name return self end
function Section:SetVisible(visible) self.Frame.Visible = visible == true return self end

function Section:SetCollapsed(collapsed)
    if not self.Collapsible then return self end
    self.Collapsed = collapsed == true
    for _, child in ipairs(self.Frame:GetChildren()) do
        if child:IsA("GuiObject") and child ~= self.Header then child.Visible = not self.Collapsed end
    end
    self.CollapseIcon.Text = self.Collapsed and "+" or "-"
    self.App:_Emit("SectionCollapsed", self.Id, self.Collapsed, {Tab = self.Tab.Name, Section = self.Name})
    return self
end

