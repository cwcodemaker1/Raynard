-- Raynard fragment: 30_controls_player_color.luau
-- Loaded by parser.luau; do not execute this fragment alone.

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

