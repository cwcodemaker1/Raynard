-- UIBuilderV6.lua
-- Reusable Roblox/Luau client UI framework.
-- Put this ModuleScript in ReplicatedStorage and require it from a LocalScript.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

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

        -- V6 window-management options.
        MinimizeDock = "TopRight",
        MinimizedWidth = 320,
        MinimizeMargin = Vector2.new(14, 14),
        ShowMinimizeDockButton = true,
        ClampToViewport = true,
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

        -- V6 visibility/window behavior.
        RestoreOnShow = true,
        ReleaseFocusOnHide = true,
        RespectGameProcessedToggle = false,
        TopbarDoubleClickMaximize = true,
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

local MINIMIZE_DOCKS = {
    "KeepPosition",
    "TopLeft",
    "TopCenter",
    "TopRight",
    "MiddleLeft",
    "Center",
    "MiddleRight",
    "BottomLeft",
    "BottomCenter",
    "BottomRight",
}

local MINIMIZE_DOCK_LOOKUP = {}
for _, dockName in ipairs(MINIMIZE_DOCKS) do
    MINIMIZE_DOCK_LOOKUP[string.lower(dockName)] = dockName
end
MINIMIZE_DOCK_LOOKUP.keep = "KeepPosition"
MINIMIZE_DOCK_LOOKUP.current = "KeepPosition"
MINIMIZE_DOCK_LOOKUP.left = "MiddleLeft"
MINIMIZE_DOCK_LOOKUP.right = "MiddleRight"
MINIMIZE_DOCK_LOOKUP.top = "TopCenter"
MINIMIZE_DOCK_LOOKUP.bottom = "BottomCenter"
MINIMIZE_DOCK_LOOKUP.topleft = "TopLeft"
MINIMIZE_DOCK_LOOKUP.topright = "TopRight"
MINIMIZE_DOCK_LOOKUP.bottomleft = "BottomLeft"
MINIMIZE_DOCK_LOOKUP.bottomright = "BottomRight"

local function normalizeMinimizeDock(value)
    local key = string.lower(tostring(value or "")):gsub("[%s_%-]", "")
    for raw, canonical in pairs(MINIMIZE_DOCK_LOOKUP) do
        if raw:gsub("[%s_%-]", "") == key then
            return canonical
        end
    end
    return "TopRight"
end

local function vectorMargin(value, fallback)
    if typeof(value) == "Vector2" then
        return value
    end
    local amount = tonumber(value) or fallback or 14
    return Vector2.new(amount, amount)
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
    self._visible = self.Config.Window.StartVisible == true
    self._windowLocked = false
    self._alwaysOnTop = false
    self._baseDisplayOrder = self.Config.DisplayOrder
    self._minimizeDock = normalizeMinimizeDock(self.Config.Window.MinimizeDock)
    self.Config.Window.MinimizeDock = self._minimizeDock
    self._expandedSize = sizeUDim(self.Config.Window.Size)
    self._lastPosition = nil
    self._lastSize = nil
    self._lastAnchorPoint = nil
    self._minimizeRestorePosition = nil
    self._minimizeRestoreSize = nil
    self._minimizeRestoreAnchorPoint = nil
    self._minimizeRestoreMaximized = false

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
        Size = UDim2.new(1, -188, 0, 21),
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
        Size = UDim2.new(1, -188, 0, 16),
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
        Size = UDim2.fromOffset(154, 32),
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

    self.MinimizeDockButton = windowButton("MinimizeDock", "v", self.Config.Window.Minimizable and self.Config.Window.ShowMinimizeDockButton ~= false)
    self.MinimizeDockButton.LayoutOrder = 1
    self.MinimizeButton = windowButton("Minimize", "-", self.Config.Window.Minimizable)
    self.MinimizeButton.LayoutOrder = 2
    self.MaximizeButton = windowButton("Maximize", "[]", self.Config.Window.Maximizable)
    self.MaximizeButton.LayoutOrder = 3
    self.CloseButton = windowButton("Close", "X", self.Config.Window.Closable)
    self.CloseButton.LayoutOrder = 4

    local dockMenu = create("Frame", {
        Name = "MinimizeDockMenu",
        Parent = gui,
        Visible = false,
        Size = UDim2.fromOffset(204, 188),
        BackgroundColor3 = self.Config.Colors.Background2,
        BorderSizePixel = 0,
        ZIndex = 500,
    })
    corner(dockMenu, self.Config.Radius.Section)
    if self.Config.Stroke.Enabled then
        stroke(dockMenu, self.Config.Colors.Border, self.Config.Stroke.Thickness, self.Config.Stroke.Transparency)
    end
    create("UIPadding", {Parent = dockMenu, PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    create("UIGridLayout", {
        Parent = dockMenu,
        CellSize = UDim2.fromOffset(90, 28),
        CellPadding = UDim2.fromOffset(6, 6),
        FillDirectionMaxCells = 2,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    self.MinimizeDockMenu = dockMenu
    self._dockMenuButtons = {}

    for index, dockName in ipairs(MINIMIZE_DOCKS) do
        local dockButton = create("TextButton", {
            Name = dockName,
            Parent = dockMenu,
            Size = UDim2.fromOffset(90, 28),
            BackgroundColor3 = self.Config.Colors.Control,
            BorderSizePixel = 0,
            Text = dockName,
            TextColor3 = self.Config.Colors.Text2,
            TextSize = self.Config.TextSizes.Tiny + 1,
            Font = self.Config.Fonts.Medium,
            AutoButtonColor = false,
            LayoutOrder = index,
            ZIndex = 501,
        })
        corner(dockButton, self.Config.Radius.Button)
        self._dockMenuButtons[dockName] = dockButton
        self:_Track(dockButton.Activated:Connect(function()
            self:SetMinimizeDock(dockName, true)
            dockMenu.Visible = false
        end))
    end

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
    local lastTopbarClick = 0
    self:_Track(topbar.InputBegan:Connect(function(input)
        if self._windowLocked or not self.Config.Window.Draggable or self._maximized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.UserInputType == Enum.UserInputType.MouseButton1 and self.Config.Behavior.TopbarDoubleClickMaximize then
                local now = os.clock()
                if now - lastTopbarClick <= 0.30 then
                    lastTopbarClick = 0
                    dragging = false
                    if self._minimized then
                        self:SetMinimized(false)
                    elseif self.Config.Window.Maximizable then
                        self:SetMaximized(not self._maximized)
                    end
                    return
                end
                lastTopbarClick = now
            end
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if self.Config.Window.ClampToViewport then self:ClampToViewport() end
            end
        end
    end))

    local resizing = false
    local resizeStart = Vector2.zero
    local resizeSize = Vector2.zero
    self:_Track(resizeGrip.InputBegan:Connect(function(input)
        if self._windowLocked or not self.Config.Window.Resizable or self._maximized or self._minimized then return end
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

    local function refreshDockMenu()
        local current = self:GetMinimizeDock()
        for dockName, button in pairs(self._dockMenuButtons) do
            local selected = dockName == current
            button.BackgroundColor3 = selected and self.Config.Colors.Accent2 or self.Config.Colors.Control
            button.TextColor3 = selected and self.Config.Colors.Text or self.Config.Colors.Text2
        end
    end

    local function positionDockMenu()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local menuSize = dockMenu.AbsoluteSize
        if menuSize.X <= 0 then menuSize = Vector2.new(204, 188) end
        local mainPosition = main.AbsolutePosition
        local mainSize = main.AbsoluteSize
        local x = mainPosition.X + mainSize.X - menuSize.X
        local y = mainPosition.Y + self.Config.Layout.TopbarHeight + 6
        x = clamp(x, 8, math.max(8, viewport.X - menuSize.X - 8))
        y = clamp(y, 8, math.max(8, viewport.Y - menuSize.Y - 8))
        dockMenu.Position = UDim2.fromOffset(x, y)
    end

    self:_Track(self.MinimizeDockButton.Activated:Connect(function()
        if not self.Config.Window.Minimizable then return end
        if dockMenu.Visible then
            dockMenu.Visible = false
        else
            refreshDockMenu()
            positionDockMenu()
            dockMenu.Visible = true
        end
    end))
    self:_Track(self.MinimizeButton.Activated:Connect(function()
        dockMenu.Visible = false
        self:SetMinimized(not self._minimized)
    end))
    self:_Track(self.MaximizeButton.Activated:Connect(function()
        dockMenu.Visible = false
        self:SetMaximized(not self._maximized)
    end))
    self:_Track(self.CloseButton.Activated:Connect(function()
        if self.Config.Behavior.CloseDestroys then self:Destroy() else self:SetVisible(false) self:_Emit("WindowClosed", "Window", false) end
    end))

    self:_Track(UserInputService.InputBegan:Connect(function(input, processed)
        -- Handle the Rayward toggle before rejecting game-processed input. This makes
        -- reopening reliable even when Roblox/CoreGui consumes the key.
        if matches(input, self.ToggleKey) then
            local focused = UserInputService:GetFocusedTextBox()
            if self:IsVisible() and self.Config.Behavior.IgnoreToggleWhileTyping and focused then
                return
            end
            if processed and self.Config.Behavior.RespectGameProcessedToggle then
                return
            end
            self:Toggle()
            return
        end
        if processed then return end
    end))

    local viewportConnection
    local function bindViewport()
        if viewportConnection then
            pcall(function() viewportConnection:Disconnect() end)
            viewportConnection = nil
        end
        local camera = workspace.CurrentCamera
        if camera then
            viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                task.defer(function()
                    if self._destroyed then return end
                    if self._minimized then
                        self:_ApplyMinimizeDock()
                    elseif self.Config.Window.ClampToViewport and not self._maximized then
                        self:ClampToViewport()
                    end
                end)
            end)
            self:_Track(viewportConnection)
        end
    end
    self:_Track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindViewport))
    bindViewport()

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
    if self._destroyed or not self.Gui then return self end
    visible = visible == true

    if not visible and self.Config.Behavior.ReleaseFocusOnHide then
        local focused = UserInputService:GetFocusedTextBox()
        if focused then
            pcall(function() focused:ReleaseFocus(false) end)
        end
    end

    if self.Tooltip then self.Tooltip.Visible = false end
    if self.MinimizeDockMenu then self.MinimizeDockMenu.Visible = false end
    self.Gui.Enabled = visible
    self._visible = visible

    if visible then
        self.Main.Visible = true
        if self.Config.Behavior.RestoreOnShow and self._minimized then
            self:SetMinimized(false)
        elseif self._minimized then
            self:_ApplyMinimizeDock()
        elseif self.Config.Window.ClampToViewport and not self._maximized then
            task.defer(function()
                if not self._destroyed then self:ClampToViewport() end
            end)
        end
    end

    self:_Emit("VisibilityChanged", "Window", visible)
    return self
end

function Library:IsVisible()
    return not self._destroyed and self.Gui ~= nil and self.Gui.Enabled == true and self.Main.Visible ~= false
end

function Library:Show() return self:SetVisible(true) end
function Library:Hide() return self:SetVisible(false) end
function Library:Toggle() return self:SetVisible(not self:IsVisible()) end
function Library:ToggleVisibility() return self:Toggle() end

function Library:SetToggleKey(key)
    if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
        self.ToggleKey = key
        self.Config.ToggleKey = key
        self:_Emit("ToggleKeyChanged", "Window", key)
    end
    return self
end

function Library:GetToggleKey() return self.ToggleKey end

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

function Library:SetPosition(position)
    self.Main.Position = position
    if self.Config.Window.ClampToViewport and not self._maximized then self:ClampToViewport() end
    return self
end

function Library:SetSize(size)
    self.Main.Size = sizeUDim(size)
    if not self._minimized then self._expandedSize = self.Main.Size end
    if self.Config.Window.ClampToViewport and not self._maximized then self:ClampToViewport() end
    return self
end

function Library:Center()
    self.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Main.Position = UDim2.fromScale(0.5, 0.5)
    return self
end

function Library:GetMinimizeDocks()
    return deepCopy(MINIMIZE_DOCKS)
end

function Library:GetMinimizeDock()
    return self._minimizeDock or normalizeMinimizeDock(self.Config.Window.MinimizeDock)
end

function Library:_ApplyMinimizeDock()
    if not self._minimized or not self.Main then return self end
    local dock = self:GetMinimizeDock()
    if dock == "KeepPosition" then
        if self.Config.Window.ClampToViewport then self:ClampToViewport() end
        return self
    end

    local margin = vectorMargin(self.Config.Window.MinimizeMargin, 14)
    local anchor = Vector2.new(0.5, 0.5)
    local position = UDim2.fromScale(0.5, 0.5)

    if dock == "TopLeft" then
        anchor = Vector2.new(0, 0)
        position = UDim2.new(0, margin.X, 0, margin.Y)
    elseif dock == "TopCenter" then
        anchor = Vector2.new(0.5, 0)
        position = UDim2.new(0.5, 0, 0, margin.Y)
    elseif dock == "TopRight" then
        anchor = Vector2.new(1, 0)
        position = UDim2.new(1, -margin.X, 0, margin.Y)
    elseif dock == "MiddleLeft" then
        anchor = Vector2.new(0, 0.5)
        position = UDim2.new(0, margin.X, 0.5, 0)
    elseif dock == "Center" then
        anchor = Vector2.new(0.5, 0.5)
        position = UDim2.fromScale(0.5, 0.5)
    elseif dock == "MiddleRight" then
        anchor = Vector2.new(1, 0.5)
        position = UDim2.new(1, -margin.X, 0.5, 0)
    elseif dock == "BottomLeft" then
        anchor = Vector2.new(0, 1)
        position = UDim2.new(0, margin.X, 1, -margin.Y)
    elseif dock == "BottomCenter" then
        anchor = Vector2.new(0.5, 1)
        position = UDim2.new(0.5, 0, 1, -margin.Y)
    elseif dock == "BottomRight" then
        anchor = Vector2.new(1, 1)
        position = UDim2.new(1, -margin.X, 1, -margin.Y)
    end

    self.Main.AnchorPoint = anchor
    self.Main.Position = position
    return self
end

function Library:SetMinimizeDock(dock, applyNow)
    local normalized = normalizeMinimizeDock(dock)
    self._minimizeDock = normalized
    self.Config.Window.MinimizeDock = normalized
    if self._minimized and applyNow ~= false then self:_ApplyMinimizeDock() end
    if self._dockMenuButtons then
        for dockName, button in pairs(self._dockMenuButtons) do
            local selected = dockName == normalized
            button.BackgroundColor3 = selected and self.Config.Colors.Accent2 or self.Config.Colors.Control
            button.TextColor3 = selected and self.Config.Colors.Text or self.Config.Colors.Text2
        end
    end
    self:_Emit("MinimizeDockChanged", "Window", normalized)
    return self
end

function Library:CycleMinimizeDock(direction)
    local current = self:GetMinimizeDock()
    local index = table.find(MINIMIZE_DOCKS, current) or 1
    local step = tonumber(direction) and (tonumber(direction) < 0 and -1 or 1) or 1
    index = ((index - 1 + step) % #MINIMIZE_DOCKS) + 1
    return self:SetMinimizeDock(MINIMIZE_DOCKS[index], true)
end

function Library:ClampToViewport(marginOverride)
    if self._destroyed or not self.Main or self._maximized then return self end
    local camera = workspace.CurrentCamera
    if not camera then return self end
    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then return self end

    local margin = vectorMargin(marginOverride or self.Config.Window.MinimizeMargin, 8)
    local size = self.Main.Size
    local width = viewport.X * size.X.Scale + size.X.Offset
    local height = viewport.Y * size.Y.Scale + size.Y.Offset
    local pos = self.Main.Position
    local anchor = self.Main.AnchorPoint
    local left = viewport.X * pos.X.Scale + pos.X.Offset - width * anchor.X
    local top = viewport.Y * pos.Y.Scale + pos.Y.Offset - height * anchor.Y

    local minX = math.min(margin.X, math.max(0, viewport.X - width))
    local maxX = math.max(minX, viewport.X - width - margin.X)
    local minY = math.min(margin.Y, math.max(0, viewport.Y - height))
    local maxY = math.max(minY, viewport.Y - height - margin.Y)
    local clampedLeft = clamp(left, minX, maxX)
    local clampedTop = clamp(top, minY, maxY)
    local dx = clampedLeft - left
    local dy = clampedTop - top

    if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 then
        self.Main.Position = UDim2.new(pos.X.Scale, pos.X.Offset + dx, pos.Y.Scale, pos.Y.Offset + dy)
        self:_Emit("WindowClamped", "Window", self.Main.Position)
    end
    return self
end

function Library:SetWindowLocked(locked)
    self._windowLocked = locked == true
    self.ResizeGrip.Visible = self.Config.Window.Resizable and not self._windowLocked and not self._minimized and not self._maximized
    self:_Emit("WindowLockedChanged", "Window", self._windowLocked)
    return self
end

function Library:IsWindowLocked() return self._windowLocked == true end

function Library:SetAlwaysOnTop(enabled)
    self._alwaysOnTop = enabled == true
    self.Gui.DisplayOrder = self._alwaysOnTop and math.max(self._baseDisplayOrder + 1000, 1000) or self._baseDisplayOrder
    self:_Emit("AlwaysOnTopChanged", "Window", self._alwaysOnTop)
    return self
end

function Library:IsAlwaysOnTop() return self._alwaysOnTop == true end

function Library:BringToFront()
    self.Gui.DisplayOrder = math.max(self.Gui.DisplayOrder, self._baseDisplayOrder) + 1
    self:_Emit("BroughtToFront", "Window", self.Gui.DisplayOrder)
    return self
end

function Library:SetMinimized(minimized)
    if not self.Config.Window.Minimizable then return self end
    minimized = minimized == true

    if minimized == self._minimized then
        if minimized then self:_ApplyMinimizeDock() end
        return self
    end

    if minimized then
        self._minimizeRestoreMaximized = self._maximized == true
        if self._maximized then self:SetMaximized(false) end

        self._minimizeRestorePosition = self.Main.Position
        self._minimizeRestoreSize = self.Main.Size
        self._minimizeRestoreAnchorPoint = self.Main.AnchorPoint
        self._expandedSize = self.Main.Size
        self._minimized = true

        self.Body.Visible = false
        self.Statusbar.Visible = false
        self.ResizeGrip.Visible = false
        self.MaximizeButton.Visible = false
        self.MinimizeButton.Text = "+"

        local currentWidth = self.Main.AbsoluteSize.X
        if currentWidth <= 0 then
            currentWidth = self.Config.Window.Size.X
        end
        local minimizedWidth = clamp(tonumber(self.Config.Window.MinimizedWidth) or 320, 220, math.max(220, currentWidth))
        self.Main.Size = UDim2.fromOffset(minimizedWidth, self.Config.Layout.TopbarHeight)
        self:_ApplyMinimizeDock()
    else
        self._minimized = false
        self.Main.AnchorPoint = self._minimizeRestoreAnchorPoint or Vector2.new(0.5, 0.5)
        self.Main.Position = self._minimizeRestorePosition or self.Config.Window.Position
        self.Main.Size = self._minimizeRestoreSize or self._expandedSize

        self.Body.Visible = true
        self.Statusbar.Visible = true
        self.MinimizeButton.Text = "-"
        self.MaximizeButton.Visible = self.Config.Window.Maximizable
        self.ResizeGrip.Visible = self.Config.Window.Resizable and not self._windowLocked

        local restoreMaximized = self._minimizeRestoreMaximized
        self._minimizeRestoreMaximized = false
        if restoreMaximized and self.Config.Window.Maximizable then
            self:SetMaximized(true)
        elseif self.Config.Window.ClampToViewport then
            self:ClampToViewport()
        end
    end

    self:_Emit("WindowMinimized", "Window", self._minimized, {Dock = self:GetMinimizeDock()})
    return self
end

function Library:IsMinimized() return self._minimized == true end

function Library:SetMaximized(maximized)
    if not self.Config.Window.Maximizable then return self end
    maximized = maximized == true

    if maximized and self._minimized then
        self._minimizeRestoreMaximized = false
        self:SetMinimized(false)
    end

    if maximized == self._maximized then return self end
    if maximized then
        self._lastPosition = self.Main.Position
        self._lastSize = self.Main.Size
        self._lastAnchorPoint = self.Main.AnchorPoint
        self.Main.AnchorPoint = Vector2.new(0, 0)
        self.Main.Position = UDim2.fromOffset(8, 8)
        self.Main.Size = UDim2.new(1, -16, 1, -16)
        self._maximized = true
        self.MaximizeButton.Text = "R"
        self.ResizeGrip.Visible = false
    else
        self.Main.AnchorPoint = self._lastAnchorPoint or Vector2.new(0.5, 0.5)
        self.Main.Position = self._lastPosition or self.Config.Window.Position
        self.Main.Size = self._lastSize or sizeUDim(self.Config.Window.Size)
        self._maximized = false
        self.MaximizeButton.Text = "[]"
        self.ResizeGrip.Visible = self.Config.Window.Resizable and not self._windowLocked and not self._minimized
        if self.Config.Window.ClampToViewport then self:ClampToViewport() end
    end
    self:_Emit("WindowMaximized", "Window", self._maximized)
    return self
end

function Library:IsMaximized() return self._maximized == true end

function Library:Restore()
    self:SetVisible(true)
    if self._minimized then self:SetMinimized(false) end
    return self
end

function Library:ResetWindow()
    if self._minimized then self:SetMinimized(false) end
    if self._maximized then self:SetMaximized(false) end
    self.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Main.Position = self.Config.Window.Position
    self.Main.Size = sizeUDim(self.Config.Window.Size)
    self._expandedSize = self.Main.Size
    self:SetWindowLocked(false)
    self:SetVisible(true)
    if self.Config.Window.ClampToViewport then self:ClampToViewport() end
    self:_Emit("WindowReset", "Window", self:GetWindowState())
    return self
end

function Library:GetWindowState()
    return {
        Visible = self:IsVisible(),
        Minimized = self._minimized == true,
        Maximized = self._maximized == true,
        Locked = self._windowLocked == true,
        AlwaysOnTop = self._alwaysOnTop == true,
        MinimizeDock = self:GetMinimizeDock(),
        Position = self.Main.Position,
        Size = self.Main.Size,
        AnchorPoint = self.Main.AnchorPoint,
        ToggleKey = self.ToggleKey,
    }
end

function Library:ApplyWindowState(state)
    if type(state) ~= "table" then return self end
    if state.MinimizeDock ~= nil then self:SetMinimizeDock(state.MinimizeDock, false) end
    if state.Position ~= nil then self.Main.Position = state.Position end
    if state.Size ~= nil then self.Main.Size = sizeUDim(state.Size) self._expandedSize = self.Main.Size end
    if state.AnchorPoint ~= nil and typeof(state.AnchorPoint) == "Vector2" then self.Main.AnchorPoint = state.AnchorPoint end
    if state.ToggleKey ~= nil then self:SetToggleKey(state.ToggleKey) end
    if state.Locked ~= nil then self:SetWindowLocked(state.Locked) end
    if state.AlwaysOnTop ~= nil then self:SetAlwaysOnTop(state.AlwaysOnTop) end
    if state.Maximized ~= nil then self:SetMaximized(state.Maximized) end
    if state.Minimized ~= nil then self:SetMinimized(state.Minimized) end
    if state.Visible ~= nil then self:SetVisible(state.Visible) end
    if self.Config.Window.ClampToViewport and not self._maximized then self:ClampToViewport() end
    self:_Emit("WindowStateApplied", "Window", self:GetWindowState())
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


----------------------------------------------------------------
-- LANGUAGE SELECTOR
----------------------------------------------------------------

function Section:AddLanguageSelector(configuration)
    configuration = configuration or {}

    local app = self.App
    local languages = configuration.Languages or configuration.Options or {}
    local selectedValue = nil
    local selectedDescriptor = nil
    local open = false
    local itemButtons = {}
    local descriptors = {}

    local closedHeight = configuration.Height or 72
    local searchEnabled = configuration.Search ~= false
    local searchHeight = searchEnabled and 38 or 0
    local itemHeight = configuration.ItemHeight or 52
    local maxHeight = configuration.MaxHeight or 260

    local row = self:_Row(closedHeight)

    local label = create("TextLabel", {
        Parent = row,
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = configuration.Text or "Language",
        TextColor3 = app.Config.Colors.Text,
        TextSize = app.Config.TextSizes.Control,
        Font = app.Config.Fonts.Normal,
        TextXAlignment = Enum.TextXAlignment.Left,
    })

    local selector = create("TextButton", {
        Parent = row,
        Position = UDim2.fromOffset(0, 27),
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = app.Config.Colors.Control,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    })
    corner(selector, app.Config.Radius.Control)
    if app.Config.Stroke.Enabled then
        stroke(selector, app.Config.Colors.Border, 1, app.Config.Stroke.Transparency)
    end

    local selectedIconHolder = create("Frame", {
        Parent = selector,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = app.Config.Colors.Background2,
        BorderSizePixel = 0,
    })
    corner(selectedIconHolder, 6)

    local selectedIcon = create("ImageLabel", {
        Parent = selectedIconHolder,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = "",
        ScaleType = Enum.ScaleType.Fit,
        Visible = false,
    })
    corner(selectedIcon, 6)

    local selectedCode = create("TextLabel", {
        Parent = selectedIconHolder,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "--",
        TextColor3 = app.Config.Colors.Accent,
        TextSize = app.Config.TextSizes.Tiny + 1,
        Font = app.Config.Fonts.Bold,
    })

    local selectedName = create("TextLabel", {
        Parent = selector,
        Position = UDim2.fromOffset(45, 3),
        Size = UDim2.new(1, -86, 0, 19),
        BackgroundTransparency = 1,
        Text = configuration.Placeholder or "Select language...",
        TextColor3 = app.Config.Colors.Text,
        TextSize = app.Config.TextSizes.Control,
        Font = app.Config.Fonts.Medium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local selectedNative = create("TextLabel", {
        Parent = selector,
        Position = UDim2.fromOffset(45, 20),
        Size = UDim2.new(1, -86, 0, 15),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = app.Config.Colors.Text2,
        TextSize = app.Config.TextSizes.Tiny + 1,
        Font = app.Config.Fonts.Normal,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local arrow = create("TextLabel", {
        Parent = selector,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(24, 30),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = app.Config.Colors.Text2,
        TextSize = 11,
        Font = app.Config.Fonts.Normal,
    })

    local popup = create("Frame", {
        Parent = row,
        Position = UDim2.fromOffset(0, 70),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = app.Config.Colors.Background2,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 50,
    })
    corner(popup, app.Config.Radius.Control)
    if app.Config.Stroke.Enabled then
        stroke(popup, app.Config.Colors.Border, 1, app.Config.Stroke.Transparency)
    end

    local searchBox = nil
    if searchEnabled then
        searchBox = create("TextBox", {
            Parent = popup,
            Position = UDim2.fromOffset(5, 5),
            Size = UDim2.new(1, -10, 0, 32),
            BackgroundColor3 = app.Config.Colors.Control,
            BorderSizePixel = 0,
            Text = "",
            PlaceholderText = configuration.SearchPlaceholder or "Search languages...",
            PlaceholderColor3 = app.Config.Colors.Text2,
            TextColor3 = app.Config.Colors.Text,
            TextSize = app.Config.TextSizes.Control,
            Font = app.Config.Fonts.Normal,
            ClearTextOnFocus = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 52,
        })
        corner(searchBox, app.Config.Radius.Control)
        create("UIPadding", {
            Parent = searchBox,
            PaddingLeft = UDim.new(0, 9),
            PaddingRight = UDim.new(0, 9),
        })
    end

    local listTop = searchEnabled and 42 or 5
    local list = create("ScrollingFrame", {
        Parent = popup,
        Position = UDim2.fromOffset(5, listTop),
        Size = UDim2.new(1, -10, 1, -(listTop + 5)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = app.Config.Colors.Scrollbar,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ZIndex = 51,
    })

    create("UIListLayout", {
        Parent = list,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local id = app:_MakeId("LanguageSelector", configuration.Id)
    local control = self:_Control(id, "LanguageSelector", configuration.Text or "Language", row, configuration)

    local function normalizeLanguage(language, index)
        if type(language) == "table" then
            local name = language.Name or language.Language or language.Label or language.Title or language.Code or tostring(index)
            local code = language.Code or language.Locale or language.Id
            local nativeName = language.NativeName or language.Native or language.LocalName
            local image = language.Image or language.Icon or language.Flag
            local value = language.Value
            if value == nil then value = language end

            return {
                Original = language,
                Value = value,
                Name = tostring(name),
                Code = code ~= nil and tostring(code) or nil,
                NativeName = nativeName ~= nil and tostring(nativeName) or nil,
                Image = image,
                Index = index,
            }
        end

        return {
            Original = language,
            Value = language,
            Name = tostring(language),
            Code = nil,
            NativeName = nil,
            Image = nil,
            Index = index,
        }
    end

    local function rebuildDescriptors()
        table.clear(descriptors)
        for index, language in ipairs(languages) do
            table.insert(descriptors, normalizeLanguage(language, index))
        end
    end

    local function descriptorMatches(descriptor, query)
        if query == "" then return true end
        query = string.lower(query)

        local haystacks = {
            descriptor.Name,
            descriptor.Code,
            descriptor.NativeName,
            tostring(descriptor.Value),
        }

        for _, text in ipairs(haystacks) do
            if text and string.find(string.lower(tostring(text)), query, 1, true) then
                return true
            end
        end

        return false
    end

    local function resolveLanguage(value)
        if value == nil then return nil end

        for _, descriptor in ipairs(descriptors) do
            if value == descriptor.Value or value == descriptor.Original then
                return descriptor
            end
        end

        local wanted = string.lower(tostring(value))
        for _, descriptor in ipairs(descriptors) do
            if string.lower(descriptor.Name) == wanted
                or (descriptor.Code and string.lower(descriptor.Code) == wanted)
                or (descriptor.NativeName and string.lower(descriptor.NativeName) == wanted)
                or string.lower(tostring(descriptor.Value)) == wanted
            then
                return descriptor
            end
        end

        return nil
    end

    local function showDescriptorIcon(holderIcon, holderCode, descriptor)
        if descriptor and descriptor.Image then
            holderIcon.Image = imageId(descriptor.Image)
            holderIcon.Visible = true
            holderCode.Visible = false
        else
            holderIcon.Image = ""
            holderIcon.Visible = false
            holderCode.Visible = true
            if descriptor then
                if descriptor.Code and descriptor.Code ~= "" then
                    holderCode.Text = string.upper(descriptor.Code:sub(1, 3))
                else
                    holderCode.Text = string.upper(descriptor.Name:sub(1, 2))
                end
            else
                holderCode.Text = "--"
            end
        end
    end

    local function renderSelection()
        if selectedDescriptor then
            selectedName.Text = selectedDescriptor.Name

            if configuration.ShowNativeName == false then
                selectedNative.Text = ""
            elseif selectedDescriptor.NativeName and selectedDescriptor.NativeName ~= selectedDescriptor.Name then
                selectedNative.Text = selectedDescriptor.NativeName
            elseif configuration.ShowCode ~= false and selectedDescriptor.Code then
                selectedNative.Text = selectedDescriptor.Code
            else
                selectedNative.Text = ""
            end

            showDescriptorIcon(selectedIcon, selectedCode, selectedDescriptor)
        else
            selectedName.Text = configuration.Placeholder or "Select language..."
            selectedNative.Text = ""
            showDescriptorIcon(selectedIcon, selectedCode, nil)
        end

        local disabled = control.Disabled
        selector.BackgroundColor3 = disabled and app.Config.Colors.ControlDisabled or app.Config.Colors.Control
        label.TextColor3 = disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
        selectedName.TextColor3 = disabled and app.Config.Colors.TextDisabled or app.Config.Colors.Text
    end

    local function countMatches(query)
        local count = 0
        for _, descriptor in ipairs(descriptors) do
            if descriptorMatches(descriptor, query or "") then
                count += 1
            end
        end
        return count
    end

    local function setOpen(state)
        if control.Disabled then state = false end
        open = state == true
        popup.Visible = open
        arrow.Text = open and "^" or "v"

        if open then
            local query = searchBox and searchBox.Text or ""
            local count = countMatches(query)
            local contentHeight = (count * (itemHeight + 4)) + searchHeight + 10
            local popupHeight = math.min(math.max(contentHeight, searchHeight + 20), maxHeight)
            popup.Size = UDim2.new(1, 0, 0, popupHeight)
            row.Size = UDim2.new(1, 0, 0, 70 + popupHeight)

            if searchBox and configuration.FocusSearchOnOpen == true then
                task.defer(function()
                    if searchBox.Parent then searchBox:CaptureFocus() end
                end)
            end
        else
            popup.Size = UDim2.new(1, 0, 0, 0)
            row.Size = UDim2.new(1, 0, 0, closedHeight)
            if searchBox then searchBox:ReleaseFocus() end
        end
    end

    local function fireChanged(previousValue, previousDescriptor)
        app:_Emit("LanguageChanged", control.Id, selectedValue, {
            Previous = previousValue,
            Label = control.Label,
            Kind = control.Kind,
            Tab = self.Tab.Name,
            Section = self.Name,
            LanguageName = selectedDescriptor and selectedDescriptor.Name or nil,
            LanguageCode = selectedDescriptor and selectedDescriptor.Code or nil,
            NativeName = selectedDescriptor and selectedDescriptor.NativeName or nil,
            LanguageImage = selectedDescriptor and selectedDescriptor.Image or nil,
            Descriptor = selectedDescriptor,
            PreviousDescriptor = previousDescriptor,
        })

        app:_Callback(configuration.Callback, selectedValue, selectedDescriptor, control)
    end

    local function set(newValue, silent)
        local descriptor = resolveLanguage(newValue)

        if newValue ~= nil and not descriptor then
            return selectedValue
        end

        local previousValue = selectedValue
        local previousDescriptor = selectedDescriptor

        selectedDescriptor = descriptor
        selectedValue = descriptor and descriptor.Value or nil
        renderSelection()

        if not silent and previousValue ~= selectedValue then
            fireChanged(previousValue, previousDescriptor)
        end

        return selectedValue
    end

    local function clearItems()
        for _, item in ipairs(itemButtons) do
            if item.Parent then item:Destroy() end
        end
        table.clear(itemButtons)
    end

    local function rebuild(query)
        query = query or ""
        clearItems()

        local visibleCount = 0

        for _, descriptor in ipairs(descriptors) do
            if descriptorMatches(descriptor, query) then
                visibleCount += 1
                local currentDescriptor = descriptor

                local choice = create("TextButton", {
                    Parent = list,
                    Size = UDim2.new(1, -6, 0, itemHeight),
                    BackgroundColor3 = selectedDescriptor == currentDescriptor and app.Config.Colors.Accent2 or app.Config.Colors.Control,
                    BorderSizePixel = 0,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 52,
                })
                corner(choice, app.Config.Radius.Control)
                table.insert(itemButtons, choice)

                local iconHolder = create("Frame", {
                    Parent = choice,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 7, 0.5, 0),
                    Size = UDim2.fromOffset(34, 34),
                    BackgroundColor3 = app.Config.Colors.Background2,
                    BorderSizePixel = 0,
                    ZIndex = 53,
                })
                corner(iconHolder, 6)

                local itemIcon = create("ImageLabel", {
                    Parent = iconHolder,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Image = "",
                    ScaleType = Enum.ScaleType.Fit,
                    Visible = false,
                    ZIndex = 54,
                })
                corner(itemIcon, 6)

                local itemCode = create("TextLabel", {
                    Parent = iconHolder,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    TextColor3 = app.Config.Colors.Accent,
                    TextSize = app.Config.TextSizes.Tiny + 1,
                    Font = app.Config.Fonts.Bold,
                    ZIndex = 54,
                })
                showDescriptorIcon(itemIcon, itemCode, currentDescriptor)

                create("TextLabel", {
                    Parent = choice,
                    Position = UDim2.fromOffset(50, 5),
                    Size = UDim2.new(1, -92, 0, 20),
                    BackgroundTransparency = 1,
                    Text = currentDescriptor.Name,
                    TextColor3 = app.Config.Colors.Text,
                    TextSize = app.Config.TextSizes.Control,
                    Font = app.Config.Fonts.Medium,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 53,
                })

                local detailText = ""
                if configuration.ShowNativeName ~= false and currentDescriptor.NativeName and currentDescriptor.NativeName ~= currentDescriptor.Name then
                    detailText = currentDescriptor.NativeName
                    if configuration.ShowCode ~= false and currentDescriptor.Code then
                        detailText ..= "  -  " .. currentDescriptor.Code
                    end
                elseif configuration.ShowCode ~= false and currentDescriptor.Code then
                    detailText = currentDescriptor.Code
                end

                create("TextLabel", {
                    Parent = choice,
                    Position = UDim2.fromOffset(50, 25),
                    Size = UDim2.new(1, -92, 0, 17),
                    BackgroundTransparency = 1,
                    Text = detailText,
                    TextColor3 = app.Config.Colors.Text2,
                    TextSize = app.Config.TextSizes.Tiny + 1,
                    Font = app.Config.Fonts.Normal,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 53,
                })

                local check = create("TextLabel", {
                    Parent = choice,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(24, 24),
                    BackgroundTransparency = 1,
                    Text = selectedDescriptor == currentDescriptor and "✓" or "",
                    TextColor3 = app.Config.Colors.Accent,
                    TextSize = 16,
                    Font = app.Config.Fonts.Bold,
                    ZIndex = 53,
                })

                control:_Connect(choice.Activated, function()
                    if control.Disabled then return end
                    set(currentDescriptor.Value)
                    rebuild(searchBox and searchBox.Text or "")
                    if configuration.CloseOnSelect ~= false then
                        setOpen(false)
                    end
                end)

                control:_Connect(choice.MouseEnter, function()
                    if not control.Disabled and app.Config.Behavior.Hover and selectedDescriptor ~= currentDescriptor then
                        app:_Tween(choice, app.Config.Animation.Fast, {BackgroundColor3 = app.Config.Colors.ControlHover})
                    end
                end)

                control:_Connect(choice.MouseLeave, function()
                    choice.BackgroundColor3 = selectedDescriptor == currentDescriptor and app.Config.Colors.Accent2 or app.Config.Colors.Control
                end)
            end
        end

        if visibleCount == 0 then
            local empty = create("TextLabel", {
                Parent = list,
                Size = UDim2.new(1, -6, 0, 42),
                BackgroundTransparency = 1,
                Text = configuration.EmptyText or "No languages found",
                TextColor3 = app.Config.Colors.Text2,
                TextSize = app.Config.TextSizes.Secondary,
                Font = app.Config.Fonts.Normal,
                ZIndex = 52,
            })
            table.insert(itemButtons, empty)
        end

        if open then setOpen(true) end
    end

    control._getter = function()
        return selectedValue
    end

    control._setter = function(newValue, silent)
        local result = set(newValue, silent)
        rebuild(searchBox and searchBox.Text or "")
        return result
    end

    control._textSetter = function(text)
        label.Text = text
    end

    control._disabledRenderer = function()
        renderSelection()
        if searchBox then searchBox.TextEditable = not control.Disabled end
        if control.Disabled then setOpen(false) end
    end

    function control:GetDescriptor()
        return selectedDescriptor
    end

    function control:GetLanguages()
        return languages
    end

    function control:SetLanguages(newLanguages, preserveSelection)
        local previousDescriptor = selectedDescriptor
        local previousValue = selectedValue

        languages = newLanguages or {}
        rebuildDescriptors()

        local nextDescriptor = nil
        if preserveSelection and previousDescriptor then
            nextDescriptor = resolveLanguage(previousDescriptor.Code or previousDescriptor.Name or previousValue)
        end

        selectedDescriptor = nextDescriptor
        selectedValue = nextDescriptor and nextDescriptor.Value or nil

        renderSelection()
        rebuild(searchBox and searchBox.Text or "")

        app:_Emit("LanguageListChanged", control.Id, languages, {
            Previous = previousValue,
            LanguageCount = #languages,
            Tab = self.Tab.Name,
            Section = self.Name,
        })

        return self
    end

    function control:Refresh()
        rebuildDescriptors()
        local current = selectedDescriptor and (selectedDescriptor.Code or selectedDescriptor.Name or selectedValue) or nil
        if current ~= nil then
            selectedDescriptor = resolveLanguage(current)
            selectedValue = selectedDescriptor and selectedDescriptor.Value or nil
        end
        renderSelection()
        rebuild(searchBox and searchBox.Text or "")
        return self
    end

    function control:SetOpen(state)
        setOpen(state)
        return self
    end

    control:_Connect(selector.Activated, function()
        if control.Disabled then return end
        setOpen(not open)
    end)

    if searchBox then
        control:_Connect(searchBox:GetPropertyChangedSignal("Text"), function()
            if not control.Disabled then
                rebuild(searchBox.Text)
            end
        end)
    end

    rebuildDescriptors()

    if configuration.Default ~= nil then
        set(configuration.Default, true)
    elseif configuration.AutoSelectFirst == true and descriptors[1] then
        set(descriptors[1].Value, true)
    else
        renderSelection()
    end

    rebuild("")

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

----------------------------------------------------------------
-- V4 EXTENDED FRAMEWORK FEATURES
----------------------------------------------------------------

local function shallowArrayCopy(source)
    local result = {}
    for i, value in ipairs(source or {}) do result[i] = value end
    return result
end

local function stringContains(haystack, needle)
    return string.find(string.lower(tostring(haystack or "")), string.lower(tostring(needle or "")), 1, true) ~= nil
end

local function valueLabel(parent, app, text, position, size)
    return create("TextLabel", {
        Parent = parent,
        Position = position or UDim2.new(),
        Size = size or UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = app.Config.Colors.Text,
        TextSize = app.Config.TextSizes.Control,
        Font = app.Config.Fonts.Normal,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
end

local function controlBox(parent, app, props)
    props = props or {}
    local className = props.ClassName or "Frame"
    local noStroke = props.NoStroke == true
    local cleaned = {}
    for key, value in pairs(props) do
        if key ~= "ClassName" and key ~= "NoStroke" then cleaned[key] = value end
    end
    cleaned.Parent = parent
    cleaned.BackgroundColor3 = cleaned.BackgroundColor3 or app.Config.Colors.Control
    cleaned.BorderSizePixel = 0
    local object = create(className, cleaned)
    corner(object, app.Config.Radius.Control)
    if app.Config.Stroke.Enabled and not noStroke then
        stroke(object, app.Config.Colors.Border, 1, app.Config.Stroke.Transparency)
    end
    return object
end

function Control:SetHeight(height)
    if self.Root and tonumber(height) then
        self.Root.Size = UDim2.new(self.Root.Size.X.Scale, self.Root.Size.X.Offset, 0, tonumber(height))
    end
    return self
end

function Control:SetOrder(order)
    if self.Root then self.Root.LayoutOrder = tonumber(order) or self.Root.LayoutOrder end
    return self
end

function Control:SetTooltip(text)
    if self.Root then self.App:_AttachTooltip(self.Root, text) end
    return self
end

function Control:Show() return self:SetVisible(true) end
function Control:Hide() return self:SetVisible(false) end
function Control:Enable() return self:SetDisabled(false) end
function Control:Disable() return self:SetDisabled(true) end

function Library:GetTab(idOrName)
    for _, tab in ipairs(self.Tabs) do
        if tab.Id == idOrName or tab.Name == idOrName then return tab end
    end
    return nil
end

function Library:GetSection(idOrName)
    for _, section in ipairs(self.Sections) do
        if section.Id == idOrName or section.Name == idOrName then return section end
    end
    return nil
end

function Library:FindControls(query)
    local results = {}
    query = string.lower(tostring(query or ""))
    for id, control in pairs(self.Controls) do
        if query == "" or stringContains(id, query) or stringContains(control.Label, query) or stringContains(control.Kind, query) then
            table.insert(results, control)
        end
    end
    table.sort(results, function(a, b) return a.Id < b.Id end)
    return results
end

function Library:SetAllDisabled(disabled, predicate)
    for _, control in pairs(self.Controls) do
        if not predicate or predicate(control) then control:SetDisabled(disabled) end
    end
    self:_Emit("AllControlsDisabled", "Window", disabled == true)
    return self
end

function Library:SetAllVisible(visible, predicate)
    for _, control in pairs(self.Controls) do
        if not predicate or predicate(control) then control:SetVisible(visible) end
    end
    self:_Emit("AllControlsVisible", "Window", visible == true)
    return self
end

function Library:GetStats()
    return {
        Controls = (function() local n = 0 for _ in pairs(self.Controls) do n += 1 end return n end)(),
        Tabs = #self.Tabs,
        Sections = #self.Sections,
        Visible = self:IsVisible(),
        Minimized = self._minimized,
        Maximized = self._maximized,
    }
end

function Library:RegisterPreset(name, state)
    self._presets = self._presets or {}
    self._presets[tostring(name)] = deepCopy(state or self:ExportState())
    self:_Emit("PresetRegistered", tostring(name), self._presets[tostring(name)])
    return self
end

function Library:ApplyPreset(name, silent)
    self._presets = self._presets or {}
    local preset = self._presets[tostring(name)]
    if preset then
        self:ImportState(deepCopy(preset), silent)
        self:_Emit("PresetApplied", tostring(name), preset)
        return true
    end
    return false
end

function Library:GetPreset(name)
    self._presets = self._presets or {}
    local preset = self._presets[tostring(name)]
    return preset and deepCopy(preset) or nil
end

function Library:GetPresets()
    self._presets = self._presets or {}
    local names = {}
    for name in pairs(self._presets) do table.insert(names, name) end
    table.sort(names)
    return names
end

function Library:RegisterCommand(name, callback, description)
    self._commands = self._commands or {}
    self._commands[string.lower(tostring(name))] = {Name = tostring(name), Callback = callback, Description = description or ""}
    return self
end

function Library:RunCommand(name, ...)
    self._commands = self._commands or {}
    local command = self._commands[string.lower(tostring(name))]
    if not command then return false, "Unknown command" end
    local ok, result = pcall(command.Callback, ...)
    self:_Emit("CommandRun", command.Name, ok and result or nil, {Success = ok, Error = ok and nil or result})
    return ok, result
end

function Library:GetCommands()
    self._commands = self._commands or {}
    local result = {}
    for _, command in pairs(self._commands) do table.insert(result, command) end
    table.sort(result, function(a, b) return a.Name < b.Name end)
    return result
end

function Library:AddGlobalKeybind(configuration)
    configuration = configuration or {}
    local binding = configuration.Key or configuration.Default or Enum.KeyCode.Unknown
    local enabled = true
    local connection = UserInputService.InputBegan:Connect(function(input, processed)
        if not enabled or (processed and configuration.IgnoreProcessed ~= false) then return end
        if configuration.IgnoreWhileTyping ~= false and UserInputService:GetFocusedTextBox() then return end
        if matches(input, binding) then
            self:_Emit("GlobalKeybindTriggered", configuration.Id or bindingName(binding), binding)
            self:_Callback(configuration.Callback, binding)
        end
    end)
    self:_Track(connection)
    return {
        Set = function(_, newBinding) binding = newBinding end,
        Get = function() return binding end,
        Enable = function() enabled = true end,
        Disable = function() enabled = false end,
        Destroy = function() pcall(function() connection:Disconnect() end) end,
    }
end

function Library:SetSidebarVisible(visible)
    visible = visible == true
    self.Sidebar.Visible = visible
    self.Content.Position = visible and UDim2.fromOffset(self.Config.Layout.SidebarWidth, 0) or UDim2.fromOffset(0, 0)
    self.Content.Size = visible and UDim2.new(1, -self.Config.Layout.SidebarWidth, 1, 0) or UDim2.fromScale(1, 1)
    self:_Emit("SidebarVisibilityChanged", "Sidebar", visible)
    return self
end

function Library:SetSidebarWidth(width)
    width = math.max(80, tonumber(width) or self.Config.Layout.SidebarWidth)
    self.Config.Layout.SidebarWidth = width
    self.Sidebar.Size = UDim2.new(0, width, 1, 0)
    if self.Sidebar.Visible then
        self.Content.Position = UDim2.fromOffset(width, 0)
        self.Content.Size = UDim2.new(1, -width, 1, 0)
    end
    return self
end

----------------------------------------------------------------
-- ICON BUTTON
----------------------------------------------------------------

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

----------------------------------------------------------------
-- HOLD BUTTON
----------------------------------------------------------------

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

----------------------------------------------------------------
-- DOUBLE CLICK BUTTON
----------------------------------------------------------------

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

----------------------------------------------------------------
-- STEPPER
----------------------------------------------------------------

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

----------------------------------------------------------------
-- RANGE SLIDER
----------------------------------------------------------------

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

----------------------------------------------------------------
-- PASSWORD / TOKEN INPUT
----------------------------------------------------------------

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

----------------------------------------------------------------
-- SEARCH BOX
----------------------------------------------------------------

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

----------------------------------------------------------------
-- CODE BOX
----------------------------------------------------------------

function Section:AddCodeBox(configuration)
    configuration = configuration or {}
    configuration.Text = configuration.Text or "Code"
    configuration.MultiLine = true
    configuration.Monospace = true
    configuration.Height = configuration.Height or 180
    return self:AddTextbox(configuration)
end

----------------------------------------------------------------
-- VALIDATED TEXT INPUTS
----------------------------------------------------------------

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


----------------------------------------------------------------
-- TAG INPUT
----------------------------------------------------------------

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

----------------------------------------------------------------
-- CHIP GROUP
----------------------------------------------------------------

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

----------------------------------------------------------------
-- RATING
----------------------------------------------------------------

function Section:AddRating(configuration)
    configuration = configuration or {}
    local app = self.App
    local maximum = math.max(1, math.floor(tonumber(configuration.Max) or 5))
    local value = clamp(math.floor(tonumber(configuration.Default) or 0), 0, maximum)
    local row = self:_Row(configuration.Height or 42)
    local label = valueLabel(row, app, configuration.Text or "Rating", UDim2.new(), UDim2.new(1, -180, 1, 0))
    local holder = create("Frame", {Parent = row, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(170, 34), BackgroundTransparency = 1})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 3)})
    local id = app:_MakeId("Rating", configuration.Id)
    local control = self:_Control(id, "Rating", configuration.Text or "Rating", row, configuration)
    local stars = {}
    local function render()
        for i, star in ipairs(stars) do
            star.Text = i <= value and (configuration.FilledSymbol or "★") or (configuration.EmptySymbol or "☆")
            star.TextColor3 = i <= value and (configuration.Color or app.Config.Colors.Warning) or app.Config.Colors.Text2
        end
    end
    local function set(newValue, silent)
        newValue = clamp(math.floor(tonumber(newValue) or 0), 0, maximum)
        local previous = value value = newValue render()
        if not silent and previous ~= value then self:_Emit(control, "RatingChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end
    for i = 1, maximum do
        local index = i
        local star = create("TextButton", {Parent = holder, Size = UDim2.fromOffset(28, 32), BackgroundTransparency = 1, Text = "☆", TextColor3 = app.Config.Colors.Text2, TextSize = 24, Font = app.Config.Fonts.Normal, AutoButtonColor = false})
        table.insert(stars, star)
        control:_Connect(star.Activated, function() if not control.Disabled then set(index == value and 0 or index) end end)
    end
    control._getter = function() return value end control._setter = set control._textSetter = function(text) label.Text = text end render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- METER / GAUGE
----------------------------------------------------------------

function Section:AddMeter(configuration)
    configuration = configuration or {}
    local app = self.App
    local minimum = tonumber(configuration.Min) or 0
    local maximum = tonumber(configuration.Max) or 100
    local value = clamp(tonumber(configuration.Default) or minimum, minimum, maximum)
    local row = self:_Row(configuration.Height or 54)
    local label = valueLabel(row, app, configuration.Text or "Meter", UDim2.new(), UDim2.new(1, -90, 0, 22))
    local number = valueLabel(row, app, "", UDim2.new(1, -85, 0, 0), UDim2.fromOffset(85, 22)) number.TextXAlignment = Enum.TextXAlignment.Right
    local bar = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0}) corner(bar, 5)
    local fill = create("Frame", {Parent = bar, Size = UDim2.fromScale(0, 1), BackgroundColor3 = configuration.Color or app.Config.Colors.Success, BorderSizePixel = 0}) corner(fill, 5)
    local id = app:_MakeId("Meter", configuration.Id)
    local control = self:_Control(id, "Meter", configuration.Text or "Meter", row, configuration)
    local function render()
        local a = maximum == minimum and 0 or clamp((value - minimum) / (maximum - minimum), 0, 1)
        fill.Size = UDim2.fromScale(a, 1)
        if configuration.Thresholds then
            local chosen = configuration.Color or app.Config.Colors.Success
            for _, threshold in ipairs(configuration.Thresholds) do if value >= threshold.Value then chosen = threshold.Color or chosen end end
            fill.BackgroundColor3 = chosen
        end
        number.Text = (configuration.Prefix or "") .. formatNumber(value, configuration.Step or 1) .. (configuration.Suffix or "")
    end
    local function set(newValue, silent)
        local previous = value value = clamp(tonumber(newValue) or value, minimum, maximum) render()
        if not silent and previous ~= value then self:_Emit(control, "MeterChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end
    control._getter = function() return value end control._setter = set control._textSetter = function(text) label.Text = text end render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- STAT CARD
----------------------------------------------------------------

function Section:AddStatCard(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Default or configuration.Value or 0
    local row = self:_Row(configuration.Height or 82)
    local box = create("Frame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.Color or app.Config.Colors.Control, BorderSizePixel = 0}) corner(box, app.Config.Radius.Control)
    local title = valueLabel(box, app, configuration.Text or "Statistic", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 20)) title.TextColor3 = app.Config.Colors.Text2
    local big = valueLabel(box, app, tostring(value), UDim2.fromOffset(12, 28), UDim2.new(1, -24, 0, 34)) big.TextSize = configuration.ValueSize or 22 big.Font = app.Config.Fonts.Bold
    local delta = valueLabel(box, app, configuration.DeltaText or "", UDim2.new(1, -120, 0, 8), UDim2.fromOffset(108, 20)) delta.TextXAlignment = Enum.TextXAlignment.Right delta.TextColor3 = configuration.DeltaColor or app.Config.Colors.Success
    local id = app:_MakeId("StatCard", configuration.Id)
    local control = self:_Control(id, "StatCard", configuration.Text or "Statistic", row, configuration)
    local function set(newValue, silent)
        local previous = value value = newValue big.Text = (configuration.Prefix or "") .. tostring(value) .. (configuration.Suffix or "")
        if not silent and previous ~= value then self:_Emit(control, "StatChanged", value, previous) app:_Callback(configuration.Callback, value, control) end
        return value
    end
    control._getter = function() return value end control._setter = set control._textSetter = function(text) title.Text = text end
    function control:SetDelta(text, color) delta.Text = tostring(text or "") if color then delta.TextColor3 = color end return self end
    set(value, true)
    return app:_Register(control)
end

----------------------------------------------------------------
-- KEY / VALUE DISPLAY
----------------------------------------------------------------

function Section:AddKeyValue(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = configuration.Value or configuration.Default or ""
    local row = self:_Row(configuration.Height or 34)
    local key = valueLabel(row, app, configuration.Text or configuration.Key or "Key", UDim2.new(), UDim2.new(0.45, -4, 1, 0)) key.TextColor3 = app.Config.Colors.Text2
    local val = valueLabel(row, app, tostring(value), UDim2.new(0.45, 4, 0, 0), UDim2.new(0.55, -4, 1, 0)) val.TextXAlignment = Enum.TextXAlignment.Right val.Font = app.Config.Fonts.Medium
    local id = app:_MakeId("KeyValue", configuration.Id)
    local control = self:_Control(id, "KeyValue", configuration.Text or configuration.Key or "Key", row, configuration)
    local function set(newValue, silent) local previous = value value = newValue val.Text = tostring(value) if not silent and previous ~= value then self:_Emit(control, "KeyValueChanged", value, previous) end return value end
    control._getter = function() return value end control._setter = set control._textSetter = function(text) key.Text = text end
    return app:_Register(control)
end

----------------------------------------------------------------
-- BREADCRUMBS
----------------------------------------------------------------

function Section:AddBreadcrumbs(configuration)
    configuration = configuration or {}
    local app = self.App
    local items = shallowArrayCopy(configuration.Items or {})
    local row = self:_Row(configuration.Height or 36)
    local holder = create("ScrollingFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new()})
    create("UIListLayout", {Parent = holder, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4)})
    local id = app:_MakeId("Breadcrumbs", configuration.Id)
    local control = self:_Control(id, "Breadcrumbs", configuration.Text or "Breadcrumbs", row, configuration)
    local children = {}
    local function render()
        for _, child in ipairs(children) do child:Destroy() end table.clear(children)
        for index, item in ipairs(items) do
            local text = type(item) == "table" and (item.Text or item.Name or tostring(index)) or tostring(item)
            local button = create("TextButton", {Parent = holder, Size = UDim2.fromOffset(math.max(42, #text * 8 + 16), 28), BackgroundTransparency = 1, Text = text, TextColor3 = index == #items and app.Config.Colors.Text or app.Config.Colors.Accent, TextSize = app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Medium, AutoButtonColor = false})
            table.insert(children, button)
            control:_Connect(button.Activated, function() if not control.Disabled then self:_Emit(control, "BreadcrumbPressed", item, nil) app:_Callback(configuration.Callback, item, index, control) end end)
            if index < #items then local sep = valueLabel(holder, app, configuration.Separator or ">", nil, UDim2.fromOffset(14, 28)) sep.TextXAlignment = Enum.TextXAlignment.Center sep.TextColor3 = app.Config.Colors.Text2 table.insert(children, sep) end
        end
    end
    control._getter = function() return shallowArrayCopy(items) end
    control._setter = function(newItems) items = shallowArrayCopy(newItems or {}) render() return shallowArrayCopy(items) end
    function control:Push(item) table.insert(items, item) render() return self end
    function control:Pop() local value = table.remove(items) render() return value end
    render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- PAGINATION
----------------------------------------------------------------

function Section:AddPagination(configuration)
    configuration = configuration or {}
    local app = self.App
    local pages = math.max(1, math.floor(tonumber(configuration.Pages) or 1))
    local page = clamp(math.floor(tonumber(configuration.Default) or 1), 1, pages)
    local row = self:_Row(configuration.Height or 40)
    local previousButton = create("TextButton", {Parent = row, Size = UDim2.fromOffset(42, 34), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = "<", TextColor3 = app.Config.Colors.Text, TextSize = 16, Font = app.Config.Fonts.Bold}) corner(previousButton, app.Config.Radius.Button)
    local nextButton = previousButton:Clone() nextButton.Parent = row nextButton.AnchorPoint = Vector2.new(1, 0) nextButton.Position = UDim2.fromScale(1, 0) nextButton.Text = ">"
    local display = valueLabel(row, app, "", UDim2.fromOffset(50, 0), UDim2.new(1, -100, 0, 34)) display.TextXAlignment = Enum.TextXAlignment.Center display.Font = app.Config.Fonts.Medium
    local id = app:_MakeId("Pagination", configuration.Id)
    local control = self:_Control(id, "Pagination", configuration.Text or "Pagination", row, configuration)
    local function render() display.Text = string.format(configuration.Format or "Page %d of %d", page, pages) end
    local function set(newPage, silent)
        newPage = clamp(math.floor(tonumber(newPage) or page), 1, pages)
        local old = page page = newPage render()
        if not silent and old ~= page then self:_Emit(control, "PageChanged", page, old) app:_Callback(configuration.Callback, page, control) end
        return page
    end
    control._getter = function() return page end control._setter = set
    function control:SetPages(count) pages = math.max(1, math.floor(tonumber(count) or pages)) page = clamp(page, 1, pages) render() return self end
    function control:Next() return set(page + 1) end
    function control:Previous() return set(page - 1) end
    control:_Connect(previousButton.Activated, function() if not control.Disabled then set(page - 1) end end)
    control:_Connect(nextButton.Activated, function() if not control.Disabled then set(page + 1) end end)
    render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- CHECKLIST
----------------------------------------------------------------

function Section:AddChecklist(configuration)
    configuration = configuration or {}
    local app = self.App
    local items = configuration.Items or {}
    local selected = {}
    for _, item in ipairs(configuration.Default or {}) do selected[tostring(item)] = true end
    local row = self:_Row(configuration.Height or math.min(260, 34 + #items * 34))
    local list = create("ScrollingFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, ScrollBarThickness = app.Config.Layout.ScrollbarThickness, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}) corner(list, app.Config.Radius.Control)
    create("UIListLayout", {Parent = list, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5)})
    local id = app:_MakeId("Checklist", configuration.Id)
    local control = self:_Control(id, "Checklist", configuration.Text or "Checklist", row, configuration)
    local function array()
        local result = {} for _, item in ipairs(items) do if selected[tostring(item)] then table.insert(result, item) end end return result
    end
    local buttons = {}
    local function render()
        for item, data in pairs(buttons) do
            local active = selected[tostring(item)] == true
            data.Mark.Text = active and "✓" or ""
            data.Box.BackgroundColor3 = active and app.Config.Colors.Accent or app.Config.Colors.Control
        end
    end
    for _, item in ipairs(items) do
        local current = item
        local button = create("TextButton", {Parent = list, Size = UDim2.new(1, -10, 0, 32), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = "", AutoButtonColor = false}) corner(button, app.Config.Radius.Control)
        local box = create("Frame", {Parent = button, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0}) corner(box, 4)
        local mark = valueLabel(box, app, "", nil, UDim2.fromScale(1, 1)) mark.TextXAlignment = Enum.TextXAlignment.Center mark.TextColor3 = app.Config.Colors.AccentText
        local text = valueLabel(button, app, tostring(current), UDim2.fromOffset(34, 0), UDim2.new(1, -40, 1, 0))
        buttons[current] = {Button = button, Box = box, Mark = mark, Text = text}
        control:_Connect(button.Activated, function()
            if control.Disabled then return end
            local previous = array() selected[tostring(current)] = not selected[tostring(current)] render()
            local now = array() self:_Emit(control, "ChecklistChanged", now, previous) app:_Callback(configuration.Callback, now, current, control)
        end)
    end
    control._getter = array
    control._setter = function(values, silent)
        local previous = array() table.clear(selected) for _, item in ipairs(values or {}) do selected[tostring(item)] = true end render()
        if not silent then local now = array() self:_Emit(control, "ChecklistChanged", now, previous) app:_Callback(configuration.Callback, now, nil, control) end return array()
    end
    render()
    return app:_Register(control)
end


----------------------------------------------------------------
-- SIMPLE LIST
----------------------------------------------------------------

function Section:AddList(configuration)
    configuration = configuration or {}
    local app = self.App
    local items = shallowArrayCopy(configuration.Items or {})
    local selected = configuration.Default
    local row = self:_Row(configuration.Height or 220)
    local list = create("ScrollingFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, ScrollBarThickness = app.Config.Layout.ScrollbarThickness, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()})
    corner(list, app.Config.Radius.Control)
    create("UIListLayout", {Parent = list, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})
    local id = app:_MakeId("List", configuration.Id)
    local control = self:_Control(id, "List", configuration.Text or "List", row, configuration)
    local buttons = {}
    local function display(item, index)
        if configuration.Display then local ok, result = pcall(configuration.Display, item, index) if ok then return tostring(result) end end
        return tostring(item)
    end
    local function renderSelection()
        for item, button in pairs(buttons) do button.BackgroundColor3 = item == selected and app.Config.Colors.Accent2 or app.Config.Colors.Control end
    end
    local function set(item, silent)
        local previous = selected selected = item renderSelection()
        if not silent and previous ~= selected then self:_Emit(control, "ListSelected", selected, previous) app:_Callback(configuration.Callback, selected, control) end
        return selected
    end
    local function rebuild()
        for _, button in pairs(buttons) do button:Destroy() end table.clear(buttons)
        for index, item in ipairs(items) do
            local current = item
            local button = create("TextButton", {Parent = list, Size = UDim2.new(1, -8, 0, configuration.ItemHeight or 32), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = display(current, index), TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false})
            corner(button, app.Config.Radius.Control) create("UIPadding", {Parent = button, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}) buttons[current] = button
            control:_Connect(button.Activated, function() if not control.Disabled then set(current) end end)
        end
        renderSelection()
    end
    control._getter = function() return selected end control._setter = set
    function control:SetItems(newItems, keepSelection) items = shallowArrayCopy(newItems or {}) if not keepSelection then selected = nil end rebuild() return self end
    function control:GetItems() return shallowArrayCopy(items) end
    function control:AddItem(item) table.insert(items, item) rebuild() return self end
    function control:RemoveItem(item) for i = #items, 1, -1 do if items[i] == item then table.remove(items, i) end end if selected == item then selected = nil end rebuild() return self end
    rebuild()
    return app:_Register(control)
end

----------------------------------------------------------------
-- SEARCHABLE LIST
----------------------------------------------------------------

function Section:AddSearchableList(configuration)
    configuration = configuration or {}
    local app = self.App
    local items = shallowArrayCopy(configuration.Items or {})
    local selected
    local row = self:_Row(configuration.Height or 270)
    local search = create("TextBox", {Parent = row, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, Text = "", PlaceholderText = configuration.Placeholder or "Search list...", PlaceholderColor3 = app.Config.Colors.Text2, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left}) corner(search, app.Config.Radius.Control)
    create("UIPadding", {Parent = search, PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)})
    local list = create("ScrollingFrame", {Parent = row, Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -40), BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, ScrollBarThickness = app.Config.Layout.ScrollbarThickness, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}) corner(list, app.Config.Radius.Control)
    create("UIListLayout", {Parent = list, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder})
    create("UIPadding", {Parent = list, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)})
    local id = app:_MakeId("SearchableList", configuration.Id)
    local control = self:_Control(id, "SearchableList", configuration.Text or "Searchable List", row, configuration)
    local children = {}
    local function textFor(item, index) if configuration.Display then local ok, result = pcall(configuration.Display, item, index) if ok then return tostring(result) end end return tostring(item) end
    local function rebuild()
        for _, child in ipairs(children) do child:Destroy() end table.clear(children)
        local query = search.Text
        for index, item in ipairs(items) do
            local current = item local text = textFor(current, index)
            if query == "" or stringContains(text, query) then
                local button = create("TextButton", {Parent = list, Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = current == selected and app.Config.Colors.Accent2 or app.Config.Colors.Control, BorderSizePixel = 0, Text = text, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Normal, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false})
                corner(button, app.Config.Radius.Control) create("UIPadding", {Parent = button, PaddingLeft = UDim.new(0, 8)}) table.insert(children, button)
                control:_Connect(button.Activated, function()
                    if control.Disabled then return end
                    local previous = selected selected = current rebuild() self:_Emit(control, "SearchableListSelected", selected, previous) app:_Callback(configuration.Callback, selected, control)
                end)
            end
        end
    end
    control._getter = function() return selected end
    control._setter = function(value, silent) local previous = selected selected = value rebuild() if not silent and previous ~= selected then self:_Emit(control, "SearchableListSelected", selected, previous) app:_Callback(configuration.Callback, selected, control) end return selected end
    function control:SetItems(newItems) items = shallowArrayCopy(newItems or {}) rebuild() return self end
    function control:SetQuery(query) search.Text = tostring(query or "") rebuild() return self end
    control:_Connect(search:GetPropertyChangedSignal("Text"), rebuild)
    rebuild()
    return app:_Register(control)
end

----------------------------------------------------------------
-- TABLE
----------------------------------------------------------------

function Section:AddTable(configuration)
    configuration = configuration or {}
    local app = self.App
    local columns = configuration.Columns or {}
    local rows = configuration.Rows or {}
    local selectedIndex = nil
    local row = self:_Row(configuration.Height or 280)
    local holder = create("ScrollingFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, ScrollBarThickness = app.Config.Layout.ScrollbarThickness, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}) corner(holder, app.Config.Radius.Control)
    local layout = create("UIListLayout", {Parent = holder, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
    local id = app:_MakeId("Table", configuration.Id)
    local control = self:_Control(id, "Table", configuration.Text or "Table", row, configuration)
    local generated = {}
    local function clear() for _, item in ipairs(generated) do item:Destroy() end table.clear(generated) end
    local function cellText(rowData, column, index)
        local key = type(column) == "table" and (column.Key or column.Name or index) or column
        local value = type(rowData) == "table" and (rowData[key] ~= nil and rowData[key] or rowData[index]) or rowData
        if type(column) == "table" and column.Format then local ok, result = pcall(column.Format, value, rowData) if ok then return tostring(result) end end
        return tostring(value == nil and "" or value)
    end
    local function rebuild()
        clear()
        local header = create("Frame", {Parent = holder, Size = UDim2.new(1, -8, 0, 32), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0, LayoutOrder = -100}) corner(header, app.Config.Radius.Control) table.insert(generated, header)
        for index, column in ipairs(columns) do
            local width = type(column) == "table" and column.Width or nil
            local label = valueLabel(header, app, type(column) == "table" and (column.Title or column.Name or column.Key or index) or column, UDim2.new((index - 1) / math.max(#columns, 1), 4, 0, 0), width and UDim2.new(0, width, 1, 0) or UDim2.new(1 / math.max(#columns, 1), -8, 1, 0))
            label.Font = app.Config.Fonts.Bold label.TextColor3 = app.Config.Colors.Text2
        end
        for index, rowData in ipairs(rows) do
            local currentIndex, currentData = index, rowData
            local line = create("TextButton", {Parent = holder, Size = UDim2.new(1, -8, 0, configuration.RowHeight or 32), BackgroundColor3 = selectedIndex == index and app.Config.Colors.Accent2 or app.Config.Colors.Control, BorderSizePixel = 0, Text = "", AutoButtonColor = false}) corner(line, app.Config.Radius.Control) table.insert(generated, line)
            for columnIndex, column in ipairs(columns) do
                local width = type(column) == "table" and column.Width or nil
                local label = valueLabel(line, app, cellText(rowData, column, columnIndex), UDim2.new((columnIndex - 1) / math.max(#columns, 1), 4, 0, 0), width and UDim2.new(0, width, 1, 0) or UDim2.new(1 / math.max(#columns, 1), -8, 1, 0))
                label.TextSize = app.Config.TextSizes.Secondary
            end
            control:_Connect(line.Activated, function()
                if control.Disabled then return end
                local previous = selectedIndex selectedIndex = currentIndex rebuild() self:_Emit(control, "TableRowSelected", currentData, previous) app:_Callback(configuration.Callback, currentData, currentIndex, control)
            end)
        end
    end
    control._getter = function() return selectedIndex and rows[selectedIndex] or nil end
    control._setter = function(value, silent)
        local previous = selectedIndex
        if type(value) == "number" then selectedIndex = clamp(math.floor(value), 1, math.max(#rows, 1)) else for i, data in ipairs(rows) do if data == value then selectedIndex = i break end end end
        rebuild()
        if not silent and previous ~= selectedIndex then app:_Callback(configuration.Callback, selectedIndex and rows[selectedIndex] or nil, selectedIndex, control) end
        return selectedIndex and rows[selectedIndex] or nil
    end
    function control:SetRows(newRows) rows = newRows or {} selectedIndex = nil rebuild() return self end
    function control:SetColumns(newColumns) columns = newColumns or {} rebuild() return self end
    function control:GetRows() return rows end
    rebuild()
    return app:_Register(control)
end

----------------------------------------------------------------
-- TREE VIEW
----------------------------------------------------------------

function Section:AddTreeView(configuration)
    configuration = configuration or {}
    local app = self.App
    local nodes = configuration.Nodes or {}
    local expanded = {}
    local selected
    local row = self:_Row(configuration.Height or 280)
    local holder = create("ScrollingFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, ScrollBarThickness = app.Config.Layout.ScrollbarThickness, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}) corner(holder, app.Config.Radius.Control)
    create("UIListLayout", {Parent = holder, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder})
    local id = app:_MakeId("TreeView", configuration.Id)
    local control = self:_Control(id, "TreeView", configuration.Text or "Tree", row, configuration)
    local generated = {}
    local function nodeName(node) return type(node) == "table" and (node.Name or node.Text or node.Label or tostring(node.Value or "Node")) or tostring(node) end
    local function nodeChildren(node) return type(node) == "table" and (node.Children or node.Items) or nil end
    local function rebuild()
        for _, item in ipairs(generated) do item:Destroy() end table.clear(generated)
        local order = 0
        local function addNodes(list, depth)
            for _, node in ipairs(list or {}) do
                order += 1
                local children = nodeChildren(node)
                local hasChildren = type(children) == "table" and #children > 0
                local line = create("TextButton", {Parent = holder, Size = UDim2.new(1, -8, 0, 30), BackgroundColor3 = selected == node and app.Config.Colors.Accent2 or app.Config.Colors.Control, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = order}) corner(line, app.Config.Radius.Control) table.insert(generated, line)
                local arrow = valueLabel(line, app, hasChildren and (expanded[node] and "v" or ">") or "", UDim2.fromOffset(8 + depth * 18, 0), UDim2.fromOffset(18, 30)) arrow.TextXAlignment = Enum.TextXAlignment.Center
                local label = valueLabel(line, app, nodeName(node), UDim2.fromOffset(28 + depth * 18, 0), UDim2.new(1, -(34 + depth * 18), 1, 0))
                control:_Connect(line.Activated, function()
                    if control.Disabled then return end
                    if hasChildren and configuration.ClickExpands ~= false then expanded[node] = not expanded[node] end
                    local previous = selected selected = node rebuild() self:_Emit(control, "TreeNodeSelected", selected, previous) app:_Callback(configuration.Callback, selected, control)
                end)
                if hasChildren and expanded[node] then addNodes(children, depth + 1) end
            end
        end
        addNodes(nodes, 0)
    end
    control._getter = function() return selected end
    control._setter = function(value, silent) local previous = selected selected = value rebuild() if not silent and previous ~= selected then app:_Callback(configuration.Callback, selected, control) end return selected end
    function control:SetNodes(newNodes) nodes = newNodes or {} selected = nil table.clear(expanded) rebuild() return self end
    function control:ExpandAll()
        local function walk(list) for _, node in ipairs(list or {}) do local children = nodeChildren(node) if children and #children > 0 then expanded[node] = true walk(children) end end end walk(nodes) rebuild() return self
    end
    function control:CollapseAll() table.clear(expanded) rebuild() return self end
    rebuild()
    return app:_Register(control)
end

----------------------------------------------------------------
-- TIMELINE
----------------------------------------------------------------

function Section:AddTimeline(configuration)
    configuration = configuration or {}
    local app = self.App
    local items = configuration.Items or {}
    local row = self:_Row(configuration.Height or math.max(80, #items * 54))
    local holder = create("Frame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1})
    create("UIListLayout", {Parent = holder, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
    local id = app:_MakeId("Timeline", configuration.Id)
    local control = self:_Control(id, "Timeline", configuration.Text or "Timeline", row, configuration)
    local generated = {}
    local function rebuild()
        for _, child in ipairs(generated) do child:Destroy() end table.clear(generated)
        for index, item in ipairs(items) do
            local frame = create("Frame", {Parent = holder, Size = UDim2.new(1, 0, 0, configuration.ItemHeight or 50), BackgroundTransparency = 1}) table.insert(generated, frame)
            local dot = create("Frame", {Parent = frame, Position = UDim2.fromOffset(5, 9), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = type(item) == "table" and item.Color or app.Config.Colors.Accent, BorderSizePixel = 0}) corner(dot, 999)
            if index < #items then create("Frame", {Parent = frame, Position = UDim2.fromOffset(10, 22), Size = UDim2.new(0, 2, 1, -10), BackgroundColor3 = app.Config.Colors.Border, BorderSizePixel = 0}) end
            local titleText = type(item) == "table" and (item.Title or item.Text or tostring(index)) or tostring(item)
            local title = valueLabel(frame, app, titleText, UDim2.fromOffset(28, 2), UDim2.new(1, -32, 0, 22)) title.Font = app.Config.Fonts.Medium
            local detail = type(item) == "table" and (item.Description or item.Time or "") or ""
            local sub = valueLabel(frame, app, detail, UDim2.fromOffset(28, 23), UDim2.new(1, -32, 0, 20)) sub.TextColor3 = app.Config.Colors.Text2 sub.TextSize = app.Config.TextSizes.Secondary
        end
    end
    control._getter = function() return items end
    control._setter = function(newItems) items = newItems or {} rebuild() return items end
    function control:Add(item) table.insert(items, item) rebuild() return self end
    function control:Clear() table.clear(items) rebuild() return self end
    rebuild()
    return app:_Register(control)
end

----------------------------------------------------------------
-- LOG CONSOLE
----------------------------------------------------------------

function Section:AddLogConsole(configuration)
    configuration = configuration or {}
    local app = self.App
    local lines = {}
    local maximum = configuration.MaxLines or 250
    local row = self:_Row(configuration.Height or 230)
    local holder = create("ScrollingFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.BackgroundColor or Color3.fromRGB(12, 12, 14), BorderSizePixel = 0, ScrollBarThickness = app.Config.Layout.ScrollbarThickness, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}) corner(holder, app.Config.Radius.Control)
    local output = create("TextLabel", {Parent = holder, Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = "", RichText = configuration.RichText == true, TextColor3 = configuration.TextColor or app.Config.Colors.Text, TextSize = configuration.TextSize or app.Config.TextSizes.Secondary, Font = app.Config.Fonts.Mono, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top})
    create("UIPadding", {Parent = holder, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)})
    local id = app:_MakeId("LogConsole", configuration.Id)
    local control = self:_Control(id, "LogConsole", configuration.Text or "Log", row, configuration)
    local function render()
        output.Text = table.concat(lines, "\n")
        task.defer(function() if holder.Parent then holder.CanvasPosition = Vector2.new(0, math.max(0, holder.AbsoluteCanvasSize.Y - holder.AbsoluteWindowSize.Y)) end end)
    end
    local function set(value)
        table.clear(lines)
        if type(value) == "table" then for _, line in ipairs(value) do table.insert(lines, tostring(line)) end else for line in tostring(value or ""):gmatch("[^\n]+") do table.insert(lines, line) end end
        while #lines > maximum do table.remove(lines, 1) end render() return shallowArrayCopy(lines)
    end
    control._getter = function() return shallowArrayCopy(lines) end control._setter = set
    function control:Log(text, prefix)
        local line = (prefix and ("[" .. tostring(prefix) .. "] ") or "") .. tostring(text)
        table.insert(lines, line) while #lines > maximum do table.remove(lines, 1) end render() self.App:_Emit("LogAdded", self.Id, line) return self
    end
    function control:Info(text) return self:Log(text, "INFO") end
    function control:Warn(text) return self:Log(text, "WARN") end
    function control:Error(text) return self:Log(text, "ERROR") end
    function control:Clear() table.clear(lines) render() return self end
    return app:_Register(control)
end

----------------------------------------------------------------
-- CONSOLE COMMAND INPUT
----------------------------------------------------------------

function Section:AddCommandBox(configuration)
    configuration = configuration or {}
    local app = self.App
    local history = {}
    local historyIndex = 0
    local row = self:_Row(configuration.Height or 38)
    local prompt = valueLabel(row, app, configuration.Prompt or ">", UDim2.fromOffset(0, 0), UDim2.fromOffset(24, 34)) prompt.TextColor3 = app.Config.Colors.Accent prompt.Font = app.Config.Fonts.Mono
    local box = create("TextBox", {Parent = row, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -24, 0, 34), BackgroundColor3 = Color3.fromRGB(12, 12, 14), BorderSizePixel = 0, Text = "", PlaceholderText = configuration.Placeholder or "command...", PlaceholderColor3 = app.Config.Colors.Text2, TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Control, Font = app.Config.Fonts.Mono, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left}) corner(box, app.Config.Radius.Control)
    create("UIPadding", {Parent = box, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
    local id = app:_MakeId("CommandBox", configuration.Id)
    local control = self:_Control(id, "CommandBox", configuration.Text or "Command", row, configuration)
    control._getter = function() return box.Text end
    control._setter = function(value) box.Text = tostring(value or "") return box.Text end
    control:_Connect(box.FocusLost, function(enter)
        if not enter or control.Disabled or box.Text == "" then return end
        local commandLine = box.Text table.insert(history, commandLine) historyIndex = #history + 1 box.Text = ""
        self:_Emit(control, "CommandSubmitted", commandLine, nil)
        if configuration.UseLibraryCommands then
            local command, rest = commandLine:match("^(%S+)%s*(.*)$")
            local ok, result = app:RunCommand(command, rest)
            app:_Callback(configuration.Callback, commandLine, ok, result, control)
        else
            app:_Callback(configuration.Callback, commandLine, control)
        end
    end)
    control:_Connect(box.InputBegan, function(input)
        if input.KeyCode == Enum.KeyCode.Up and #history > 0 then historyIndex = clamp(historyIndex - 1, 1, #history) box.Text = history[historyIndex] box.CursorPosition = #box.Text + 1
        elseif input.KeyCode == Enum.KeyCode.Down and #history > 0 then historyIndex = clamp(historyIndex + 1, 1, #history + 1) box.Text = history[historyIndex] or "" box.CursorPosition = #box.Text + 1 end
    end)
    function control:GetHistory() return shallowArrayCopy(history) end
    function control:ClearHistory() table.clear(history) historyIndex = 0 return self end
    return app:_Register(control)
end


----------------------------------------------------------------
-- SPARKLINE
----------------------------------------------------------------

function Section:AddSparkline(configuration)
    configuration = configuration or {}
    local app = self.App
    local values = shallowArrayCopy(configuration.Values or configuration.Default or {1, 3, 2, 5, 4})
    local row = self:_Row(configuration.Height or 90)
    local title = valueLabel(row, app, configuration.Text or "Sparkline", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local chart = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -28), BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, ClipsDescendants = true}) corner(chart, app.Config.Radius.Control)
    local id = app:_MakeId("Sparkline", configuration.Id)
    local control = self:_Control(id, "Sparkline", configuration.Text or "Sparkline", row, configuration)
    local generated = {}
    local function render()
        for _, child in ipairs(generated) do child:Destroy() end table.clear(generated)
        if #values < 2 then return end
        local minV, maxV = math.huge, -math.huge
        for _, v in ipairs(values) do v = tonumber(v) or 0 minV = math.min(minV, v) maxV = math.max(maxV, v) end
        if maxV == minV then maxV = minV + 1 end
        local width = math.max(chart.AbsoluteSize.X, 300)
        local height = math.max(chart.AbsoluteSize.Y, 50)
        for i = 1, #values - 1 do
            local x1 = (i - 1) / (#values - 1) * width
            local x2 = i / (#values - 1) * width
            local y1 = height - ((values[i] - minV) / (maxV - minV)) * height
            local y2 = height - ((values[i + 1] - minV) / (maxV - minV)) * height
            local dx, dy = x2 - x1, y2 - y1
            local length = math.sqrt(dx * dx + dy * dy)
            local line = create("Frame", {Parent = chart, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromOffset(x1, y1), Size = UDim2.fromOffset(length, configuration.Thickness or 2), Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = configuration.Color or app.Config.Colors.Accent, BorderSizePixel = 0})
            table.insert(generated, line)
        end
    end
    control._getter = function() return shallowArrayCopy(values) end control._setter = function(newValues) values = shallowArrayCopy(newValues or {}) task.defer(render) return shallowArrayCopy(values) end
    function control:Add(value) table.insert(values, tonumber(value) or 0) if configuration.MaxPoints and #values > configuration.MaxPoints then table.remove(values, 1) end task.defer(render) return self end
    function control:Clear() table.clear(values) render() return self end
    control._textSetter = function(text) title.Text = text end
    task.defer(render)
    return app:_Register(control)
end

----------------------------------------------------------------
-- BAR CHART
----------------------------------------------------------------

function Section:AddBarChart(configuration)
    configuration = configuration or {}
    local app = self.App
    local values = shallowArrayCopy(configuration.Values or configuration.Default or {5, 8, 3, 7})
    local row = self:_Row(configuration.Height or 160)
    local title = valueLabel(row, app, configuration.Text or "Bar Chart", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local chart = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -28), BackgroundColor3 = app.Config.Colors.Background2, BorderSizePixel = 0, ClipsDescendants = true}) corner(chart, app.Config.Radius.Control)
    local id = app:_MakeId("BarChart", configuration.Id)
    local control = self:_Control(id, "BarChart", configuration.Text or "Bar Chart", row, configuration)
    local generated = {}
    local function render()
        for _, child in ipairs(generated) do child:Destroy() end table.clear(generated)
        local maxV = 1
        for _, item in ipairs(values) do local v = type(item) == "table" and tonumber(item.Value or item[2]) or tonumber(item) maxV = math.max(maxV, v or 0) end
        local count = math.max(#values, 1)
        for index, item in ipairs(values) do
            local v = type(item) == "table" and tonumber(item.Value or item[2]) or tonumber(item) or 0
            local labelText = type(item) == "table" and tostring(item.Label or item.Name or index) or tostring(index)
            local slot = create("Frame", {Parent = chart, Position = UDim2.new((index - 1) / count, 3, 0, 4), Size = UDim2.new(1 / count, -6, 1, -8), BackgroundTransparency = 1}) table.insert(generated, slot)
            local bar = create("Frame", {Parent = slot, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 4, 1, -22), Size = UDim2.new(1, -8, (v / maxV), 0), BackgroundColor3 = type(item) == "table" and item.Color or configuration.Color or app.Config.Colors.Accent, BorderSizePixel = 0}) corner(bar, 4)
            local label = valueLabel(slot, app, labelText, UDim2.new(0, 0, 1, -20), UDim2.new(1, 0, 0, 18)) label.TextXAlignment = Enum.TextXAlignment.Center label.TextSize = app.Config.TextSizes.Tiny
        end
    end
    control._getter = function() return shallowArrayCopy(values) end control._setter = function(newValues) values = shallowArrayCopy(newValues or {}) render() return shallowArrayCopy(values) end control._textSetter = function(text) title.Text = text end
    render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- LINE CHART
----------------------------------------------------------------

function Section:AddLineChart(configuration)
    configuration = configuration or {}
    configuration.Height = configuration.Height or 170
    configuration.Thickness = configuration.Thickness or 2
    local control = self:AddSparkline(configuration)
    control.Kind = "LineChart"
    return control
end

----------------------------------------------------------------
-- HEATMAP
----------------------------------------------------------------

function Section:AddHeatmap(configuration)
    configuration = configuration or {}
    local app = self.App
    local values = configuration.Values or {{0.1, 0.5, 0.9}, {0.3, 0.7, 0.2}}
    local row = self:_Row(configuration.Height or 170)
    local title = valueLabel(row, app, configuration.Text or "Heatmap", UDim2.new(), UDim2.new(1, 0, 0, 22))
    local grid = create("Frame", {Parent = row, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 1, -28), BackgroundTransparency = 1})
    local id = app:_MakeId("Heatmap", configuration.Id)
    local control = self:_Control(id, "Heatmap", configuration.Text or "Heatmap", row, configuration)
    local cells = {}
    local function mix(a, b, t) return a:Lerp(b, clamp(t, 0, 1)) end
    local function render()
        for _, child in ipairs(cells) do child:Destroy() end table.clear(cells)
        local rows = #values local cols = 0 for _, r in ipairs(values) do cols = math.max(cols, #r) end cols = math.max(cols, 1) rows = math.max(rows, 1)
        for y, dataRow in ipairs(values) do
            for x, raw in ipairs(dataRow) do
                local v = clamp(tonumber(raw) or 0, 0, 1)
                local button = create("TextButton", {Parent = grid, Position = UDim2.new((x - 1) / cols, 2, (y - 1) / rows, 2), Size = UDim2.new(1 / cols, -4, 1 / rows, -4), BackgroundColor3 = mix(configuration.LowColor or app.Config.Colors.Control, configuration.HighColor or app.Config.Colors.Accent, v), BorderSizePixel = 0, Text = configuration.ShowValues == false and "" or string.format("%.2f", v), TextColor3 = app.Config.Colors.Text, TextSize = app.Config.TextSizes.Tiny, Font = app.Config.Fonts.Mono, AutoButtonColor = false}) corner(button, 4) table.insert(cells, button)
                control:_Connect(button.Activated, function() if not control.Disabled then self:_Emit(control, "HeatmapCellPressed", v, nil) app:_Callback(configuration.Callback, v, x, y, control) end end)
            end
        end
    end
    control._getter = function() return values end control._setter = function(newValues) values = newValues or {} render() return values end control._textSetter = function(text) title.Text = text end render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- LOADING SPINNER
----------------------------------------------------------------

function Section:AddLoadingSpinner(configuration)
    configuration = configuration or {}
    local app = self.App
    local running = configuration.Running ~= false
    local row = self:_Row(configuration.Height or 46)
    local spinner = create("TextLabel", {Parent = row, Size = UDim2.fromOffset(38, 38), BackgroundTransparency = 1, Text = configuration.Symbol or "◌", TextColor3 = configuration.Color or app.Config.Colors.Accent, TextSize = configuration.Size or 28, Font = app.Config.Fonts.Bold})
    local label = valueLabel(row, app, configuration.Text or "Loading...", UDim2.fromOffset(44, 0), UDim2.new(1, -44, 1, 0)) label.TextColor3 = app.Config.Colors.Text2
    local id = app:_MakeId("LoadingSpinner", configuration.Id)
    local control = self:_Control(id, "LoadingSpinner", configuration.Text or "Loading", row, configuration)
    local angle = 0
    local connection = RunService.RenderStepped:Connect(function(dt) if running and row.Parent then angle = (angle + dt * (configuration.Speed or 240)) % 360 spinner.Rotation = angle end end)
    table.insert(control._connections, connection)
    control._getter = function() return running end control._setter = function(value) running = value == true spinner.Visible = running return running end control._textSetter = function(text) label.Text = text end
    function control:Start() return self:Set(true) end function control:Stop() return self:Set(false) end
    return app:_Register(control)
end

----------------------------------------------------------------
-- SKELETON LOADER
----------------------------------------------------------------

function Section:AddSkeleton(configuration)
    configuration = configuration or {}
    local app = self.App
    local running = configuration.Running ~= false
    local row = self:_Row(configuration.Height or 90)
    local bars = {}
    for i = 1, (configuration.Lines or 3) do
        local bar = create("Frame", {Parent = row, Position = UDim2.new(0, 0, 0, (i - 1) * 26), Size = UDim2.new(i == (configuration.Lines or 3) and 0.65 or 1, 0, 0, 18), BackgroundColor3 = app.Config.Colors.Control, BorderSizePixel = 0}) corner(bar, 5) table.insert(bars, bar)
    end
    local id = app:_MakeId("Skeleton", configuration.Id)
    local control = self:_Control(id, "Skeleton", configuration.Text or "Skeleton", row, configuration)
    local t = 0
    local connection = RunService.RenderStepped:Connect(function(dt)
        if not running then return end t += dt * 3 local alpha = 0.15 + (math.sin(t) + 1) * 0.15 for _, bar in ipairs(bars) do bar.BackgroundTransparency = alpha end
    end)
    table.insert(control._connections, connection)
    control._getter = function() return running end control._setter = function(value) running = value == true for _, bar in ipairs(bars) do bar.Visible = running end return running end
    function control:Start() return self:Set(true) end function control:Stop() return self:Set(false) end
    return app:_Register(control)
end

----------------------------------------------------------------
-- COUNTDOWN
----------------------------------------------------------------

function Section:AddCountdown(configuration)
    configuration = configuration or {}
    local app = self.App
    local duration = tonumber(configuration.Seconds or configuration.Default) or 60
    local remaining = duration
    local running = configuration.AutoStart == true
    local row = self:_Row(configuration.Height or 50)
    local label = valueLabel(row, app, configuration.Text or "Countdown", UDim2.new(), UDim2.new(1, -120, 1, 0))
    local display = valueLabel(row, app, "", UDim2.new(1, -110, 0, 0), UDim2.fromOffset(110, 50)) display.TextXAlignment = Enum.TextXAlignment.Right display.TextSize = 20 display.Font = app.Config.Fonts.Bold display.TextColor3 = app.Config.Colors.Accent
    local id = app:_MakeId("Countdown", configuration.Id)
    local control = self:_Control(id, "Countdown", configuration.Text or "Countdown", row, configuration)
    local accumulator = 0
    local function render() local total = math.max(0, math.ceil(remaining)) local m = math.floor(total / 60) local s = total % 60 display.Text = string.format("%02d:%02d", m, s) end
    local connection = RunService.Heartbeat:Connect(function(dt)
        if not running or remaining <= 0 then return end remaining -= dt
        if remaining <= 0 then remaining = 0 running = false render() self:_Emit(control, "CountdownFinished", 0, nil) app:_Callback(configuration.Callback, control) else render() end
    end)
    table.insert(control._connections, connection)
    control._getter = function() return remaining end
    control._setter = function(value) remaining = math.max(0, tonumber(value) or remaining) render() return remaining end
    function control:Start(seconds) if seconds then remaining = tonumber(seconds) or remaining end running = true render() return self end
    function control:Pause() running = false return self end
    function control:Reset(seconds) remaining = tonumber(seconds) or duration running = false render() return self end
    function control:IsRunning() return running end
    control._textSetter = function(text) label.Text = text end render()
    return app:_Register(control)
end

----------------------------------------------------------------
-- CLOCK
----------------------------------------------------------------

function Section:AddClock(configuration)
    configuration = configuration or {}
    local app = self.App
    local row = self:_Row(configuration.Height or 42)
    local label = valueLabel(row, app, configuration.Text or "Clock", UDim2.new(), UDim2.new(1, -150, 1, 0))
    local display = valueLabel(row, app, "", UDim2.new(1, -145, 0, 0), UDim2.fromOffset(145, 42)) display.TextXAlignment = Enum.TextXAlignment.Right display.Font = app.Config.Fonts.Mono display.TextColor3 = app.Config.Colors.Accent
    local id = app:_MakeId("Clock", configuration.Id)
    local control = self:_Control(id, "Clock", configuration.Text or "Clock", row, configuration)
    local running = true
    local elapsed = 0
    local function update() display.Text = os.date(configuration.Format or "%H:%M:%S") end
    local connection = RunService.Heartbeat:Connect(function(dt) if running then elapsed += dt if elapsed >= (configuration.Interval or 0.25) then elapsed = 0 update() end end end)
    table.insert(control._connections, connection)
    control._getter = function() return display.Text end
    control._setter = function(value) running = value ~= false return running end
    control._textSetter = function(text) label.Text = text end
    function control:Pause() running = false return self end function control:Resume() running = true return self end
    update()
    return app:_Register(control)
end

----------------------------------------------------------------
-- FPS METER
----------------------------------------------------------------

function Section:AddFPSMeter(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = 0
    local row = self:_Row(configuration.Height or 36)
    local label = valueLabel(row, app, configuration.Text or "FPS", UDim2.new(), UDim2.new(1, -100, 1, 0))
    local display = valueLabel(row, app, "0 FPS", UDim2.new(1, -95, 0, 0), UDim2.fromOffset(95, 36)) display.TextXAlignment = Enum.TextXAlignment.Right display.TextColor3 = app.Config.Colors.Success display.Font = app.Config.Fonts.Mono
    local id = app:_MakeId("FPSMeter", configuration.Id)
    local control = self:_Control(id, "FPSMeter", configuration.Text or "FPS", row, configuration)
    local frames, time = 0, 0
    local connection = RunService.RenderStepped:Connect(function(dt)
        frames += 1 time += dt
        if time >= (configuration.Interval or 0.5) then value = math.round(frames / time) frames, time = 0, 0 display.Text = tostring(value) .. " FPS" if value < 30 then display.TextColor3 = app.Config.Colors.Danger elseif value < 50 then display.TextColor3 = app.Config.Colors.Warning else display.TextColor3 = app.Config.Colors.Success end end
    end)
    table.insert(control._connections, connection)
    control._getter = function() return value end control._textSetter = function(text) label.Text = text end
    return app:_Register(control)
end

----------------------------------------------------------------
-- MEMORY METER
----------------------------------------------------------------

function Section:AddMemoryMeter(configuration)
    configuration = configuration or {}
    local app = self.App
    local value = 0
    local row = self:_Row(configuration.Height or 36)
    local label = valueLabel(row, app, configuration.Text or "Lua Memory", UDim2.new(), UDim2.new(1, -130, 1, 0))
    local display = valueLabel(row, app, "", UDim2.new(1, -125, 0, 0), UDim2.fromOffset(125, 36)) display.TextXAlignment = Enum.TextXAlignment.Right display.Font = app.Config.Fonts.Mono display.TextColor3 = app.Config.Colors.Info
    local id = app:_MakeId("MemoryMeter", configuration.Id)
    local control = self:_Control(id, "MemoryMeter", configuration.Text or "Memory", row, configuration)
    local elapsed = 0
    local connection = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt if elapsed >= (configuration.Interval or 1) then elapsed = 0 value = gcinfo() / 1024 display.Text = string.format("%.1f MB", value) end
    end)
    table.insert(control._connections, connection)
    control._getter = function() return value end control._textSetter = function(text) label.Text = text end
    return app:_Register(control)
end


----------------------------------------------------------------
-- VIEWPORT MODEL
----------------------------------------------------------------

function Section:AddViewportModel(configuration)
    configuration = configuration or {}
    local app = self.App
    local source = configuration.Model
    local row = self:_Row(configuration.Height or 220)
    local viewport = create("ViewportFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.BackgroundColor or app.Config.Colors.Background2, BorderSizePixel = 0, Ambient = configuration.Ambient or Color3.fromRGB(180, 180, 180), LightColor = configuration.LightColor or Color3.new(1, 1, 1), LightDirection = configuration.LightDirection or Vector3.new(-1, -1, -1)})
    corner(viewport, app.Config.Radius.Control)
    local camera = Instance.new("Camera") camera.Parent = viewport viewport.CurrentCamera = camera
    local world = Instance.new("WorldModel") world.Parent = viewport
    local id = app:_MakeId("ViewportModel", configuration.Id)
    local control = self:_Control(id, "ViewportModel", configuration.Text or "Viewport", row, configuration)
    local clone
    local rotation = 0
    local autoRotate = configuration.AutoRotate == true
    local function clear() if clone then clone:Destroy() clone = nil end end
    local function frameModel()
        if not clone then return end
        local cf, size
        if clone:IsA("Model") then cf, size = clone:GetBoundingBox() elseif clone:IsA("BasePart") then cf, size = clone.CFrame, clone.Size else return end
        local maxSize = math.max(size.X, size.Y, size.Z)
        local distance = math.max(3, maxSize * (configuration.Zoom or 1.8))
        camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y * 0.15, distance), cf.Position)
    end
    local function set(newSource, silent)
        clear() source = newSource
        if typeof(source) == "Instance" then
            local ok, result = pcall(function() return source:Clone() end)
            if ok and result then clone = result clone.Parent = world frameModel() end
        end
        if not silent then self:_Emit(control, "ViewportModelChanged", source, nil) app:_Callback(configuration.Callback, source, control) end
        return source
    end
    local connection = RunService.RenderStepped:Connect(function(dt)
        if autoRotate and clone then
            rotation += dt * (configuration.RotationSpeed or 35)
            if clone:IsA("Model") then local pivot = clone:GetPivot() clone:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.rad(rotation), 0)) elseif clone:IsA("BasePart") then clone.CFrame = CFrame.new(clone.Position) * CFrame.Angles(0, math.rad(rotation), 0) end
        end
    end)
    table.insert(control._connections, connection)
    control._getter = function() return source end control._setter = set
    function control:SetAutoRotate(state) autoRotate = state == true return self end
    function control:Frame() frameModel() return self end
    function control:GetClone() return clone end
    set(source, true)
    return app:_Register(control)
end

----------------------------------------------------------------
-- AVATAR VIEWPORT
----------------------------------------------------------------

function Section:AddAvatarViewport(configuration)
    configuration = configuration or {}
    local app = self.App
    local player = configuration.Player or Players.LocalPlayer
    local row = self:_Row(configuration.Height or 240)
    local viewport = create("ViewportFrame", {Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = configuration.BackgroundColor or app.Config.Colors.Background2, BorderSizePixel = 0, Ambient = Color3.fromRGB(190,190,190), LightColor = Color3.new(1,1,1), LightDirection = Vector3.new(-1,-1,-1)}) corner(viewport, app.Config.Radius.Control)
    local world = Instance.new("WorldModel") world.Parent = viewport
    local camera = Instance.new("Camera") camera.Parent = viewport viewport.CurrentCamera = camera
    local id = app:_MakeId("AvatarViewport", configuration.Id)
    local control = self:_Control(id, "AvatarViewport", configuration.Text or "Avatar", row, configuration)
    local model
    local function set(target, silent)
        if typeof(target) == "number" then
            for _, p in ipairs(Players:GetPlayers()) do if p.UserId == target then target = p break end end
        end
        if not (typeof(target) == "Instance" and target:IsA("Player")) then return player end
        player = target
        if model then model:Destroy() model = nil end
        task.spawn(function()
            local ok, created = pcall(function() return Players:CreateHumanoidModelFromUserId(player.UserId) end)
            if ok and created and world.Parent then
                model = created model.Parent = world
                local cf, size = model:GetBoundingBox()
                camera.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y * 0.1, math.max(4, size.Magnitude * 0.75)), cf.Position + Vector3.new(0, size.Y * 0.05, 0))
            end
        end)
        if not silent then self:_Emit(control, "AvatarChanged", player, nil) app:_Callback(configuration.Callback, player, control) end
        return player
    end
    control._getter = function() return player end control._setter = set
    set(player, true)
    return app:_Register(control)
end

----------------------------------------------------------------
-- COLOR SWATCHES
----------------------------------------------------------------

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

----------------------------------------------------------------
-- FONT SELECTOR
----------------------------------------------------------------

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

----------------------------------------------------------------
-- ENUM SELECTOR
----------------------------------------------------------------

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

----------------------------------------------------------------
-- UDIM INPUT
----------------------------------------------------------------

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

----------------------------------------------------------------
-- UDIM2 INPUT
----------------------------------------------------------------

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
    if configuration.Build then local ok,res=pcall(configuration.Build,container,c,app,self) if ok then c.BuildResult=res else warn("[UIBuilderV6 Custom]",res) end end
    if configuration.Render then app:_Callback(configuration.Render,container,state,c,self) end
    return app:_Register(c)
end
function Section:AddRawGui(configuration) configuration=configuration or {} configuration.Kind=configuration.Kind or "RawGui" return self:AddCustom(configuration) end

function Library:RegisterTheme(name,theme) self._themes=self._themes or {} self._themes[tostring(name)]=deepCopy(theme or {}) return self end
function Library:GetTheme(name) self._themes=self._themes or {} local t=self._themes[tostring(name)] return t and deepCopy(t) or nil end
function Library:GetThemes() self._themes=self._themes or {} local r={} for n in pairs(self._themes) do table.insert(r,n) end table.sort(r) return r end
function Library:ApplyTheme(nameOrTheme)
    local t=type(nameOrTheme)=="string" and self:GetTheme(nameOrTheme) or nameOrTheme if type(t)~="table" then return false end
    self.Config=deepMerge(self.Config,t) local c=self.Config.Colors self.Main.BackgroundColor3=c.Background self.Topbar.BackgroundColor3=c.Background2 self.Sidebar.BackgroundColor3=c.Sidebar self.Statusbar.BackgroundColor3=c.Background2 self.TitleLabel.TextColor3=c.Text self.SubtitleLabel.TextColor3=c.Text2 self.StatusLabel.TextColor3=c.Text2 self:_Emit("ThemeApplied","Theme",nameOrTheme) return true
end
function Library:SetAccent(color) if typeof(color)=="Color3" then self.Config.Colors.Accent=color self:_Emit("AccentChanged","Theme",color) end return self end
function Library:SetUIScale(scale) scale=clamp(tonumber(scale) or 1,.5,2.5) local s=self.Main:FindFirstChild("UIBuilderV6Scale") if not s then s=Instance.new("UIScale") s.Name="UIBuilderV6Scale" s.Parent=self.Main end s.Scale=scale self._uiScale=scale return self end
function Library:GetUIScale() return self._uiScale or 1 end
function Library:SetReducedMotion(v) self._reducedMotion=v==true self.Config.Animation.Enabled=not self._reducedMotion return self end
function Library:GetReducedMotion() return self._reducedMotion==true end
function Library:SetTextScale(scale) scale=clamp(tonumber(scale) or 1,.6,2) for _,o in ipairs(self.Gui:GetDescendants()) do if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then local b=o:GetAttribute("UIB6BaseText") or o.TextSize o:SetAttribute("UIB6BaseText",b) o.TextSize=math.max(8,math.floor(b*scale+.5)) end end self._textScale=scale return self end
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

----------------------------------------------------------------
-- V5 COMPOSITE CONTROLS
----------------------------------------------------------------

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
function Section:AddFilterableTable(configuration)configuration=configuration or {}local source=configuration.Rows or {}local c=self:AddTable(configuration)c.Kind="FilterableTable"c.SourceRows=source function c:Filter(q)q=string.lower(tostring(q or ""))local r={}for _,row in ipairs(self.SourceRows)do if q==""or string.find(string.lower(tostring(row)),q,1,true)or string.find(string.lower(v5format and v5format(row)or ""),q,1,true)then table.insert(r,row)end end self:SetRows(r)return self end return c end
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


----------------------------------------------------------------
-- V5 SPECIALIZED DEFAULT BEHAVIORS
----------------------------------------------------------------

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

----------------------------------------------------------------
-- V5 FEATURE REGISTRY (100+ named built-ins)
----------------------------------------------------------------

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


----------------------------------------------------------------
-- V6: WINDOW MANAGEMENT CONTROLS
----------------------------------------------------------------

function Section:AddMinimizeDockSelector(configuration)
    configuration = configuration or {}
    local app = self.App
    local userCallback = configuration.Callback
    local options = configuration.Options or app:GetMinimizeDocks()
    local defaultDock = configuration.Default or app:GetMinimizeDock()
    local cfg = deepMerge(configuration, {
        Text = configuration.Text or "Minimized Window Location",
        Options = options,
        Default = defaultDock,
    })
    cfg.Callback = function(value, control)
        app:SetMinimizeDock(value, true)
        if type(userCallback) == "function" then app:_Callback(userCallback, value, control) end
    end
    return self:AddDropdown(cfg)
end

function Section:AddWindowLockToggle(configuration)
    configuration = configuration or {}
    local app = self.App
    local userCallback = configuration.Callback
    local cfg = deepMerge(configuration, {
        Text = configuration.Text or "Lock Window Position",
        Default = configuration.Default ~= nil and configuration.Default or app:IsWindowLocked(),
    })
    cfg.Callback = function(value, control)
        app:SetWindowLocked(value)
        if type(userCallback) == "function" then app:_Callback(userCallback, value, control) end
    end
    return self:AddToggle(cfg)
end

function Section:AddAlwaysOnTopToggle(configuration)
    configuration = configuration or {}
    local app = self.App
    local userCallback = configuration.Callback
    local cfg = deepMerge(configuration, {
        Text = configuration.Text or "Always On Top",
        Default = configuration.Default ~= nil and configuration.Default or app:IsAlwaysOnTop(),
    })
    cfg.Callback = function(value, control)
        app:SetAlwaysOnTop(value)
        if type(userCallback) == "function" then app:_Callback(userCallback, value, control) end
    end
    return self:AddToggle(cfg)
end

function Section:AddRestoreOnShowToggle(configuration)
    configuration = configuration or {}
    local app = self.App
    local userCallback = configuration.Callback
    local cfg = deepMerge(configuration, {
        Text = configuration.Text or "Restore When Shown",
        Default = configuration.Default ~= nil and configuration.Default or app.Config.Behavior.RestoreOnShow,
    })
    cfg.Callback = function(value, control)
        app.Config.Behavior.RestoreOnShow = value == true
        if type(userCallback) == "function" then app:_Callback(userCallback, value, control) end
    end
    return self:AddToggle(cfg)
end

Section.AddMinimizeLocation = Section.AddMinimizeDockSelector
Section.AddDockSelector = Section.AddMinimizeDockSelector

----------------------------------------------------------------
-- V6: RUNTIME API / FEATURE INTROSPECTION
----------------------------------------------------------------

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
Section.AddLanguage = Section.AddLanguageSelector
Section.AddLanguageSelect = Section.AddLanguageSelector
Section.AddInfo = Section.AddCallout
Section.AddBadge = Section.AddStatus
Section.AddTags = Section.AddTagInput
Section.AddStars = Section.AddRating
Section.AddGauge = Section.AddMeter
Section.AddDataTable = Section.AddTable
Section.AddTree = Section.AddTreeView
Section.AddConsole = Section.AddLogConsole
Section.AddCommandInput = Section.AddCommandBox
Section.AddSpinner = Section.AddLoadingSpinner
Section.AddAvatar = Section.AddAvatarViewport
Section.AddSwatches = Section.AddColorSwatches
Section.AddVector2 = Section.AddVector2Input
Section.AddVector3 = Section.AddVector3Input
Section.AddRGB = Section.AddRGBInput
Section.AddProperties = Section.AddPropertyGrid
Section.AddAccordion = Section.AddDisclosure
Section.AddSubTabs = Section.AddMiniTabs

setmetatable(Library, {
    __call = function(_, configuration)
        return Library.new(configuration)
    end,
})

return Library
