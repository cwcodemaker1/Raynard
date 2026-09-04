# Raynard — Modular Source Build

Raynard is now split across multiple source files instead of being maintained as one giant `main.luau`.

## How it works

`parser.luau` is the only file a client needs to load directly. It:

1. downloads `manifest.luau`;
2. reads the ordered list of Raynard source fragments;
3. downloads each file under `src/`;
4. concatenates those fragments **before compilation**;
5. compiles the combined source once; and
6. returns the normal Raynard library table.

Concatenating before compilation is deliberate. Raynard has many internal `local` functions and tables that reference one another. Compiling every fragment separately would break those local relationships. The parser approach gives you modular files on GitHub while preserving the exact single-chunk Luau semantics Raynard expects.

## Repository layout

```text
Raynard/
├─ parser.luau
├─ manifest.luau
├─ src/
│  ├─ 00_core.luau
│  ├─ 10_window_sections.luau
│  ├─ 20_controls_standard.luau
│  ├─ 30_controls_player_color.luau
│  ├─ 40_framework_extensions.luau
│  ├─ 50_controls_input.luau
│  ├─ 60_controls_data.luau
│  ├─ 70_controls_visual.luau
│  ├─ 80_controls_advanced.luau
│  └─ 90_features_v5_v6.luau
└─ examples/
   ├─ basic.client.luau
   └─ custom-root.client.luau
```

## Normal usage

Upload the package contents to the root of the Raynard repository, then clients only need:

```lua
local Raynard = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/parser.luau"
))()

local UI = Raynard({
    Title = "My UI",
    ToggleKey = Enum.KeyCode.RightShift,
})
```

Existing code after the loader remains normal Raynard code:

```lua
local Main = UI:AddTab("Players")
local PlayersSection = Main:AddSection("Players")

PlayersSection:AddPlayerList({
    Id = "Players",
    Text = "Player",
})
```

## Adding another Raynard source file

Create a new `.luau` file in `src/` and add it to `manifest.luau` in the exact location where it should execute.

For example:

```lua
Files = {
    "00_core.luau",
    "10_window_sections.luau",
    "15_my_new_framework_feature.luau",
    "20_controls_standard.luau",
}
```

The parser does not need to be changed.

## Why the manifest order matters

The fragments form one Luau source chunk. Definitions must therefore appear before code that depends on them. `00_core.luau` must remain first and `90_features_v5_v6.luau` must remain last unless the framework architecture itself is changed.

## Parser configuration

By default the parser uses:

```text
https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/
```

To test another branch/repository:

```lua
local env = getgenv and getgenv() or _G

env.RaynardParserConfig = {
    Root = "https://raw.githubusercontent.com/cwcodemaker1/Raynard/dev/",
}

local Raynard = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/parser.luau"
))()
```

`RaynardParserConfig.Sources` can also provide individual fragment source strings directly, which is useful while developing a fragment without publishing it first.

## Avatar viewport

This modular build includes the updated `AddAvatarViewport` implementation with:

```lua
FixedRotation = 180
AutoRotate = true
RotationSpeed = 35
```

and runtime methods including:

```lua
Avatar:SetFixedRotation(180)
Avatar:SetRotation(45)
Avatar:SetAutoRotate(true)
Avatar:SetRotationSpeed(25)
Avatar:ResetRotation()
```

Only `HumanoidRootPart` is anchored in the viewport clone so R6/R15 Motor6Ds, the neck, waist, shoulders, hips, and accessory welds remain intact.

## Notes

- This loader targets client environments that provide `game:HttpGet` and `loadstring`.
- `ToggleKey = false` is supported because Raynard's input matcher ignores non-Enum bindings.
- The framework is branded as **Raynard** throughout this build.
