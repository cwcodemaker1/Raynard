-- Raynard fragment: 60_controls_data.luau
-- Loaded by parser.luau; do not execute this fragment alone.

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


