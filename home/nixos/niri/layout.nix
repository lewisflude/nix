# Niri Layout Configuration
{
  themeConstants,
  ...
}:
{
  layout = {
    gaps = 16;
    always-center-single-column = true;
    empty-workspace-above-first = true;
    default-column-display = "tabbed";

    # Center focused column when it doesn't fit on screen
    center-focused-column = "on-overflow";

    # Preset column widths for quick switching with Mod+R
    preset-column-widths = [
      { proportion = 1.0 / 3.0; }
      { proportion = 1.0 / 2.0; }
      { proportion = 2.0 / 3.0; }
      { proportion = 1.0; }
    ];
    focus-ring = {
      width = 3;
      active = {
        color = themeConstants.niri.colors.focus-ring.active;
      };
      inactive = {
        color = themeConstants.niri.colors.focus-ring.inactive;
      };
    };
    struts = {
      left = 0;
      right = 0;
      top = 0;
      bottom = 0;
    };
    border = {
      width = 2;
      active = {
        color = themeConstants.niri.colors.border.active;
      };
      inactive = {
        color = themeConstants.niri.colors.border.inactive;
      };
      urgent = {
        color = themeConstants.niri.colors.border.urgent;
      };
    };
    shadow = {
      enable = true;
      softness = 80;
      spread = 6;
      offset = {
        x = 0;
        y = 12;
      };
      color = themeConstants.niri.colors.shadow;
      # Set to false to prevent background "spilling out" beyond borders
      # This fixes the issue with context menus and popups
      draw-behind-window = false;
    };
    tab-indicator = {
      hide-when-single-tab = true;
      place-within-column = true;
      gap = 4;
      width = 4;
      position = "right";
      gaps-between-tabs = 2;
      corner-radius = 4;
      active = {
        color = themeConstants.niri.colors.tab-indicator.active;
      };
      inactive = {
        color = themeConstants.niri.colors.tab-indicator.inactive;
      };
    };
  };
}
