# Niri Layout Configuration
#
# IMPORTANT: Gap and radius values are synchronized with Ironbar tokens
# to create visual harmony between the bar and window manager.
# See: modules/shared/features/theming/applications/desktop/ironbar-home/tokens.nix
{
  lib,
  themeConstants,
  niriSync,
  shadowColor,
  inactiveShadowColor,
  colors,
  ...
}:
{
  layout = {
    # Window spacing - synchronized with Ironbar bar margin
    # 8pt Grid: compact = 8px, relaxed = 12px
    gaps = niriSync.windowGap;

    # Layout behavior
    always-center-single-column = true;
    empty-workspace-above-first = true;
    default-column-display = "tabbed";

    # Center focused column when it doesn't fit on screen with previous column
    center-focused-column = "on-overflow";

    # Preset column widths for quick switching with Mod+R
    preset-column-widths = [
      { proportion = 1.0 / 3.0; }
      { proportion = 1.0 / 2.0; }
      { proportion = 2.0 / 3.0; }
      { proportion = 1.0; }
    ];

    # Focus ring: primary visual indicator for focused window
    # With prefer-no-csd = true, focus ring is drawn correctly around windows
    # Uses Signal theme accent-focus color for consistency
    focus-ring = {
      width = 3;
      active = {
        color = colors."accent-focus".hex;
      };
      inactive = {
        color = themeConstants.niri.colors.focus-ring.inactive;
      };
    };

    # Border: disabled in favor of focus ring for cleaner aesthetic
    # Per guide: "Disable standard borders to prefer the smoother focus ring"
    border = {
      enable = false;
    };

    # Drop shadows for depth
    shadow = {
      enable = true;
      # Reduced from 80 to 40 for better performance while maintaining soft appearance
      softness = 40;
      spread = 6;
      offset = {
        x = 0;
        y = 12;
      };
      color = shadowColor;
      # Dimmer shadows for inactive windows (more transparent - 40% opacity instead of 66%)
      inactive-color = inactiveShadowColor;
      # False because we use prefer-no-csd (draws shadows correctly with rounded corners)
      draw-behind-window = false;
    };

    # Tab indicator for tabbed columns
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

    # Visual hint when inserting windows between columns
    insert-hint = {
      enable = true;
      display = {
        # Use border active color for consistency
        color = themeConstants.niri.colors.border.active;
      };
    };

    # Struts: reserve screen edges (not needed)
    struts = {
      left = 0;
      right = 0;
      top = 0;
      bottom = 0;
    };
  };
}
