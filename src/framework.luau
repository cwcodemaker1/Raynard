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
