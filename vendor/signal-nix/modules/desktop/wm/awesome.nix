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
# CONFIGURATION METHOD: lua-config (Tier 4)
# HOME-MANAGER MODULE: xsession.windowManager.awesome (via xdg.configFile)
# UPSTREAM SCHEMA: https://awesomewm.org/
# SCHEMA VERSION: 4.3
# LAST VALIDATED: 2026-01-17
# NOTES: awesome uses Lua for config. We provide a theme file with ONLY colors.
#        Users configure borders, gaps, fonts, menu sizes, etc. in their own theme.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for all colors
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    surface-raised = semantic.ui "element-hover" themeMode;
    text-primary = semantic.text "primary" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-dim = semantic.text "tertiary" themeMode;
    divider = semantic.ui "panel-border" themeMode;
  };

  # Generate awesome theme file in Lua - COLORS ONLY
  awesomeTheme = ''
    -- Signal theme for awesome WM - COLORS ONLY
    -- To use: require("signal-theme") in your rc.lua
    -- Configure borders, gaps, fonts, sizes, etc. in your own theme file

    local theme = {}

    -- Background colors
    theme.bg_normal     = "${colors.surface-base.hex}"
    theme.bg_focus      = "${colors.surface-raised.hex}"
    theme.bg_urgent     = "${(semantic.status "error" themeMode).hex}"
    theme.bg_minimize   = "${colors.divider.hex}"
    theme.bg_systray    = theme.bg_normal

    -- Foreground colors
    theme.fg_normal     = "${colors.text-secondary.hex}"
    theme.fg_focus      = "${colors.text-primary.hex}"
    theme.fg_urgent     = "${colors.surface-base.hex}"
    theme.fg_minimize   = "${colors.text-dim.hex}"

    -- Border colors (not border_width)
    theme.border_normal = "${colors.divider.hex}"
    theme.border_focus  = "${(semantic.vcs "modified" themeMode).hex}"
    theme.border_marked = "${(semantic.status "warning" themeMode).hex}"

    -- Titlebar colors
    theme.titlebar_bg_normal = theme.bg_normal
    theme.titlebar_bg_focus  = theme.bg_focus
    theme.titlebar_fg_normal = theme.fg_normal
    theme.titlebar_fg_focus  = theme.fg_focus

    -- Taglist colors
    theme.taglist_bg_focus    = "${(semantic.vcs "modified" themeMode).hex}"
    theme.taglist_fg_focus    = "${colors.surface-base.hex}"
    theme.taglist_bg_occupied = theme.bg_focus
    theme.taglist_fg_occupied = theme.fg_normal
    theme.taglist_bg_empty    = theme.bg_normal
    theme.taglist_fg_empty    = theme.fg_minimize
    theme.taglist_bg_urgent   = theme.bg_urgent
    theme.taglist_fg_urgent   = theme.fg_urgent

    -- Tasklist colors
    theme.tasklist_bg_normal = theme.bg_normal
    theme.tasklist_fg_normal = theme.fg_normal
    theme.tasklist_bg_focus  = theme.bg_focus
    theme.tasklist_fg_focus  = theme.fg_focus
    theme.tasklist_bg_urgent = theme.bg_urgent
    theme.tasklist_fg_urgent = theme.fg_urgent

    -- Menu colors (not sizes)
    theme.menu_bg_normal = theme.bg_normal
    theme.menu_bg_focus  = theme.bg_focus
    theme.menu_fg_normal = theme.fg_normal
    theme.menu_fg_focus  = theme.fg_focus
    theme.menu_border_color = "${colors.divider.hex}"

    -- Notification colors (not sizes)
    theme.notification_bg = theme.bg_normal
    theme.notification_fg = theme.fg_normal
    theme.notification_border_color = "${(semantic.vcs "modified" themeMode).hex}"
    theme.notification_opacity = 0.95

    -- Hotkeys popup colors (not fonts)
    theme.hotkeys_bg = theme.bg_normal
    theme.hotkeys_fg = theme.fg_normal
    theme.hotkeys_border_color = theme.border_focus
    theme.hotkeys_modifiers_fg = "${(semantic.vcs "modified" themeMode).hex}"
    theme.hotkeys_label_fg = "${(semantic.vcs "modified" themeMode).hex}"

    -- Tooltip colors (not sizes)
    theme.tooltip_bg = theme.bg_focus
    theme.tooltip_fg = theme.fg_focus
    theme.tooltip_border_color = theme.border_normal

    return theme
  '';

  # Check if awesome should be themed
  shouldTheme = signalLib.shouldThemeApp "awesome" [
    "desktop"
    "wm"
    "awesome"
  ] cfg config;

  # Platform guard - awesome is Linux-only (X11 window manager)
  platformOk = signalLib.platform.guard pkgs "awesome";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    xdg.configFile."awesome/signal-theme.lua".text = awesomeTheme;

    # Provide helper instructions via a README
    xdg.configFile."awesome/SIGNAL_THEME_README.txt".text = ''
      Signal Theme for Awesome WM - COLORS ONLY

      To use this theme, add this line to your rc.lua:

        beautiful.init(gears.filesystem.get_configuration_dir() .. "signal-theme.lua")

      Replace any existing beautiful.init() call with the above line.

      The theme provides ONLY colors. You must configure:
      - border_width, useless_gap
      - fonts (theme.font, theme.hotkeys_font, etc.)
      - menu dimensions (menu_height, menu_width)
      - notification sizes (notification_width, etc.)
      - Other layout/sizing properties

      Example additions to your rc.lua after beautiful.init():
        beautiful.border_width = 2
        beautiful.useless_gap = 8
        beautiful.font = "Inter 12"
        beautiful.hotkeys_font = "Inter 12"
        beautiful.hotkeys_description_font = "Inter 10"
        beautiful.menu_height = 24
        beautiful.menu_width = 200
    '';
  };
}
