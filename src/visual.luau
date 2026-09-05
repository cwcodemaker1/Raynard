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

function Section:AddLineChart(configuration)
    configuration = configuration or {}
    configuration.Height = configuration.Height or 170
    configuration.Thickness = configuration.Thickness or 2
    local control = self:AddSparkline(configuration)
    control.Kind = "LineChart"
    return control
end

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
