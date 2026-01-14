# Ironbar Design Tokens
#
# This file defines the design system for Ironbar's visual language.
# All CSS values should reference these tokens for consistency.
#
# Design Principles:
# 1. 4px base unit for spacing (follows Material Design / 8pt grid)
# 2. Consistent opacity scale for visual hierarchy
# 3. Modular type scale for typography
# 4. Semantic naming for intent, not values
{
  # ============================================================================
  # SPACING SCALE
  # ============================================================================
  # Based on 4px base unit (common in design systems)
  # Named semantically: xs, sm, md, lg, xl, 2xl, 3xl
  spacing = {
    none = "0";
    xs = "2px"; # 0.5 units - tight spacing
    sm = "4px"; # 1 unit - small gaps
    md = "8px"; # 2 units - standard spacing
    lg = "12px"; # 3 units - comfortable spacing
    xl = "16px"; # 4 units - section separation
    "2xl" = "20px"; # 5 units - large gaps
    "3xl" = "24px"; # 6 units - major sections
  };

  # Widget-specific spacing (derived from scale)
  widget = {
    # Internal padding
    paddingTight = "4px 8px"; # sm md - compact widgets
    paddingNormal = "5px 10px"; # ~sm+xs ~md+xs - standard widgets
    paddingComfortable = "7px 12px"; # lg variant - tray, larger targets
    paddingSpacious = "16px"; # xl - popups

    # External margins (gap between widgets)
    gapTight = "8px"; # md - closely related items
    gapNormal = "12px"; # lg - standard separation
    gapSection = "16px"; # xl - between logical groups
    gapLarge = "18px"; # xl+xs - major sections (e.g., workspaces to focused)
  };

  # Island container spacing
  island = {
    padding = "5px 10px"; # Consistent island internal padding
    paddingCenter = "5px 6px"; # Slightly tighter for clock (visual balance)
    margin = "8px"; # Gap from screen edges
    borderRadius = "11px"; # Softer than 12px, more refined
  };

  # ============================================================================
  # SIZING SCALE
  # ============================================================================
  # Fixed dimensions for consistent layout
  sizing = {
    # Heights
    barHeight = "44px"; # Total bar height
    widgetHeight = "36px"; # Standard widget row height
    itemHeight = "32px"; # Workspace items, smaller elements
    touchTarget = "24px"; # Minimum touch target (tray buttons)
    iconSmall = "18px"; # Standard icons
    iconMedium = "20px"; # Focused window icon
    iconLarge = "22px"; # Tray icons (accessibility)

    # Widths
    workspaceItem = "32px"; # Individual workspace button
    controlWidget = "70px"; # Brightness/volume (icon + value)
    clockWidth = "130px"; # Prevents layout shift
    labelMaxWidth = "300px"; # Focused window title truncation
    notificationWidth = "40px"; # Notification indicator
    buttonMinWidth = "36px"; # Standard button
    popupWidth = "320px"; # Calendar popup
  };

  # ============================================================================
  # OPACITY SCALE
  # ============================================================================
  # Semantic opacity levels for visual hierarchy
  # Follows accessibility guidelines (WCAG contrast)
  opacity = {
    # Content visibility
    invisible = "0"; # Hidden elements
    hint = "0.1"; # Subtle separators, dividers
    disabled = "0.4"; # Inactive/empty workspaces
    muted = "0.45"; # Inactive window titles
    secondary = "0.7"; # Occupied workspaces, layout indicator
    tertiary = "0.75"; # Focused window title (normal)
    primary = "0.8"; # System info, notifications
    emphasis = "0.95"; # Active window title, clock
    full = "1"; # Focused workspace, alerts

    # Hover state modifiers
    hoverSubtle = "0.65"; # Workspace hover (from 0.4)
    hoverFull = "1"; # System info hover (from 0.8)
  };

  # ============================================================================
  # TYPOGRAPHY SCALE
  # ============================================================================
  # Modular type scale for hierarchy
  # Base: 14px, Scale: ~1.125 (Major Second)
  typography = {
    # Font sizes
    size = {
      xs = "13px"; # Secondary info (focused title, sys-info)
      sm = "14px"; # Base size (controls, buttons, labels)
      md = "15px"; # Workspace icons, layout indicator
      lg = "16px"; # Clock (visual anchor)
      xl = "17px"; # Popup headers (not currently used, reserved)
    };

    # Font weights
    weight = {
      normal = "400"; # Default text
      medium = "450"; # Active window title (subtle emphasis)
      semibold = "500"; # Active workspace, sys-info
      bold = "600"; # Clock, popup headers, critical alerts
    };

    # Line heights (match widget heights for vertical centering)
    lineHeight = {
      widget = "36px"; # Standard widget alignment
      item = "32px"; # Workspace items
      compact = "28px"; # Brightness/volume (tighter)
      popup = "1.5"; # Popup text (relative)
      popupHeader = "1.4"; # Popup headers
    };

    # Letter spacing
    letterSpacing = {
      normal = "0"; # Default
      clock = "0.02em"; # Slight tracking for clock
    };

    # Special features
    features = {
      tabularNums = "tabular-nums"; # Prevent width shifts on numbers
    };
  };

  # ============================================================================
  # BORDER RADIUS SCALE
  # ============================================================================
  radius = {
    none = "0";
    sm = "6px"; # Tray buttons, small interactive elements
    md = "8px"; # Workspace items, hover states, focus rings
    lg = "11px"; # Island containers
    xl = "12px"; # Popups
  };

  # ============================================================================
  # SHADOWS
  # ============================================================================
  shadow = {
    # Island shadows (subtle elevation)
    island = "0 2px 10px rgba(0, 0, 0, 0.06)";
    islandCenter = "0 2px 14px rgba(0, 0, 0, 0.08)"; # Slightly stronger for clock
    popup = "0 4px 16px rgba(0, 0, 0, 0.12)";
  };

  # ============================================================================
  # COLORS (Non-theme, hardcoded values that should be extracted)
  # ============================================================================
  # These are the rgba values currently hardcoded in the CSS
  # They represent interaction states independent of theme
  colors = {
    # Hover/active backgrounds (neutral overlay)
    hoverBgSubtle = "rgba(37, 38, 47, 0.12)"; # Workspace hover
    hoverBg = "rgba(37, 38, 47, 0.15)"; # Standard hover
    activeBg = "rgba(37, 38, 47, 0.25)"; # Active/pressed state

    # Alert colors (should ideally come from theme)
    warning = "#fab387"; # Orange - high resource usage
    critical = "#f38ba8"; # Red - critical usage
  };

  # ============================================================================
  # TRANSITIONS
  # ============================================================================
  # Consistent animation timing
  transition = {
    # Durations
    duration = {
      fast = "50ms"; # Press feedback (transform)
      normal = "150ms"; # Standard transitions
      slow = "200ms"; # Width expansions (if used)
    };

    # Easing functions
    easing = {
      default = "ease";
      out = "ease-out"; # Popup entrance
      inOut = "ease-in-out"; # Animations (pulse)
    };

    # Common transition strings
    opacity = "opacity 150ms ease";
    background = "background-color 150ms ease";
    transform = "transform 50ms ease";
    all = "opacity 150ms ease, background-color 150ms ease";
    interactive = "opacity 150ms ease, background-color 150ms ease, transform 80ms ease";
    control = "background-color 150ms ease, transform 50ms ease";
  };

  # ============================================================================
  # Z-INDEX (if needed in future)
  # ============================================================================
  zIndex = {
    base = "0";
    popup = "100";
    tooltip = "200";
  };
}
