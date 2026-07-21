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
# CONFIGURATION METHOD: stylesheet (Tier 1) + JSON config
# HOME-MANAGER MODULE: programs.waybar.style
# UPSTREAM SCHEMA: https://github.com/Alexays/Waybar/wiki/Styling
# SCHEMA VERSION: 0.10.0
# LAST VALIDATED: 2026-01-17
# NOTES: Waybar uses CSS for styling. Home Manager provides a style option
#        that accepts a string containing CSS. We provide a comprehensive stylesheet.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for all colors
  c = {
    surface-base = (semantic.ui "panel-background" themeMode).hex;
    surface-raised = (semantic.ui "element-hover" themeMode).hex;
    surface-hover = (semantic.ui "element-active" themeMode).hex;
    text-primary = (semantic.text "primary" themeMode).hex;
    text-secondary = (semantic.text "secondary" themeMode).hex;
    text-tertiary = (semantic.text "tertiary" themeMode).hex;
    divider-primary = (semantic.ui "panel-border" themeMode).hex;
    accent-primary = (semantic.vcs "modified" themeMode).hex;
    accent-danger = (semantic.status "error" themeMode).hex;
    accent-warning = (semantic.status "warning" themeMode).hex;
    accent-success = (semantic.status "success" themeMode).hex;
  };

  # Check if waybar should be themed
  shouldTheme = signalLib.shouldThemeApp "waybar" [
    "desktop"
    "bars"
    "waybar"
  ] cfg config;

  # Platform guard - Waybar is Linux-only (Wayland/X11 status bar)
  platformOk = signalLib.platform.guard pkgs "waybar";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    programs.waybar.style = ''
      * {
        font-family: "Inter", sans-serif;
        font-size: 13px;
        font-weight: 500;
        min-height: 0;
      }

      window#waybar {
        background-color: ${c.surface-base};
        color: ${c.text-primary};
        border-bottom: 2px solid ${c.divider-primary};
      }

      #workspaces button {
        padding: 0 8px;
        color: ${c.text-secondary};
        background-color: transparent;
        border: none;
        border-bottom: 2px solid transparent;
      }

      #workspaces button.focused,
      #workspaces button.active {
        color: ${c.text-primary};
        background-color: ${c.surface-raised};
        border-bottom: 2px solid ${c.accent-primary};
      }

      #workspaces button.urgent {
        color: ${c.accent-danger};
        border-bottom: 2px solid ${c.accent-danger};
      }

      #workspaces button:hover {
        background-color: ${c.surface-hover};
        color: ${c.text-primary};
      }

      #mode {
        background-color: ${c.accent-warning};
        color: ${c.surface-base};
        padding: 0 12px;
        font-weight: 600;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #wireplumber,
      #custom-media,
      #tray,
      #mode,
      #idle_inhibitor,
      #scratchpad,
      #mpd,
      #language {
        padding: 0 12px;
        color: ${c.text-primary};
      }

      #battery.charging,
      #battery.plugged {
        color: ${c.accent-success};
      }

      #battery.critical:not(.charging) {
        background-color: ${c.accent-danger};
        color: ${c.surface-base};
        animation: blink 0.5s linear infinite alternate;
      }

      @keyframes blink {
        to {
          opacity: 0.7;
        }
      }

      #cpu.warning {
        color: ${c.accent-warning};
      }

      #cpu.critical {
        color: ${c.accent-danger};
      }

      #memory.warning {
        color: ${c.accent-warning};
      }

      #memory.critical {
        color: ${c.accent-danger};
      }

      #temperature.critical {
        color: ${c.accent-danger};
      }

      #network.disconnected {
        color: ${c.text-tertiary};
      }

      #pulseaudio.muted,
      #wireplumber.muted {
        color: ${c.text-tertiary};
      }

      #idle_inhibitor.activated {
        color: ${c.accent-primary};
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        color: ${c.accent-danger};
      }

      tooltip {
        background-color: ${c.surface-raised};
        color: ${c.text-primary};
        border: 1px solid ${c.divider-primary};
        border-radius: 4px;
      }

      tooltip label {
        color: ${c.text-primary};
      }
    '';
  };
}
