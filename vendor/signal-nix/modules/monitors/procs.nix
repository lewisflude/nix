{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
# CONFIGURATION METHOD: xdg-config-file (Tier 4)
# HOME-MANAGER MODULE: xdg.configFile
# UPSTREAM SCHEMA: https://github.com/dalance/procs#configuration
# SCHEMA VERSION: v0.14.10
# LAST VALIDATED: 2026-01-18
# NOTES: Procs uses TOML configuration with terminal color names.
#        Colors support theme-aware format: "BrightColor|Color" (dark|light).
#        Config location: ~/.config/procs/config.toml
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  # Map Signal colors to terminal color names
  # Procs uses standard terminal color names (BrightWhite, Blue, etc.)
  # Format: "DarkThemeColor|LightThemeColor" or single color for both
  colors = {
    # Surface and text colors
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-tertiary = semantic.text "tertiary" themeMode;
    divider = semantic.ui "panel-border" themeMode;

    # Accent colors for semantic meanings
    primary = semantic.status "success" themeMode;
    secondary = semantic.status "info" themeMode;
    tertiary = semantic.syntax "keyword" themeMode; # Uses tertiary accent
    success = semantic.status "success" themeMode;
    warning = semantic.status "warning" themeMode;
    danger = semantic.status "error" themeMode;
    info = semantic.status "info" themeMode;

    # Categorical colors for varied data
    # Note: Using getCategorical helper for direct data-viz access
    # Required by procs config format for process coloring
    data-viz-01 = semantic.getCategorical "data-viz-01" themeMode;
    data-viz-02 = semantic.getCategorical "data-viz-02" themeMode;
  };

  # Generate TOML config content
  # Procs expects specific color format and sections
  procsConfig = pkgs.writeText "procs-config.toml" ''
    # Signal Theme for procs
    # Generated from Signal Design System

    # Column definitions - keeping procs defaults, just theming colors
    [[columns]]
    kind = "Pid"
    style = "BrightYellow"
    numeric_search = true
    nonnumeric_search = false

    [[columns]]
    kind = "User"
    style = "BrightGreen"
    numeric_search = false
    nonnumeric_search = true

    [[columns]]
    kind = "State"
    style = "ByState"
    numeric_search = false
    nonnumeric_search = false

    [[columns]]
    kind = "Nice"
    style = "BrightCyan"
    numeric_search = false
    nonnumeric_search = false
    align = "Right"

    [[columns]]
    kind = "CpuTime"
    style = "BrightCyan"
    numeric_search = false
    nonnumeric_search = false

    [[columns]]
    kind = "UsageCpu"
    style = "ByPercentage"
    numeric_search = false
    nonnumeric_search = false
    align = "Right"

    [[columns]]
    kind = "UsageMem"
    style = "ByPercentage"
    numeric_search = false
    nonnumeric_search = false
    align = "Right"

    [[columns]]
    kind = "VmSize"
    style = "ByUnit"
    numeric_search = false
    nonnumeric_search = false
    align = "Right"

    [[columns]]
    kind = "VmRss"
    style = "ByUnit"
    numeric_search = false
    nonnumeric_search = false
    align = "Right"

    [[columns]]
    kind = "TcpPort"
    style = "BrightMagenta"
    numeric_search = true
    nonnumeric_search = false
    align = "Right"

    [[columns]]
    kind = "UdpPort"
    style = "BrightMagenta"
    numeric_search = true
    nonnumeric_search = false
    align = "Right"

    [[columns]]
    kind = "Command"
    style = "BrightWhite"
    numeric_search = false
    nonnumeric_search = true

    # Style section - themed with Signal colors
    [style]
    header = "BrightWhite"
    unit = "BrightWhite"
    tree = "BrightCyan"

    # Percentage-based coloring (0% -> 100%)
    # Low usage = blue/green, high usage = yellow/red
    [style.by_percentage]
    color_000 = "BrightBlue"      # 0-25%: Low usage (blue)
    color_025 = "BrightGreen"     # 25-50%: Moderate usage (green)
    color_050 = "BrightYellow"    # 50-75%: High usage (yellow)
    color_075 = "BrightRed"       # 75-100%: Very high usage (red)
    color_100 = "BrightRed"       # 100%+: Critical usage (red)

    # Process state coloring
    # D=uninterruptible sleep, R=running, S=sleeping, T=stopped, Z=zombie, etc.
    [style.by_state]
    color_d = "BrightRed"         # D: Uninterruptible sleep (danger)
    color_r = "BrightGreen"       # R: Running (success)
    color_s = "BrightBlue"        # S: Sleeping (info)
    color_t = "BrightCyan"        # T: Stopped (info)
    color_z = "BrightMagenta"     # Z: Zombie (warning)
    color_x = "BrightMagenta"     # X: Dead (warning)
    color_k = "BrightYellow"      # K: Wakekill (warning)
    color_w = "BrightYellow"      # W: Waking (warning)
    color_p = "BrightYellow"      # P: Parked (warning)

    # Unit-based coloring (K, M, G, T, P)
    # Smaller units = blue/green, larger units = yellow/red
    [style.by_unit]
    color_k = "BrightBlue"        # Kilobytes (small)
    color_m = "BrightGreen"       # Megabytes (medium)
    color_g = "BrightYellow"      # Gigabytes (large)
    color_t = "BrightRed"         # Terabytes (very large)
    color_p = "BrightRed"         # Petabytes (critical)
    color_x = "BrightBlue"        # Other units

    # Search configuration
    [search]
    numeric_search = "Exact"
    nonnumeric_search = "Partial"
    logic = "And"
    case = "Smart"

    # Display configuration
    [display]
    show_self = false
    show_thread = false
    show_thread_in_tree = true
    cut_to_terminal = true
    cut_to_pager = false
    cut_to_pipe = false
    color_mode = "Auto"
    separator = "│"
    ascending = "▲"
    descending = "▼"
    tree_symbols = ["│", "─", "┬", "├", "└"]
    theme = "Auto"

    # Sort configuration
    [sort]
    column = 0
    order = "Ascending"

    # Docker configuration
    [docker]
    path = "unix:///var/run/docker.sock"

    # Pager configuration
    [pager]
    mode = "Auto"
    detect_width = false
    use_builtin = false
  '';

  # Check if procs should be themed
  shouldTheme = signalLib.shouldThemeApp "procs" [
    "monitors"
    "procs"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    # Link the config file to the expected location
    xdg.configFile."procs/config.toml".source = procsConfig;
  };
}
