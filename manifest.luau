-- Raynard modular manifest
-- File order matters because parser.luau concatenates these before compiling.

return {
    Name = "Raynard",
    Version = "Modular 1",
    SourceDirectory = "src/",
    Files = {
        "00_core.luau",
        "10_window_sections.luau",
        "20_controls_standard.luau",
        "30_controls_player_color.luau",
        "40_framework_extensions.luau",
        "50_controls_input.luau",
        "60_controls_data.luau",
        "70_controls_visual.luau",
        "80_controls_advanced.luau",
        "90_features_v5_v6.luau",
    },
}
