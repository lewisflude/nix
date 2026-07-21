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
# CONFIGURATION METHOD: theme-file (Tier 1)
# HOME-MANAGER MODULE: programs.rofi.theme
# UPSTREAM SCHEMA: https://github.com/davatorium/rofi/blob/next/doc/rofi-theme.5.markdown
# SCHEMA VERSION: 1.7.5
# LAST VALIDATED: 2026-01-17
# NOTES: Rofi uses its own CSS-like theme format with @theme directive.
#        Home Manager accepts an attrset that gets serialized to .rasi format.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    surface-raised = semantic.ui "element-hover" themeMode;
    surface-hover = semantic.ui "element-active" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    divider-primary = semantic.ui "panel-border" themeMode;
    selected = semantic.core "focus" themeMode;
    active = semantic.status "success" themeMode;
    urgent = semantic.status "error" themeMode;
  };

  # Check if rofi should be themed
  shouldTheme = signalLib.shouldThemeApp "rofi" [
    "desktop"
    "launchers"
    "rofi"
  ] cfg config;

  # Platform guard - Rofi is Linux-only (X11/Wayland launcher)
  platformOk = signalLib.platform.guard pkgs "rofi";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    programs.rofi.theme = {
      "*" = {
        background = colors.surface-base.hex;
        background-alt = colors.surface-raised.hex;
        foreground = colors.text-primary.hex;
        foreground-alt = colors.text-secondary.hex;
        selected = colors.selected.hex;
        active = colors.active.hex;
        urgent = colors.urgent.hex;
        border-color = colors.divider-primary.hex;
      };

      window = {
        background-color = "@background";
        border = "2px";
        border-color = "@border-color";
      };

      mainbox = {
        background-color = "@background";
        children = [
          "inputbar"
          "message"
          "listview"
        ];
      };

      inputbar = {
        background-color = "@background-alt";
        text-color = "@foreground";
        border = "0 0 2px 0";
        border-color = "@selected";
        children = [
          "prompt"
          "entry"
        ];
      };

      prompt = {
        background-color = "inherit";
        text-color = "@selected";
      };

      entry = {
        background-color = "inherit";
        text-color = "@foreground";
        placeholder = "Search...";
        placeholder-color = "@foreground-alt";
      };

      message = {
        background-color = "@background-alt";
        border = "2px 0 0 0";
        border-color = "@border-color";
      };

      textbox = {
        background-color = "inherit";
        text-color = "@foreground";
      };

      listview = {
        background-color = "@background";
        border = "2px 0 0 0";
        border-color = "@border-color";
        lines = 8;
        scrollbar = true;
      };

      element = {
        background-color = "@background";
        text-color = "@foreground";
      };

      "element selected normal" = {
        background-color = "@selected";
        text-color = "@background";
      };

      "element selected active" = {
        background-color = "@active";
        text-color = "@background";
      };

      "element selected urgent" = {
        background-color = "@urgent";
        text-color = "@background";
      };

      "element normal active" = {
        text-color = "@active";
      };

      "element normal urgent" = {
        text-color = "@urgent";
      };

      "element alternate normal" = {
        background-color = "@background";
      };

      "element alternate active" = {
        background-color = "@background";
        text-color = "@active";
      };

      "element alternate urgent" = {
        background-color = "@background";
        text-color = "@urgent";
      };

      scrollbar = {
        background-color = "@background-alt";
        handle-color = "@selected";
        border = "0 0 0 2px";
        border-color = "@border-color";
      };
    };
  };
}
