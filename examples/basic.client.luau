-- Example: load modular Raynard from GitHub.
local Raynard = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/cwcodemaker1/Raynard/main/parser.luau"
))()

local UI = Raynard({
    Title = "Raynard Modular",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = UI:AddTab("Main")
local Section = Main:AddSection("Example")

Section:AddLabel({Text = "Raynard was assembled by parser.luau"})
Section:AddToggle({Text = "Enabled", Default = true})
Section:AddSlider({Text = "Speed", Min = 0, Max = 100, Default = 50})
