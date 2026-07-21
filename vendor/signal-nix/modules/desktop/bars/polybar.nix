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
# CONFIGURATION METHOD: ini-config (Tier 2)
# HOME-MANAGER MODULE: services.polybar.settings
# UPSTREAM SCHEMA: https://github.com/polybar/polybar
# SCHEMA VERSION: 3.7.1
# LAST VALIDATED: 2026-01-17
# NOTES: Polybar uses INI-style config with [bar/...] and [module/...] sections.
#        Home-Manager provides settings attrset. We define colors section.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Polybar uses hex with optional alpha: #AARRGGBB or #RRGGBB
  # Check if polybar should be themed
  # Check if polybar should be themed
  # NOTE: Polybar is a service, not a program, so we check services.polybar.enable
  shouldTheme =
    cfg.desktop.bars.polybar.enable || (cfg.autoEnable && (config.services.polybar.enable or false));

  # Platform guard - Polybar is Linux-only (X11 status bar)
  platformOk = signalLib.platform.guard pkgs "polybar";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    services.polybar.settings = {
      # Colors section that can be referenced in bar configs - using semantic bridge
      "colors" = {
        background = (semantic.ui "panel-background" themeMode).hex;
        background-alt = (semantic.ui "element-hover" themeMode).hex;
        foreground = (semantic.text "primary" themeMode).hex;
        foreground-alt = (semantic.text "secondary" themeMode).hex;
        foreground-dim = (semantic.text "tertiary" themeMode).hex;

        # Accent colors
        primary = (semantic.vcs "modified" themeMode).hex;
        secondary = (semantic.vcs "modified" themeMode).hex;
        alert = (semantic.status "error" themeMode).hex;
        warning = (semantic.status "warning" themeMode).hex;
        success = (semantic.status "success" themeMode).hex;

        # UI elements
        border = (semantic.ui "panel-border" themeMode).hex;

        # Module-specific colors
        cpu = (semantic.vcs "modified" themeMode).hex;
        memory = (semantic.vcs "modified" themeMode).hex;
        network = (semantic.status "success" themeMode).hex;
        battery = (semantic.status "warning" themeMode).hex;
        temperature = (semantic.status "error" themeMode).hex;
      };

      # Example bar config using Signal colors
      # Users can override this in their own config
      "bar/signal" = {
        background = "\${colors.background}";
        foreground = "\${colors.foreground}";

        border-color = "\${colors.border}";

        # Module colors

        # Font (users should override)
        font-0 = "Inter:size=10;2";
      };

      # Example module configs
      "module/cpu" = {
        type = "internal/cpu";
        format-prefix = "CPU ";
        format-prefix-foreground = "\${colors.cpu}";
        label = "%percentage%%";
      };

      "module/memory" = {
        type = "internal/memory";
        format-prefix = "RAM ";
        format-prefix-foreground = "\${colors.memory}";
        label = "%percentage_used%%";
      };

      "module/date" = {
        type = "internal/date";
        date = "%Y-%m-%d%";
        time = "%H:%M";
        label = "%date% %time%";
        format-foreground = "\${colors.foreground}";
      };

      "module/battery" = {
        type = "internal/battery";
        battery = "BAT0";
        adapter = "AC";
        format-charging = "<label-charging>";
        format-charging-foreground = "\${colors.success}";
        format-discharging = "<label-discharging>";
        format-discharging-foreground = "\${colors.foreground}";
        format-full = "<label-full>";
        format-full-foreground = "\${colors.success}";
        label-charging = "⚡ %percentage%%";
        label-discharging = "🔋 %percentage%%";
        label-full = "🔌 Full";
      };
    };
  };
}
