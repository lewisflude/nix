# Ironbar Design Tokens
#
# Mathematical UI Physics - 8-Point Grid System
#
# This file defines the design system using professional spatial mathematics.
# All values follow the 8pt grid (multiples of 8, with 4pt micro-grid for fine details).
#
# Design Principles:
# 1. 8pt Grid: All major dimensions are multiples of 8 (8, 16, 24, 32, 40, 48)
# 2. 4pt Micro-grid: Fine details use multiples of 4 (4, 12, 20)
# 3. Modular Typography: 1.125 (Major Second) scale for font sizes
# 4. Optical Balance: Icons are 2-4px larger than adjacent text
# 5. Gestalt Synchronization: Niri and Ironbar share the same radii and gaps
#
# Profile Selection:
# - compact: 40px bar, 8px gaps (optimized for 1080p)
# - relaxed: 48px bar, 12px gaps (optimized for 1440p/4K)
{
  colors ? null,
  theme ? null,
}:
let
  # ============================================================================
  # PROFILE SELECTION
  # ============================================================================
  # Change this to "relaxed" for 1440p+ displays
  profile = "compact";

  # Profile-specific values
  profiles = {
    compact = {
      barHeight = 40;
      globalGap = 8; # Distance from screen edge AND between islands
      islandRadius = 12; # Height / 3 ≈ 13, rounded to 12 for grid
      fontSize = 13;
      iconSize = 16; # fontSize + 3 (optical balance)
      itemPadding = 12; # Horizontal breathing room
      borderWidth = 1;
    };
    relaxed = {
      barHeight = 48;
      globalGap = 12; # Airier spacing for larger displays
      islandRadius = 16; # Height / 3 = 16
      fontSize = 14;
      iconSize = 18; # fontSize + 4 (optical balance)
      itemPadding = 16; # More generous padding
      borderWidth = 2;
    };
  };

  # Active profile
  p = profiles.${profile};

  # Derived calculations (Mathematical UI Physics)
  widgetHeight = p.barHeight - 4; # Allow 2px padding top/bottom for island
in
{
  # ============================================================================
  # EXPORTED PROFILE VALUES (for Niri synchronization)
  # ============================================================================
  inherit profile;

  # CRITICAL: These values MUST match your Niri configuration
  # The bar should feel like "just another window" in the system
  niriSync = {
    windowGap = p.globalGap; # Niri layout.gaps
    windowRadius = p.islandRadius; # Niri geometry-corner-radius
    barMargin = p.globalGap; # Distance from screen edges
  };

  # ============================================================================
  # SPACING SCALE (8pt Grid)
  # ============================================================================
  spacing = {
    none = "0";
    xs = "4px"; # 1 micro-unit - fine details
    sm = "8px"; # 1 unit - standard small gaps
    md = "12px"; # 1.5 units - comfortable spacing
    lg = "16px"; # 2 units - section separation
    xl = "20px"; # 2.5 units - generous gaps
    "2xl" = "24px"; # 3 units - major sections
    "3xl" = "32px"; # 4 units - large separation
  };

  # Widget-specific spacing
  widget = {
    paddingTight = "0 ${toString (p.itemPadding - 4)}px";
    paddingNormal = "0 ${toString p.itemPadding}px";
    paddingComfortable = "0 ${toString (p.itemPadding + 4)}px";
    gapTight = "${toString p.globalGap}px";
    gapNormal = "${toString (p.globalGap + 4)}px";
    gapSection = "${toString (p.globalGap * 2)}px";
    gapLarge = "${toString (p.globalGap + 8)}px";
    paddingSpacious = "${toString (p.itemPadding + 8)}px";
  };

  # Island container spacing
  island = {
    padding = "4px ${toString p.itemPadding}px";
    paddingCenter = "4px ${toString (p.itemPadding + 4)}px";
    margin = "${toString p.globalGap}px";
    borderRadius = "${toString p.islandRadius}px";
  };

  # ============================================================================
  # SIZING SCALE
  # ============================================================================
  sizing = {
    barHeight = "${toString p.barHeight}px";
    widgetHeight = "${toString widgetHeight}px";
    itemHeight = "${toString (p.barHeight - 8)}px";
    touchTarget = "24px";
    iconSmall = "${toString p.iconSize}px";
    iconMedium = "${toString (p.iconSize + 2)}px";
    iconLarge = "${toString (p.iconSize + 4)}px";
    workspaceItem = "${toString (p.barHeight - 8)}px";
    controlWidget = "72px";
    clockWidth = "128px";
    labelMaxWidth = "296px";
    notificationWidth = "40px";
    buttonMinWidth = "${toString widgetHeight}px";
    popupWidth = "320px";
  };

  # ============================================================================
  # OPACITY SCALE
  # ============================================================================
  opacity = {
    invisible = "0";
    hint = "0.1";
    disabled = "0.4";
    muted = "0.45";
    secondary = "0.7";
    tertiary = "0.75";
    primary = "0.8";
    emphasis = "0.95";
    full = "1";
    hoverSubtle = "0.65";
    hoverFull = "1";
  };

  # ============================================================================
  # TYPOGRAPHY SCALE (Modular: 1.125 Major Second)
  # ============================================================================
  typography = {
    size = {
      xs = "${toString (p.fontSize - 1)}px"; # Micro text
      sm = "${toString p.fontSize}px"; # Base text
      md = "${toString (p.fontSize + 1)}px"; # Workspace icons
      lg = "${toString (p.fontSize + 3)}px"; # Large text
      xl = "${toString (p.fontSize + 5)}px"; # Popup headers
    };
    weight = {
      normal = "400";
      medium = "450";
      semibold = "500";
      bold = "600";
    };
    # Font family for data widgets (clock, sys-info, battery)
    # Enforces physical stability - numbers won't shift as values change
    fontMono = "monospace";
    lineHeight = {
      widget = "${toString widgetHeight}px";
      item = "${toString (p.barHeight - 8)}px";
      compact = "${toString (p.barHeight - 12)}px";
      popup = "1.5";
      popupHeader = "1.4";
    };
    # NOTE: letter-spacing and font-variant-numeric are not supported in GTK CSS
    # Removed: letterSpacing, features.tabularNums
  };

  # ============================================================================
  # BORDER RADIUS SCALE
  # ============================================================================
  radius = {
    none = "0";
    sm = "${toString (p.islandRadius - 6)}px";
    md = "${toString (p.islandRadius - 4)}px";
    lg = "${toString p.islandRadius}px";
    xl = "${toString (p.islandRadius + 2)}px";
  };

  # ============================================================================
  # SHADOWS
  # ============================================================================
  # NOTE: GTK CSS only supports inset shadows reliably
  # Using inset highlights instead of outset drop shadows
  shadow = {
    island = "inset 0 1px 0 rgba(255, 255, 255, 0.08)";
    islandCenter = "inset 0 1px 0 rgba(255, 255, 255, 0.1)";
    popup = "inset 0 1px 0 rgba(255, 255, 255, 0.12)";
  };

  # ============================================================================
  # COLORS (Interaction states using Signal theme)
  # ============================================================================
  interactionColors =
    if colors != null && theme != null then
      {
        # Use Signal theme surface colors with transparency for interactions
        hoverBgSubtle = "rgba(${theme.formats.rgbString colors."surface-emphasis"}, 0.12)";
        hoverBg = "rgba(${theme.formats.rgbString colors."surface-emphasis"}, 0.15)";
        activeBg = "rgba(${theme.formats.rgbString colors."surface-emphasis"}, 0.25)";
        # Use Signal theme accent colors for status indicators
        warning = colors."accent-warning".hex;
        critical = colors."accent-danger".hex;
      }
    else
      {
        # Fallback colors (should rarely be used)
        hoverBgSubtle = "rgba(37, 38, 47, 0.12)";
        hoverBg = "rgba(37, 38, 47, 0.15)";
        activeBg = "rgba(37, 38, 47, 0.25)";
        warning = "#fab387";
        critical = "#f38ba8";
      };

  # ============================================================================
  # TRANSITIONS
  # ============================================================================
  # NOTE: GTK CSS does not support transform property
  transition = {
    duration = {
      fast = "50ms";
      normal = "150ms";
      slow = "200ms";
    };
    easing = {
      default = "ease";
      out = "ease-out";
      inOut = "ease-in-out";
    };
    opacity = "opacity 150ms ease";
    background = "background-color 150ms ease";
    all = "opacity 150ms ease, background-color 150ms ease";
    interactive = "opacity 150ms ease, background-color 150ms ease";
    control = "background-color 150ms ease";
  };

  # ============================================================================
  # Z-INDEX
  # ============================================================================
  zIndex = {
    base = "0";
    popup = "100";
    tooltip = "200";
  };
}
