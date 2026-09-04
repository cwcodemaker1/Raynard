-- Raynard fragment: 00_core.luau
-- Loaded by parser.luau; do not execute this fragment alone.

-- Raynard modular source
-- Reusable Roblox/Luau client UI framework.
-- Put this ModuleScript in ReplicatedStorage and require it from a LocalScript.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Library = {}
Library.__index = Library
Library.Version = "Raynard Modular 1"

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
                if not ok then warn("[Raynard Signal]", err) end
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
    Title = "UI Builder",
    Subtitle = "Client Interface",
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

