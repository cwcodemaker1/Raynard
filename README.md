# Raynard 

Raynard is split into small ordered Luau source files and assembled by `parser.luau`. The public entrypoint is `init.luau`.

## Layout

```text
examples/
  client.luau
  root.luau
src/
  advanced.luau
  avatar.luau
  control.luau
  controlcolor.luau
  core.luau
  data.luau
  feat.luau
  framework.luau
  init.luau
  inputs.luau
  visual.luau
  window.luau
README.md
init.luau
manifest.luau
parser.luau
```

## Load

```lua
local Raynard=loadstring(game:HttpGet("https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/init.luau"))()
local UI=Raynard({Title="My UI"})
```

`init.luau` refreshes the local `Rayward` cache when file APIs are available and then runs `parser.luau`. `parser.luau` reads the files in `manifest.luau`, combines them once, compiles them once, and returns the Raynard library. `src/init.luau` is the final source fragment and returns the completed library.

The revamp keeps the existing Raynard control APIs, moves viewport/avatar controls into `src/avatar.luau`, fixes stale local installs, fixes callback/custom-build error handling, fixes the filterable-table search implementation, removes old UIBuilder naming, and keeps avatar rotation rig-safe.
