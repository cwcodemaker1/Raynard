local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Library = {}
Library.__index = Library

local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({_listeners = {}, _destroyed = false}, Signal)
end

function Signal:Connect(fn)
    assert(type(fn) == "function", "Signal:Connect expects a function")
    local signal = self
    local connection = {Connected = true}
    self._listeners[connection] = fn
    function connection:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        signal._listeners[self] = nil
    end
    return connection
end

function Signal:Once(fn)
    local c
    c = self:Connect(function(...)
        c:Disconnect()
        fn(...)
    end)
    return c
end

function Signal:Fire(...)
    if self._destroyed then return end
    local args = table.pack(...)
    for connection, fn in pairs(self._listeners) do
        if connection.Connected then
            task.spawn(function()
                local ok, err = pcall(fn, table.unpack(args, 1, args.n))
                if not ok then warn("[UIBuilder Signal]", err) end
            end)
        end
    end
end

function Signal:Destroy()
    self._destroyed = true
    for connection in pairs(self._listeners) do
        connection.Connected = false
    end
    table.clear(self._listeners)
end

local DEFAULT = {
    Name = "Raynard",
    Title = "Raynard",
    Subtitle = "Building block by block",
    ToggleKey = Enum.KeyCode.RightShift,
    DisplayOrder = 100,

    Window = {
        Size = Vector2.new(780, 540),
        MinSize = Vector2.new(520, 340),
        MaxSize = Vector2.new(1500, 950),
        Position = UDim2.fromScale(0.5, 0.5),
        Draggable = true,
        Resizable = true,
        Minimizable = true,
        Maximizable = true,
        Closable = true,
        StartVisible = true,
    },

    Colors = {
        Background = Color3.fromRGB(16, 16, 16),
        Background2 = Color3.fromRGB(24, 24, 24),
        Sidebar = Color3.fromRGB(19, 19, 21),
        Section = Color3.fromRGB(24, 24, 26),
        Control = Color3.fromRGB(31, 31, 34),
        ControlHover = Color3.fromRGB(38, 38, 42),
        ControlPressed = Color3.fromRGB(44, 44, 48),
        ControlDisabled = Color3.fromRGB(25, 25, 28),
        Border = Color3.fromRGB(48, 48, 52),
        Text = Color3.fromRGB(235, 235, 240),
        Text2 = Color3.fromRGB(145, 145, 155),
        TextDisabled = Color3.fromRGB(85, 85, 95),
        Accent = Color3.fromRGB(143, 180, 255),
        Accent2 = Color3.fromRGB(81, 102, 144),
        AccentText = Color3.fromRGB(18, 18, 20),
        Success = Color3.fromRGB(75, 190, 115),
        Warning = Color3.fromRGB(230, 180, 70),
        Danger = Color3.fromRGB(225, 80, 80),
        Info = Color3.fromRGB(95, 160, 235),
        Scrollbar = Color3.fromRGB(81, 102, 144),
        Overlay = Color3.fromRGB(0, 0, 0),
        Tooltip = Color3.fromRGB(28, 28, 31),
    },

    Transparency = {
        Window = 0,
        Topbar = 0,
        Sidebar = 0,
        Section = 0,
        Control = 0,
        Border = 0,
        Overlay = 0.35,
    },

    Fonts = {
        Title = Enum.Font.GothamBold,
        Subtitle = Enum.Font.Gotham,
        Tab = Enum.Font.GothamMedium,
        Section = Enum.Font.GothamSemibold,
        Normal = Enum.Font.Gotham,
        Medium = Enum.Font.GothamMedium,
        Bold = Enum.Font.GothamBold,
        Mono = Enum.Font.RobotoMono,
    },

    TextSizes = {
        Title = 16,
        Subtitle = 11,
        Tab = 13,
        Section = 14,
        Control = 13,
        Secondary = 12,
        Tiny = 10,
        Status = 11,
    },

    Radius = {
        Window = 10,
        Section = 8,
        Control = 6,
        Button = 6,
        Avatar = 999,
        Modal = 10,
        Tooltip = 6,
    },

    Stroke = {
        Enabled = true,
        Thickness = 1,
        Transparency = 0,
    },

    Layout = {
        TopbarHeight = 50,
        StatusbarHeight = 24,
        SidebarWidth = 170,
        PagePadding = 10,
        SectionPadding = 10,
        SectionSpacing = 10,
        ControlSpacing = 7,
        TabHeight = 38,
        TabSpacing = 6,
        ButtonHeight = 38,
        ToggleHeight = 38,
        SliderHeight = 62,
        TextboxHeight = 64,
        DropdownHeight = 64,
        ProgressHeight = 52,
        KeybindHeight = 38,
        PlayerCardHeight = 72,
        ScrollbarThickness = 4,
        ResizeGrip = 16,
    },

    Animation = {
        Enabled = true,
        Fast = 0.08,
        Normal = 0.15,
        EasingStyle = Enum.EasingStyle.Quad,
        EasingDirection = Enum.EasingDirection.Out,
    },

    Behavior = {
        CloseDestroys = false,
        Hover = true,
        Tooltips = true,
        Notifications = true,
        AutoSelectFirstTab = true,
        IgnoreToggleWhileTyping = true,
    },
}

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = deepCopy(v) end
    return result
end

local function deepMerge(base, override)
    local result = deepCopy(base)
    if type(override) ~= "table" then return result end
    for k, v in pairs(override) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = deepMerge(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

local function create(className, props)
    local object = Instance.new(className)
    local parent = props and props.Parent
    if props then
        for property, value in pairs(props) do
            if property ~= "Parent" then object[property] = value end
        end
    end
    if parent then object.Parent = parent end
    return object
end

local function corner(object, radius)
    return create("UICorner", {Parent = object, CornerRadius = UDim.new(0, radius or 6)})
end

local function stroke(object, color, thickness, transparency)
    return create("UIStroke", {
        Parent = object,
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    })
end

local function imageId(value)
    if value == nil then return "" end
    if type(value) == "number" then return "rbxassetid://" .. tostring(value) end
    local text = tostring(value)
    if tonumber(text) then return "rbxassetid://" .. text end
    return text
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function stepValue(value, minimum, maximum, step)
    value = clamp(value, minimum, maximum)
    if step and step > 0 then
        value = minimum + math.floor(((value - minimum) / step) + 0.5) * step
        value = clamp(value, minimum, maximum)
    end
    return value
end

local function formatNumber(value, step)
    if not step or step >= 1 then
        if math.abs(value - math.round(value)) < 0.000001 then return tostring(math.round(value)) end
        return tostring(value)
    end
    local decimals = 0
    local test = step
    while test < 1 and decimals < 6 do
        test *= 10
        decimals += 1
    end
    return string.format("%." .. tostring(decimals) .. "f", value)
end

local function sizeUDim(value)
    if typeof(value) == "UDim2" then return value end
    if typeof(value) == "Vector2" then return UDim2.fromOffset(value.X, value.Y) end
    return UDim2.fromOffset(780, 540)
end

local function bindName(binding)
    if typeof(binding) ~= "EnumItem" then return "None" end
    return binding.Name:gsub("MouseButton", "Mouse ")
end

local function matches(input, binding)
    if typeof(binding) ~= "EnumItem" then return false end
    if binding.EnumType == Enum.KeyCode then return input.KeyCode == binding end
    if binding.EnumType == Enum.UserInputType then return input.UserInputType == binding end
    return false
end

local function toHex(color)
    return string.format("#%02X%02X%02X", math.round(color.R * 255), math.round(color.G * 255), math.round(color.B * 255))
end

local function fromHex(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("#", "")
    if #text ~= 6 then return nil end
    local r = tonumber(text:sub(1, 2), 16)
    local g = tonumber(text:sub(3, 4), 16)
    local b = tonumber(text:sub(5, 6), 16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r, g, b)
end

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
    if not localPlayer then error("UIBuilder must be created from a LocalScript/client context") end

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
        if not ok then warn("[UIBuilder Callback]", err) end
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

function Section:AddColorPicker(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Default or Color3.fromRGB(255, 255, 255)
    local h, s, v = value:ToHSV()
    local row = self:_Row(configuration.Height or 210)

    local label = create("TextLabel", {Parent = row, Size = UDim2.new(1, -115, 0, 22), BackgroundTransparency = 1, Text = configuration.Text or "Color",
        TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left})
    local preview = create("Frame", {Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(30, 22), BackgroundColor3 = value, BorderSizePixel = 0})
    corner(preview, 5)
    local hexBox = create("TextBox", {Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -38, 0, 0), Size = UDim2.fromOffset(74, 22), BackgroundColor3 = app.Config.Colors.Control,
        BorderSizePixel = 0, Text = toHex(value), TextColor3 = app.Config.Colors.Text2, TextSize = app.Config.TextSizes.Tiny + 1, Font = app.Config.Fonts.Mono, ClearTextOnFocus = false})
    corner(hexBox, 5)
    local sv = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, -30, 0, 125), BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Active = true, ClipsDescendants = true})
    corner(sv, app.Config.Radius.Control)
    local white = create("Frame", {Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0})
    create("UIGradient", {Parent = white, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})})
    local black = create("Frame", {Parent = sv, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0})
    create("UIGradient", {Parent = black, Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})})
    local svCursor = create("Frame", {Parent = sv, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(s, 1 - v), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5})
    corner(svCursor, 999)
    stroke(svCursor, Color3.new(0, 0, 0), 1, 0)
    local hueBar = create("Frame", {Parent = row, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 30), Size = UDim2.fromOffset(20, 125), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Active = true})
    corner(hueBar, 6)
    create("UIGradient", {Parent = hueBar, Rotation = 90, Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))})})
    local hueCursor = create("Frame", {Parent = hueBar, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, h), Size = UDim2.new(1, 6, 0, 4), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5})
    corner(hueCursor, 2)
    stroke(hueCursor, Color3.new(0, 0, 0), 1, 0)
    local rgb = create("TextLabel", {Parent = row, Position = UDim2.fromOffset(0, 162), Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = "",
        TextColor3 = app.Config.Colors.Text2, TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Mono, TextXAlignment = Enum.TextXAlignment.Left})

    local id = app:_MakeId("ColorPicker", configuration.Id)
    local control = self:_Control(id, "ColorPicker", configuration.Text or "Color", row, configuration)
    local draggingSV = false
    local draggingHue = false

    local function render()
        value = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = value
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0.5, h)
        hexBox.Text = toHex(value)
        rgb.Text = string.format("RGB %d, %d, %d", math.round(value.R * 255), math.round(value.G * 255), math.round(value.B * 255))
    end

    local function emit(previous, silent)
        if not silent and previous ~= value then self:_Emit(control, "ColorChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
    end

    local function set(newValue, silent)
        if typeof(newValue) ~= "Color3" and type(newValue) == "string" then newValue = fromHex(newValue) end
        if typeof(newValue) ~= "Color3" then return value end
        local previous = value
        value = newValue
        h, s, v = value:ToHSV()
        render()
        emit(previous, silent)
        return value
    end

    local function setSV(x, y)
        if control.Disabled or sv.AbsoluteSize.X <= 0 or sv.AbsoluteSize.Y <= 0 then return end
        local previous = value
        s = clamp((x - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
        v = 1 - clamp((y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
        render()
        emit(previous, false)
    end

    local function setHue(y)
        if control.Disabled or hueBar.AbsoluteSize.Y <= 0 then return end
        local previous = value
        h = clamp((y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
        render()
        emit(previous, false)
    end

    control._getter = function() return value end
    control._setter = set
    control._textSetter = function(text) label.Text = text end
    control._disabledRenderer = function() hexBox.TextEditable = not control.Disabled label.TextColor3 = control.Disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text end
    control:_Connect(sv.InputBegan, function(input) if not control.Disabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then draggingSV = true setSV(input.Position.X, input.Position.Y) end end)
    control:_Connect(hueBar.InputBegan, function(input) if not control.Disabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then draggingHue = true setHue(input.Position.Y) end end)
    control:_Connect(UserInputService.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if draggingSV then setSV(input.Position.X, input.Position.Y) elseif draggingHue then setHue(input.Position.Y) end
        end
    end)
    control:_Connect(UserInputService.InputEnded, function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSV = false draggingHue = false end end)
    control:_Connect(hexBox.FocusLost, function() if control.Disabled then return end local color = fromHex(hexBox.Text) if color then set(color) else hexBox.Text = toHex(value) end end)
    render()
    return app:_Register(control)
end

function Library:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    local controls = {}
    for _, control in pairs(self.Controls) do table.insert(controls, control) end
    for _, control in ipairs(controls) do pcall(function() control:Destroy() end) end
    table.clear(self.Controls)
    for _, connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
    table.clear(self._connections)
    self.Feedback:Destroy()
    if self.Gui then self.Gui:Destroy() end
end

Library.CreateWindow = Library.new
Section.AddInput = Section.AddTextbox
Section.AddNumberInput = Section.AddNumberbox
Section.AddSelect = Section.AddDropdown
Section.AddSearchSelect = Section.AddSearchDropdown
Section.AddMultiSelect = Section.AddMultiDropdown
Section.AddPlayerSelect = Section.AddPlayerPicker
Section.AddColor = Section.AddColorPicker
Section.AddInfo = Section.AddCallout
Section.AddBadge = Section.AddStatus

setmetatable(Library, {
    __call = function(_, configuration)
        return Library.new(configuration)
    end,
})

return Library
