# Niri Layout Configuration
#
# IMPORTANT: Gap and radius values are synchronized with Ironbar design tokens
# to create visual harmony between the bar and window manager.
# Ironbar tokens are now provided by Signal flake
#
# Note: All color theming removed - should come from signal-nix when Niri support is added
{
  niriSync,
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

    # Focus ring: disabled until signal-nix provides colors
    # focus-ring = { ... };

    # Border: disabled in favor of focus ring for cleaner aesthetic
    border = {
      enable = false;
    };

    # Drop shadows: disabled until signal-nix provides colors
    # shadow = { ... };

    # Tab indicator: disabled until signal-nix provides colors
    # tab-indicator = { ... };

    # Visual hint when inserting windows: disabled until signal-nix provides colors
    # insert-hint = { ... };

    # Struts: reserve screen edges (not needed)
    struts = {
      left = 0;
      right = 0;
      top = 0;
      bottom = 0;
    };
  };
}
