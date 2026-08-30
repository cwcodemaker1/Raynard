# Raynard

A reusable Roblox/Luau client UI framework

## Table of contents

- [Installation](#1-installation)
- [Your first UI](#2-your-first-ui)
- [The mental model](#3-the-mental-model)
- [Window and theme configuration](#4-window-and-theme-configuration)
- [Control handles](#5-control-handles)
- [Callbacks and centralized feedback](#6-callbacks-and-centralized-feedback)
- [State, presets, undo/redo, and control IDs](#7-state-presets-undoredo-and-control-ids)
- [Custom controls and reusable components](#8-custom-controls-and-reusable-components)
- [Framework API reference](#9-framework-api-reference)
- [Tab and section lifecycle API](#10-tab-and-section-lifecycle-api)
- [Complete feature reference](#11-complete-feature-reference)
- [Feedback event index](#12-feedback-event-index)
- [Common recipes](#13-common-recipes)
- [Troubleshooting](#14-troubleshooting)
- [Beginner glossary](#15-beginner-glossary)

> **Note:** Raynard exposes a very large number of callable `Section:Add...` feature names. Some are native controls, some are wrappers around another control, and some are aliases. The feature reference identifies those differences instead of pretending every name is a completely separate renderer.

## 1. Installation

Raynard is client-side. The reusable ModuleScript belongs in `ReplicatedStorage`. The LocalScript that calls it belongs somewhere Roblox runs LocalScripts, such as `StarterPlayerScripts`.

```
ReplicatedStorage
└── Raynard                 [ModuleScript]

StarterPlayer
└── StarterPlayerScripts
    └── MyInterface            [LocalScript]
```

**Why?** A ModuleScript does not run by itself. Your LocalScript uses `require()` to load the module and then creates the interface.

## 2. Your first UI

This is the smallest useful example. Copy it into a LocalScript after placing the module as shown above.

```
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Raynard = require(ReplicatedStorage:WaitForChild("Raynard"))

local UI = Raynard({
    Title = "My Interface",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = UI:AddTab("Main")
local Settings = Main:AddSection("Settings")

Settings:AddToggle({
    Id = "Enabled",
    Text = "Enabled",
    Default = true,
})

Settings:AddSlider({
    Id = "Speed",
    Text = "Speed",
    Min = 0,
    Max = 100,
    Default = 25,
})

Settings:AddButton({
    Text = "Print values",
    Callback = function()
        print(UI:GetValue("Enabled"))
        print(UI:GetValue("Speed"))
    end,
})
```

## 3. The mental model

UI / Window

Tab

Section

Control

You create one **UI**. The UI contains **tabs**. Tabs contain **sections**. Sections create **controls**. Most controls return a handle you can save in a variable and manipulate later.

```
local UI = Raynard({Title = "Example"})
local Main = UI:AddTab("Main")
local Settings = Main:AddSection("Settings")
local Speed = Settings:AddSlider({Id = "Speed", Min = 0, Max = 100})
```

## 4. Window and theme configuration

The constructor accepts a nested configuration table. Raynard deep-merges your settings into its defaults, so you only need to specify values you actually want to change.

```
local UI = Raynard({
    Name = "MyUI",
    Title = "My Interface",
    Subtitle = "Client Interface",
    ToggleKey = Enum.KeyCode.RightShift,
    DisplayOrder = 100,

    Window = {
        Size = Vector2.new(780, 540),
        MinSize = Vector2.new(520, 340),
        MaxSize = Vector2.new(1500, 950),
        Draggable = true,
        Resizable = true,
        Minimizable = true,
        Maximizable = true,
        Closable = true,
        StartVisible = true,
    },

    Colors = {
        Background = Color3.fromRGB(16, 16, 16),
        Accent = Color3.fromRGB(143, 180, 255),
        Text = Color3.fromRGB(235, 235, 240),
    },

    Behavior = {
        Tooltips = true,
        Notifications = true,
        AutoSelectFirstTab = true,
        IgnoreToggleWhileTyping = true,
    },
})
```

### Window

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `Size` | Vector2 | `780 × 540` | Starting window size. |
| `MinSize` | Vector2 | `520 × 340` | Smallest resize size. |
| `MaxSize` | Vector2 | `1500 × 950` | Largest resize size. |
| `Position` | UDim2 | `center` | Starting window position. |
| `Draggable` | boolean | `true` | Whether the title bar can drag the window. |
| `Resizable` | boolean | `true` | Whether the lower-right resize grip is enabled. |
| `Minimizable` | boolean | `true` | Whether the minimize button is available. |
| `Maximizable` | boolean | `true` | Whether the maximize button is available. |
| `Closable` | boolean | `true` | Whether the close button is available. |
| `StartVisible` | boolean | `true` | Whether the GUI starts visible. |

### Behavior

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `CloseDestroys` | boolean | `false` | If true, close destroys the UI instead of only hiding it. |
| `Hover` | boolean | `true` | Enables hover visual effects. |
| `Tooltips` | boolean | `true` | Enables configured tooltips. |
| `Notifications` | boolean | `true` | Enables toast notifications. |
| `AutoSelectFirstTab` | boolean | `true` | Automatically opens the first tab. |
| `IgnoreToggleWhileTyping` | boolean | `true` | Prevents the global UI toggle key from firing while typing in a TextBox. |

### Layout

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `TopbarHeight` | number | `50` | Height of the title bar. |
| `StatusbarHeight` | number | `24` | Height of the bottom status bar. |
| `SidebarWidth` | number | `170` | Width of the tab sidebar. |
| `PagePadding` | number | `10` | Padding around each tab page. |
| `SectionPadding` | number | `10` | Padding inside sections. |
| `SectionSpacing` | number | `10` | Space between sections. |
| `ControlSpacing` | number | `7` | Space between controls. |
| `TabHeight` | number | `38` | Height of each sidebar tab. |
| `ButtonHeight` | number | `38` | Default button height. |
| `ToggleHeight` | number | `38` | Default toggle height. |
| `SliderHeight` | number | `62` | Default slider height. |
| `TextboxHeight` | number | `64` | Default textbox height. |
| `DropdownHeight` | number | `64` | Default dropdown height. |
| `ProgressHeight` | number | `52` | Default progress height. |
| `KeybindHeight` | number | `38` | Default keybind height. |
| `PlayerCardHeight` | number | `72` | Default player card height. |
| `ScrollbarThickness` | number | `4` | Default scrollbar thickness. |
| `ResizeGrip` | number | `16` | Resize handle size. |

### Colors

All of these are Color3 values. Override only the colors you want to change.

`Background``Background2``Sidebar``Section``Control``ControlHover``ControlPressed``ControlDisabled``Border``Text``Text2``TextDisabled``Accent``Accent2``AccentText``Success``Warning``Danger``Info``Scrollbar``Overlay``Tooltip`

### Fonts

Font slots used by titles, tabs, sections, controls, and code/monospace text.

`Title``Subtitle``Tab``Section``Normal``Medium``Bold``Mono`

### TextSizes

Default text sizes for common interface roles.

`Title``Subtitle``Tab``Section``Control``Secondary``Tiny``Status`

### Radius

Corner-radius values in pixels.

`Window``Section``Control``Button``Avatar``Modal``Tooltip`

### Stroke

`Stroke.Enabled`, `Stroke.Thickness`, and `Stroke.Transparency` control common UI outlines.

### Animation

`Animation.Enabled`, `Fast`, `Normal`, `EasingStyle`, and `EasingDirection` control built-in transitions.

## 5. Control handles

Interactive controls usually return a **Control handle**. Saving it is useful when you need to change that control later.

```
local Speed = Settings:AddSlider({
    Id = "Speed",
    Text = "Speed",
    Min = 0,
    Max = 100,
    Default = 25,
})

print(Speed:Get())
Speed:Set(50)
Speed:Disable()
Speed:Enable()
Speed:Hide()
Speed:Show()
Speed:SetText("Movement speed")
```

| Method | What it does |
| --- | --- |
| `Control:AddTag(t)` | Adds a custom tag to a control handle. |
| `Control:Destroy()` | Removes this control and cleans up its connections. |
| `Control:Disable()` | Convenience method for SetDisabled(true). |
| `Control:Enable()` | Convenience method for SetDisabled(false). |
| `Control:Flash(color,duration)` | Briefly flashes the control with a specified color. |
| `Control:Get()` | Returns the current value for this control. |
| `Control:GetMetadata(k)` | Reads custom metadata from a control handle. |
| `Control:GetTags()` | Returns all custom tags for the control. |
| `Control:HasTag(t)` | Checks whether a control has a tag. |
| `Control:Hide()` | Convenience method for SetVisible(false). |
| `Control:IsDisabled()` | Returns whether the control is disabled. |
| `Control:RemoveTag(t)` | Removes a custom tag from a control handle. |
| `Control:Set(value, silent)` | Changes the control value. |
| `Control:SetDisabled(disabled)` | Enables or disables interaction with this control. |
| `Control:SetHeight(height)` | Changes the control row height. |
| `Control:SetMetadata(k,v)` | Stores custom metadata on a control handle. |
| `Control:SetOrder(order)` | Changes the control layout order. |
| `Control:SetText(text)` | Changes the label/text associated with the control. |
| `Control:SetTooltip(text)` | Changes the tooltip text. |
| `Control:SetVisible(visible)` | Shows or hides this control. |
| `Control:SetZIndex(z)` | Changes ZIndex for the control UI where supported. |
| `Control:Show()` | Convenience method for SetVisible(true). |

Not every specialized control has the exact same meaningful value type. For example, a slider returns a number, a toggle returns a boolean, a player picker returns a Player, and a language selector can return the selected language entry/value. Use the individual feature card for its configuration and underlying implementation.

## 6. Callbacks and centralized feedback

You can react to a control in two ways. The easiest is its own `Callback`. For logging, analytics, debugging, or one central dispatcher, subscribe to `UI.Feedback`.

```
UI.Feedback:Connect(function(packet)
    print(packet.Type)   -- e.g. "SliderChanged"
    print(packet.Id)     -- the control Id
    print(packet.Value)  -- the new value
    print(packet.Window) -- window title
    print(packet.Time)   -- os.clock() timestamp
end)
```

The standard feedback packet contains `Type`, `Id`, `Value`, `Window`, and `Time`. Controls may add extra fields.

## 7. State, presets, undo/redo, and control IDs

**Ids matter.** An Id is the stable name used by `GetValue`, `SetValue`, export/import, presets, groups, bindings, and watchers.

```
local saved = UI:ExportState()

-- Change controls normally...
UI:SetValue("Speed", 90)
UI:SetValue("Enabled", false)

-- Restore the saved values later.
UI:ImportState(saved)
```

### Named presets

```
UI:RegisterPreset("Fast", {
    Speed = 90,
    Enabled = true,
})

UI:ApplyPreset("Fast")
```

### Undo / redo

```
UI:Snapshot("Before changes")
UI:SetValue("Speed", 100)

UI:Undo()
UI:Redo()
```

## 8. Custom controls and reusable components

The built-in catalog is large, but `AddCustom` is the escape hatch for anything Roblox GUI can render. `RegisterComponent` lets you package that custom UI as a reusable named component.

```
UI:RegisterComponent("Counter", function(section, config)
    return section:AddCustom({
        Id = config.Id,
        Text = config.Text or "Counter",
        Default = config.Default or 0,
        Height = 60,

        Build = function(frame, control, app)
            local button = control:Create("TextButton", {
                Parent = frame,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = app.Config.Colors.Control,
                TextColor3 = app.Config.Colors.Text,
                Text = "Count: 0",
            })

            control:_Connect(button.Activated, function()
                control:Set(control:Get() + 1)
            end)

            control.Render = function(value)
                button.Text = "Count: " .. tostring(value)
            end
        end,
    })
end)

local Counter = Settings:AddComponent("Counter", {
    Id = "Counter",
    Default = 5,
})
```

**Use custom components when:** a built-in feature is close but not exact, you need a proprietary layout, or you want a reusable control unique to your game.

## 9. Framework API reference

These methods operate on the whole Raynard instance.

| Method | Meaning |
| --- | --- |
| `UI:AddDependency(source,target,configuration)` | Adds a dependency rule between controls. |
| `UI:AddGlobalKeybind(configuration)` | Registers a keybind that is not tied to one section control. |
| `UI:AddTab(configuration)` | Creates a top-level sidebar tab. |
| `UI:ApplyPreset(name, silent)` | Applies a previously registered preset. |
| `UI:ApplyTheme(nameOrTheme)` | Applies a registered theme or a theme table to the UI. |
| `UI:BindControls(source,target,transform)` | Links one control to another, optionally transforming the value. |
| `UI:Center()` | Moves the window back to the center of the screen. |
| `UI:ClearHistory()` | Clears stored undo/redo history. |
| `UI:Confirm(configuration)` | Shows a confirmation modal and reports true/false. |
| `UI:CreateGroup(name,ids)` | Creates a named group of control IDs for bulk management. |
| `UI:Destroy()` | Disconnects Raynard connections and destroys the generated GUI. |
| `UI:ExportState()` | Returns a table containing the current values of controls that expose a value. |
| `UI:FindControls(query)` | Searches registered controls. |
| `UI:FocusControl(id)` | Attempts to focus or navigate to a control by Id. |
| `UI:GetAPICounts()` | Returns counts for feature, framework, control, tab, and section APIs. |
| `UI:GetCommands()` | Returns all registered commands. |
| `UI:GetComponents()` | Returns registered custom component factories. |
| `UI:GetControl(id)` | Returns a control handle by its Id. |
| `UI:GetControlCatalog()` | Returns public methods available on control handles. |
| `UI:GetFeatureCatalog()` | Returns every callable Section:Add... feature name. |
| `UI:GetFeatureInfo(name)` | Returns metadata describing one feature, including whether it is dynamic and what implementation it targets. |
| `UI:GetFrameworkCatalog()` | Returns the public Library/UI methods. |
| `UI:GetGroup(name)` | Returns a named control group. |
| `UI:GetHistory()` | Returns history information. |
| `UI:GetLocale()` | Returns the active locale code. |
| `UI:GetPreset(name)` | Gets one named preset. |
| `UI:GetPresets()` | Returns the registered presets. |
| `UI:GetReducedMotion()` | Returns reduced-motion state. |
| `UI:GetSection(idOrName)` | Finds an existing section by name or Id. |
| `UI:GetSectionCatalog()` | Returns public methods available on sections. |
| `UI:GetStats()` | Returns summary information about the current Raynard instance. |
| `UI:GetTab(idOrName)` | Finds an existing tab by name or Id. |
| `UI:GetTabCatalog()` | Returns public methods available on tab handles. |
| `UI:GetTextScale()` | Returns global text scale. |
| `UI:GetTheme(name)` | Returns a named theme. |
| `UI:GetThemes()` | Returns all registered themes. |
| `UI:GetUIScale()` | Returns current overall UI scale. |
| `UI:GetValue(id)` | Reads the current value of a control by Id. |
| `UI:GetViewportSize()` | Returns the current viewport size. |
| `UI:ImportState(state, silent)` | Applies a previously exported state table back to matching control IDs. |
| `UI:IsVisible()` | Returns whether the complete UI is currently visible. |
| `Raynard.new(configuration)` | Creates a new Raynard window from a configuration table. |
| `UI:Notify(configuration)` | Shows a temporary toast notification. |
| `UI:Prompt(configuration)` | Shows a text-entry modal and reports the submitted text. |
| `UI:Redo()` | Reapplies a state that was undone. |
| `UI:RegisterCommand(name, callback, description)` | Registers a named command that can later be executed from code or command controls. |
| `UI:RegisterComponent(name,factory)` | Registers a reusable custom component factory. |
| `UI:RegisterLocale(code,data)` | Registers a table of translated strings for a locale code. |
| `UI:RegisterPreset(name, state)` | Stores a named control-state preset. |
| `UI:RegisterTheme(name,theme)` | Stores a named theme table. |
| `UI:ResetState(silent)` | Restores the configured default state. |
| `UI:RunCommand(name, ...)` | Runs a registered command by name. |
| `UI:SelectTab(target)` | Selects a tab by handle, name, or identifier. |
| `UI:SetAccent(color)` | Changes the UI accent color. |
| `UI:SetAllDisabled(disabled, predicate)` | Enables or disables many controls at once, optionally using a predicate. |
| `UI:SetAllVisible(visible, predicate)` | Shows or hides many controls at once, optionally using a predicate. |
| `UI:SetDefaultState(state)` | Sets the state used by ResetState(). |
| `UI:SetLocale(code)` | Changes the active locale. |
| `UI:SetMaximized(maximized)` | Maximizes or restores the window. |
| `UI:SetMinimized(minimized)` | Minimizes or restores the body of the window. |
| `UI:SetPosition(position)` | Moves the main window to a new UDim2 position. |
| `UI:SetReducedMotion(v)` | Turns reduced-motion behavior on or off. |
| `UI:SetSidebarVisible(visible)` | Shows or hides the left tab sidebar. |
| `UI:SetSidebarWidth(width)` | Changes the sidebar width. |
| `UI:SetSize(size)` | Changes the main window size. |
| `UI:SetStatus(text, color)` | Changes the text shown in the bottom status bar. |
| `UI:SetSubtitle(text)` | Changes the smaller subtitle under the title. |
| `UI:SetTextScale(scale)` | Changes global text scaling. |
| `UI:SetTitle(text)` | Changes the window title text. |
| `UI:SetUIScale(scale)` | Changes overall UI scale. |
| `UI:SetValue(id, value, silent)` | Changes a control value by Id. Use silent=true to suppress normal change callbacks where supported. |
| `UI:SetVisible(visible)` | Shows or hides the complete ScreenGui. |
| `UI:Snapshot(name)` | Stores the current state in the undo/history system. |
| `UI:Toggle()` | Toggles the complete UI between visible and hidden. |
| `UI:Translate(key,fallback)` | Looks up a translated string by key. |
| `UI:UnbindControls(source,target)` | Removes a control binding. |
| `UI:Undo()` | Restores the previous state snapshot. |
| `UI:UnregisterComponent(name)` | Removes a registered custom component factory. |
| `UI:WatchControl(id,fn)` | Runs a function when a particular control changes. |

## 10. Tab and section lifecycle API

### Tabs

| Method | Meaning |
| --- | --- |
| `Tab:AddSection(configuration)` | Adds section to this tab. |
| `Tab:Select()` | Runs the select operation on this tab. |
| `Tab:SetName(name)` | Changes name for this tab. |
| `Tab:SetVisible(visible)` | Changes visible for this tab. |

### Sections

| Method | Meaning |
| --- | --- |
| `Section:SetCollapsed(collapsed)` | Changes collapsed for this section. |
| `Section:SetName(name)` | Changes name for this section. |
| `Section:SetVisible(visible)` | Changes visible for this section. |

All `Section:Add…` feature methods are documented in the searchable catalog below.

## 11. Complete feature reference

This section documents every feature name present in `Raynard_FeatureCatalog.txt`. **Native** means the method has its own direct implementation. **Wrapper** means it supplies a named convenience interface over another control. **Alias** means it is another public name for an existing method.

### AddAccentPicker

SelectorsWrapper→ AddColorPicker

[#](#feature-AddAccentPicker)

Lets the user choose a value using the accent picker interface. This is a convenience wrapper implemented through AddColorPicker.

Configuration, feedback & example

#### Resolved implementation

`AddColorPicker`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ColorChanged`

#### Example

```
local control = Section:AddAccentPicker({
    Id = "AccentPicker",
    Text = "Color",
    Default = Color3.fromRGB(143, 180, 255),
})
```

### AddAccordion

Layout & OtherAlias→ AddDisclosure

[#](#feature-AddAccordion)

Organizes UI content using a accordion layout/control. This is a convenience alias implemented through AddDisclosure.

Configuration, feedback & example

#### Resolved implementation

`AddDisclosure`

#### Common configuration keys

`Callback`, `Content`, `Description`, `Height`, `Id`, `Open`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`DisclosureChanged`

#### Example

```
local control = Section:AddAccordion({
    Id = "Accordion",
    Text = "Accordion",
})
```

### AddAccordionPanel

Layout & OtherWrapper→ AddDisclosure

[#](#feature-AddAccordionPanel)

Organizes UI content using a accordion panel layout/control. This is a convenience wrapper implemented through AddDisclosure.

Configuration, feedback & example

#### Resolved implementation

`AddDisclosure`

#### Common configuration keys

`Callback`, `Content`, `Description`, `Height`, `Id`, `Open`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`DisclosureChanged`

#### Example

```
local control = Section:AddAccordionPanel({
    Id = "AccordionPanel",
    Text = "Accordion Panel",
})
```

### AddActionButton

ActionsWrapper→ AddButton

[#](#feature-AddActionButton)

Creates a action button action that the user can press. This is a convenience wrapper implemented through AddButton.

Configuration, feedback & example

#### Resolved implementation

`AddButton`

#### Common configuration keys

`Callback`, `Color`, `Font`, `Height`, `HoverColor`, `Id`, `Radius`, `Stroke`, `Text`, `TextColor`, `TextSize`

#### Callback fields

`Callback`

#### Feedback events

`ButtonPressed`

#### Example

```
local control = Section:AddActionButton({
    Id = "ActionButton",
    Text = "Click me",
    Callback = function()
        print("Pressed")
    end,
})
```

### AddActionRow

ActionsNative

[#](#feature-AddActionRow)

Adds the Action Row UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddActionRow`

#### Common configuration keys

`ButtonText`, `ButtonWidth`, `Callback`, `Color`, `Description`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ActionPressed`

#### Example

```
local control = Section:AddActionRow({
    Id = "ActionRow",
    Text = "Action Row",
})
```

### AddAlert

VisualsWrapper→ AddCallout

[#](#feature-AddAlert)

Adds the Alert UI feature to a section. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddAlert({
    Id = "Alert",
    Text = "Alert",
})
```

### AddAlignmentSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddAlignmentSelector)

Lets the user choose a value using the alignment selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddAlignmentSelector({
    Id = "AlignmentSelector",
    Text = "Alignment Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddAngleInput

InputsWrapper→ AddNumberbox

[#](#feature-AddAngleInput)

Lets the user enter or edit a value using a angle input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddAngleInput({
    Id = "AngleInput",
    Text = "Angle Input",
})
```

### AddAreaChart

Charts & LiveWrapper→ AddLineChart

[#](#feature-AddAreaChart)

Displays data visually using a area chart. This is a convenience wrapper implemented through AddLineChart.

Configuration, feedback & example

#### Resolved implementation

`AddLineChart`

#### Common configuration keys

`Height`, `Thickness`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddAreaChart({
    Id = "AreaChart",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddArrayEditor

InputsNative→ AddEditableList

[#](#feature-AddArrayEditor)

Lets the user enter or edit a value using a array editor control.

Configuration, feedback & example

#### Resolved implementation

`AddEditableList`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddArrayEditor({
    Id = "ArrayEditor",
    Text = "Array Editor",
})
```

### AddAspectRatioSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddAspectRatioSelector)

Lets the user choose a value using the aspect ratio selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddAspectRatioSelector({
    Id = "AspectRatioSelector",
    Text = "Aspect Ratio Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddAssetIdInput

InputsWrapper→ AddNumberbox

[#](#feature-AddAssetIdInput)

Lets the user enter or edit a value using a asset id input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddAssetIdInput({
    Id = "AssetIdInput",
    Text = "Asset Id Input",
})
```

### AddAttributeEditor

InputsWrapper→ AddPropertyGrid

[#](#feature-AddAttributeEditor)

Lets the user enter or edit a value using a attribute editor control. This is a convenience wrapper implemented through AddPropertyGrid.

Configuration, feedback & example

#### Resolved implementation

`AddPropertyGrid`

#### Common configuration keys

`Default`, `Height`, `Id`, `Properties`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`PropertyChanged`

#### Example

```
local control = Section:AddAttributeEditor({
    Id = "AttributeEditor",
    Text = "Attribute Editor",
})
```

### AddAttributeViewer

DataWrapper→ AddPropertyGrid

[#](#feature-AddAttributeViewer)

Displays information using a attribute viewer. This is a convenience wrapper implemented through AddPropertyGrid.

Configuration, feedback & example

#### Resolved implementation

`AddPropertyGrid`

#### Common configuration keys

`Default`, `Height`, `Id`, `Properties`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`PropertyChanged`

#### Example

```
local control = Section:AddAttributeViewer({
    Id = "AttributeViewer",
    Text = "Attribute Viewer",
})
```

### AddAutoComplete

SelectorsAlias→ AddAutocomplete

[#](#feature-AddAutoComplete)

Adds the Auto Complete UI feature to a section. This is a convenience alias implemented through AddAutocomplete.

Configuration, feedback & example

#### Resolved implementation

`AddSearchDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`SearchDropdownChanged`

#### Example

```
local control = Section:AddAutoComplete({
    Id = "AutoComplete",
    Text = "Auto Complete",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddAutocomplete

SelectorsWrapper→ AddSearchDropdown

[#](#feature-AddAutocomplete)

Adds the Autocomplete UI feature to a section. This is a convenience wrapper implemented through AddSearchDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddSearchDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`SearchDropdownChanged`

#### Example

```
local control = Section:AddAutocomplete({
    Id = "Autocomplete",
    Text = "Autocomplete",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddAutomaticSizeSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddAutomaticSizeSelector)

Lets the user choose a value using the automatic size selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddAutomaticSizeSelector({
    Id = "AutomaticSizeSelector",
    Text = "Automatic Size Selector",
    Enum = Enum.EasingStyle,
})
```

### AddAvatar

VisualsAlias→ AddAvatarViewport

[#](#feature-AddAvatar)

Adds the Avatar UI feature to a section. This is a convenience alias implemented through AddAvatarViewport.

Configuration, feedback & example

#### Resolved implementation

`AddAvatarViewport`

#### Common configuration keys

`BackgroundColor`, `Callback`, `Height`, `Id`, `Player`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`AvatarChanged`

#### Example

```
local control = Section:AddAvatar({
    Id = "Avatar",
    Text = "Avatar",
    Player = game.Players.LocalPlayer,
    Height = 180,
})
```

### AddAvatarPreview

VisualsWrapper→ AddAvatarViewport

[#](#feature-AddAvatarPreview)

Displays information using a avatar preview. This is a convenience wrapper implemented through AddAvatarViewport.

Configuration, feedback & example

#### Resolved implementation

`AddAvatarViewport`

#### Common configuration keys

`BackgroundColor`, `Callback`, `Height`, `Id`, `Player`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`AvatarChanged`

#### Example

```
local control = Section:AddAvatarPreview({
    Id = "AvatarPreview",
    Text = "Avatar",
    Player = game.Players.LocalPlayer,
    Height = 180,
})
```

### AddAvatarStack

VisualsWrapper→ AddPlayerList

[#](#feature-AddAvatarStack)

Adds the Avatar Stack UI feature to a section. This is a convenience wrapper implemented through AddPlayerList.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerList`

#### Common configuration keys

`Callback`, `ExcludeLocalPlayer`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PlayerListSelected`

#### Example

```
local control = Section:AddAvatarStack({
    Id = "AvatarStack",
    Text = "Player",
    Callback = function(player)
        if player then print(player.Name) end
    end,
})
```

### AddAvatarViewport

InputsNative

[#](#feature-AddAvatarViewport)

Displays a player avatar in a ViewportFrame.

Configuration, feedback & example

#### Resolved implementation

`AddAvatarViewport`

#### Common configuration keys

`BackgroundColor`, `Callback`, `Height`, `Id`, `Player`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`AvatarChanged`

#### Example

```
local control = Section:AddAvatarViewport({
    Id = "AvatarViewport",
    Text = "Avatar",
    Player = game.Players.LocalPlayer,
    Height = 180,
})
```

### AddBadge

VisualsAlias→ AddStatus

[#](#feature-AddBadge)

Displays information using a badge. This is a convenience alias implemented through AddStatus.

Configuration, feedback & example

#### Resolved implementation

`AddStatus`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`StatusChanged`

#### Example

```
local control = Section:AddBadge({
    Id = "Badge",
    Text = "Connection",
    Default = "Online",
})
```

### AddBarChart

Charts & LiveNative

[#](#feature-AddBarChart)

Draws a simple bar chart from numeric values.

Configuration, feedback & example

#### Resolved implementation

`AddBarChart`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `Text`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddBarChart({
    Id = "BarChart",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddBarGraph

Charts & LiveWrapper→ AddBarChart

[#](#feature-AddBarGraph)

Displays data visually using a bar graph. This is a convenience wrapper implemented through AddBarChart.

Configuration, feedback & example

#### Resolved implementation

`AddBarChart`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `Text`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddBarGraph({
    Id = "BarGraph",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddBatteryIndicator

VisualsWrapper→ AddMeter

[#](#feature-AddBatteryIndicator)

Displays a status or numeric measurement using a battery indicator. This is a convenience wrapper implemented through AddMeter.

Configuration, feedback & example

#### Resolved implementation

`AddMeter`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`, `Thresholds`

#### Callback fields

`Callback`

#### Feedback events

`MeterChanged`

#### Example

```
local control = Section:AddBatteryIndicator({
    Id = "BatteryIndicator",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddBinaryInput

InputsWrapper→ AddTextbox

[#](#feature-AddBinaryInput)

Lets the user enter or edit a value using a binary input control. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddBinaryInput({
    Id = "BinaryInput",
    Text = "Binary Input",
    Default = "Example text",
})
```

### AddBoard

Layout & OtherAlias→ AddKanban

[#](#feature-AddBoard)

Displays or manages structured items using a board. This is a convenience alias implemented through AddKanban.

Configuration, feedback & example

#### Resolved implementation

`AddKanban`

#### Common configuration keys

`Columns`, `Height`, `Id`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddBoard({
    Id = "Board",
    Text = "Board",
})
```

### AddBooleanSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddBooleanSelector)

Lets the user choose a value using the boolean selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddBooleanSelector({
    Id = "BooleanSelector",
    Text = "Boolean Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddBooleanToggle

Layout & OtherWrapper→ AddToggle

[#](#feature-AddBooleanToggle)

Creates a setting-style boolean toggle for switching state. This is a convenience wrapper implemented through AddToggle.

Configuration, feedback & example

#### Resolved implementation

`AddToggle`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ToggleChanged`

#### Example

```
local control = Section:AddBooleanToggle({
    Id = "BooleanToggle",
    Text = "Enabled",
    Default = true,
    Callback = function(value)
        print(value)
    end,
})
```

### AddBreadcrumbs

Layout & OtherNative

[#](#feature-AddBreadcrumbs)

Adds the Breadcrumbs UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddBreadcrumbs`

#### Common configuration keys

`Callback`, `Height`, `Id`, `Items`, `Separator`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`BreadcrumbPressed`

#### Example

```
local control = Section:AddBreadcrumbs({
    Id = "Breadcrumbs",
    Text = "Breadcrumbs",
})
```

### AddBrickColorSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddBrickColorSelector)

Lets the user choose a value using the brick color selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddBrickColorSelector({
    Id = "BrickColorSelector",
    Text = "Brick Color Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddBrightnessInput

InputsWrapper→ AddSlider

[#](#feature-AddBrightnessInput)

Lets the user enter or edit a value using a brightness input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddBrightnessInput({
    Id = "BrightnessInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddBulletChart

Charts & LiveWrapper→ AddProgress

[#](#feature-AddBulletChart)

Displays data visually using a bullet chart. This is a convenience wrapper implemented through AddProgress.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddBulletChart({
    Id = "BulletChart",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddButton

ActionsNative

[#](#feature-AddButton)

Creates a normal clickable button and calls your Callback when the user presses it.

Configuration, feedback & example

#### Resolved implementation

`AddButton`

#### Common configuration keys

`Callback`, `Color`, `Font`, `Height`, `HoverColor`, `Id`, `Radius`, `Stroke`, `Text`, `TextColor`, `TextSize`

#### Callback fields

`Callback`

#### Feedback events

`ButtonPressed`

#### Example

```
local control = Section:AddButton({
    Id = "Button",
    Text = "Click me",
    Callback = function()
        print("Pressed")
    end,
})
```

### AddButtonGroup

ActionsNative

[#](#feature-AddButtonGroup)

Creates a button group action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddButtonGroup`

#### Common configuration keys

`Alignment`, `Buttons`, `Callback`, `EqualWidth`, `Height`, `Id`, `Spacing`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ButtonGroupPressed`

#### Example

```
local control = Section:AddButtonGroup({
    Id = "ButtonGroup",
    Text = "Button Group",
})
```

### AddCFrameInput

InputsNative

[#](#feature-AddCFrameInput)

Lets the user enter or edit a value using a c frame input control.

Configuration, feedback & example

#### Resolved implementation

`AddCFrameInput`

#### Common configuration keys

`Callback`, `Default`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCFrameInput({
    Id = "CFrameInput",
    Text = "C Frame Input",
})
```

### AddCallout

VisualsNative

[#](#feature-AddCallout)

Adds the Callout UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCallout({
    Id = "Callout",
    Text = "Callout",
})
```

### AddCapacityBar

Layout & OtherWrapper→ AddProgress

[#](#feature-AddCapacityBar)

Adds the Capacity Bar UI feature to a section. This is a convenience wrapper implemented through AddProgress.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddCapacityBar({
    Id = "CapacityBar",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddCard

VisualsNative

[#](#feature-AddCard)

Displays information using a card.

Configuration, feedback & example

#### Resolved implementation

`AddCard`

#### Common configuration keys

`Height`, `Kind`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCard({
    Id = "Card",
    Text = "Card",
})
```

### AddCardSelect

SelectorsNative→ AddGridSelect

[#](#feature-AddCardSelect)

Lets the user choose a value using the card select interface.

Configuration, feedback & example

#### Resolved implementation

`AddGridSelect`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCardSelect({
    Id = "CardSelect",
    Text = "Card Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddCards

VisualsAlias→ AddCardSelect

[#](#feature-AddCards)

Displays information using a cards. This is a convenience alias implemented through AddCardSelect.

Configuration, feedback & example

#### Resolved implementation

`AddGridSelect`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCards({
    Id = "Cards",
    Text = "Cards",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddCarousel

VisualsWrapper→ AddImage

[#](#feature-AddCarousel)

Adds the Carousel UI feature to a section. This is a convenience wrapper implemented through AddImage.

Configuration, feedback & example

#### Resolved implementation

`AddImage`

#### Common configuration keys

`BackgroundColor`, `BackgroundTransparency`, `Callback`, `Height`, `Id`, `Image`, `ImageColor`, `ImageTransparency`, `Radius`, `ScaleType`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ImageChanged`, `ImagePressed`

#### Example

```
local control = Section:AddCarousel({
    Id = "Carousel",
    Image = "rbxassetid://107844260625621",
    Height = 140,
})
```

### AddCheckbox

InputsAlias→ AddToggle

[#](#feature-AddCheckbox)

Lets the user enter or edit a value using a checkbox control. This is a convenience alias implemented through AddToggle.

Configuration, feedback & example

#### Resolved implementation

`AddToggle`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ToggleChanged`

#### Example

```
local control = Section:AddCheckbox({
    Id = "Checkbox",
    Text = "Enabled",
    Default = true,
    Callback = function(value)
        print(value)
    end,
})
```

### AddChecklist

DataNative

[#](#feature-AddChecklist)

Displays or manages structured items using a checklist.

Configuration, feedback & example

#### Resolved implementation

`AddChecklist`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ChecklistChanged`

#### Example

```
local control = Section:AddChecklist({
    Id = "Checklist",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddChipGroup

SelectorsNative

[#](#feature-AddChipGroup)

Organizes UI content using a chip group layout/control.

Configuration, feedback & example

#### Resolved implementation

`AddChipGroup`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ChipSelected`

#### Example

```
local control = Section:AddChipGroup({
    Id = "ChipGroup",
    Text = "Chip Group",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddChoiceChips

SelectorsWrapper→ AddChipGroup

[#](#feature-AddChoiceChips)

Adds the Choice Chips UI feature to a section. This is a convenience wrapper implemented through AddChipGroup.

Configuration, feedback & example

#### Resolved implementation

`AddChipGroup`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ChipSelected`

#### Example

```
local control = Section:AddChoiceChips({
    Id = "ChoiceChips",
    Text = "Choice Chips",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddCircularGauge

Charts & LiveWrapper→ AddMeter

[#](#feature-AddCircularGauge)

Displays a status or numeric measurement using a circular gauge. This is a convenience wrapper implemented through AddMeter.

Configuration, feedback & example

#### Resolved implementation

`AddMeter`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`, `Thresholds`

#### Callback fields

`Callback`

#### Feedback events

`MeterChanged`

#### Example

```
local control = Section:AddCircularGauge({
    Id = "CircularGauge",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddClock

Charts & LiveNative

[#](#feature-AddClock)

Adds the Clock UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddClock`

#### Common configuration keys

`Format`, `Height`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddClock({
    Id = "Clock",
    Text = "Clock",
})
```

### AddCodeBox

InputsNative

[#](#feature-AddCodeBox)

Lets the user enter or edit a value using a code box control.

Configuration, feedback & example

#### Resolved implementation

`AddCodeBox`

#### Common configuration keys

`Height`, `Monospace`, `MultiLine`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCodeBox({
    Id = "CodeBox",
    Text = "Code Box",
    Default = "Example text",
})
```

### AddCodeInput

InputsWrapper→ AddCodeBox

[#](#feature-AddCodeInput)

Lets the user enter or edit a value using a code input control. This is a convenience wrapper implemented through AddCodeBox.

Configuration, feedback & example

#### Resolved implementation

`AddCodeBox`

#### Common configuration keys

`Height`, `Monospace`, `MultiLine`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCodeInput({
    Id = "CodeInput",
    Text = "Code Input",
    Default = "Example text",
})
```

### AddCodePreview

VisualsWrapper→ AddCodeBox

[#](#feature-AddCodePreview)

Displays information using a code preview. This is a convenience wrapper implemented through AddCodeBox.

Configuration, feedback & example

#### Resolved implementation

`AddCodeBox`

#### Common configuration keys

`Height`, `Monospace`, `MultiLine`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCodePreview({
    Id = "CodePreview",
    Text = "Code Preview",
    Default = "Example text",
})
```

### AddColor

Layout & OtherAlias→ AddColorPicker

[#](#feature-AddColor)

Adds the Color UI feature to a section. This is a convenience alias implemented through AddColorPicker.

Configuration, feedback & example

#### Resolved implementation

`AddColorPicker`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ColorChanged`

#### Example

```
local control = Section:AddColor({
    Id = "Color",
    Text = "Color",
    Default = Color3.fromRGB(143, 180, 255),
})
```

### AddColorHeatmap

Charts & LiveWrapper→ AddHeatmap

[#](#feature-AddColorHeatmap)

Displays data visually using a color heatmap. This is a convenience wrapper implemented through AddHeatmap.

Configuration, feedback & example

#### Resolved implementation

`AddHeatmap`

#### Common configuration keys

`Callback`, `Height`, `HighColor`, `Id`, `LowColor`, `ShowValues`, `Text`, `Values`

#### Callback fields

`Callback`

#### Feedback events

`HeatmapCellPressed`

#### Example

```
local control = Section:AddColorHeatmap({
    Id = "ColorHeatmap",
    Text = "Heatmap",
    Values = {
        {0.1, 0.5, 0.9},
        {0.8, 0.3, 0.6},
    },
})
```

### AddColorHistory

DataWrapper→ AddColorSwatches

[#](#feature-AddColorHistory)

Adds the Color History UI feature to a section. This is a convenience wrapper implemented through AddColorSwatches.

Configuration, feedback & example

#### Resolved implementation

`AddColorSwatches`

#### Common configuration keys

`Callback`, `Colors`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SwatchChanged`

#### Example

```
local control = Section:AddColorHistory({
    Id = "ColorHistory",
    Text = "Color History",
})
```

### AddColorPalette

VisualsWrapper→ AddColorSwatches

[#](#feature-AddColorPalette)

Adds the Color Palette UI feature to a section. This is a convenience wrapper implemented through AddColorSwatches.

Configuration, feedback & example

#### Resolved implementation

`AddColorSwatches`

#### Common configuration keys

`Callback`, `Colors`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SwatchChanged`

#### Example

```
local control = Section:AddColorPalette({
    Id = "ColorPalette",
    Text = "Color Palette",
})
```

### AddColorPicker

SelectorsNative

[#](#feature-AddColorPicker)

Provides an interactive color picker and returns a Roblox Color3.

Configuration, feedback & example

#### Resolved implementation

`AddColorPicker`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ColorChanged`

#### Example

```
local control = Section:AddColorPicker({
    Id = "ColorPicker",
    Text = "Color",
    Default = Color3.fromRGB(143, 180, 255),
})
```

### AddColorSelector

SelectorsWrapper→ AddColorPicker

[#](#feature-AddColorSelector)

Lets the user choose a value using the color selector interface. This is a convenience wrapper implemented through AddColorPicker.

Configuration, feedback & example

#### Resolved implementation

`AddColorPicker`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ColorChanged`

#### Example

```
local control = Section:AddColorSelector({
    Id = "ColorSelector",
    Text = "Color",
    Default = Color3.fromRGB(143, 180, 255),
})
```

### AddColorSwatches

SelectorsNative

[#](#feature-AddColorSwatches)

Adds the Color Swatches UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddColorSwatches`

#### Common configuration keys

`Callback`, `Colors`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SwatchChanged`

#### Example

```
local control = Section:AddColorSwatches({
    Id = "ColorSwatches",
    Text = "Color Swatches",
})
```

### AddColumns

Layout & OtherNative

[#](#feature-AddColumns)

Creates multiple side-by-side child sections using builder functions.

Configuration, feedback & example

#### Resolved implementation

`AddColumns`

#### Common configuration keys

`Builders`, `Columns`, `Height`, `Id`, `Spacing`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddColumns({
    Id = "Columns",
    Text = "Columns",
})
```

### AddColumnsLayout

Layout & OtherAlias→ AddColumns

[#](#feature-AddColumnsLayout)

Organizes UI content using a columns layout layout/control. This is a convenience alias implemented through AddColumns.

Configuration, feedback & example

#### Resolved implementation

`AddColumns`

#### Common configuration keys

`Builders`, `Columns`, `Height`, `Id`, `Spacing`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddColumnsLayout({
    Id = "ColumnsLayout",
    Text = "Columns Layout",
})
```

### AddCombobox

InputsWrapper→ AddSearchDropdown

[#](#feature-AddCombobox)

Lets the user choose a value using the combobox interface. This is a convenience wrapper implemented through AddSearchDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddSearchDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`SearchDropdownChanged`

#### Example

```
local control = Section:AddCombobox({
    Id = "Combobox",
    Text = "Combobox",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddCommandBox

InputsNative

[#](#feature-AddCommandBox)

Lets the user enter or edit a value using a command box control.

Configuration, feedback & example

#### Resolved implementation

`AddCommandBox`

#### Common configuration keys

`Callback`, `Height`, `Id`, `Placeholder`, `Prompt`, `Text`, `UseLibraryCommands`

#### Callback fields

`Callback`

#### Feedback events

`CommandSubmitted`

#### Example

```
local control = Section:AddCommandBox({
    Id = "CommandBox",
    Text = "Command Box",
})
```

### AddCommandInput

InputsAlias→ AddCommandBox

[#](#feature-AddCommandInput)

Lets the user enter or edit a value using a command input control. This is a convenience alias implemented through AddCommandBox.

Configuration, feedback & example

#### Resolved implementation

`AddCommandBox`

#### Common configuration keys

`Callback`, `Height`, `Id`, `Placeholder`, `Prompt`, `Text`, `UseLibraryCommands`

#### Callback fields

`Callback`

#### Feedback events

`CommandSubmitted`

#### Example

```
local control = Section:AddCommandInput({
    Id = "CommandInput",
    Text = "Command Input",
})
```

### AddCommandPalette

ActionsNative

[#](#feature-AddCommandPalette)

Adds the Command Palette UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddCommandPalette`

#### Common configuration keys

`Callback`, `Display`, `Options`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCommandPalette({
    Id = "CommandPalette",
    Text = "Command Palette",
})
```

### AddCommands

ActionsAlias→ AddCommandPalette

[#](#feature-AddCommands)

Adds the Commands UI feature to a section. This is a convenience alias implemented through AddCommandPalette.

Configuration, feedback & example

#### Resolved implementation

`AddCommandPalette`

#### Common configuration keys

`Callback`, `Display`, `Options`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCommands({
    Id = "Commands",
    Text = "Commands",
})
```

### AddComparisonSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddComparisonSelector)

Lets the user choose a value using the comparison selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddComparisonSelector({
    Id = "ComparisonSelector",
    Text = "Comparison Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddCompletionBar

Layout & OtherWrapper→ AddProgress

[#](#feature-AddCompletionBar)

Adds the Completion Bar UI feature to a section. This is a convenience wrapper implemented through AddProgress.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddCompletionBar({
    Id = "CompletionBar",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddComponent

Layout & OtherNative

[#](#feature-AddComponent)

Creates a reusable custom component that was previously registered with UI:RegisterComponent().

Configuration, feedback & example

#### Resolved implementation

`AddComponent`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddComponent({
    Id = "Component",
    Text = "Component",
})
```

### AddConfirmButton

ActionsNative→ AddButton

[#](#feature-AddConfirmButton)

Creates a confirm button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddButton`

#### Common configuration keys

`Callback`, `Color`, `Font`, `Height`, `HoverColor`, `Id`, `Radius`, `Stroke`, `Text`, `TextColor`, `TextSize`

#### Callback fields

`Callback`

#### Feedback events

`ButtonPressed`

#### Example

```
local control = Section:AddConfirmButton({
    Id = "ConfirmButton",
    Text = "Click me",
    Callback = function()
        print("Pressed")
    end,
})
```

### AddConsole

DataAlias→ AddLogConsole

[#](#feature-AddConsole)

Adds the Console UI feature to a section. This is a convenience alias implemented through AddLogConsole.

Configuration, feedback & example

#### Resolved implementation

`AddLogConsole`

#### Common configuration keys

`BackgroundColor`, `Height`, `Id`, `MaxLines`, `RichText`, `Text`, `TextColor`, `TextSize`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`LogAdded`

#### Example

```
local console = Section:AddConsole({
    Id = "Console",
    Text = "Console",
    Height = 160,
})

-- Depending on the returned handle, use its runtime methods
-- to append/update console content.
```

### AddConsoleView

DataWrapper→ AddLogConsole

[#](#feature-AddConsoleView)

Displays information using a console view. This is a convenience wrapper implemented through AddLogConsole.

Configuration, feedback & example

#### Resolved implementation

`AddLogConsole`

#### Common configuration keys

`BackgroundColor`, `Height`, `Id`, `MaxLines`, `RichText`, `Text`, `TextColor`, `TextSize`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`LogAdded`

#### Example

```
local console = Section:AddConsoleView({
    Id = "ConsoleView",
    Text = "Console",
    Height = 160,
})

-- Depending on the returned handle, use its runtime methods
-- to append/update console content.
```

### AddContainer

Layout & OtherAlias→ AddPanel

[#](#feature-AddContainer)

Organizes UI content using a container layout/control. This is a convenience alias implemented through AddPanel.

Configuration, feedback & example

#### Resolved implementation

`AddPanel`

#### Common configuration keys

`Kind`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddContainer({
    Id = "Container",
    Text = "Container",
})
```

### AddContextMenuButton

ActionsWrapper→ AddDropdown

[#](#feature-AddContextMenuButton)

Creates a context menu button action that the user can press. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddContextMenuButton({
    Id = "ContextMenuButton",
    Text = "Context Menu Button",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddControlManager

DataWrapper→ AddTable

[#](#feature-AddControlManager)

Adds the Control Manager UI feature to a section. This is a convenience wrapper implemented through AddTable.

Configuration, feedback & example

#### Resolved implementation

`AddTable`

#### Common configuration keys

`Callback`, `Columns`, `Height`, `Id`, `RowHeight`, `Rows`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TableRowSelected`

#### Example

```
local control = Section:AddControlManager({
    Id = "ControlManager",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddControlSearch

Layout & OtherNative

[#](#feature-AddControlSearch)

Adds the Control Search UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddControlSearch`

#### Common configuration keys

`Display`, `Options`

#### Callback fields

`Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddControlSearch({
    Id = "ControlSearch",
    Text = "Control Search",
})
```

### AddCopyField

InputsWrapper→ AddTextbox

[#](#feature-AddCopyField)

Lets the user enter or edit a value using a copy field control. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddCopyField({
    Id = "CopyField",
    Text = "Copy Field",
    Default = "Example text",
})
```

### AddCornerRadiusInput

InputsWrapper→ AddSlider

[#](#feature-AddCornerRadiusInput)

Lets the user enter or edit a value using a corner radius input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddCornerRadiusInput({
    Id = "CornerRadiusInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddCountdown

Charts & LiveNative

[#](#feature-AddCountdown)

Displays a countdown timer and can emit an event when it reaches zero.

Configuration, feedback & example

#### Resolved implementation

`AddCountdown`

#### Common configuration keys

`AutoStart`, `Callback`, `Default`, `Height`, `Id`, `Seconds`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`CountdownFinished`

#### Example

```
local control = Section:AddCountdown({
    Id = "Countdown",
    Text = "Countdown",
})
```

### AddCounterCard

VisualsWrapper→ AddStatCard

[#](#feature-AddCounterCard)

Displays information using a counter card. This is a convenience wrapper implemented through AddStatCard.

Configuration, feedback & example

#### Resolved implementation

`AddStatCard`

#### Common configuration keys

`Callback`, `Color`, `Default`, `DeltaColor`, `DeltaText`, `Height`, `Id`, `Prefix`, `Suffix`, `Text`, `Value`, `ValueSize`

#### Callback fields

`Callback`

#### Feedback events

`StatChanged`

#### Example

```
local control = Section:AddCounterCard({
    Id = "CounterCard",
    Text = "Score",
    Default = 125,
    DeltaText = "+12%",
})
```

### AddCountrySelector

SelectorsNative→ AddSearchDropdown

[#](#feature-AddCountrySelector)

Lets the user choose a value using the country selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddSearchDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`SearchDropdownChanged`

#### Example

```
local control = Section:AddCountrySelector({
    Id = "CountrySelector",
    Text = "Country Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddCurrencyInput

InputsWrapper→ AddNumberbox

[#](#feature-AddCurrencyInput)

Lets the user enter or edit a value using a currency input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCurrencyInput({
    Id = "CurrencyInput",
    Text = "Currency Input",
})
```

### AddCurveEditor

InputsWrapper→ AddLineChart

[#](#feature-AddCurveEditor)

Lets the user enter or edit a value using a curve editor control. This is a convenience wrapper implemented through AddLineChart.

Configuration, feedback & example

#### Resolved implementation

`AddLineChart`

#### Common configuration keys

`Height`, `Thickness`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddCurveEditor({
    Id = "CurveEditor",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddCustom

Layout & OtherNative

[#](#feature-AddCustom)

Builds a completely custom Raynard control. You supply the Roblox GUI objects while Raynard still handles IDs, state, visibility, callbacks, feedback, and cleanup.

Configuration, feedback & example

#### Resolved implementation

`AddCustom`

#### Common configuration keys

`BackgroundColor`, `BackgroundTransparency`, `Build`, `Callback`, `ClipsDescendants`, `Corner`, `Default`, `EventType`, `Height`, `Id`, `Kind`, `Radius`, `Render`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`Changed`, `CustomEvent`

#### Example

```
local control = Section:AddCustom({
    Id = "Custom",
    Text = "Custom control",
    Default = 0,
    Height = 70,

    Build = function(frame, control, app)
        control:Create("TextLabel", {
            Parent = frame,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "My custom content",
            TextColor3 = app.Config.Colors.Text,
        })
    end,
})
```

### AddCustomControl

Layout & OtherAlias→ AddCustom

[#](#feature-AddCustomControl)

Adds the Custom Control UI feature to a section. This is a convenience alias implemented through AddCustom.

Configuration, feedback & example

#### Resolved implementation

`AddCustom`

#### Common configuration keys

`BackgroundColor`, `BackgroundTransparency`, `Build`, `Callback`, `ClipsDescendants`, `Corner`, `Default`, `EventType`, `Height`, `Id`, `Kind`, `Radius`, `Render`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`Changed`, `CustomEvent`

#### Example

```
local control = Section:AddCustomControl({
    Id = "CustomControl",
    Text = "Custom control",
    Default = 0,
    Height = 70,

    Build = function(frame, control, app)
        control:Create("TextLabel", {
            Parent = frame,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "My custom content",
            TextColor3 = app.Config.Colors.Text,
        })
    end,
})
```

### AddDangerButton

ActionsWrapper→ AddButton

[#](#feature-AddDangerButton)

Creates a danger button action that the user can press. This is a convenience wrapper implemented through AddButton.

Configuration, feedback & example

#### Resolved implementation

`AddButton`

#### Common configuration keys

`Callback`, `Color`, `Font`, `Height`, `HoverColor`, `Id`, `Radius`, `Stroke`, `Text`, `TextColor`, `TextSize`

#### Callback fields

`Callback`

#### Feedback events

`ButtonPressed`

#### Example

```
local control = Section:AddDangerButton({
    Id = "DangerButton",
    Text = "Click me",
    Callback = function()
        print("Pressed")
    end,
})
```

### AddDataGrid

DataWrapper→ AddTable

[#](#feature-AddDataGrid)

Displays or manages structured items using a data grid. This is a convenience wrapper implemented through AddTable.

Configuration, feedback & example

#### Resolved implementation

`AddTable`

#### Common configuration keys

`Callback`, `Columns`, `Height`, `Id`, `RowHeight`, `Rows`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TableRowSelected`

#### Example

```
local control = Section:AddDataGrid({
    Id = "DataGrid",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddDataGridEditor

InputsAlias→ AddEditableTable

[#](#feature-AddDataGridEditor)

Lets the user enter or edit a value using a data grid editor control. This is a convenience alias implemented through AddEditableTable.

Configuration, feedback & example

#### Resolved implementation

`AddEditableTable`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDataGridEditor({
    Id = "DataGridEditor",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddDataTable

DataAlias→ AddTable

[#](#feature-AddDataTable)

Displays or manages structured items using a data table. This is a convenience alias implemented through AddTable.

Configuration, feedback & example

#### Resolved implementation

`AddTable`

#### Common configuration keys

`Callback`, `Columns`, `Height`, `Id`, `RowHeight`, `Rows`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TableRowSelected`

#### Example

```
local control = Section:AddDataTable({
    Id = "DataTable",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddDateInput

InputsNative

[#](#feature-AddDateInput)

Lets the user enter or edit a value using a date input control.

Configuration, feedback & example

#### Resolved implementation

`AddDateInput`

#### Common configuration keys

`Placeholder`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDateInput({
    Id = "DateInput",
    Text = "Date Input",
    Default = "2026-08-29",
})
```

### AddDaySelector

SelectorsNative→ AddDropdown

[#](#feature-AddDaySelector)

Lets the user choose a value using the day selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddDaySelector({
    Id = "DaySelector",
    Text = "Day Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddDegreesInput

InputsWrapper→ AddNumberbox

[#](#feature-AddDegreesInput)

Lets the user enter or edit a value using a degrees input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDegreesInput({
    Id = "DegreesInput",
    Text = "Degrees Input",
})
```

### AddDeltaStat

Layout & OtherWrapper→ AddStatCard

[#](#feature-AddDeltaStat)

Adds the Delta Stat UI feature to a section. This is a convenience wrapper implemented through AddStatCard.

Configuration, feedback & example

#### Resolved implementation

`AddStatCard`

#### Common configuration keys

`Callback`, `Color`, `Default`, `DeltaColor`, `DeltaText`, `Height`, `Id`, `Prefix`, `Suffix`, `Text`, `Value`, `ValueSize`

#### Callback fields

`Callback`

#### Feedback events

`StatChanged`

#### Example

```
local control = Section:AddDeltaStat({
    Id = "DeltaStat",
    Text = "Score",
    Default = 125,
    DeltaText = "+12%",
})
```

### AddDeviceIndicator

Players & WorldWrapper→ AddKeyValue

[#](#feature-AddDeviceIndicator)

Displays a status or numeric measurement using a device indicator. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddDeviceIndicator({
    Id = "DeviceIndicator",
    Text = "Device Indicator",
})
```

### AddDictionaryEditor

InputsWrapper→ AddEditableList

[#](#feature-AddDictionaryEditor)

Lets the user enter or edit a value using a dictionary editor control. This is a convenience wrapper implemented through AddEditableList.

Configuration, feedback & example

#### Resolved implementation

`AddEditableList`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDictionaryEditor({
    Id = "DictionaryEditor",
    Text = "Dictionary Editor",
})
```

### AddDigitalClock

Charts & LiveWrapper→ AddClock

[#](#feature-AddDigitalClock)

Adds the Digital Clock UI feature to a section. This is a convenience wrapper implemented through AddClock.

Configuration, feedback & example

#### Resolved implementation

`AddClock`

#### Common configuration keys

`Format`, `Height`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDigitalClock({
    Id = "DigitalClock",
    Text = "Digital Clock",
})
```

### AddDirectionSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddDirectionSelector)

Lets the user choose a value using the direction selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddDirectionSelector({
    Id = "DirectionSelector",
    Text = "Direction Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddDisclosure

Layout & OtherNative

[#](#feature-AddDisclosure)

Creates expandable/collapsible content inside a section.

Configuration, feedback & example

#### Resolved implementation

`AddDisclosure`

#### Common configuration keys

`Callback`, `Content`, `Description`, `Height`, `Id`, `Open`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`DisclosureChanged`

#### Example

```
local control = Section:AddDisclosure({
    Id = "Disclosure",
    Text = "Disclosure",
})
```

### AddDistanceInput

InputsWrapper→ AddNumberbox

[#](#feature-AddDistanceInput)

Lets the user enter or edit a value using a distance input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDistanceInput({
    Id = "DistanceInput",
    Text = "Distance Input",
})
```

### AddDivider

Layout & OtherNative

[#](#feature-AddDivider)

Adds the Divider UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddDivider`

#### Common configuration keys

`Color`, `Height`, `Thickness`, `Transparency`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDivider({
    Id = "Divider",
    Text = "Divider",
})
```

### AddDonutChart

Charts & LiveWrapper→ AddBarChart

[#](#feature-AddDonutChart)

Displays data visually using a donut chart. This is a convenience wrapper implemented through AddBarChart.

Configuration, feedback & example

#### Resolved implementation

`AddBarChart`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `Text`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDonutChart({
    Id = "DonutChart",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddDoubleClickButton

ActionsNative

[#](#feature-AddDoubleClickButton)

Creates a double click button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddDoubleClickButton`

#### Common configuration keys

`Callback`, `Color`, `Height`, `Id`, `Interval`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`DoubleClicked`, `FirstClick`

#### Example

```
local control = Section:AddDoubleClickButton({
    Id = "DoubleClickButton",
    Text = "Double Click Button",
})
```

### AddDragValue

Layout & OtherWrapper→ AddSlider

[#](#feature-AddDragValue)

Adds the Drag Value UI feature to a section. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddDragValue({
    Id = "DragValue",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddDropdown

SelectorsNative

[#](#feature-AddDropdown)

Shows a list of choices and lets the user select one item.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddDropdown({
    Id = "Dropdown",
    Text = "Dropdown",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddDropdownButton

SelectorsNative→ AddDropdown

[#](#feature-AddDropdownButton)

Creates a dropdown button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddDropdownButton({
    Id = "DropdownButton",
    Text = "Dropdown Button",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddDualList

DataNative

[#](#feature-AddDualList)

Displays or manages structured items using a dual list.

Configuration, feedback & example

#### Resolved implementation

`AddDualList`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Selected`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDualList({
    Id = "DualList",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddDurationInput

InputsWrapper→ AddNumberbox

[#](#feature-AddDurationInput)

Lets the user enter or edit a value using a duration input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddDurationInput({
    Id = "DurationInput",
    Text = "Duration Input",
})
```

### AddDurationLabel

VisualsWrapper→ AddKeyValue

[#](#feature-AddDurationLabel)

Displays information using a duration label. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddDurationLabel({
    Id = "DurationLabel",
    Text = "Duration Label",
})
```

### AddEasingDirectionSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddEasingDirectionSelector)

Lets the user choose a value using the easing direction selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEasingDirectionSelector({
    Id = "EasingDirectionSelector",
    Text = "Easing Direction Selector",
    Enum = Enum.EasingStyle,
})
```

### AddEasingStyleSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddEasingStyleSelector)

Lets the user choose a value using the easing style selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEasingStyleSelector({
    Id = "EasingStyleSelector",
    Text = "Easing Style Selector",
    Enum = Enum.EasingStyle,
})
```

### AddEditableLabel

DataWrapper→ AddTextbox

[#](#feature-AddEditableLabel)

Displays or manages structured items using a editable label. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddEditableLabel({
    Id = "EditableLabel",
    Text = "Editable Label",
    Default = "Example text",
})
```

### AddEditableList

DataNative

[#](#feature-AddEditableList)

Displays or manages structured items using a editable list.

Configuration, feedback & example

#### Resolved implementation

`AddEditableList`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEditableList({
    Id = "EditableList",
    Text = "Editable List",
})
```

### AddEditableTable

DataNative

[#](#feature-AddEditableTable)

Displays or manages structured items using a editable table.

Configuration, feedback & example

#### Resolved implementation

`AddEditableTable`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEditableTable({
    Id = "EditableTable",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddEmailBox

InputsNative

[#](#feature-AddEmailBox)

Lets the user enter or edit a value using a email box control.

Configuration, feedback & example

#### Resolved implementation

`AddEmailBox`

#### Common configuration keys

`Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEmailBox({
    Id = "EmailBox",
    Text = "Email Box",
    Default = "demo@example.com",
})
```

### AddEmailInput

InputsWrapper→ AddEmailBox

[#](#feature-AddEmailInput)

Lets the user enter or edit a value using a email input control. This is a convenience wrapper implemented through AddEmailBox.

Configuration, feedback & example

#### Resolved implementation

`AddEmailBox`

#### Common configuration keys

`Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEmailInput({
    Id = "EmailInput",
    Text = "Email Input",
    Default = "demo@example.com",
})
```

### AddEmojiPicker

SelectorsNative→ AddGridSelect

[#](#feature-AddEmojiPicker)

Lets the user choose a value using the emoji picker interface.

Configuration, feedback & example

#### Resolved implementation

`AddGridSelect`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEmojiPicker({
    Id = "EmojiPicker",
    Text = "Emoji Picker",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddEmptyState

VisualsWrapper→ AddCallout

[#](#feature-AddEmptyState)

Adds the Empty State UI feature to a section. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEmptyState({
    Id = "EmptyState",
    Text = "Empty State",
})
```

### AddEnumMultiSelect

SelectorsWrapper→ AddMultiDropdown

[#](#feature-AddEnumMultiSelect)

Lets the user choose a value using the enum multi select interface. This is a convenience wrapper implemented through AddMultiDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddMultiDropdown`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MultiDropdownChanged`

#### Example

```
local control = Section:AddEnumMultiSelect({
    Id = "EnumMultiSelect",
    Text = "Enum Multi Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = {"Alpha"},
})
```

### AddEnumSelector

SelectorsNative

[#](#feature-AddEnumSelector)

Lets the user choose a value using the enum selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddEnumSelector({
    Id = "EnumSelector",
    Text = "Enum Selector",
    Enum = Enum.EasingStyle,
})
```

### AddErrorCard

VisualsWrapper→ AddCallout

[#](#feature-AddErrorCard)

Displays information using a error card. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddErrorCard({
    Id = "ErrorCard",
    Text = "Error Card",
})
```

### AddEventCounter

Charts & LiveWrapper→ AddKeyValue

[#](#feature-AddEventCounter)

Adds the Event Counter UI feature to a section. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddEventCounter({
    Id = "EventCounter",
    Text = "Event Counter",
})
```

### AddEventLog

DataWrapper→ AddLogConsole

[#](#feature-AddEventLog)

Adds the Event Log UI feature to a section. This is a convenience wrapper implemented through AddLogConsole.

Configuration, feedback & example

#### Resolved implementation

`AddLogConsole`

#### Common configuration keys

`BackgroundColor`, `Height`, `Id`, `MaxLines`, `RichText`, `Text`, `TextColor`, `TextSize`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`LogAdded`

#### Example

```
local console = Section:AddEventLog({
    Id = "EventLog",
    Text = "Console",
    Height = 160,
})

-- Depending on the returned handle, use its runtime methods
-- to append/update console content.
```

### AddFOVInput

InputsWrapper→ AddSlider

[#](#feature-AddFOVInput)

Lets the user enter or edit a value using a fov input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddFOVInput({
    Id = "FOVInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddFPSMeter

Charts & LiveNative

[#](#feature-AddFPSMeter)

Displays a live frames-per-second reading.

Configuration, feedback & example

#### Resolved implementation

`AddFPSMeter`

#### Common configuration keys

`Height`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddFPSMeter({
    Id = "FPSMeter",
    Text = "FPS Meter",
})
```

### AddFeatureToggle

Layout & OtherWrapper→ AddToggle

[#](#feature-AddFeatureToggle)

Creates a setting-style feature toggle for switching state. This is a convenience wrapper implemented through AddToggle.

Configuration, feedback & example

#### Resolved implementation

`AddToggle`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ToggleChanged`

#### Example

```
local control = Section:AddFeatureToggle({
    Id = "FeatureToggle",
    Text = "Enabled",
    Default = true,
    Callback = function(value)
        print(value)
    end,
})
```

### AddFillDirectionSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddFillDirectionSelector)

Lets the user choose a value using the fill direction selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddFillDirectionSelector({
    Id = "FillDirectionSelector",
    Text = "Fill Direction Selector",
    Enum = Enum.EasingStyle,
})
```

### AddFilterChips

SelectorsWrapper→ AddChipGroup

[#](#feature-AddFilterChips)

Adds the Filter Chips UI feature to a section. This is a convenience wrapper implemented through AddChipGroup.

Configuration, feedback & example

#### Resolved implementation

`AddChipGroup`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ChipSelected`

#### Example

```
local control = Section:AddFilterChips({
    Id = "FilterChips",
    Text = "Filter Chips",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddFilterableTable

DataNative

[#](#feature-AddFilterableTable)

Displays or manages structured items using a filterable table.

Configuration, feedback & example

#### Resolved implementation

`AddFilterableTable`

#### Common configuration keys

`Rows`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddFilterableTable({
    Id = "FilterableTable",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddFloatInput

InputsWrapper→ AddNumberbox

[#](#feature-AddFloatInput)

Lets the user enter or edit a value using a float input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddFloatInput({
    Id = "FloatInput",
    Text = "Float Input",
})
```

### AddFocusTracker

Players & WorldWrapper→ AddLiveValue

[#](#feature-AddFocusTracker)

Adds the Focus Tracker UI feature to a section. This is a convenience wrapper implemented through AddLiveValue.

Configuration, feedback & example

#### Resolved implementation

`AddLiveValue`

#### Common configuration keys

`Default`, `Getter`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddFocusTracker({
    Id = "FocusTracker",
    Text = "Focus Tracker",
})
```

### AddFontPicker

SelectorsWrapper→ AddFontSelector

[#](#feature-AddFontPicker)

Lets the user choose a value using the font picker interface. This is a convenience wrapper implemented through AddFontSelector.

Configuration, feedback & example

#### Resolved implementation

`AddFontSelector`

#### Common configuration keys

`Callback`, `Display`, `Fonts`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddFontPicker({
    Id = "FontPicker",
    Text = "Font Picker",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddFontSelector

SelectorsNative

[#](#feature-AddFontSelector)

Lets the user choose a value using the font selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddFontSelector`

#### Common configuration keys

`Callback`, `Display`, `Fonts`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddFontSelector({
    Id = "FontSelector",
    Text = "Font Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddFontWeightSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddFontWeightSelector)

Lets the user choose a value using the font weight selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddFontWeightSelector({
    Id = "FontWeightSelector",
    Text = "Font Weight Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddFrameTime

Charts & LiveNative

[#](#feature-AddFrameTime)

Adds the Frame Time UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddFrameTime`

#### Common configuration keys

`Getter`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddFrameTime({
    Id = "FrameTime",
    Text = "Frame Time",
})
```

### AddGallery

Layout & OtherAlias→ AddImageGallery

[#](#feature-AddGallery)

Adds the Gallery UI feature to a section. This is a convenience alias implemented through AddImageGallery.

Configuration, feedback & example

#### Resolved implementation

`AddImageGallery`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddGallery({
    Id = "Gallery",
    Text = "Gallery",
})
```

### AddGauge

Charts & LiveAlias→ AddMeter

[#](#feature-AddGauge)

Displays a status or numeric measurement using a gauge. This is a convenience alias implemented through AddMeter.

Configuration, feedback & example

#### Resolved implementation

`AddMeter`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`, `Thresholds`

#### Callback fields

`Callback`

#### Feedback events

`MeterChanged`

#### Example

```
local control = Section:AddGauge({
    Id = "Gauge",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddGaugeChart

Charts & LiveWrapper→ AddMeter

[#](#feature-AddGaugeChart)

Displays data visually using a gauge chart. This is a convenience wrapper implemented through AddMeter.

Configuration, feedback & example

#### Resolved implementation

`AddMeter`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`, `Thresholds`

#### Callback fields

`Callback`

#### Feedback events

`MeterChanged`

#### Example

```
local control = Section:AddGaugeChart({
    Id = "GaugeChart",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddGradientEditor

InputsWrapper→ AddGradientPreview

[#](#feature-AddGradientEditor)

Lets the user enter or edit a value using a gradient editor control. This is a convenience wrapper implemented through AddGradientPreview.

Configuration, feedback & example

#### Resolved implementation

`AddGradientPreview`

#### Common configuration keys

`Colors`, `Height`, `Id`, `Rotation`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddGradientEditor({
    Id = "GradientEditor",
    Text = "Gradient Editor",
})
```

### AddGradientPreview

VisualsNative

[#](#feature-AddGradientPreview)

Displays information using a gradient preview.

Configuration, feedback & example

#### Resolved implementation

`AddGradientPreview`

#### Common configuration keys

`Colors`, `Height`, `Id`, `Rotation`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddGradientPreview({
    Id = "GradientPreview",
    Text = "Gradient Preview",
})
```

### AddGradientViewer

VisualsWrapper→ AddGradientPreview

[#](#feature-AddGradientViewer)

Displays information using a gradient viewer. This is a convenience wrapper implemented through AddGradientPreview.

Configuration, feedback & example

#### Resolved implementation

`AddGradientPreview`

#### Common configuration keys

`Colors`, `Height`, `Id`, `Rotation`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddGradientViewer({
    Id = "GradientViewer",
    Text = "Gradient Viewer",
})
```

### AddGridPicker

SelectorsAlias→ AddGridSelect

[#](#feature-AddGridPicker)

Lets the user choose a value using the grid picker interface. This is a convenience alias implemented through AddGridSelect.

Configuration, feedback & example

#### Resolved implementation

`AddGridSelect`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddGridPicker({
    Id = "GridPicker",
    Text = "Grid Picker",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddGridSelect

SelectorsNative

[#](#feature-AddGridSelect)

Lets the user choose a value using the grid select interface.

Configuration, feedback & example

#### Resolved implementation

`AddGridSelect`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddGridSelect({
    Id = "GridSelect",
    Text = "Grid Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddGroupBox

InputsNative

[#](#feature-AddGroupBox)

Lets the user enter or edit a value using a group box control.

Configuration, feedback & example

#### Resolved implementation

`AddGroupBox`

#### Common configuration keys

`Kind`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddGroupBox({
    Id = "GroupBox",
    Text = "Group Box",
})
```

### AddHeader

VisualsNative

[#](#feature-AddHeader)

Adds the Header UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddHeader`

#### Common configuration keys

`Color`, `Font`, `Height`, `TextSize`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddHeader({
    Id = "Header",
    Text = "Header",
})
```

### AddHealthBar

VisualsWrapper→ AddProgress

[#](#feature-AddHealthBar)

Adds the Health Bar UI feature to a section. This is a convenience wrapper implemented through AddProgress.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddHealthBar({
    Id = "HealthBar",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddHeartbeatIndicator

Charts & LiveWrapper→ AddStatus

[#](#feature-AddHeartbeatIndicator)

Displays a status or numeric measurement using a heartbeat indicator. This is a convenience wrapper implemented through AddStatus.

Configuration, feedback & example

#### Resolved implementation

`AddStatus`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`StatusChanged`

#### Example

```
local control = Section:AddHeartbeatIndicator({
    Id = "HeartbeatIndicator",
    Text = "Connection",
    Default = "Online",
})
```

### AddHeatmap

Charts & LiveNative

[#](#feature-AddHeatmap)

Displays a grid of values using low-to-high color intensity.

Configuration, feedback & example

#### Resolved implementation

`AddHeatmap`

#### Common configuration keys

`Callback`, `Height`, `HighColor`, `Id`, `LowColor`, `ShowValues`, `Text`, `Values`

#### Callback fields

`Callback`

#### Feedback events

`HeatmapCellPressed`

#### Example

```
local control = Section:AddHeatmap({
    Id = "Heatmap",
    Text = "Heatmap",
    Values = {
        {0.1, 0.5, 0.9},
        {0.8, 0.3, 0.6},
    },
})
```

### AddHero

VisualsWrapper→ AddCallout

[#](#feature-AddHero)

Adds the Hero UI feature to a section. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddHero({
    Id = "Hero",
    Text = "Hero",
})
```

### AddHexInput

InputsWrapper→ AddTextbox

[#](#feature-AddHexInput)

Lets the user enter or edit a value using a hex input control. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddHexInput({
    Id = "HexInput",
    Text = "Hex Input",
    Default = "Example text",
})
```

### AddHighContrastToggle

Layout & OtherWrapper→ AddToggle

[#](#feature-AddHighContrastToggle)

Creates a setting-style high contrast toggle for switching state. This is a convenience wrapper implemented through AddToggle.

Configuration, feedback & example

#### Resolved implementation

`AddToggle`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ToggleChanged`

#### Example

```
local control = Section:AddHighContrastToggle({
    Id = "HighContrastToggle",
    Text = "Enabled",
    Default = true,
    Callback = function(value)
        print(value)
    end,
})
```

### AddHistogram

Charts & LiveWrapper→ AddBarChart

[#](#feature-AddHistogram)

Displays data visually using a histogram. This is a convenience wrapper implemented through AddBarChart.

Configuration, feedback & example

#### Resolved implementation

`AddBarChart`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `Text`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddHistogram({
    Id = "Histogram",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddHistoryViewer

DataWrapper→ AddList

[#](#feature-AddHistoryViewer)

Displays information using a history viewer. This is a convenience wrapper implemented through AddList.

Configuration, feedback & example

#### Resolved implementation

`AddList`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `ItemHeight`, `Items`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`ListSelected`

#### Example

```
local control = Section:AddHistoryViewer({
    Id = "HistoryViewer",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddHoldButton

ActionsNative

[#](#feature-AddHoldButton)

Creates a hold button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddHoldButton`

#### Common configuration keys

`Accent`, `Callback`, `Color`, `Height`, `HoldTime`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`HoldCancelled`, `HoldCompleted`

#### Example

```
local control = Section:AddHoldButton({
    Id = "HoldButton",
    Text = "Hold Button",
})
```

### AddHotkeyHint

ActionsNative

[#](#feature-AddHotkeyHint)

Adds the Hotkey Hint UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddHotkeyHint`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddHotkeyHint({
    Id = "HotkeyHint",
    Text = "Hotkey Hint",
})
```

### AddIPAddressInput

InputsWrapper→ AddIPBox

[#](#feature-AddIPAddressInput)

Lets the user enter or edit a value using a ip address input control. This is a convenience wrapper implemented through AddIPBox.

Configuration, feedback & example

#### Resolved implementation

`AddIPBox`

#### Common configuration keys

`Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddIPAddressInput({
    Id = "IPressInput",
    Text = "IP Address Input",
    Default = "127.0.0.1",
})
```

### AddIPBox

InputsNative

[#](#feature-AddIPBox)

Lets the user enter or edit a value using a ip box control.

Configuration, feedback & example

#### Resolved implementation

`AddIPBox`

#### Common configuration keys

`Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddIPBox({
    Id = "IPBox",
    Text = "IP Box",
    Default = "127.0.0.1",
})
```

### AddIconButton

ActionsNative

[#](#feature-AddIconButton)

Creates a icon button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddIconButton`

#### Common configuration keys

`Callback`, `Color`, `Height`, `Icon`, `IconColor`, `IconSize`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`IconButtonPressed`

#### Example

```
local control = Section:AddIconButton({
    Id = "IconButton",
    Text = "Icon Button",
})
```

### AddIconLabel

VisualsWrapper→ AddLabel

[#](#feature-AddIconLabel)

Displays information using a icon label. This is a convenience wrapper implemented through AddLabel.

Configuration, feedback & example

#### Resolved implementation

`AddLabel`

#### Common configuration keys

`Alignment`, `Color`, `Font`, `Height`, `Id`, `RichText`, `Text`, `TextSize`, `VerticalAlignment`, `Wrapped`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddIconLabel({
    Id = "IconLabel",
    Text = "Icon Label",
})
```

### AddIconPicker

SelectorsWrapper→ AddImageSelect

[#](#feature-AddIconPicker)

Lets the user choose a value using the icon picker interface. This is a convenience wrapper implemented through AddImageSelect.

Configuration, feedback & example

#### Resolved implementation

`AddImageSelect`

#### Common configuration keys

`Callback`, `Height`, `Id`, `Items`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddIconPicker({
    Id = "IconPicker",
    Text = "Icon Picker",
})
```

### AddImage

VisualsNative

[#](#feature-AddImage)

Adds the Image UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddImage`

#### Common configuration keys

`BackgroundColor`, `BackgroundTransparency`, `Callback`, `Height`, `Id`, `Image`, `ImageColor`, `ImageTransparency`, `Radius`, `ScaleType`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ImageChanged`, `ImagePressed`

#### Example

```
local control = Section:AddImage({
    Id = "Image",
    Image = "rbxassetid://107844260625621",
    Height = 140,
})
```

### AddImageGallery

VisualsNative

[#](#feature-AddImageGallery)

Adds the Image Gallery UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddImageGallery`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddImageGallery({
    Id = "ImageGallery",
    Text = "Image Gallery",
})
```

### AddImageSelect

SelectorsNative

[#](#feature-AddImageSelect)

Lets the user choose a value using the image select interface.

Configuration, feedback & example

#### Resolved implementation

`AddImageSelect`

#### Common configuration keys

`Callback`, `Height`, `Id`, `Items`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddImageSelect({
    Id = "ImageSelect",
    Text = "Image Select",
})
```

### AddImages

VisualsAlias→ AddImageGallery

[#](#feature-AddImages)

Adds the Images UI feature to a section. This is a convenience alias implemented through AddImageGallery.

Configuration, feedback & example

#### Resolved implementation

`AddImageGallery`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddImages({
    Id = "Images",
    Text = "Images",
})
```

### AddInfo

Layout & OtherAlias→ AddCallout

[#](#feature-AddInfo)

Adds the Info UI feature to a section. This is a convenience alias implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddInfo({
    Id = "Info",
    Text = "Info",
})
```

### AddInfoCard

VisualsWrapper→ AddCallout

[#](#feature-AddInfoCard)

Displays information using a info card. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddInfoCard({
    Id = "InfoCard",
    Text = "Info Card",
})
```

### AddInlineEdit

Layout & OtherWrapper→ AddTextbox

[#](#feature-AddInlineEdit)

Adds the Inline Edit UI feature to a section. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddInlineEdit({
    Id = "InlineEdit",
    Text = "Inline Edit",
    Default = "Example text",
})
```

### AddInput

InputsAlias→ AddTextbox

[#](#feature-AddInput)

Lets the user enter or edit a value using a input control. This is a convenience alias implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddInput({
    Id = "Input",
    Text = "Input",
    Default = "Example text",
})
```

### AddInputMonitor

InputsWrapper→ AddLogConsole

[#](#feature-AddInputMonitor)

Lets the user enter or edit a value using a input monitor control. This is a convenience wrapper implemented through AddLogConsole.

Configuration, feedback & example

#### Resolved implementation

`AddLogConsole`

#### Common configuration keys

`BackgroundColor`, `Height`, `Id`, `MaxLines`, `RichText`, `Text`, `TextColor`, `TextSize`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`LogAdded`

#### Example

```
local console = Section:AddInputMonitor({
    Id = "InputMonitor",
    Text = "Console",
    Height = 160,
})

-- Depending on the returned handle, use its runtime methods
-- to append/update console content.
```

### AddInputTypeSelector

InputsWrapper→ AddEnumSelector

[#](#feature-AddInputTypeSelector)

Lets the user choose a value using the input type selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddInputTypeSelector({
    Id = "InputTypeSelector",
    Text = "Input Type Selector",
    Enum = Enum.EasingStyle,
})
```

### AddInspector

DataWrapper→ AddPropertyGrid

[#](#feature-AddInspector)

Adds the Inspector UI feature to a section. This is a convenience wrapper implemented through AddPropertyGrid.

Configuration, feedback & example

#### Resolved implementation

`AddPropertyGrid`

#### Common configuration keys

`Default`, `Height`, `Id`, `Properties`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`PropertyChanged`

#### Example

```
local control = Section:AddInspector({
    Id = "Inspector",
    Text = "Inspector",
})
```

### AddInstanceInfo

Players & WorldNative

[#](#feature-AddInstanceInfo)

Adds the Instance Info UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddInstanceInfo`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Instance`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`InstanceChanged`

#### Example

```
local control = Section:AddInstanceInfo({
    Id = "InstanceInfo",
    Text = "Instance Info",
})
```

### AddInstanceMultiSelect

SelectorsNative→ AddMultiDropdown

[#](#feature-AddInstanceMultiSelect)

Lets the user choose a value using the instance multi select interface.

Configuration, feedback & example

#### Resolved implementation

`AddMultiDropdown`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MultiDropdownChanged`

#### Example

```
local control = Section:AddInstanceMultiSelect({
    Id = "InstanceMultiSelect",
    Text = "Instance Multi Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = {"Alpha"},
})
```

### AddInstanceSelector

SelectorsNative→ AddDropdown

[#](#feature-AddInstanceSelector)

Lets the user choose a value using the instance selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddInstanceSelector({
    Id = "InstanceSelector",
    Text = "Instance Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddIntegerInput

InputsWrapper→ AddNumberbox

[#](#feature-AddIntegerInput)

Lets the user enter or edit a value using a integer input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddIntegerInput({
    Id = "IntegerInput",
    Text = "Integer Input",
})
```

### AddInventoryGrid

DataWrapper→ AddGridSelect

[#](#feature-AddInventoryGrid)

Displays or manages structured items using a inventory grid. This is a convenience wrapper implemented through AddGridSelect.

Configuration, feedback & example

#### Resolved implementation

`AddGridSelect`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddInventoryGrid({
    Id = "InventoryGrid",
    Text = "Inventory Grid",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddJSONViewer

Layout & OtherWrapper→ AddCodeBox

[#](#feature-AddJSONViewer)

Displays information using a json viewer. This is a convenience wrapper implemented through AddCodeBox.

Configuration, feedback & example

#### Resolved implementation

`AddCodeBox`

#### Common configuration keys

`Height`, `Monospace`, `MultiLine`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddJSONViewer({
    Id = "JSONViewer",
    Text = "JSON Viewer",
    Default = "Example text",
})
```

### AddKPI

Charts & LiveWrapper→ AddStatCard

[#](#feature-AddKPI)

Adds the KPI UI feature to a section. This is a convenience wrapper implemented through AddStatCard.

Configuration, feedback & example

#### Resolved implementation

`AddStatCard`

#### Common configuration keys

`Callback`, `Color`, `Default`, `DeltaColor`, `DeltaText`, `Height`, `Id`, `Prefix`, `Suffix`, `Text`, `Value`, `ValueSize`

#### Callback fields

`Callback`

#### Feedback events

`StatChanged`

#### Example

```
local control = Section:AddKPI({
    Id = "KPI",
    Text = "Score",
    Default = 125,
    DeltaText = "+12%",
})
```

### AddKanban

DataNative

[#](#feature-AddKanban)

Adds the Kanban UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddKanban`

#### Common configuration keys

`Columns`, `Height`, `Id`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddKanban({
    Id = "Kanban",
    Text = "Kanban",
})
```

### AddKeyCodeViewer

Players & WorldWrapper→ AddKeyValue

[#](#feature-AddKeyCodeViewer)

Displays information using a key code viewer. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddKeyCodeViewer({
    Id = "KeyCodeViewer",
    Text = "Key Code Viewer",
})
```

### AddKeySelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddKeySelector)

Lets the user choose a value using the key selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddKeySelector({
    Id = "KeySelector",
    Text = "Key Selector",
    Enum = Enum.EasingStyle,
})
```

### AddKeyValue

Layout & OtherNative

[#](#feature-AddKeyValue)

Adds the Key Value UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddKeyValue({
    Id = "KeyValue",
    Text = "Key Value",
})
```

### AddKeybind

ActionsNative

[#](#feature-AddKeybind)

Lets the user choose a keyboard or mouse binding and can fire a callback when that binding is pressed.

Configuration, feedback & example

#### Resolved implementation

`AddKeybind`

#### Common configuration keys

`AllowMouse`, `Callback`, `Changed`, `Default`, `Height`, `Id`, `IgnoreWhileTyping`, `Text`

#### Callback fields

`Callback`, `Changed`

#### Feedback events

`KeybindChanged`, `KeybindTriggered`

#### Example

```
local control = Section:AddKeybind({
    Id = "Keybind",
    Text = "Action key",
    Default = Enum.KeyCode.G,
    Callback = function(key)
        print("Pressed", key)
    end,
})
```

### AddKeyboardTester

Players & WorldWrapper→ AddKeybind

[#](#feature-AddKeyboardTester)

Displays or manages structured items using a keyboard tester. This is a convenience wrapper implemented through AddKeybind.

Configuration, feedback & example

#### Resolved implementation

`AddKeybind`

#### Common configuration keys

`AllowMouse`, `Callback`, `Changed`, `Default`, `Height`, `Id`, `IgnoreWhileTyping`, `Text`

#### Callback fields

`Callback`, `Changed`

#### Feedback events

`KeybindChanged`, `KeybindTriggered`

#### Example

```
local control = Section:AddKeyboardTester({
    Id = "KeyboardTester",
    Text = "Action key",
    Default = Enum.KeyCode.G,
    Callback = function(key)
        print("Pressed", key)
    end,
})
```

### AddLabel

VisualsNative

[#](#feature-AddLabel)

Displays information using a label.

Configuration, feedback & example

#### Resolved implementation

`AddLabel`

#### Common configuration keys

`Alignment`, `Color`, `Font`, `Height`, `Id`, `RichText`, `Text`, `TextSize`, `VerticalAlignment`, `Wrapped`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLabel({
    Id = "Label",
    Text = "Label",
})
```

### AddLabeledValue

VisualsWrapper→ AddKeyValue

[#](#feature-AddLabeledValue)

Displays information using a labeled value. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddLabeledValue({
    Id = "LabeledValue",
    Text = "Labeled Value",
})
```

### AddLanguage

SelectorsAlias→ AddLanguageSelector

[#](#feature-AddLanguage)

Adds the Language UI feature to a section. This is a convenience alias implemented through AddLanguageSelector.

Configuration, feedback & example

#### Resolved implementation

`AddLanguageSelector`

#### Common configuration keys

`AutoSelectFirst`, `Callback`, `CloseOnSelect`, `Default`, `EmptyText`, `FocusSearchOnOpen`, `Height`, `Id`, `ItemHeight`, `Languages`, `MaxHeight`, `Options`, `Placeholder`, `Search`, `SearchPlaceholder`, `ShowCode`, `ShowNativeName`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`LanguageChanged`, `LanguageListChanged`

#### Example

```
local control = Section:AddLanguage({
    Id = "Language",
    Text = "Language",
    Default = "en",
    Languages = {
        {Name = "English", Code = "en", NativeName = "English"},
        {Name = "Spanish", Code = "es", NativeName = "Español"},
        {Name = "Japanese", Code = "ja", NativeName = "日本語"},
    },
})
```

### AddLanguagePicker

SelectorsWrapper→ AddLanguageSelector

[#](#feature-AddLanguagePicker)

Lets the user choose a value using the language picker interface. This is a convenience wrapper implemented through AddLanguageSelector.

Configuration, feedback & example

#### Resolved implementation

`AddLanguageSelector`

#### Common configuration keys

`AutoSelectFirst`, `Callback`, `CloseOnSelect`, `Default`, `EmptyText`, `FocusSearchOnOpen`, `Height`, `Id`, `ItemHeight`, `Languages`, `MaxHeight`, `Options`, `Placeholder`, `Search`, `SearchPlaceholder`, `ShowCode`, `ShowNativeName`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`LanguageChanged`, `LanguageListChanged`

#### Example

```
local control = Section:AddLanguagePicker({
    Id = "LanguagePicker",
    Text = "Language",
    Default = "en",
    Languages = {
        {Name = "English", Code = "en", NativeName = "English"},
        {Name = "Spanish", Code = "es", NativeName = "Español"},
        {Name = "Japanese", Code = "ja", NativeName = "日本語"},
    },
})
```

### AddLanguageSelect

SelectorsAlias→ AddLanguageSelector

[#](#feature-AddLanguageSelect)

Lets the user choose a value using the language select interface. This is a convenience alias implemented through AddLanguageSelector.

Configuration, feedback & example

#### Resolved implementation

`AddLanguageSelector`

#### Common configuration keys

`AutoSelectFirst`, `Callback`, `CloseOnSelect`, `Default`, `EmptyText`, `FocusSearchOnOpen`, `Height`, `Id`, `ItemHeight`, `Languages`, `MaxHeight`, `Options`, `Placeholder`, `Search`, `SearchPlaceholder`, `ShowCode`, `ShowNativeName`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`LanguageChanged`, `LanguageListChanged`

#### Example

```
local control = Section:AddLanguageSelect({
    Id = "LanguageSelect",
    Text = "Language",
    Default = "en",
    Languages = {
        {Name = "English", Code = "en", NativeName = "English"},
        {Name = "Spanish", Code = "es", NativeName = "Español"},
        {Name = "Japanese", Code = "ja", NativeName = "日本語"},
    },
})
```

### AddLanguageSelector

SelectorsNative

[#](#feature-AddLanguageSelector)

Shows a searchable list of languages. Entries can be simple strings or richer tables with Name, Code, NativeName, and Image.

Configuration, feedback & example

#### Resolved implementation

`AddLanguageSelector`

#### Common configuration keys

`AutoSelectFirst`, `Callback`, `CloseOnSelect`, `Default`, `EmptyText`, `FocusSearchOnOpen`, `Height`, `Id`, `ItemHeight`, `Languages`, `MaxHeight`, `Options`, `Placeholder`, `Search`, `SearchPlaceholder`, `ShowCode`, `ShowNativeName`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`LanguageChanged`, `LanguageListChanged`

#### Example

```
local control = Section:AddLanguageSelector({
    Id = "LanguageSelector",
    Text = "Language",
    Default = "en",
    Languages = {
        {Name = "English", Code = "en", NativeName = "English"},
        {Name = "Spanish", Code = "es", NativeName = "Español"},
        {Name = "Japanese", Code = "ja", NativeName = "日本語"},
    },
})
```

### AddLatitudeInput

InputsWrapper→ AddSlider

[#](#feature-AddLatitudeInput)

Lets the user enter or edit a value using a latitude input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddLatitudeInput({
    Id = "LatitudeInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddLeaderboard

DataNative

[#](#feature-AddLeaderboard)

Displays or manages structured items using a leaderboard.

Configuration, feedback & example

#### Resolved implementation

`AddLeaderboard`

#### Common configuration keys

`Columns`, `Rows`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLeaderboard({
    Id = "Leaderboard",
    Text = "Leaderboard",
})
```

### AddLineChart

Charts & LiveNative

[#](#feature-AddLineChart)

Draws a simple line-style chart from numeric values.

Configuration, feedback & example

#### Resolved implementation

`AddLineChart`

#### Common configuration keys

`Height`, `Thickness`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLineChart({
    Id = "LineChart",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddLineGraph

Charts & LiveWrapper→ AddLineChart

[#](#feature-AddLineGraph)

Displays data visually using a line graph. This is a convenience wrapper implemented through AddLineChart.

Configuration, feedback & example

#### Resolved implementation

`AddLineChart`

#### Common configuration keys

`Height`, `Thickness`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLineGraph({
    Id = "LineGraph",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddList

DataNative

[#](#feature-AddList)

Displays or manages structured items using a list.

Configuration, feedback & example

#### Resolved implementation

`AddList`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `ItemHeight`, `Items`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`ListSelected`

#### Example

```
local control = Section:AddList({
    Id = "List",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddListEditor

InputsAlias→ AddEditableList

[#](#feature-AddListEditor)

Lets the user enter or edit a value using a list editor control. This is a convenience alias implemented through AddEditableList.

Configuration, feedback & example

#### Resolved implementation

`AddEditableList`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddListEditor({
    Id = "ListEditor",
    Text = "List Editor",
})
```

### AddLive

Charts & LiveAlias→ AddLiveValue

[#](#feature-AddLive)

Adds the Live UI feature to a section. This is a convenience alias implemented through AddLiveValue.

Configuration, feedback & example

#### Resolved implementation

`AddLiveValue`

#### Common configuration keys

`Default`, `Getter`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLive({
    Id = "Live",
    Text = "Live",
})
```

### AddLiveNumber

SelectorsWrapper→ AddLiveValue

[#](#feature-AddLiveNumber)

Adds the Live Number UI feature to a section. This is a convenience wrapper implemented through AddLiveValue.

Configuration, feedback & example

#### Resolved implementation

`AddLiveValue`

#### Common configuration keys

`Default`, `Getter`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLiveNumber({
    Id = "LiveNumber",
    Text = "Live Number",
})
```

### AddLiveProgress

Charts & LiveWrapper→ AddProgress

[#](#feature-AddLiveProgress)

Displays a status or numeric measurement using a live progress. This is a convenience wrapper implemented through AddProgress.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddLiveProgress({
    Id = "LiveProgress",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddLiveText

Charts & LiveWrapper→ AddLiveValue

[#](#feature-AddLiveText)

Adds the Live Text UI feature to a section. This is a convenience wrapper implemented through AddLiveValue.

Configuration, feedback & example

#### Resolved implementation

`AddLiveValue`

#### Common configuration keys

`Default`, `Getter`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLiveText({
    Id = "LiveText",
    Text = "Live Text",
})
```

### AddLiveValue

Charts & LiveNative

[#](#feature-AddLiveValue)

Adds the Live Value UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddLiveValue`

#### Common configuration keys

`Default`, `Getter`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLiveValue({
    Id = "LiveValue",
    Text = "Live Value",
})
```

### AddLoadingBar

Charts & LiveWrapper→ AddProgress

[#](#feature-AddLoadingBar)

Adds the Loading Bar UI feature to a section. This is a convenience wrapper implemented through AddProgress.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddLoadingBar({
    Id = "LoadingBar",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddLoadingSpinner

InputsNative

[#](#feature-AddLoadingSpinner)

Adds the Loading Spinner UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddLoadingSpinner`

#### Common configuration keys

`Color`, `Height`, `Id`, `Running`, `Size`, `Speed`, `Symbol`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLoadingSpinner({
    Id = "LoadingSpinner",
    Text = "Loading Spinner",
})
```

### AddLogConsole

DataNative

[#](#feature-AddLogConsole)

Displays log lines in a console-style panel and supports adding more lines at runtime.

Configuration, feedback & example

#### Resolved implementation

`AddLogConsole`

#### Common configuration keys

`BackgroundColor`, `Height`, `Id`, `MaxLines`, `RichText`, `Text`, `TextColor`, `TextSize`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`LogAdded`

#### Example

```
local console = Section:AddLogConsole({
    Id = "LogConsole",
    Text = "Console",
    Height = 160,
})

-- Depending on the returned handle, use its runtime methods
-- to append/update console content.
```

### AddLongitudeInput

InputsWrapper→ AddSlider

[#](#feature-AddLongitudeInput)

Lets the user enter or edit a value using a longitude input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddLongitudeInput({
    Id = "LongitudeInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddLuaTableViewer

DataWrapper→ AddCodeBox

[#](#feature-AddLuaTableViewer)

Displays or manages structured items using a lua table viewer. This is a convenience wrapper implemented through AddCodeBox.

Configuration, feedback & example

#### Resolved implementation

`AddCodeBox`

#### Common configuration keys

`Height`, `Monospace`, `MultiLine`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddLuaTableViewer({
    Id = "LuaTableViewer",
    Text = "Lua Table Viewer",
    Default = "Example text",
})
```

### AddMarquee

Charts & LiveWrapper→ AddLabel

[#](#feature-AddMarquee)

Adds the Marquee UI feature to a section. This is a convenience wrapper implemented through AddLabel.

Configuration, feedback & example

#### Resolved implementation

`AddLabel`

#### Common configuration keys

`Alignment`, `Color`, `Font`, `Height`, `Id`, `RichText`, `Text`, `TextSize`, `VerticalAlignment`, `Wrapped`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddMarquee({
    Id = "Marquee",
    Text = "Marquee",
})
```

### AddMaskedInput

InputsWrapper→ AddPasswordBox

[#](#feature-AddMaskedInput)

Lets the user enter or edit a value using a masked input control. This is a convenience wrapper implemented through AddPasswordBox.

Configuration, feedback & example

#### Resolved implementation

`AddPasswordBox`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaskCharacter`, `Placeholder`, `Revealed`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PasswordChanged`

#### Example

```
local control = Section:AddMaskedInput({
    Id = "MaskedInput",
    Text = "Masked Input",
    Default = "Example text",
})
```

### AddMaterialPreview

VisualsWrapper→ AddViewportModel

[#](#feature-AddMaterialPreview)

Displays information using a material preview. This is a convenience wrapper implemented through AddViewportModel.

Configuration, feedback & example

#### Resolved implementation

`AddViewportModel`

#### Common configuration keys

`Ambient`, `AutoRotate`, `BackgroundColor`, `Callback`, `Height`, `Id`, `LightColor`, `LightDirection`, `Model`, `RotationSpeed`, `Text`, `Zoom`

#### Callback fields

`Callback`

#### Feedback events

`ViewportModelChanged`

#### Example

```
local control = Section:AddMaterialPreview({
    Id = "MaterialPreview",
    Text = "3D Preview",
    Model = workspace:FindFirstChild("MyModel"),
    Height = 180,
    AutoRotate = true,
})
```

### AddMaterialSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddMaterialSelector)

Lets the user choose a value using the material selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddMaterialSelector({
    Id = "MaterialSelector",
    Text = "Material Selector",
    Enum = Enum.EasingStyle,
})
```

### AddMatrix

DataWrapper→ AddTable

[#](#feature-AddMatrix)

Adds the Matrix UI feature to a section. This is a convenience wrapper implemented through AddTable.

Configuration, feedback & example

#### Resolved implementation

`AddTable`

#### Common configuration keys

`Callback`, `Columns`, `Height`, `Id`, `RowHeight`, `Rows`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TableRowSelected`

#### Example

```
local control = Section:AddMatrix({
    Id = "Matrix",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddMemoryMeter

Charts & LiveNative

[#](#feature-AddMemoryMeter)

Displays a live client memory reading.

Configuration, feedback & example

#### Resolved implementation

`AddMemoryMeter`

#### Common configuration keys

`Height`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddMemoryMeter({
    Id = "MemoryMeter",
    Text = "Memory Meter",
})
```

### AddMeter

Charts & LiveNative

[#](#feature-AddMeter)

Displays a status or numeric measurement using a meter.

Configuration, feedback & example

#### Resolved implementation

`AddMeter`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`, `Thresholds`

#### Callback fields

`Callback`

#### Feedback events

`MeterChanged`

#### Example

```
local control = Section:AddMeter({
    Id = "Meter",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddMetricCard

VisualsWrapper→ AddStatCard

[#](#feature-AddMetricCard)

Displays information using a metric card. This is a convenience wrapper implemented through AddStatCard.

Configuration, feedback & example

#### Resolved implementation

`AddStatCard`

#### Common configuration keys

`Callback`, `Color`, `Default`, `DeltaColor`, `DeltaText`, `Height`, `Id`, `Prefix`, `Suffix`, `Text`, `Value`, `ValueSize`

#### Callback fields

`Callback`

#### Feedback events

`StatChanged`

#### Example

```
local control = Section:AddMetricCard({
    Id = "MetricCard",
    Text = "Score",
    Default = 125,
    DeltaText = "+12%",
})
```

### AddMiniBarChart

Charts & LiveWrapper→ AddBarChart

[#](#feature-AddMiniBarChart)

Displays data visually using a mini bar chart. This is a convenience wrapper implemented through AddBarChart.

Configuration, feedback & example

#### Resolved implementation

`AddBarChart`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `Text`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddMiniBarChart({
    Id = "MiniBarChart",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddMiniGraph

Charts & LiveWrapper→ AddSparkline

[#](#feature-AddMiniGraph)

Displays data visually using a mini graph. This is a convenience wrapper implemented through AddSparkline.

Configuration, feedback & example

#### Resolved implementation

`AddSparkline`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `MaxPoints`, `Text`, `Thickness`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddMiniGraph({
    Id = "MiniGraph",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddMiniProgress

Charts & LiveWrapper→ AddProgress

[#](#feature-AddMiniProgress)

Displays a status or numeric measurement using a mini progress. This is a convenience wrapper implemented through AddProgress.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddMiniProgress({
    Id = "MiniProgress",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddMiniTabs

Layout & OtherNative

[#](#feature-AddMiniTabs)

Creates a small nested tab interface inside a section.

Configuration, feedback & example

#### Resolved implementation

`AddMiniTabs`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Tabs`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MiniTabChanged`

#### Example

```
local control = Section:AddMiniTabs({
    Id = "MiniTabs",
    Text = "Mini Tabs",
})
```

### AddModalButton

ActionsNative→ AddButton

[#](#feature-AddModalButton)

Creates a modal button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddButton`

#### Common configuration keys

`Callback`, `Color`, `Font`, `Height`, `HoverColor`, `Id`, `Radius`, `Stroke`, `Text`, `TextColor`, `TextSize`

#### Callback fields

`Callback`

#### Feedback events

`ButtonPressed`

#### Example

```
local control = Section:AddModalButton({
    Id = "ModalButton",
    Text = "Click me",
    Callback = function()
        print("Pressed")
    end,
})
```

### AddModeSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddModeSelector)

Lets the user choose a value using the mode selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddModeSelector({
    Id = "ModeSelector",
    Text = "Mode Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddModelPreview

VisualsWrapper→ AddViewportModel

[#](#feature-AddModelPreview)

Displays information using a model preview. This is a convenience wrapper implemented through AddViewportModel.

Configuration, feedback & example

#### Resolved implementation

`AddViewportModel`

#### Common configuration keys

`Ambient`, `AutoRotate`, `BackgroundColor`, `Callback`, `Height`, `Id`, `LightColor`, `LightDirection`, `Model`, `RotationSpeed`, `Text`, `Zoom`

#### Callback fields

`Callback`

#### Feedback events

`ViewportModelChanged`

#### Example

```
local control = Section:AddModelPreview({
    Id = "ModelPreview",
    Text = "3D Preview",
    Model = workspace:FindFirstChild("MyModel"),
    Height = 180,
    AutoRotate = true,
})
```

### AddMonthSelector

SelectorsNative→ AddDropdown

[#](#feature-AddMonthSelector)

Lets the user choose a value using the month selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddMonthSelector({
    Id = "MonthSelector",
    Text = "Month Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddMouseButtonSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddMouseButtonSelector)

Creates a mouse button selector action that the user can press. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddMouseButtonSelector({
    Id = "MouseButtonSelector",
    Text = "Mouse Button Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddMouseTester

Players & WorldWrapper→ AddKeybind

[#](#feature-AddMouseTester)

Adds the Mouse Tester UI feature to a section. This is a convenience wrapper implemented through AddKeybind.

Configuration, feedback & example

#### Resolved implementation

`AddKeybind`

#### Common configuration keys

`AllowMouse`, `Callback`, `Changed`, `Default`, `Height`, `Id`, `IgnoreWhileTyping`, `Text`

#### Callback fields

`Callback`, `Changed`

#### Feedback events

`KeybindChanged`, `KeybindTriggered`

#### Example

```
local control = Section:AddMouseTester({
    Id = "MouseTester",
    Text = "Action key",
    Default = Enum.KeyCode.G,
    Callback = function(key)
        print("Pressed", key)
    end,
})
```

### AddMultiDropdown

SelectorsNative

[#](#feature-AddMultiDropdown)

Lets the user choose more than one option from the same list.

Configuration, feedback & example

#### Resolved implementation

`AddMultiDropdown`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MultiDropdownChanged`

#### Example

```
local control = Section:AddMultiDropdown({
    Id = "MultiDropdown",
    Text = "Multi Dropdown",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = {"Alpha"},
})
```

### AddMultiSelect

SelectorsAlias→ AddMultiDropdown

[#](#feature-AddMultiSelect)

Lets the user choose a value using the multi select interface. This is a convenience alias implemented through AddMultiDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddMultiDropdown`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MultiDropdownChanged`

#### Example

```
local control = Section:AddMultiSelect({
    Id = "MultiSelect",
    Text = "Multi Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = {"Alpha"},
})
```

### AddMultilineBox

InputsWrapper→ AddTextbox

[#](#feature-AddMultilineBox)

Lets the user enter or edit a value using a multiline box control. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddMultilineBox({
    Id = "MultilineBox",
    Text = "Multiline Box",
    Default = "Example text",
})
```

### AddNavigationList

DataWrapper→ AddList

[#](#feature-AddNavigationList)

Displays or manages structured items using a navigation list. This is a convenience wrapper implemented through AddList.

Configuration, feedback & example

#### Resolved implementation

`AddList`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `ItemHeight`, `Items`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`ListSelected`

#### Example

```
local control = Section:AddNavigationList({
    Id = "NavigationList",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddNestedTabs

Layout & OtherWrapper→ AddMiniTabs

[#](#feature-AddNestedTabs)

Organizes UI content using a nested tabs layout/control. This is a convenience wrapper implemented through AddMiniTabs.

Configuration, feedback & example

#### Resolved implementation

`AddMiniTabs`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Tabs`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MiniTabChanged`

#### Example

```
local control = Section:AddNestedTabs({
    Id = "NestedTabs",
    Text = "Nested Tabs",
})
```

### AddNotificationFeed

DataNative

[#](#feature-AddNotificationFeed)

Displays a list of notification-style entries.

Configuration, feedback & example

#### Resolved implementation

`AddNotificationFeed`

#### Common configuration keys

`Height`, `Id`, `ItemHeight`, `Items`, `MaxItems`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`FeedItemAdded`

#### Example

```
local control = Section:AddNotificationFeed({
    Id = "NotificationFeed",
    Text = "Notification Feed",
})
```

### AddNotificationsList

DataWrapper→ AddNotificationFeed

[#](#feature-AddNotificationsList)

Displays or manages structured items using a notifications list. This is a convenience wrapper implemented through AddNotificationFeed.

Configuration, feedback & example

#### Resolved implementation

`AddNotificationFeed`

#### Common configuration keys

`Height`, `Id`, `ItemHeight`, `Items`, `MaxItems`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`FeedItemAdded`

#### Example

```
local control = Section:AddNotificationsList({
    Id = "NotificationsList",
    Text = "Notifications List",
})
```

### AddNudgeControl

Layout & OtherWrapper→ AddStepper

[#](#feature-AddNudgeControl)

Adds the Nudge Control UI feature to a section. This is a convenience wrapper implemented through AddStepper.

Configuration, feedback & example

#### Resolved implementation

`AddStepper`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`StepperChanged`

#### Example

```
local control = Section:AddNudgeControl({
    Id = "NudgeControl",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddNumberCard

VisualsWrapper→ AddStatCard

[#](#feature-AddNumberCard)

Displays information using a number card. This is a convenience wrapper implemented through AddStatCard.

Configuration, feedback & example

#### Resolved implementation

`AddStatCard`

#### Common configuration keys

`Callback`, `Color`, `Default`, `DeltaColor`, `DeltaText`, `Height`, `Id`, `Prefix`, `Suffix`, `Text`, `Value`, `ValueSize`

#### Callback fields

`Callback`

#### Feedback events

`StatChanged`

#### Example

```
local control = Section:AddNumberCard({
    Id = "NumberCard",
    Text = "Score",
    Default = 125,
    DeltaText = "+12%",
})
```

### AddNumberInput

InputsAlias→ AddNumberbox

[#](#feature-AddNumberInput)

Lets the user enter or edit a value using a number input control. This is a convenience alias implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddNumberInput({
    Id = "NumberInput",
    Text = "Number Input",
})
```

### AddNumberRangeInput

InputsNative

[#](#feature-AddNumberRangeInput)

Lets the user enter or edit a value using a number range input control.

Configuration, feedback & example

#### Resolved implementation

`AddNumberRangeInput`

#### Common configuration keys

`Callback`, `Default`, `Id`, `Max`, `Min`, `Step`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddNumberRangeInput({
    Id = "NumberRangeInput",
    Text = "Number Range Input",
})
```

### AddNumberbox

InputsNative

[#](#feature-AddNumberbox)

Lets the user enter or edit a value using a numberbox control.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddNumberbox({
    Id = "Numberbox",
    Text = "Numberbox",
})
```

### AddOTPInput

InputsWrapper→ AddNumberbox

[#](#feature-AddOTPInput)

Lets the user enter or edit a value using a otp input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddOTPInput({
    Id = "OTPInput",
    Text = "OTP Input",
})
```

### AddObjectPath

Players & WorldWrapper→ AddKeyValue

[#](#feature-AddObjectPath)

Adds the Object Path UI feature to a section. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddObjectPath({
    Id = "ObjectPath",
    Text = "Object Path",
})
```

### AddOnOffSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddOnOffSelector)

Lets the user choose a value using the on off selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddOnOffSelector({
    Id = "OnOffSelector",
    Text = "On Off Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddOpacityInput

InputsWrapper→ AddSlider

[#](#feature-AddOpacityInput)

Lets the user enter or edit a value using a opacity input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddOpacityInput({
    Id = "OpacityInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddOperatorSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddOperatorSelector)

Lets the user choose a value using the operator selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddOperatorSelector({
    Id = "OperatorSelector",
    Text = "Operator Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddOrientationSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddOrientationSelector)

Lets the user choose a value using the orientation selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddOrientationSelector({
    Id = "OrientationSelector",
    Text = "Orientation Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddPINInput

InputsWrapper→ AddNumberbox

[#](#feature-AddPINInput)

Lets the user enter or edit a value using a pin input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPINInput({
    Id = "PINInput",
    Text = "PIN Input",
})
```

### AddPageHeader

VisualsWrapper→ AddCallout

[#](#feature-AddPageHeader)

Adds the Page Header UI feature to a section. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPageHeader({
    Id = "PageHeader",
    Text = "Page Header",
})
```

### AddPageSizeSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddPageSizeSelector)

Lets the user choose a value using the page size selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddPageSizeSelector({
    Id = "PageSizeSelector",
    Text = "Page Size Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddPagination

Layout & OtherNative

[#](#feature-AddPagination)

Adds the Pagination UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddPagination`

#### Common configuration keys

`Callback`, `Default`, `Format`, `Height`, `Id`, `Pages`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PageChanged`

#### Example

```
local control = Section:AddPagination({
    Id = "Pagination",
    Text = "Pagination",
})
```

### AddPaletteEditor

InputsWrapper→ AddColorSwatches

[#](#feature-AddPaletteEditor)

Lets the user enter or edit a value using a palette editor control. This is a convenience wrapper implemented through AddColorSwatches.

Configuration, feedback & example

#### Resolved implementation

`AddColorSwatches`

#### Common configuration keys

`Callback`, `Colors`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SwatchChanged`

#### Example

```
local control = Section:AddPaletteEditor({
    Id = "PaletteEditor",
    Text = "Palette Editor",
})
```

### AddPanel

Layout & OtherNative

[#](#feature-AddPanel)

Organizes UI content using a panel layout/control.

Configuration, feedback & example

#### Resolved implementation

`AddPanel`

#### Common configuration keys

`Kind`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPanel({
    Id = "Panel",
    Text = "Panel",
})
```

### AddParagraph

VisualsNative

[#](#feature-AddParagraph)

Displays data visually using a paragraph.

Configuration, feedback & example

#### Resolved implementation

`AddParagraph`

#### Common configuration keys

`Height`, `VerticalAlignment`, `Wrapped`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddParagraph({
    Id = "Paragraph",
    Text = "Paragraph",
})
```

### AddPasswordBox

InputsNative

[#](#feature-AddPasswordBox)

Lets the user enter or edit a value using a password box control.

Configuration, feedback & example

#### Resolved implementation

`AddPasswordBox`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaskCharacter`, `Placeholder`, `Revealed`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PasswordChanged`

#### Example

```
local control = Section:AddPasswordBox({
    Id = "PasswordBox",
    Text = "Password Box",
    Default = "Example text",
})
```

### AddPasswordInput

InputsWrapper→ AddPasswordBox

[#](#feature-AddPasswordInput)

Lets the user enter or edit a value using a password input control. This is a convenience wrapper implemented through AddPasswordBox.

Configuration, feedback & example

#### Resolved implementation

`AddPasswordBox`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaskCharacter`, `Placeholder`, `Revealed`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PasswordChanged`

#### Example

```
local control = Section:AddPasswordInput({
    Id = "PasswordInput",
    Text = "Password Input",
    Default = "Example text",
})
```

### AddPatternInput

InputsWrapper→ AddTextbox

[#](#feature-AddPatternInput)

Lets the user enter or edit a value using a pattern input control. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddPatternInput({
    Id = "PatternInput",
    Text = "Pattern Input",
    Default = "Example text",
})
```

### AddPercentInput

InputsNative

[#](#feature-AddPercentInput)

Lets the user enter or edit a value using a percent input control.

Configuration, feedback & example

#### Resolved implementation

`AddPercentInput`

#### Common configuration keys

`Default`, `Max`, `Min`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPercentInput({
    Id = "PercentInput",
    Text = "Percent Input",
    Default = 50,
})
```

### AddPercentageInput

InputsWrapper→ AddPercentInput

[#](#feature-AddPercentageInput)

Lets the user enter or edit a value using a percentage input control. This is a convenience wrapper implemented through AddPercentInput.

Configuration, feedback & example

#### Resolved implementation

`AddPercentInput`

#### Common configuration keys

`Default`, `Max`, `Min`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPercentageInput({
    Id = "PercentageInput",
    Text = "Percentage Input",
    Default = 50,
})
```

### AddPerformanceFPS

Charts & LiveWrapper→ AddFPSMeter

[#](#feature-AddPerformanceFPS)

Adds the Performance FPS UI feature to a section. This is a convenience wrapper implemented through AddFPSMeter.

Configuration, feedback & example

#### Resolved implementation

`AddFPSMeter`

#### Common configuration keys

`Height`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPerformanceFPS({
    Id = "PerformanceFPS",
    Text = "Performance FPS",
})
```

### AddPerformanceMemory

Charts & LiveWrapper→ AddMemoryMeter

[#](#feature-AddPerformanceMemory)

Adds the Performance Memory UI feature to a section. This is a convenience wrapper implemented through AddMemoryMeter.

Configuration, feedback & example

#### Resolved implementation

`AddMemoryMeter`

#### Common configuration keys

`Height`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPerformanceMemory({
    Id = "PerformanceMemory",
    Text = "Performance Memory",
})
```

### AddPermissionSelector

SelectorsWrapper→ AddMultiDropdown

[#](#feature-AddPermissionSelector)

Lets the user choose a value using the permission selector interface. This is a convenience wrapper implemented through AddMultiDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddMultiDropdown`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MultiDropdownChanged`

#### Example

```
local control = Section:AddPermissionSelector({
    Id = "PermissionSelector",
    Text = "Permission Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = {"Alpha"},
})
```

### AddPhoneInput

InputsWrapper→ AddTextbox

[#](#feature-AddPhoneInput)

Lets the user enter or edit a value using a phone input control. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddPhoneInput({
    Id = "PhoneInput",
    Text = "Phone Input",
    Default = "Example text",
})
```

### AddPieChart

Charts & LiveWrapper→ AddBarChart

[#](#feature-AddPieChart)

Displays data visually using a pie chart. This is a convenience wrapper implemented through AddBarChart.

Configuration, feedback & example

#### Resolved implementation

`AddBarChart`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `Text`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPieChart({
    Id = "PieChart",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddPill

VisualsWrapper→ AddStatus

[#](#feature-AddPill)

Adds the Pill UI feature to a section. This is a convenience wrapper implemented through AddStatus.

Configuration, feedback & example

#### Resolved implementation

`AddStatus`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`StatusChanged`

#### Example

```
local control = Section:AddPill({
    Id = "Pill",
    Text = "Connection",
    Default = "Online",
})
```

### AddPingMeter

InputsNative

[#](#feature-AddPingMeter)

Displays a status or numeric measurement using a ping meter.

Configuration, feedback & example

#### Resolved implementation

`AddPingMeter`

#### Common configuration keys

`Getter`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPingMeter({
    Id = "PingMeter",
    Text = "Ping Meter",
})
```

### AddPlayerCard

VisualsNative

[#](#feature-AddPlayerCard)

Displays a player avatar, display name, and username.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerCard`

#### Common configuration keys

`Height`, `Id`, `Player`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`PlayerCardChanged`

#### Example

```
local control = Section:AddPlayerCard({
    Id = "PlayerCard",
    Player = game.Players.LocalPlayer,
})
```

### AddPlayerCount

Players & WorldNative

[#](#feature-AddPlayerCount)

Adds the Player Count UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerCount`

#### Common configuration keys

`Getter`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPlayerCount({
    Id = "PlayerCount",
    Text = "Player Count",
})
```

### AddPlayerList

DataNative

[#](#feature-AddPlayerList)

Shows a scrollable live list of players that can be selected.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerList`

#### Common configuration keys

`Callback`, `ExcludeLocalPlayer`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PlayerListSelected`

#### Example

```
local control = Section:AddPlayerList({
    Id = "PlayerList",
    Text = "Player",
    Callback = function(player)
        if player then print(player.Name) end
    end,
})
```

### AddPlayerMultiSelect

SelectorsNative→ AddMultiDropdown

[#](#feature-AddPlayerMultiSelect)

Lets the user choose a value using the player multi select interface.

Configuration, feedback & example

#### Resolved implementation

`AddMultiDropdown`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MultiDropdownChanged`

#### Example

```
local control = Section:AddPlayerMultiSelect({
    Id = "PlayerMultiSelect",
    Text = "Player Multi Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = {"Alpha"},
})
```

### AddPlayerPicker

SelectorsNative

[#](#feature-AddPlayerPicker)

Lets the user select a live Roblox Player and automatically updates as players join or leave.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerPicker`

#### Common configuration keys

`Callback`, `Default`, `ExcludeLocalPlayer`, `Height`, `Id`, `MaxHeight`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PlayerSelected`

#### Example

```
local control = Section:AddPlayerPicker({
    Id = "PlayerPicker",
    Text = "Player",
    Callback = function(player)
        if player then print(player.Name) end
    end,
})
```

### AddPlayerSelect

SelectorsAlias→ AddPlayerPicker

[#](#feature-AddPlayerSelect)

Lets the user choose a value using the player select interface. This is a convenience alias implemented through AddPlayerPicker.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerPicker`

#### Common configuration keys

`Callback`, `Default`, `ExcludeLocalPlayer`, `Height`, `Id`, `MaxHeight`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PlayerSelected`

#### Example

```
local control = Section:AddPlayerSelect({
    Id = "PlayerSelect",
    Text = "Player",
    Callback = function(player)
        if player then print(player.Name) end
    end,
})
```

### AddPlayerSelector

SelectorsWrapper→ AddPlayerPicker

[#](#feature-AddPlayerSelector)

Lets the user choose a value using the player selector interface. This is a convenience wrapper implemented through AddPlayerPicker.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerPicker`

#### Common configuration keys

`Callback`, `Default`, `ExcludeLocalPlayer`, `Height`, `Id`, `MaxHeight`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PlayerSelected`

#### Example

```
local control = Section:AddPlayerSelector({
    Id = "PlayerSelector",
    Text = "Player",
    Callback = function(player)
        if player then print(player.Name) end
    end,
})
```

### AddPlayersList

DataWrapper→ AddPlayerList

[#](#feature-AddPlayersList)

Displays or manages structured items using a players list. This is a convenience wrapper implemented through AddPlayerList.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerList`

#### Common configuration keys

`Callback`, `ExcludeLocalPlayer`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PlayerListSelected`

#### Example

```
local control = Section:AddPlayersList({
    Id = "PlayersList",
    Text = "Player",
    Callback = function(player)
        if player then print(player.Name) end
    end,
})
```

### AddPollingLabel

VisualsWrapper→ AddLiveValue

[#](#feature-AddPollingLabel)

Displays information using a polling label. This is a convenience wrapper implemented through AddLiveValue.

Configuration, feedback & example

#### Resolved implementation

`AddLiveValue`

#### Common configuration keys

`Default`, `Getter`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPollingLabel({
    Id = "PollingLabel",
    Text = "Polling Label",
})
```

### AddPortInput

InputsNative

[#](#feature-AddPortInput)

Lets the user enter or edit a value using a port input control.

Configuration, feedback & example

#### Resolved implementation

`AddPortInput`

#### Common configuration keys

`Default`, `Max`, `Min`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPortInput({
    Id = "PortInput",
    Text = "Port Input",
    Default = 8080,
})
```

### AddPortSelector

InputsWrapper→ AddPortInput

[#](#feature-AddPortSelector)

Lets the user choose a value using the port selector interface. This is a convenience wrapper implemented through AddPortInput.

Configuration, feedback & example

#### Resolved implementation

`AddPortInput`

#### Common configuration keys

`Default`, `Max`, `Min`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPortSelector({
    Id = "PortSelector",
    Text = "Port Selector",
    Default = 8080,
})
```

### AddPositiveNumberInput

InputsWrapper→ AddNumberbox

[#](#feature-AddPositiveNumberInput)

Lets the user enter or edit a value using a positive number input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPositiveNumberInput({
    Id = "PositiveNumberInput",
    Text = "Positive Number Input",
})
```

### AddPreset

ActionsAlias→ AddPresetSelector

[#](#feature-AddPreset)

Adds the Preset UI feature to a section. This is a convenience alias implemented through AddPresetSelector.

Configuration, feedback & example

#### Resolved implementation

`AddPresetSelector`

#### Common configuration keys

`Callback`, `Options`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPreset({
    Id = "Preset",
    Text = "Preset",
})
```

### AddPresetSelector

SelectorsNative

[#](#feature-AddPresetSelector)

Lets the user choose a value using the preset selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddPresetSelector`

#### Common configuration keys

`Callback`, `Options`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPresetSelector({
    Id = "PresetSelector",
    Text = "Preset Selector",
})
```

### AddPrimaryButton

ActionsWrapper→ AddButton

[#](#feature-AddPrimaryButton)

Creates a primary button action that the user can press. This is a convenience wrapper implemented through AddButton.

Configuration, feedback & example

#### Resolved implementation

`AddButton`

#### Common configuration keys

`Callback`, `Color`, `Font`, `Height`, `HoverColor`, `Id`, `Radius`, `Stroke`, `Text`, `TextColor`, `TextSize`

#### Callback fields

`Callback`

#### Feedback events

`ButtonPressed`

#### Example

```
local control = Section:AddPrimaryButton({
    Id = "PrimaryButton",
    Text = "Click me",
    Callback = function()
        print("Pressed")
    end,
})
```

### AddPriorityInput

InputsWrapper→ AddDropdown

[#](#feature-AddPriorityInput)

Lets the user enter or edit a value using a priority input control. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddPriorityInput({
    Id = "PriorityInput",
    Text = "Priority Input",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddProfileCard

VisualsWrapper→ AddPlayerCard

[#](#feature-AddProfileCard)

Displays information using a profile card. This is a convenience wrapper implemented through AddPlayerCard.

Configuration, feedback & example

#### Resolved implementation

`AddPlayerCard`

#### Common configuration keys

`Height`, `Id`, `Player`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`PlayerCardChanged`

#### Example

```
local control = Section:AddProfileCard({
    Id = "ProfileCard",
    Player = game.Players.LocalPlayer,
})
```

### AddProgress

Charts & LiveNative

[#](#feature-AddProgress)

Displays progress between a minimum and maximum value.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddProgress({
    Id = "Progress",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddProgressRing

Charts & LiveWrapper→ AddMeter

[#](#feature-AddProgressRing)

Displays a status or numeric measurement using a progress ring. This is a convenience wrapper implemented through AddMeter.

Configuration, feedback & example

#### Resolved implementation

`AddMeter`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`, `Thresholds`

#### Callback fields

`Callback`

#### Feedback events

`MeterChanged`

#### Example

```
local control = Section:AddProgressRing({
    Id = "ProgressRing",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddPromptButton

ActionsNative→ AddButton

[#](#feature-AddPromptButton)

Creates a prompt button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddButton`

#### Common configuration keys

`Callback`, `Color`, `Font`, `Height`, `HoverColor`, `Id`, `Radius`, `Stroke`, `Text`, `TextColor`, `TextSize`

#### Callback fields

`Callback`

#### Feedback events

`ButtonPressed`

#### Example

```
local control = Section:AddPromptButton({
    Id = "PromptButton",
    Text = "Click me",
    Callback = function()
        print("Pressed")
    end,
})
```

### AddProperties

Layout & OtherAlias→ AddPropertyGrid

[#](#feature-AddProperties)

Adds the Properties UI feature to a section. This is a convenience alias implemented through AddPropertyGrid.

Configuration, feedback & example

#### Resolved implementation

`AddPropertyGrid`

#### Common configuration keys

`Default`, `Height`, `Id`, `Properties`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`PropertyChanged`

#### Example

```
local control = Section:AddProperties({
    Id = "Properties",
    Text = "Properties",
})
```

### AddPropertyGrid

DataNative

[#](#feature-AddPropertyGrid)

Displays or manages structured items using a property grid.

Configuration, feedback & example

#### Resolved implementation

`AddPropertyGrid`

#### Common configuration keys

`Default`, `Height`, `Id`, `Properties`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`PropertyChanged`

#### Example

```
local control = Section:AddPropertyGrid({
    Id = "PropertyGrid",
    Text = "Property Grid",
})
```

### AddPropertyInspector

DataWrapper→ AddPropertyGrid

[#](#feature-AddPropertyInspector)

Adds the Property Inspector UI feature to a section. This is a convenience wrapper implemented through AddPropertyGrid.

Configuration, feedback & example

#### Resolved implementation

`AddPropertyGrid`

#### Common configuration keys

`Default`, `Height`, `Id`, `Properties`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`PropertyChanged`

#### Example

```
local control = Section:AddPropertyInspector({
    Id = "PropertyInspector",
    Text = "Property Inspector",
})
```

### AddPropertyWatcher

DataNative

[#](#feature-AddPropertyWatcher)

Adds the Property Watcher UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddPropertyWatcher`

#### Common configuration keys

`Getter`, `Instance`, `Property`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddPropertyWatcher({
    Id = "PropertyWatcher",
    Text = "Property Watcher",
})
```

### AddQualitySelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddQualitySelector)

Lets the user choose a value using the quality selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddQualitySelector({
    Id = "QualitySelector",
    Text = "Quality Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddQueue

DataNative

[#](#feature-AddQueue)

Displays or manages structured items using a queue.

Configuration, feedback & example

#### Resolved implementation

`AddQueue`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddQueue({
    Id = "Queue",
    Text = "Queue",
})
```

### AddQuote

VisualsWrapper→ AddCallout

[#](#feature-AddQuote)

Adds the Quote UI feature to a section. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddQuote({
    Id = "Quote",
    Text = "Quote",
})
```

### AddRGB

Layout & OtherAlias→ AddRGBInput

[#](#feature-AddRGB)

Adds the RGB UI feature to a section. This is a convenience alias implemented through AddRGBInput.

Configuration, feedback & example

#### Resolved implementation

`AddRGBInput`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`RGBChanged`

#### Example

```
local control = Section:AddRGB({
    Id = "RGB",
    Text = "RGB",
})
```

### AddRGBEditor

InputsWrapper→ AddRGBInput

[#](#feature-AddRGBEditor)

Lets the user enter or edit a value using a rgb editor control. This is a convenience wrapper implemented through AddRGBInput.

Configuration, feedback & example

#### Resolved implementation

`AddRGBInput`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`RGBChanged`

#### Example

```
local control = Section:AddRGBEditor({
    Id = "RGBEditor",
    Text = "RGB Editor",
})
```

### AddRGBInput

InputsNative

[#](#feature-AddRGBInput)

Lets the user enter or edit a value using a rgb input control.

Configuration, feedback & example

#### Resolved implementation

`AddRGBInput`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`RGBChanged`

#### Example

```
local control = Section:AddRGBInput({
    Id = "RGBInput",
    Text = "RGB Input",
})
```

### AddRadialProgress

Charts & LiveWrapper→ AddMeter

[#](#feature-AddRadialProgress)

Displays a status or numeric measurement using a radial progress. This is a convenience wrapper implemented through AddMeter.

Configuration, feedback & example

#### Resolved implementation

`AddMeter`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`, `Thresholds`

#### Callback fields

`Callback`

#### Feedback events

`MeterChanged`

#### Example

```
local control = Section:AddRadialProgress({
    Id = "RadialProgress",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddRadiansInput

InputsWrapper→ AddNumberbox

[#](#feature-AddRadiansInput)

Lets the user enter or edit a value using a radians input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddRadiansInput({
    Id = "RadiansInput",
    Text = "Radians Input",
})
```

### AddRadioGroup

SelectorsNative

[#](#feature-AddRadioGroup)

Organizes UI content using a radio group layout/control.

Configuration, feedback & example

#### Resolved implementation

`AddRadioGroup`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`RadioChanged`

#### Example

```
local control = Section:AddRadioGroup({
    Id = "RadioGroup",
    Text = "Radio Group",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddRangeSlider

InputsNative

[#](#feature-AddRangeSlider)

Adds the Range Slider UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddRangeSlider`

#### Common configuration keys

`Accent`, `Callback`, `DefaultHigh`, `DefaultLow`, `Height`, `High`, `Id`, `Low`, `Max`, `Min`, `Step`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`RangeChanged`

#### Example

```
local control = Section:AddRangeSlider({
    Id = "RangeSlider",
    Text = "Range",
    Min = 0,
    Max = 100,
    DefaultLow = 25,
    DefaultHigh = 75,
})
```

### AddRankings

Layout & OtherAlias→ AddLeaderboard

[#](#feature-AddRankings)

Adds the Rankings UI feature to a section. This is a convenience alias implemented through AddLeaderboard.

Configuration, feedback & example

#### Resolved implementation

`AddLeaderboard`

#### Common configuration keys

`Columns`, `Rows`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddRankings({
    Id = "Rankings",
    Text = "Rankings",
})
```

### AddRating

Layout & OtherNative

[#](#feature-AddRating)

Lets the user select a star/symbol rating.

Configuration, feedback & example

#### Resolved implementation

`AddRating`

#### Common configuration keys

`Callback`, `Color`, `Default`, `EmptySymbol`, `FilledSymbol`, `Height`, `Id`, `Max`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`RatingChanged`

#### Example

```
local control = Section:AddRating({
    Id = "Rating",
    Text = "Rating",
    Default = 4,
    Max = 5,
})
```

### AddRaw

Layout & OtherAlias→ AddRawGui

[#](#feature-AddRaw)

Adds the Raw UI feature to a section. This is a convenience alias implemented through AddRawGui.

Configuration, feedback & example

#### Resolved implementation

`AddRawGui`

#### Common configuration keys

`Kind`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddRaw({
    Id = "Raw",
    Text = "Raw",
})
```

### AddRawGui

Layout & OtherNative

[#](#feature-AddRawGui)

Adds the Raw Gui UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddRawGui`

#### Common configuration keys

`Kind`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddRawGui({
    Id = "RawGui",
    Text = "Raw Gui",
})
```

### AddReadOnlyField

InputsWrapper→ AddKeyValue

[#](#feature-AddReadOnlyField)

Lets the user enter or edit a value using a read only field control. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddReadOnlyField({
    Id = "ReadOnlyField",
    Text = "Read Only Field",
})
```

### AddRedoButton

ActionsNative

[#](#feature-AddRedoButton)

Creates a redo button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddRedoButton`

#### Common configuration keys

`Callback`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddRedoButton({
    Id = "RedoButton",
    Text = "Redo Button",
})
```

### AddReducedMotionToggle

Layout & OtherNative

[#](#feature-AddReducedMotionToggle)

Creates a setting-style reduced motion toggle for switching state.

Configuration, feedback & example

#### Resolved implementation

`AddReducedMotionToggle`

#### Common configuration keys

`Callback`, `Default`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddReducedMotionToggle({
    Id = "ReducedMotionToggle",
    Text = "Reduced Motion Toggle",
})
```

### AddRefreshRateSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddRefreshRateSelector)

Lets the user choose a value using the refresh rate selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddRefreshRateSelector({
    Id = "RefreshRateSelector",
    Text = "Refresh Rate Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddReorder

Layout & OtherAlias→ AddReorderList

[#](#feature-AddReorder)

Adds the Reorder UI feature to a section. This is a convenience alias implemented through AddReorderList.

Configuration, feedback & example

#### Resolved implementation

`AddReorderList`

#### Common configuration keys

`Callback`, `Height`, `Id`, `Items`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ReorderChanged`

#### Example

```
local control = Section:AddReorder({
    Id = "Reorder",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddReorderList

DataNative

[#](#feature-AddReorderList)

Displays or manages structured items using a reorder list.

Configuration, feedback & example

#### Resolved implementation

`AddReorderList`

#### Common configuration keys

`Callback`, `Height`, `Id`, `Items`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ReorderChanged`

#### Example

```
local control = Section:AddReorderList({
    Id = "ReorderList",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddResetButton

ActionsNative

[#](#feature-AddResetButton)

Creates a reset button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddResetButton`

#### Common configuration keys

`Callback`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddResetButton({
    Id = "ResetButton",
    Text = "Reset Button",
})
```

### AddResolutionSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddResolutionSelector)

Lets the user choose a value using the resolution selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddResolutionSelector({
    Id = "ResolutionSelector",
    Text = "Resolution Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddResponsivePreview

VisualsWrapper→ AddLiveValue

[#](#feature-AddResponsivePreview)

Displays information using a responsive preview. This is a convenience wrapper implemented through AddLiveValue.

Configuration, feedback & example

#### Resolved implementation

`AddLiveValue`

#### Common configuration keys

`Default`, `Getter`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddResponsivePreview({
    Id = "ResponsivePreview",
    Text = "Responsive Preview",
})
```

### AddRoleSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddRoleSelector)

Lets the user choose a value using the role selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddRoleSelector({
    Id = "RoleSelector",
    Text = "Role Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddSafeAreaIndicator

Players & WorldWrapper→ AddKeyValue

[#](#feature-AddSafeAreaIndicator)

Displays a status or numeric measurement using a safe area indicator. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddSafeAreaIndicator({
    Id = "SafeAreaIndicator",
    Text = "Safe Area Indicator",
})
```

### AddScaleTypeSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddScaleTypeSelector)

Lets the user choose a value using the scale type selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddScaleTypeSelector({
    Id = "ScaleTypeSelector",
    Text = "Scale Type Selector",
    Enum = Enum.EasingStyle,
})
```

### AddScatterPlot

Charts & LiveWrapper→ AddLineChart

[#](#feature-AddScatterPlot)

Displays data visually using a scatter plot. This is a convenience wrapper implemented through AddLineChart.

Configuration, feedback & example

#### Resolved implementation

`AddLineChart`

#### Common configuration keys

`Height`, `Thickness`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddScatterPlot({
    Id = "ScatterPlot",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddScoreboard

DataWrapper→ AddLeaderboard

[#](#feature-AddScoreboard)

Displays or manages structured items using a scoreboard. This is a convenience wrapper implemented through AddLeaderboard.

Configuration, feedback & example

#### Resolved implementation

`AddLeaderboard`

#### Common configuration keys

`Columns`, `Rows`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddScoreboard({
    Id = "Scoreboard",
    Text = "Scoreboard",
})
```

### AddScrollArea

Layout & OtherNative

[#](#feature-AddScrollArea)

Adds the Scroll Area UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddScrollArea`

#### Common configuration keys

`Height`, `Kind`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddScrollArea({
    Id = "ScrollArea",
    Text = "Scroll Area",
})
```

### AddSearchBox

InputsNative

[#](#feature-AddSearchBox)

Lets the user enter or edit a value using a search box control.

Configuration, feedback & example

#### Resolved implementation

`AddSearchBox`

#### Common configuration keys

`Callback`, `Live`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SearchChanged`

#### Example

```
local control = Section:AddSearchBox({
    Id = "SearchBox",
    Text = "Search Box",
    Default = "Example text",
})
```

### AddSearchDropdown

SelectorsNative

[#](#feature-AddSearchDropdown)

A dropdown with text search for longer option lists.

Configuration, feedback & example

#### Resolved implementation

`AddSearchDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`SearchDropdownChanged`

#### Example

```
local control = Section:AddSearchDropdown({
    Id = "SearchDropdown",
    Text = "Search Dropdown",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddSearchInput

InputsWrapper→ AddSearchBox

[#](#feature-AddSearchInput)

Lets the user enter or edit a value using a search input control. This is a convenience wrapper implemented through AddSearchBox.

Configuration, feedback & example

#### Resolved implementation

`AddSearchBox`

#### Common configuration keys

`Callback`, `Live`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SearchChanged`

#### Example

```
local control = Section:AddSearchInput({
    Id = "SearchInput",
    Text = "Search Input",
    Default = "Example text",
})
```

### AddSearchResults

DataWrapper→ AddSearchableList

[#](#feature-AddSearchResults)

Adds the Search Results UI feature to a section. This is a convenience wrapper implemented through AddSearchableList.

Configuration, feedback & example

#### Resolved implementation

`AddSearchableList`

#### Common configuration keys

`Callback`, `Display`, `Height`, `Id`, `Items`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`SearchableListSelected`

#### Example

```
local control = Section:AddSearchResults({
    Id = "SearchResults",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddSearchSelect

SelectorsAlias→ AddSearchDropdown

[#](#feature-AddSearchSelect)

Lets the user choose a value using the search select interface. This is a convenience alias implemented through AddSearchDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddSearchDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`SearchDropdownChanged`

#### Example

```
local control = Section:AddSearchSelect({
    Id = "SearchSelect",
    Text = "Search Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddSearchableList

DataNative

[#](#feature-AddSearchableList)

Displays or manages structured items using a searchable list.

Configuration, feedback & example

#### Resolved implementation

`AddSearchableList`

#### Common configuration keys

`Callback`, `Display`, `Height`, `Id`, `Items`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`SearchableListSelected`

#### Example

```
local control = Section:AddSearchableList({
    Id = "SearchableList",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddSecondaryButton

ActionsWrapper→ AddButton

[#](#feature-AddSecondaryButton)

Creates a secondary button action that the user can press. This is a convenience wrapper implemented through AddButton.

Configuration, feedback & example

#### Resolved implementation

`AddButton`

#### Common configuration keys

`Callback`, `Color`, `Font`, `Height`, `HoverColor`, `Id`, `Radius`, `Stroke`, `Text`, `TextColor`, `TextSize`

#### Callback fields

`Callback`

#### Feedback events

`ButtonPressed`

#### Example

```
local control = Section:AddSecondaryButton({
    Id = "SecondaryButton",
    Text = "Click me",
    Callback = function()
        print("Pressed")
    end,
})
```

### AddSectionIndex

Layout & OtherWrapper→ AddList

[#](#feature-AddSectionIndex)

Adds the Section Index UI feature to a section. This is a convenience wrapper implemented through AddList.

Configuration, feedback & example

#### Resolved implementation

`AddList`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `ItemHeight`, `Items`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`ListSelected`

#### Example

```
local control = Section:AddSectionIndex({
    Id = "SectionIndex",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddSegmented

SelectorsNative

[#](#feature-AddSegmented)

Adds the Segmented UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddSegmented`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SegmentedChanged`

#### Example

```
local control = Section:AddSegmented({
    Id = "Segmented",
    Text = "Segmented",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddSelect

SelectorsAlias→ AddDropdown

[#](#feature-AddSelect)

Lets the user choose a value using the select interface. This is a convenience alias implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddSelect({
    Id = "Select",
    Text = "Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddSensitivityInput

InputsWrapper→ AddSlider

[#](#feature-AddSensitivityInput)

Lets the user enter or edit a value using a sensitivity input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddSensitivityInput({
    Id = "SensitivityInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddServerUptime

Charts & LiveNative

[#](#feature-AddServerUptime)

Adds the Server Uptime UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddServerUptime`

#### Common configuration keys

`Getter`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddServerUptime({
    Id = "ServerUptime",
    Text = "Server Uptime",
})
```

### AddSeveritySelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddSeveritySelector)

Lets the user choose a value using the severity selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddSeveritySelector({
    Id = "SeveritySelector",
    Text = "Severity Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddShortcutList

ActionsWrapper→ AddTable

[#](#feature-AddShortcutList)

Displays or manages structured items using a shortcut list. This is a convenience wrapper implemented through AddTable.

Configuration, feedback & example

#### Resolved implementation

`AddTable`

#### Common configuration keys

`Callback`, `Columns`, `Height`, `Id`, `RowHeight`, `Rows`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TableRowSelected`

#### Example

```
local control = Section:AddShortcutList({
    Id = "ShortcutList",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddSignalStrength

VisualsWrapper→ AddMeter

[#](#feature-AddSignalStrength)

Adds the Signal Strength UI feature to a section. This is a convenience wrapper implemented through AddMeter.

Configuration, feedback & example

#### Resolved implementation

`AddMeter`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`, `Thresholds`

#### Callback fields

`Callback`

#### Feedback events

`MeterChanged`

#### Example

```
local control = Section:AddSignalStrength({
    Id = "SignalStrength",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddSkeleton

Charts & LiveNative

[#](#feature-AddSkeleton)

Adds the Skeleton UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddSkeleton`

#### Common configuration keys

`Height`, `Id`, `Lines`, `Running`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSkeleton({
    Id = "Skeleton",
    Text = "Skeleton",
})
```

### AddSkeletonLoader

Charts & LiveWrapper→ AddSkeleton

[#](#feature-AddSkeletonLoader)

Adds the Skeleton Loader UI feature to a section. This is a convenience wrapper implemented through AddSkeleton.

Configuration, feedback & example

#### Resolved implementation

`AddSkeleton`

#### Common configuration keys

`Height`, `Id`, `Lines`, `Running`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSkeletonLoader({
    Id = "SkeletonLoader",
    Text = "Skeleton Loader",
})
```

### AddSlider

InputsNative

[#](#feature-AddSlider)

Lets the user choose a number by dragging along a range.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddSlider({
    Id = "Slider",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddSlotGrid

DataWrapper→ AddGridSelect

[#](#feature-AddSlotGrid)

Displays or manages structured items using a slot grid. This is a convenience wrapper implemented through AddGridSelect.

Configuration, feedback & example

#### Resolved implementation

`AddGridSelect`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSlotGrid({
    Id = "SlotGrid",
    Text = "Slot Grid",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddSortDirectionSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddSortDirectionSelector)

Lets the user choose a value using the sort direction selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddSortDirectionSelector({
    Id = "SortDirectionSelector",
    Text = "Sort Direction Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddSortOrderSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddSortOrderSelector)

Lets the user choose a value using the sort order selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSortOrderSelector({
    Id = "SortOrderSelector",
    Text = "Sort Order Selector",
    Enum = Enum.EasingStyle,
})
```

### AddSortSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddSortSelector)

Lets the user choose a value using the sort selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddSortSelector({
    Id = "SortSelector",
    Text = "Sort Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddSortableList

DataWrapper→ AddReorderList

[#](#feature-AddSortableList)

Displays or manages structured items using a sortable list. This is a convenience wrapper implemented through AddReorderList.

Configuration, feedback & example

#### Resolved implementation

`AddReorderList`

#### Common configuration keys

`Callback`, `Height`, `Id`, `Items`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ReorderChanged`

#### Example

```
local control = Section:AddSortableList({
    Id = "SortableList",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddSortableTable

DataNative

[#](#feature-AddSortableTable)

Displays or manages structured items using a sortable table.

Configuration, feedback & example

#### Resolved implementation

`AddSortableTable`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSortableTable({
    Id = "SortableTable",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddSpacer

Layout & OtherNative

[#](#feature-AddSpacer)

Adds the Spacer UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddSpacer`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSpacer({
    Id = "Spacer",
    Text = "Spacer",
})
```

### AddSparkline

Charts & LiveNative

[#](#feature-AddSparkline)

Adds the Sparkline UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddSparkline`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `MaxPoints`, `Text`, `Thickness`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSparkline({
    Id = "Sparkline",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddSpeedInput

InputsWrapper→ AddNumberbox

[#](#feature-AddSpeedInput)

Lets the user enter or edit a value using a speed input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSpeedInput({
    Id = "SpeedInput",
    Text = "Speed Input",
})
```

### AddSpinner

InputsAlias→ AddLoadingSpinner

[#](#feature-AddSpinner)

Adds the Spinner UI feature to a section. This is a convenience alias implemented through AddLoadingSpinner.

Configuration, feedback & example

#### Resolved implementation

`AddLoadingSpinner`

#### Common configuration keys

`Color`, `Height`, `Id`, `Running`, `Size`, `Speed`, `Symbol`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSpinner({
    Id = "Spinner",
    Text = "Spinner",
})
```

### AddSplitButton

ActionsWrapper→ AddButtonGroup

[#](#feature-AddSplitButton)

Creates a split button action that the user can press. This is a convenience wrapper implemented through AddButtonGroup.

Configuration, feedback & example

#### Resolved implementation

`AddButtonGroup`

#### Common configuration keys

`Alignment`, `Buttons`, `Callback`, `EqualWidth`, `Height`, `Id`, `Spacing`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ButtonGroupPressed`

#### Example

```
local control = Section:AddSplitButton({
    Id = "SplitButton",
    Text = "Split Button",
})
```

### AddStackedBarChart

Charts & LiveWrapper→ AddBarChart

[#](#feature-AddStackedBarChart)

Displays data visually using a stacked bar chart. This is a convenience wrapper implemented through AddBarChart.

Configuration, feedback & example

#### Resolved implementation

`AddBarChart`

#### Common configuration keys

`Color`, `Default`, `Height`, `Id`, `Text`, `Values`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddStackedBarChart({
    Id = "StackedBarChart",
    Text = "Data",
    Values = {4, 9, 6, 12, 8, 15},
})
```

### AddStarRating

Layout & OtherWrapper→ AddRating

[#](#feature-AddStarRating)

Adds the Star Rating UI feature to a section. This is a convenience wrapper implemented through AddRating.

Configuration, feedback & example

#### Resolved implementation

`AddRating`

#### Common configuration keys

`Callback`, `Color`, `Default`, `EmptySymbol`, `FilledSymbol`, `Height`, `Id`, `Max`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`RatingChanged`

#### Example

```
local control = Section:AddStarRating({
    Id = "StarRating",
    Text = "Rating",
    Default = 4,
    Max = 5,
})
```

### AddStars

Layout & OtherAlias→ AddRating

[#](#feature-AddStars)

Adds the Stars UI feature to a section. This is a convenience alias implemented through AddRating.

Configuration, feedback & example

#### Resolved implementation

`AddRating`

#### Common configuration keys

`Callback`, `Color`, `Default`, `EmptySymbol`, `FilledSymbol`, `Height`, `Id`, `Max`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`RatingChanged`

#### Example

```
local control = Section:AddStars({
    Id = "Stars",
    Text = "Rating",
    Default = 4,
    Max = 5,
})
```

### AddStatCard

VisualsNative

[#](#feature-AddStatCard)

Displays information using a stat card.

Configuration, feedback & example

#### Resolved implementation

`AddStatCard`

#### Common configuration keys

`Callback`, `Color`, `Default`, `DeltaColor`, `DeltaText`, `Height`, `Id`, `Prefix`, `Suffix`, `Text`, `Value`, `ValueSize`

#### Callback fields

`Callback`

#### Feedback events

`StatChanged`

#### Example

```
local control = Section:AddStatCard({
    Id = "StatCard",
    Text = "Score",
    Default = 125,
    DeltaText = "+12%",
})
```

### AddStateDebugger

Layout & OtherNative

[#](#feature-AddStateDebugger)

Adds the State Debugger UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddStateDebugger`

#### Common configuration keys

`Code`, `Height`, `Id`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddStateDebugger({
    Id = "StateDebugger",
    Text = "State Debugger",
})
```

### AddStateSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddStateSelector)

Lets the user choose a value using the state selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddStateSelector({
    Id = "StateSelector",
    Text = "State Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddStatus

VisualsNative

[#](#feature-AddStatus)

Displays a compact status badge with a value and color.

Configuration, feedback & example

#### Resolved implementation

`AddStatus`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`StatusChanged`

#### Example

```
local control = Section:AddStatus({
    Id = "Status",
    Text = "Connection",
    Default = "Online",
})
```

### AddStatusLight

VisualsWrapper→ AddStatus

[#](#feature-AddStatusLight)

Adds the Status Light UI feature to a section. This is a convenience wrapper implemented through AddStatus.

Configuration, feedback & example

#### Resolved implementation

`AddStatus`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`StatusChanged`

#### Example

```
local control = Section:AddStatusLight({
    Id = "StatusLight",
    Text = "Connection",
    Default = "Online",
})
```

### AddStatusSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddStatusSelector)

Lets the user choose a value using the status selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddStatusSelector({
    Id = "StatusSelector",
    Text = "Status Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddStepIndicator

InputsWrapper→ AddPagination

[#](#feature-AddStepIndicator)

Displays a status or numeric measurement using a step indicator. This is a convenience wrapper implemented through AddPagination.

Configuration, feedback & example

#### Resolved implementation

`AddPagination`

#### Common configuration keys

`Callback`, `Default`, `Format`, `Height`, `Id`, `Pages`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PageChanged`

#### Example

```
local control = Section:AddStepIndicator({
    Id = "StepIndicator",
    Text = "Step Indicator",
})
```

### AddStepper

InputsNative

[#](#feature-AddStepper)

Adds the Stepper UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddStepper`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`StepperChanged`

#### Example

```
local control = Section:AddStepper({
    Id = "Stepper",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddStrokeWidthInput

InputsWrapper→ AddSlider

[#](#feature-AddStrokeWidthInput)

Lets the user enter or edit a value using a stroke width input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddStrokeWidthInput({
    Id = "StrokeWidthInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddSubTabs

Layout & OtherAlias→ AddMiniTabs

[#](#feature-AddSubTabs)

Organizes UI content using a sub tabs layout/control. This is a convenience alias implemented through AddMiniTabs.

Configuration, feedback & example

#### Resolved implementation

`AddMiniTabs`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Tabs`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MiniTabChanged`

#### Example

```
local control = Section:AddSubTabs({
    Id = "SubTabs",
    Text = "Sub Tabs",
})
```

### AddSuccessCard

VisualsWrapper→ AddCallout

[#](#feature-AddSuccessCard)

Displays information using a success card. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSuccessCard({
    Id = "SuccessCard",
    Text = "Success Card",
})
```

### AddSwatches

SelectorsAlias→ AddColorSwatches

[#](#feature-AddSwatches)

Adds the Swatches UI feature to a section. This is a convenience alias implemented through AddColorSwatches.

Configuration, feedback & example

#### Resolved implementation

`AddColorSwatches`

#### Common configuration keys

`Callback`, `Colors`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SwatchChanged`

#### Example

```
local control = Section:AddSwatches({
    Id = "Swatches",
    Text = "Swatches",
})
```

### AddSwitchRow

Layout & OtherWrapper→ AddToggle

[#](#feature-AddSwitchRow)

Adds the Switch Row UI feature to a section. This is a convenience wrapper implemented through AddToggle.

Configuration, feedback & example

#### Resolved implementation

`AddToggle`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ToggleChanged`

#### Example

```
local control = Section:AddSwitchRow({
    Id = "SwitchRow",
    Text = "Enabled",
    Default = true,
    Callback = function(value)
        print(value)
    end,
})
```

### AddSymbolPicker

SelectorsNative→ AddGridSelect

[#](#feature-AddSymbolPicker)

Lets the user choose a value using the symbol picker interface.

Configuration, feedback & example

#### Resolved implementation

`AddGridSelect`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Options`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddSymbolPicker({
    Id = "SymbolPicker",
    Text = "Symbol Picker",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddTable

DataNative

[#](#feature-AddTable)

Displays rows and columns of structured data and can report row selection.

Configuration, feedback & example

#### Resolved implementation

`AddTable`

#### Common configuration keys

`Callback`, `Columns`, `Height`, `Id`, `RowHeight`, `Rows`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TableRowSelected`

#### Example

```
local control = Section:AddTable({
    Id = "Table",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddTableEditor

InputsWrapper→ AddEditableTable

[#](#feature-AddTableEditor)

Lets the user enter or edit a value using a table editor control. This is a convenience wrapper implemented through AddEditableTable.

Configuration, feedback & example

#### Resolved implementation

`AddEditableTable`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTableEditor({
    Id = "TableEditor",
    Text = "Data",
    Columns = {"Name", "Score"},
    Rows = {
        {Name = "Alpha", Score = 125},
        {Name = "Bravo", Score = 90},
    },
})
```

### AddTagInput

InputsNative

[#](#feature-AddTagInput)

Lets the user enter and manage multiple text tags.

Configuration, feedback & example

#### Resolved implementation

`AddTagInput`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxTags`, `Placeholder`, `Text`, `Unique`

#### Callback fields

`Callback`

#### Feedback events

`TagsChanged`

#### Example

```
local control = Section:AddTagInput({
    Id = "TagInput",
    Text = "Tags",
    Default = {"alpha", "beta"},
})
```

### AddTagViewer

Layout & OtherWrapper→ AddList

[#](#feature-AddTagViewer)

Displays information using a tag viewer. This is a convenience wrapper implemented through AddList.

Configuration, feedback & example

#### Resolved implementation

`AddList`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `ItemHeight`, `Items`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`ListSelected`

#### Example

```
local control = Section:AddTagViewer({
    Id = "TagViewer",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddTags

Layout & OtherAlias→ AddTagInput

[#](#feature-AddTags)

Adds the Tags UI feature to a section. This is a convenience alias implemented through AddTagInput.

Configuration, feedback & example

#### Resolved implementation

`AddTagInput`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxTags`, `Placeholder`, `Text`, `Unique`

#### Callback fields

`Callback`

#### Feedback events

`TagsChanged`

#### Example

```
local control = Section:AddTags({
    Id = "Tags",
    Text = "Tags",
    Default = {"alpha", "beta"},
})
```

### AddTagsEditor

InputsWrapper→ AddTagInput

[#](#feature-AddTagsEditor)

Lets the user enter or edit a value using a tags editor control. This is a convenience wrapper implemented through AddTagInput.

Configuration, feedback & example

#### Resolved implementation

`AddTagInput`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxTags`, `Placeholder`, `Text`, `Unique`

#### Callback fields

`Callback`

#### Feedback events

`TagsChanged`

#### Example

```
local control = Section:AddTagsEditor({
    Id = "TagsEditor",
    Text = "Tags",
    Default = {"alpha", "beta"},
})
```

### AddTaskList

DataWrapper→ AddChecklist

[#](#feature-AddTaskList)

Displays or manages structured items using a task list. This is a convenience wrapper implemented through AddChecklist.

Configuration, feedback & example

#### Resolved implementation

`AddChecklist`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ChecklistChanged`

#### Example

```
local control = Section:AddTaskList({
    Id = "TaskList",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddTasks

DataAlias→ AddTaskList

[#](#feature-AddTasks)

Adds the Tasks UI feature to a section. This is a convenience alias implemented through AddTaskList.

Configuration, feedback & example

#### Resolved implementation

`AddChecklist`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Items`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ChecklistChanged`

#### Example

```
local control = Section:AddTasks({
    Id = "Tasks",
    Text = "Items",
    Items = {"Alpha", "Bravo", "Charlie"},
})
```

### AddTeamMultiSelect

SelectorsNative→ AddMultiDropdown

[#](#feature-AddTeamMultiSelect)

Lets the user choose a value using the team multi select interface.

Configuration, feedback & example

#### Resolved implementation

`AddMultiDropdown`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MultiDropdownChanged`

#### Example

```
local control = Section:AddTeamMultiSelect({
    Id = "TeamMultiSelect",
    Text = "Team Multi Select",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = {"Alpha"},
})
```

### AddTeamSelector

SelectorsNative→ AddDropdown

[#](#feature-AddTeamSelector)

Lets the user choose a value using the team selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddTeamSelector({
    Id = "TeamSelector",
    Text = "Team Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddTelemetry

Charts & LiveAlias→ AddLiveValue

[#](#feature-AddTelemetry)

Adds the Telemetry UI feature to a section. This is a convenience alias implemented through AddLiveValue.

Configuration, feedback & example

#### Resolved implementation

`AddLiveValue`

#### Common configuration keys

`Default`, `Getter`, `Id`, `Interval`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTelemetry({
    Id = "Telemetry",
    Text = "Telemetry",
})
```

### AddTextAlignmentSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddTextAlignmentSelector)

Lets the user choose a value using the text alignment selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTextAlignmentSelector({
    Id = "TextAlignmentSelector",
    Text = "Text Alignment Selector",
    Enum = Enum.EasingStyle,
})
```

### AddTextScaleSlider

InputsNative

[#](#feature-AddTextScaleSlider)

Adds the Text Scale Slider UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddTextScaleSlider`

#### Common configuration keys

`Callback`, `Default`, `Max`, `Min`, `Step`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTextScaleSlider({
    Id = "TextScaleSlider",
    Text = "Text Scale Slider",
})
```

### AddTextbox

InputsNative

[#](#feature-AddTextbox)

Creates a text input. It can also be numeric, multiline, live-updating, or length-limited.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddTextbox({
    Id = "Textbox",
    Text = "Textbox",
    Default = "Example text",
})
```

### AddTheme

Layout & OtherAlias→ AddThemeSelector

[#](#feature-AddTheme)

Adds the Theme UI feature to a section. This is a convenience alias implemented through AddThemeSelector.

Configuration, feedback & example

#### Resolved implementation

`AddThemeSelector`

#### Common configuration keys

`Callback`, `Options`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTheme({
    Id = "Theme",
    Text = "Theme",
})
```

### AddThemePreview

VisualsWrapper→ AddColorSwatches

[#](#feature-AddThemePreview)

Displays information using a theme preview. This is a convenience wrapper implemented through AddColorSwatches.

Configuration, feedback & example

#### Resolved implementation

`AddColorSwatches`

#### Common configuration keys

`Callback`, `Colors`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SwatchChanged`

#### Example

```
local control = Section:AddThemePreview({
    Id = "ThemePreview",
    Text = "Theme Preview",
})
```

### AddThemeSelector

SelectorsNative

[#](#feature-AddThemeSelector)

Lets the user choose a value using the theme selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddThemeSelector`

#### Common configuration keys

`Callback`, `Options`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddThemeSelector({
    Id = "ThemeSelector",
    Text = "Theme Selector",
})
```

### AddTicker

Charts & LiveWrapper→ AddLabel

[#](#feature-AddTicker)

Adds the Ticker UI feature to a section. This is a convenience wrapper implemented through AddLabel.

Configuration, feedback & example

#### Resolved implementation

`AddLabel`

#### Common configuration keys

`Alignment`, `Color`, `Font`, `Height`, `Id`, `RichText`, `Text`, `TextSize`, `VerticalAlignment`, `Wrapped`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTicker({
    Id = "Ticker",
    Text = "Ticker",
})
```

### AddTimeInput

InputsNative

[#](#feature-AddTimeInput)

Lets the user enter or edit a value using a time input control.

Configuration, feedback & example

#### Resolved implementation

`AddTimeInput`

#### Common configuration keys

`Placeholder`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTimeInput({
    Id = "TimeInput",
    Text = "Time Input",
    Default = "16:30",
})
```

### AddTimeline

Layout & OtherNative

[#](#feature-AddTimeline)

Adds the Timeline UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddTimeline`

#### Common configuration keys

`Height`, `Id`, `ItemHeight`, `Items`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTimeline({
    Id = "Timeline",
    Text = "Timeline",
})
```

### AddTimelineView

Layout & OtherWrapper→ AddTimeline

[#](#feature-AddTimelineView)

Displays information using a timeline view. This is a convenience wrapper implemented through AddTimeline.

Configuration, feedback & example

#### Resolved implementation

`AddTimeline`

#### Common configuration keys

`Height`, `Id`, `ItemHeight`, `Items`, `Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTimelineView({
    Id = "TimelineView",
    Text = "Timeline View",
})
```

### AddTimer

Charts & LiveWrapper→ AddCountdown

[#](#feature-AddTimer)

Adds the Timer UI feature to a section. This is a convenience wrapper implemented through AddCountdown.

Configuration, feedback & example

#### Resolved implementation

`AddCountdown`

#### Common configuration keys

`AutoStart`, `Callback`, `Default`, `Height`, `Id`, `Seconds`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`CountdownFinished`

#### Example

```
local control = Section:AddTimer({
    Id = "Timer",
    Text = "Timer",
})
```

### AddTimestamp

Layout & OtherWrapper→ AddKeyValue

[#](#feature-AddTimestamp)

Adds the Timestamp UI feature to a section. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddTimestamp({
    Id = "Timestamp",
    Text = "Timestamp",
})
```

### AddTimezoneSelector

SelectorsNative→ AddDropdown

[#](#feature-AddTimezoneSelector)

Lets the user choose a value using the timezone selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddTimezoneSelector({
    Id = "TimezoneSelector",
    Text = "Timezone Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddToggle

Layout & OtherNative

[#](#feature-AddToggle)

Creates a true/false switch. Use it for settings that are either enabled or disabled.

Configuration, feedback & example

#### Resolved implementation

`AddToggle`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ToggleChanged`

#### Example

```
local control = Section:AddToggle({
    Id = "Toggle",
    Text = "Enabled",
    Default = true,
    Callback = function(value)
        print(value)
    end,
})
```

### AddToggleButton

ActionsNative

[#](#feature-AddToggleButton)

Creates a toggle button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddToggleButton`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `OffColor`, `OffText`, `OnColor`, `OnText`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ToggleButtonChanged`

#### Example

```
local control = Section:AddToggleButton({
    Id = "ToggleButton",
    Text = "Toggle Button",
})
```

### AddToggleRow

Layout & OtherWrapper→ AddToggle

[#](#feature-AddToggleRow)

Creates a setting-style toggle row for switching state. This is a convenience wrapper implemented through AddToggle.

Configuration, feedback & example

#### Resolved implementation

`AddToggle`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ToggleChanged`

#### Example

```
local control = Section:AddToggleRow({
    Id = "ToggleRow",
    Text = "Enabled",
    Default = true,
    Callback = function(value)
        print(value)
    end,
})
```

### AddTokenBox

InputsAlias→ AddPasswordBox

[#](#feature-AddTokenBox)

Lets the user enter or edit a value using a token box control. This is a convenience alias implemented through AddPasswordBox.

Configuration, feedback & example

#### Resolved implementation

`AddPasswordBox`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `MaskCharacter`, `Placeholder`, `Revealed`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`PasswordChanged`

#### Example

```
local control = Section:AddTokenBox({
    Id = "TokenBox",
    Text = "Token Box",
    Default = "Example text",
})
```

### AddToolbar

ActionsNative

[#](#feature-AddToolbar)

Adds the Toolbar UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddToolbar`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddToolbar({
    Id = "Toolbar",
    Text = "Toolbar",
})
```

### AddTrafficLight

VisualsWrapper→ AddStatus

[#](#feature-AddTrafficLight)

Adds the Traffic Light UI feature to a section. This is a convenience wrapper implemented through AddStatus.

Configuration, feedback & example

#### Resolved implementation

`AddStatus`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`StatusChanged`

#### Example

```
local control = Section:AddTrafficLight({
    Id = "TrafficLight",
    Text = "Connection",
    Default = "Online",
})
```

### AddTransfer

Layout & OtherAlias→ AddTransferList

[#](#feature-AddTransfer)

Adds the Transfer UI feature to a section. This is a convenience alias implemented through AddTransferList.

Configuration, feedback & example

#### Resolved implementation

`AddTransferList`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTransfer({
    Id = "Transfer",
    Text = "Transfer",
})
```

### AddTransferList

DataNative

[#](#feature-AddTransferList)

Displays or manages structured items using a transfer list.

Configuration, feedback & example

#### Resolved implementation

`AddTransferList`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTransferList({
    Id = "TransferList",
    Text = "Transfer List",
})
```

### AddTransparencyInput

InputsWrapper→ AddSlider

[#](#feature-AddTransparencyInput)

Lets the user enter or edit a value using a transparency input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddTransparencyInput({
    Id = "TransparencyInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddTree

DataAlias→ AddTreeView

[#](#feature-AddTree)

Displays or manages structured items using a tree. This is a convenience alias implemented through AddTreeView.

Configuration, feedback & example

#### Resolved implementation

`AddTreeView`

#### Common configuration keys

`Callback`, `ClickExpands`, `Height`, `Id`, `Nodes`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TreeNodeSelected`

#### Example

```
local control = Section:AddTree({
    Id = "Tree",
    Text = "Tree",
    Nodes = {
        {Name = "Workspace", Children = {
            {Name = "Camera"},
            {Name = "Terrain"},
        }},
    },
})
```

### AddTreeExplorer

DataWrapper→ AddTreeView

[#](#feature-AddTreeExplorer)

Displays or manages structured items using a tree explorer. This is a convenience wrapper implemented through AddTreeView.

Configuration, feedback & example

#### Resolved implementation

`AddTreeView`

#### Common configuration keys

`Callback`, `ClickExpands`, `Height`, `Id`, `Nodes`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TreeNodeSelected`

#### Example

```
local control = Section:AddTreeExplorer({
    Id = "TreeExplorer",
    Text = "Tree",
    Nodes = {
        {Name = "Workspace", Children = {
            {Name = "Camera"},
            {Name = "Terrain"},
        }},
    },
})
```

### AddTreeView

DataNative

[#](#feature-AddTreeView)

Displays hierarchical parent/child data as an expandable tree.

Configuration, feedback & example

#### Resolved implementation

`AddTreeView`

#### Common configuration keys

`Callback`, `ClickExpands`, `Height`, `Id`, `Nodes`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TreeNodeSelected`

#### Example

```
local control = Section:AddTreeView({
    Id = "TreeView",
    Text = "Tree",
    Nodes = {
        {Name = "Workspace", Children = {
            {Name = "Camera"},
            {Name = "Terrain"},
        }},
    },
})
```

### AddTriStateToggle

Layout & OtherNative

[#](#feature-AddTriStateToggle)

Creates a setting-style tri state toggle for switching state.

Configuration, feedback & example

#### Resolved implementation

`AddTriStateToggle`

#### Common configuration keys

`Callback`, `DefaultIndex`, `Height`, `Id`, `States`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`TriStateChanged`

#### Example

```
local control = Section:AddTriStateToggle({
    Id = "TriStateToggle",
    Text = "Tri State Toggle",
})
```

### AddTwoColumn

Layout & OtherNative

[#](#feature-AddTwoColumn)

Adds the Two Column UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddTwoColumn`

#### Common configuration keys

`Columns`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddTwoColumn({
    Id = "TwoColumn",
    Text = "Two Column",
})
```

### AddUDim2Editor

InputsWrapper→ AddUDim2Input

[#](#feature-AddUDim2Editor)

Lets the user enter or edit a value using a u dim2 editor control. This is a convenience wrapper implemented through AddUDim2Input.

Configuration, feedback & example

#### Resolved implementation

`AddUDim2Input`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`UDim2Changed`

#### Example

```
local control = Section:AddUDim2Editor({
    Id = "UDim2Editor",
    Text = "U Dim2 Editor",
})
```

### AddUDim2Input

InputsNative

[#](#feature-AddUDim2Input)

Lets the user enter or edit a value using a u dim2 input control.

Configuration, feedback & example

#### Resolved implementation

`AddUDim2Input`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`UDim2Changed`

#### Example

```
local control = Section:AddUDim2Input({
    Id = "UDim2Input",
    Text = "U Dim2 Input",
})
```

### AddUDimEditor

InputsWrapper→ AddUDimInput

[#](#feature-AddUDimEditor)

Lets the user enter or edit a value using a u dim editor control. This is a convenience wrapper implemented through AddUDimInput.

Configuration, feedback & example

#### Resolved implementation

`AddUDimInput`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`UDimChanged`

#### Example

```
local control = Section:AddUDimEditor({
    Id = "UDimEditor",
    Text = "U Dim Editor",
})
```

### AddUDimInput

InputsNative

[#](#feature-AddUDimInput)

Lets the user enter or edit a value using a u dim input control.

Configuration, feedback & example

#### Resolved implementation

`AddUDimInput`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`UDimChanged`

#### Example

```
local control = Section:AddUDimInput({
    Id = "UDimInput",
    Text = "U Dim Input",
})
```

### AddUIScaleSlider

InputsNative

[#](#feature-AddUIScaleSlider)

Adds the UI Scale Slider UI feature to a section.

Configuration, feedback & example

#### Resolved implementation

`AddUIScaleSlider`

#### Common configuration keys

`Callback`, `Default`, `Max`, `Min`, `Step`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddUIScaleSlider({
    Id = "UIScaleSlider",
    Text = "UI Scale Slider",
})
```

### AddURLBox

InputsNative

[#](#feature-AddURLBox)

Lets the user enter or edit a value using a url box control.

Configuration, feedback & example

#### Resolved implementation

`AddURLBox`

#### Common configuration keys

`Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddURLBox({
    Id = "URLBox",
    Text = "URL Box",
    Default = "https://example.com",
})
```

### AddURLInput

InputsWrapper→ AddURLBox

[#](#feature-AddURLInput)

Lets the user enter or edit a value using a url input control. This is a convenience wrapper implemented through AddURLBox.

Configuration, feedback & example

#### Resolved implementation

`AddURLBox`

#### Common configuration keys

`Text`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddURLInput({
    Id = "URLInput",
    Text = "URL Input",
    Default = "https://example.com",
})
```

### AddUndoButton

ActionsNative

[#](#feature-AddUndoButton)

Creates a undo button action that the user can press.

Configuration, feedback & example

#### Resolved implementation

`AddUndoButton`

#### Common configuration keys

`Callback`, `Text`

#### Callback fields

`Callback`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddUndoButton({
    Id = "UndoButton",
    Text = "Undo Button",
})
```

### AddUnitSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddUnitSelector)

Lets the user choose a value using the unit selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddUnitSelector({
    Id = "UnitSelector",
    Text = "Unit Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddUserIdInput

InputsWrapper→ AddNumberbox

[#](#feature-AddUserIdInput)

Lets the user enter or edit a value using a user id input control. This is a convenience wrapper implemented through AddNumberbox.

Configuration, feedback & example

#### Resolved implementation

`AddNumberbox`

#### Common configuration keys

`Numeric`, `ReturnNumber`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddUserIdInput({
    Id = "UserIdInput",
    Text = "User Id Input",
})
```

### AddUsernameInput

InputsWrapper→ AddTextbox

[#](#feature-AddUsernameInput)

Lets the user enter or edit a value using a username input control. This is a convenience wrapper implemented through AddTextbox.

Configuration, feedback & example

#### Resolved implementation

`AddTextbox`

#### Common configuration keys

`Callback`, `ClearOnFocus`, `Default`, `EnterCallback`, `Height`, `Id`, `Live`, `Max`, `MaxLength`, `Min`, `Monospace`, `MultiLine`, `Numeric`, `Placeholder`, `ReturnNumber`, `Text`, `TextSize`

#### Callback fields

`Callback`, `EnterCallback`

#### Feedback events

`TextboxChanged`, `TextboxEnter`

#### Example

```
local control = Section:AddUsernameInput({
    Id = "UsernameInput",
    Text = "Username Input",
    Default = "Example text",
})
```

### AddVector2

InputsAlias→ AddVector2Input

[#](#feature-AddVector2)

Adds the Vector2 UI feature to a section. This is a convenience alias implemented through AddVector2Input.

Configuration, feedback & example

#### Resolved implementation

`AddVector2Input`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddVector2({
    Id = "Vector2",
    Text = "Vector2",
})
```

### AddVector2Editor

InputsWrapper→ AddVector2Input

[#](#feature-AddVector2Editor)

Lets the user enter or edit a value using a vector2 editor control. This is a convenience wrapper implemented through AddVector2Input.

Configuration, feedback & example

#### Resolved implementation

`AddVector2Input`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddVector2Editor({
    Id = "Vector2Editor",
    Text = "Vector2 Editor",
})
```

### AddVector2Input

InputsNative

[#](#feature-AddVector2Input)

Lets the user enter or edit a value using a vector2 input control.

Configuration, feedback & example

#### Resolved implementation

`AddVector2Input`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddVector2Input({
    Id = "Vector2Input",
    Text = "Vector2 Input",
})
```

### AddVector3

InputsAlias→ AddVector3Input

[#](#feature-AddVector3)

Adds the Vector3 UI feature to a section. This is a convenience alias implemented through AddVector3Input.

Configuration, feedback & example

#### Resolved implementation

`AddVector3Input`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddVector3({
    Id = "Vector3",
    Text = "Vector3",
})
```

### AddVector3Editor

InputsWrapper→ AddVector3Input

[#](#feature-AddVector3Editor)

Lets the user enter or edit a value using a vector3 editor control. This is a convenience wrapper implemented through AddVector3Input.

Configuration, feedback & example

#### Resolved implementation

`AddVector3Input`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddVector3Editor({
    Id = "Vector3Editor",
    Text = "Vector3 Editor",
})
```

### AddVector3Input

InputsNative

[#](#feature-AddVector3Input)

Lets the user enter or edit a value using a vector3 input control.

Configuration, feedback & example

#### Resolved implementation

`AddVector3Input`

#### Common configuration keys

No configuration keys discovered on the resolved implementation.

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddVector3Input({
    Id = "Vector3Input",
    Text = "Vector3 Input",
})
```

### AddVerticalAlignmentSelector

SelectorsWrapper→ AddEnumSelector

[#](#feature-AddVerticalAlignmentSelector)

Lets the user choose a value using the vertical alignment selector interface. This is a convenience wrapper implemented through AddEnumSelector.

Configuration, feedback & example

#### Resolved implementation

`AddEnumSelector`

#### Common configuration keys

`Callback`, `Display`, `Enum`, `Options`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddVerticalAlignmentSelector({
    Id = "VerticalAlignmentSelector",
    Text = "Vertical Alignment Selector",
    Enum = Enum.EasingStyle,
})
```

### AddViewportInstance

InputsWrapper→ AddViewportModel

[#](#feature-AddViewportInstance)

Displays information using a viewport instance. This is a convenience wrapper implemented through AddViewportModel.

Configuration, feedback & example

#### Resolved implementation

`AddViewportModel`

#### Common configuration keys

`Ambient`, `AutoRotate`, `BackgroundColor`, `Callback`, `Height`, `Id`, `LightColor`, `LightDirection`, `Model`, `RotationSpeed`, `Text`, `Zoom`

#### Callback fields

`Callback`

#### Feedback events

`ViewportModelChanged`

#### Example

```
local control = Section:AddViewportInstance({
    Id = "ViewportInstance",
    Text = "3D Preview",
    Model = workspace:FindFirstChild("MyModel"),
    Height = 180,
    AutoRotate = true,
})
```

### AddViewportModel

InputsNative

[#](#feature-AddViewportModel)

Displays a 3D Model in a ViewportFrame, with optional automatic rotation.

Configuration, feedback & example

#### Resolved implementation

`AddViewportModel`

#### Common configuration keys

`Ambient`, `AutoRotate`, `BackgroundColor`, `Callback`, `Height`, `Id`, `LightColor`, `LightDirection`, `Model`, `RotationSpeed`, `Text`, `Zoom`

#### Callback fields

`Callback`

#### Feedback events

`ViewportModelChanged`

#### Example

```
local control = Section:AddViewportModel({
    Id = "ViewportModel",
    Text = "3D Preview",
    Model = workspace:FindFirstChild("MyModel"),
    Height = 180,
    AutoRotate = true,
})
```

### AddViewportPart

InputsWrapper→ AddViewportModel

[#](#feature-AddViewportPart)

Displays information using a viewport part. This is a convenience wrapper implemented through AddViewportModel.

Configuration, feedback & example

#### Resolved implementation

`AddViewportModel`

#### Common configuration keys

`Ambient`, `AutoRotate`, `BackgroundColor`, `Callback`, `Height`, `Id`, `LightColor`, `LightDirection`, `Model`, `RotationSpeed`, `Text`, `Zoom`

#### Callback fields

`Callback`

#### Feedback events

`ViewportModelChanged`

#### Example

```
local control = Section:AddViewportPart({
    Id = "ViewportPart",
    Text = "3D Preview",
    Model = workspace:FindFirstChild("MyModel"),
    Height = 180,
    AutoRotate = true,
})
```

### AddViewportSize

InputsWrapper→ AddKeyValue

[#](#feature-AddViewportSize)

Displays information using a viewport size. This is a convenience wrapper implemented through AddKeyValue.

Configuration, feedback & example

#### Resolved implementation

`AddKeyValue`

#### Common configuration keys

`Default`, `Height`, `Id`, `Key`, `Text`, `Value`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

`KeyValueChanged`

#### Example

```
local control = Section:AddViewportSize({
    Id = "ViewportSize",
    Text = "Viewport Size",
})
```

### AddVolumeInput

InputsWrapper→ AddSlider

[#](#feature-AddVolumeInput)

Lets the user enter or edit a value using a volume input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddVolumeInput({
    Id = "VolumeInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddWarningCard

VisualsWrapper→ AddCallout

[#](#feature-AddWarningCard)

Displays information using a warning card. This is a convenience wrapper implemented through AddCallout.

Configuration, feedback & example

#### Resolved implementation

`AddCallout`

#### Common configuration keys

`Height`, `Text`, `Title`, `Type`

#### Callback fields

No dedicated callback field detected.

#### Feedback events

No dedicated feedback event detected.

#### Example

```
local control = Section:AddWarningCard({
    Id = "WarningCard",
    Text = "Warning Card",
})
```

### AddWizard

Layout & OtherWrapper→ AddMiniTabs

[#](#feature-AddWizard)

Adds the Wizard UI feature to a section. This is a convenience wrapper implemented through AddMiniTabs.

Configuration, feedback & example

#### Resolved implementation

`AddMiniTabs`

#### Common configuration keys

`Callback`, `Default`, `Height`, `Id`, `Tabs`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`MiniTabChanged`

#### Example

```
local control = Section:AddWizard({
    Id = "Wizard",
    Text = "Wizard",
})
```

### AddXPBar

VisualsWrapper→ AddProgress

[#](#feature-AddXPBar)

Adds the XP Bar UI feature to a section. This is a convenience wrapper implemented through AddProgress.

Configuration, feedback & example

#### Resolved implementation

`AddProgress`

#### Common configuration keys

`Callback`, `Color`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `ShowValue`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`ProgressChanged`

#### Example

```
local control = Section:AddXPBar({
    Id = "XPBar",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

### AddYearSelector

SelectorsNative→ AddDropdown

[#](#feature-AddYearSelector)

Lets the user choose a value using the year selector interface.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddYearSelector({
    Id = "YearSelector",
    Text = "Year Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddYesNoSelector

SelectorsWrapper→ AddDropdown

[#](#feature-AddYesNoSelector)

Lets the user choose a value using the yes no selector interface. This is a convenience wrapper implemented through AddDropdown.

Configuration, feedback & example

#### Resolved implementation

`AddDropdown`

#### Common configuration keys

`Callback`, `Default`, `Display`, `Height`, `Id`, `MaxHeight`, `Options`, `Placeholder`, `Text`

#### Callback fields

`Callback`, `Display`

#### Feedback events

`DropdownChanged`

#### Example

```
local control = Section:AddYesNoSelector({
    Id = "YesNoSelector",
    Text = "Yes No Selector",
    Options = {"Alpha", "Bravo", "Charlie"},
    Default = "Alpha",
})
```

### AddZoomInput

InputsWrapper→ AddSlider

[#](#feature-AddZoomInput)

Lets the user enter or edit a value using a zoom input control. This is a convenience wrapper implemented through AddSlider.

Configuration, feedback & example

#### Resolved implementation

`AddSlider`

#### Common configuration keys

`Accent`, `Callback`, `Default`, `Height`, `Id`, `Max`, `Min`, `Prefix`, `Step`, `Suffix`, `Text`

#### Callback fields

`Callback`

#### Feedback events

`SliderChanged`

#### Example

```
local control = Section:AddZoomInput({
    Id = "ZoomInput",
    Text = "Amount",
    Min = 0,
    Max = 100,
    Default = 50,
    Step = 1,
})
```

## 12. Feedback event index

These event names were detected in direct Raynard implementations. Wrappers generally inherit the events of the control they target.

`AccentChanged``ActionPressed``AllControlsDisabled``AllControlsVisible``AvatarChanged``BreadcrumbPressed``ButtonGroupPressed``ButtonPressed``Changed``ChecklistChanged``ChipSelected``ColorChanged``CommandRun``CommandSubmitted``ComponentRegistered``ConfirmResult``CountdownFinished``CustomEvent``DisclosureChanged``DoubleClicked``DropdownChanged``FeedItemAdded``FirstClick``GlobalKeybindTriggered``HeatmapCellPressed``HoldCancelled``HoldCompleted``IconButtonPressed``ImageChanged``ImagePressed``InstanceChanged``KeyValueChanged``KeybindChanged``KeybindTriggered``LanguageChanged``LanguageListChanged``ListSelected``LocaleChanged``LogAdded``MeterChanged``MiniTabChanged``MultiDropdownChanged``Notification``PageChanged``PasswordChanged``PlayerCardChanged``PlayerListSelected``PlayerSelected``PresetApplied``PresetRegistered``ProgressChanged``PromptResult``PropertyChanged``RGBChanged``RadioChanged``RangeChanged``RatingChanged``ReorderChanged``SearchChanged``SearchDropdownChanged``SearchableListSelected``SectionCollapsed``SegmentedChanged``SidebarVisibilityChanged``SliderChanged``StatChanged``StateImported``StatusChanged``StepperChanged``SwatchChanged``TabSelected``TableRowSelected``TagsChanged``TextboxChanged``TextboxEnter``ThemeApplied``ToggleButtonChanged``ToggleChanged``TreeNodeSelected``TriStateChanged``UDim2Changed``UDimChanged``Validation``ViewportModelChanged``VisibilityChanged``WindowClosed``WindowMaximized``WindowMinimized``WindowResized`

## 13. Common recipes

### Read a value

```
local speed = UI:GetValue("Speed")
print(speed)
```

### Change a value

```
UI:SetValue("Speed", 75)
```

### Hide the entire UI

```
UI:SetVisible(false)
-- or
UI:Toggle()
```

### Disable a control

```
local control = UI:GetControl("Speed")
control:Disable()
```

### Watch one control

```
UI:WatchControl("Speed", function(value)
    print("Speed changed", value)
end)
```

### Bind two controls

```
UI:BindControls("Speed", "Progress", function(value)
    return value
end)
```

### Localization

```
UI:RegisterLocale("en", {Hello = "Hello"})
UI:RegisterLocale("es", {Hello = "Hola"})
UI:SetLocale("es")
print(UI:Translate("Hello", "Hello"))
```

### Theme presets

```
UI:RegisterTheme("Green", {
    Colors = {
        Accent = Color3.fromRGB(110, 220, 150),
    },
})
UI:ApplyTheme("Green")
```

## 14. Troubleshooting

### Nothing appears

Make sure the **ModuleScript** is in ReplicatedStorage and the code calling it is a **LocalScript** in StarterPlayerScripts/StarterGui or another client-running location. A LocalScript sitting in ReplicatedStorage does not execute.

### Infinite yield on WaitForChild

The name must match exactly. The ModuleScript name must match exactly. If it is named `Raynard`, require it with `WaitForChild("Raynard")`.

### Duplicate control Id

Every explicit control Id must be unique inside one UI instance. Rename one of the duplicate IDs.

### Feature exists but looks like another feature

Check its card in the catalog. It may intentionally be a wrapper or alias that resolves to a shared renderer.

### A callback errors

Look in Roblox Studio Output. Raynard runs callbacks through protected calls and warns with `[Raynard Callback]` when your callback throws an error.

### 425-control showcase is slow

The full Raynard showcase deliberately creates hundreds of widgets. A real game UI should only instantiate the controls it needs.

## 15. Beginner glossary

| Term | Meaning |
| --- | --- |
| ModuleScript | A reusable Roblox Lua module loaded with `require()`. |
| LocalScript | Code that runs on a player's client. Raynard is intended to be created from client code. |
| Callback | A function you give a control so your code runs when something happens. |
| Control handle | The object returned by an Add… method. You can call methods like Get, Set, Hide, or Disable on it. |
| Id | A unique text identifier used to find and manipulate a control later. |
| Alias | Another public method name pointing at an existing implementation. |
| Wrapper | A convenience method that configures or forwards to another underlying control. |
| Feedback packet | A table sent through `UI.Feedback` describing an interaction. |
| State | The current values of controls, usually keyed by control Id. |
| Enum | A Roblox predefined set of named values, such as `Enum.KeyCode.G`. |
