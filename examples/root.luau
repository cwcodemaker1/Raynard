-- Optional: point parser.luau at another branch/repository without editing it.
local env = getgenv and getgenv() or _G
env.RaynardParserConfig = {
    Root = "https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/",
}

local Raynard = loadstring(game:HttpGet(
    env.RaynardParserConfig.Root .. "parser.luau"
))()

local UI = Raynard({Title = "Custom Parser Root"})
