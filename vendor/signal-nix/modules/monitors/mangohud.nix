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
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.mangohud.settings
# UPSTREAM SCHEMA: https://github.com/flightlessmango/MangoHud#configuration
# SCHEMA VERSION: 0.7.0
# LAST VALIDATED: 2026-01-18
# NOTES: MangoHud is a gaming overlay for Vulkan/OpenGL on Linux.
#        Colors use hex format WITHOUT # prefix. Alpha is a separate float (0.0-1.0).
#        Works with Steam, native games, Wine/Proton, and Lutris.
let
  inherit (lib) mkIf mkDefault removePrefix;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    divider-primary = semantic.ui "panel-border" themeMode;
  };

  inherit (signalPalette) accent;

  # Helper to get hex without # prefix (MangoHud requirement)
  hexRaw = color: removePrefix "#" color.hex;

  # Check if mangohud should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "mangohud" [
    "monitors"
    "mangohud"
  ] cfg config;

  # Platform guard - MangoHud is Linux-only (Vulkan/OpenGL overlay)
  platformOk = signalLib.platform.guard pkgs "mangohud";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    programs.mangohud = {
      settings = {
        # Background overlay colors
        background_color = mkDefault (hexRaw colors.surface-base);
        background_alpha = mkDefault 0.8; # 80% opacity for visibility while gaming

        # Text color for all labels
        text_color = mkDefault (hexRaw colors.text-primary);

        # Component-specific colors
        gpu_color = mkDefault (hexRaw accent.tertiary.Lc75); # Purple for GPU metrics
        cpu_color = mkDefault (hexRaw accent.secondary.Lc75); # Blue for CPU metrics
        vram_color = mkDefault (hexRaw accent.warning.Lc75); # Yellow/orange for VRAM
        ram_color = mkDefault (hexRaw accent.primary.Lc75); # Green for RAM metrics

        # Graph colors
        frametime_color = mkDefault (hexRaw accent.secondary.Lc75); # Blue for performance graphs
        engine_color = mkDefault (hexRaw colors.text-secondary); # Secondary text for engine info
        wine_color = mkDefault (hexRaw accent.tertiary.Lc75); # Purple for Wine/Proton info

        # Additional graph colors for consistency
        gpu_load_color = mkDefault [
          (hexRaw accent.tertiary.Lc75)
          (hexRaw accent.tertiary.Lc75)
        ];
        cpu_load_color = mkDefault [
          (hexRaw accent.secondary.Lc75)
          (hexRaw accent.secondary.Lc75)
        ];

        # Network colors (if network stats enabled)
        network_color_download = mkDefault (hexRaw accent.primary.Lc75); # Green for download
        network_color_upload = mkDefault (hexRaw accent.danger.Lc75); # Red for upload
      };
    };
  };
}
