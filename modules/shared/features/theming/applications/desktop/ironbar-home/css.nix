{
  colors,
  theme,
  ...
}:
let
  # Import design tokens with Signal theme colors
  tokens = import ./tokens.nix { inherit colors theme; };

  # Destructure for cleaner access
  inherit (tokens)
    spacing
    widget
    island
    sizing
    opacity
    typography
    radius
    shadow
    transition
    ;
  interactionColors = tokens.interactionColors;

  # Helper to convert hex to rgba with opacity
  # Note: GTK CSS doesn't support alpha() function, so we use pre-computed values
  # The theme's surface colors already have appropriate darkness

  # ============================================================================
  # BASE CSS - Global Reset & Typography
  # ============================================================================
  # Implements Principle #2: Visual Hierarchy through typography
  baseCss = ''
    /* GLOBAL RESET & TYPOGRAPHY */
    * {
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.semibold};
      border: none;
      border-radius: 0px;
      box-shadow: none;
    }

    /* Base bar styling - minimal padding, islands handle their own */
    #bar {
      padding: 0px ${spacing.md};
      min-height: ${sizing.barHeight};
    }
  '';

  # ============================================================================
  # THEME CSS - Floating Islands Design
  # ============================================================================
  # Implements Principle #1: Law of Common Region
  # The main bar background is TRANSPARENT - only islands get color
  themeCss =
    if colors != null then
      ''
        /* PRINCIPLE 1: The "Island" Strategy
           Main bar background has subtle tint for depth separation.
           Border-radius creates "floating capsule" aesthetic.
           NOTE: GTK CSS only supports inset shadows - outset shadows removed */
        window {
          background-color: rgba(0, 0, 0, 0.02);
          border-radius: ${radius.lg}; /* 12px (compact) or 16px (relaxed) */
        }

        /* Global text color from theme */
        * {
          color: ${colors."text-primary".hex};
        }

        /* ===== FLOATING ISLANDS ===== */
        /* Common island styling - Gestalt Law of Common Region */
        /* Strengthened border for better visual separation */
        /* Using inset highlight for depth (GTK CSS limitation) */
        #bar #start,
        #bar #center,
        #bar #end {
          background-color: ${colors."surface-base".hex};
          border: 1px solid rgba(0, 0, 0, 0.3);
          border-radius: ${radius.lg};
          box-shadow: ${shadow.island};
        }

        /* Island 1: Navigation (left) - Workspaces + System Info */
        #bar #start {
          padding: ${island.padding};
          margin-right: ${spacing.lg};
        }

        /* Island 2: Focus (center) - Window Title */
        /* Center island has stronger highlight for emphasis */
        #bar #center {
          padding: ${island.paddingCenter};
          box-shadow: ${shadow.islandCenter};
        }

        /* Island 3: Status (right) - Controls + Clock + Power */
        #bar #end {
          padding: ${island.padding};
          margin-left: ${spacing.lg};
        }
      ''
    else
      "";

  # ============================================================================
  # WIDGET THEME CSS (Interactive States & Accents)
  # ============================================================================
  # Implements Principle #4: Active State Pop
  # Implements Principle #7: Strip Visualization for workspaces
  widgetThemeCss =
    if colors != null then
      ''











        /* ===== POPUP STYLING ===== */
        /* Match island aesthetic for consistency */
        .popup {
          background-color: ${colors."surface-base".hex};
          border: 1px solid ${colors."surface-emphasis".hex};
          border-radius: ${radius.xl};
          box-shadow: ${shadow.popup};
        }

        /* ===== INTERACTIVE CONTROLS ===== */
        /* Base state: clean, no borders or shadows */
        .brightness,
        .volume,
        .popup-button {
          border: none;
          box-shadow: none;
          outline: none;
          background: transparent;
        }

        /* Active popup button with left accent bar */
        .popup-button:active,
        .popup-button.active,
        .popup-button.open {
          border-left: 3px solid ${colors."accent-focus".hex};
        }



        /* ===== BATTERY WIDGET ===== */
        /* Only shown on laptop hosts (conditional via hasBattery option) */
        /* FIX #2: Font Stability - Monospace ensures physical stability */
        .battery {
          padding: ${spacing.xs} ${spacing.md};
          font-family: ${typography.fontMono};
          transition: ${transition.all};
        }

        /* Low battery warning state with left accent bar */
        .battery.warning {
          color: ${interactionColors.warning};
          border-left: 3px solid ${interactionColors.warning};
          padding-left: calc(${spacing.md} - 3px);
        }

        /* Critical battery state with left accent bar and pulse */
        .battery.critical {
          color: ${interactionColors.critical};
          animation: pulse 1s ease-in-out infinite;
          border-left: 3px solid ${interactionColors.critical};
          padding-left: calc(${spacing.md} - 3px);
        }

        /* ===== FOCUS INDICATOR ===== */
        /* Keyboard navigation accessibility - DISABLED for cleaner appearance
           The blue outline was creating visual artifacts on workspace buttons
           Note: Using :focus instead of :focus-visible (CSS Level 4, not supported in GTK) */
        *:focus {
          outline: none;
        }
      ''
    else
      "";

  # ============================================================================
  # LAYOUT CSS (Structure & Spacing)
  # ============================================================================
  layoutCss = ''

    /* ===== ISLAND STRUCTURE ===== */
    #bar #start,
    #bar #center,
    #bar #end {
      min-height: ${sizing.widgetHeight};
    }

    /* FIX #5: Smooth Tray Jitter - widgets slide smoothly when tray expands/contracts */
    #bar #end > * {
      transition: all 0.2s cubic-bezier(0.25, 1, 0.5, 1);
    }

    /* ===== WIDGET CONTAINERS ===== */
    .widget-container {
      margin: ${spacing.none};
      min-height: ${sizing.widgetHeight};
    }

    .widget-container > box {
      min-height: ${sizing.widgetHeight};
    }

    .widget {
      min-height: ${sizing.widgetHeight};
    }

    /* ===== ISLAND 1: NAVIGATION ===== */
    /* Workspaces + Separator + System Info */

    .workspaces {
      padding: ${widget.paddingTight};
    }

    .workspaces .item {
      min-width: ${sizing.workspaceItem};
      min-height: ${sizing.itemHeight};
      margin: 0 1px; /* Consistent minimal gap */
      padding: ${spacing.xs} ${spacing.sm};
      font-size: ${typography.size.md};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.item};
      color: ${colors."text-tertiary".hex};
      border-radius: ${radius.md};
      transition: ${transition.interactive};
    }

    .workspaces .item:hover {
      color: ${colors."text-primary".hex};
      opacity: ${opacity.hoverSubtle};
      background-color: ${interactionColors.hoverBgSubtle};
    }

    /* Visual Hierarchy: Bold weight for active state with left accent bar */
    /* Material Design pattern - combines color, shape, and position */
    /* Right-side-only radius integrates accent bar cleanly */
    .workspaces .item.focused,
    .workspaces .item.active {
      font-weight: ${typography.weight.bold};
      border-left: 3px solid ${colors."accent-focus".hex};
      background-color: ${colors."surface-subtle".hex};
      border-top-left-radius: 0;
      border-bottom-left-radius: 0;
      border-top-right-radius: ${radius.md};
      border-bottom-right-radius: ${radius.md};
    }

    .workspaces .item.occupied {
      opacity: ${opacity.secondary};
    }

    .workspaces .item.urgent {
      opacity: ${opacity.full};
      animation: urgentPulse 1.5s ease-in-out infinite;
    }

    @keyframes urgentPulse {
      0%, 100% { opacity: ${opacity.full}; }
      50% { opacity: 0.5; }
    }

    .workspaces .item:first-child {
      margin-left: ${spacing.none};
    }

    .workspaces .item:last-child {
      margin-right: ${spacing.none};
    }

    /* Focused window title
       Note: Text truncation handled by widget config (truncate.mode/max_length) */
    /* Consistent font rendering for crisp appearance */
    .label {
      padding: ${spacing.none} 14px;
      font-family: sans-serif;
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.medium};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      opacity: ${opacity.tertiary};
      color: ${colors."text-secondary".hex};
      transition: ${transition.opacity};
    }

    .label image {
      margin-right: 9px;
    }

    /* Active/focused label state with left accent bar */
    /* Right-side-only radius for clean integration */
    .label.active,
    .label.focused {
      color: ${colors."text-primary".hex};
      font-weight: ${typography.weight.semibold};
      border-left: 3px solid ${colors."accent-focus".hex};
      border-top-left-radius: 0;
      border-bottom-left-radius: 0;
      border-top-right-radius: ${radius.md};
      border-bottom-right-radius: ${radius.md};
      padding-left: calc(14px - 3px); /* Compensate border to prevent content shift */
    }

    .label.inactive {
      opacity: ${opacity.muted};
    }

    /* FIX #4: Empty Desktop Collapse - gracefully hide empty state */
    /* Note: GTK CSS doesn't support :empty pseudo-class, handled by Ironbar config */

    /* ===== ISLAND 2: FOCUS CONTEXT ===== */
    /* Focused window title - "what am I working on" indicator
       Text truncation handled by widget config (truncate.mode/max_length)
       FIX: Vertical padding prevents text clipping (ascenders like 'D', 'h', 'b') */

    /* Center island label - base state without accent bar */
    #center .label {
      padding: ${spacing.xs} ${spacing.lg};
      font-family: sans-serif;
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.medium};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      opacity: ${opacity.emphasis};
      border-left: none;
    }

    /* When focused/active, add left accent bar with padding compensation */
    /* Right-side-only radius for seamless accent bar */
    #center .label.active,
    #center .label.focused {
      border-left: 3px solid ${colors."accent-focus".hex};
      border-top-left-radius: 0;
      border-bottom-left-radius: 0;
      border-top-right-radius: ${radius.md};
      border-bottom-right-radius: ${radius.md};
      padding-left: calc(${spacing.lg} - 3px);
    }

    /* FIX #4: Empty Desktop Collapse - center island collapses when no window focused */
    /* Note: GTK CSS doesn't support :empty pseudo-class, handled by Ironbar config */

    /* ===== CLOCK (Now in End Island) ===== */
    /* Ambient data - lighter weight than interactive workspaces
       FIX #2: Font Stability - Monospace prevents jitter as time changes
       Visual centering achieved through symmetric padding */

    .clock {
      padding: 0 ${spacing.lg};
      font-family: ${typography.fontMono};
      font-size: ${typography.size.lg};
      font-weight: ${typography.weight.medium};
      min-width: ${sizing.clockWidth};
      min-height: ${sizing.widgetHeight};
      line-height: ${typography.lineHeight.widget};
      opacity: 0.9;
      background-color: ${colors."surface-subtle".hex};
      border-radius: ${radius.md};
      color: ${colors."text-primary".hex};
    }

    /* ===== ISLAND 3: SYSTEM STATUS ===== */
    /* Widget order: Tray → Layout → Brightness → Volume → Notifications → Clock → Power
       Grouped by function: Communications → State → Controls → Time → Action */

    /* Niri layout indicator - State indicator group */
    .niri-layout {
      padding: ${spacing.none} 10px;
      margin-right: ${spacing.md};
      font-size: ${typography.size.md};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      opacity: ${opacity.secondary};
      transition: ${transition.all};
    }

    .niri-layout:hover {
      opacity: ${opacity.hoverFull};
      background-color: ${interactionColors.hoverBg};
      border-radius: ${radius.md};
    }

    /* Active niri-layout state (when popup is open) with left accent bar */
    .niri-layout:active,
    .niri-layout.active,
    .niri-layout.open {
      opacity: ${opacity.full};
      background-color: ${interactionColors.activeBg};
      border-left: 3px solid ${colors."accent-focus".hex};
      padding-left: calc(10px - 3px);
      border-radius: ${radius.md};
    }

    /* Brightness control - Hardware controls group */
    /* FIX: Explicit border removal on all sides to prevent visual seams */
    .brightness {
      padding: 0 10px;
      min-height: ${sizing.widgetHeight};
      transition: ${transition.control};
    }

    /* Volume control - Hardware controls group */
    /* FIX: Explicit border removal on all sides to prevent visual seams */
    .volume {
      padding: 0 10px;
      margin-right: ${spacing.lg};
      min-height: ${sizing.widgetHeight};
      transition: ${transition.control};
      background: transparent;
    }

    /* Hover states for brightness/volume */
    .brightness:hover,
    .volume:hover {
      background-color: ${interactionColors.hoverBg};
      border-radius: ${radius.md};
    }

    /* Active/pressed states with left accent bar */
    .brightness:active,
    .brightness.active,
    .brightness.open,
    .volume:active,
    .volume.active,
    .volume.open {
      background-color: ${interactionColors.activeBg};
      opacity: 0.9;
      border-left: 3px solid ${colors."accent-focus".hex};
      padding-left: calc(10px - 3px); /* Compensate for 10px left padding */
    }

    /* System tray - Communications group */
    .tray {
      padding: ${widget.paddingComfortable};
      margin-right: ${spacing.sm};
      min-height: ${sizing.widgetHeight};
      background-color: ${colors."surface-subtle".hex};
      border-radius: ${radius.md};
    }

    .tray button {
      min-height: ${sizing.touchTarget};
      min-width: ${sizing.touchTarget};
      padding: ${spacing.xs};
      margin: ${spacing.none} 3px;
      transition: ${transition.control};
    }

    /* Active tray button state with left accent bar */
    .tray button:active,
    .tray button.active,
    .tray button.focused {
      opacity: 0.9;
      border-left: 3px solid ${colors."accent-focus".hex};
      border-top-left-radius: 0;
      border-bottom-left-radius: 0;
      border-top-right-radius: ${radius.sm};
      border-bottom-right-radius: ${radius.sm};
      padding-left: calc(${spacing.xs} - 3px);
    }

        /* Normalize tray icon sizes for consistent appearance */
        /* Target both 'image' (GTK3 legacy) and 'picture' (GTK4) widgets */
        /* Use -gtk-icon-size for sizing (GTK-supported property) */
        /* Add opacity to reduce visual prominence of colorful icons */
        .tray button image,
        .tray button picture {
          -gtk-icon-size: 18px;
          min-width: 18px;
          min-height: 18px;
          padding: 0px;
          margin: 0;
          opacity: 0.85;
        }
        
        /* Reduce prominence of colorful icons on hover */
        .tray button:hover image,
        .tray button:hover picture {
          opacity: 1.0;
        }

    /* Notifications - Communications group */
    /* FIX: Reduced padding to tighten icon/count spacing */
    .notifications {
      padding: ${spacing.none} ${spacing.sm};
      margin-right: ${spacing.lg};
      min-width: ${sizing.notificationWidth};
      min-height: ${sizing.widgetHeight};
      line-height: ${typography.lineHeight.widget};
      opacity: ${opacity.primary};
      transition: ${transition.all};
    }

    /* Tighter spacing between notification icon and count */
    .notifications > * {
      margin: 0;
    }

    .notifications label {
      margin-left: ${spacing.xs};
    }

    .notifications:hover {
      opacity: ${opacity.hoverFull};
      background-color: ${interactionColors.hoverBg};
      border-radius: ${radius.md};
    }

    /* Active notification state (when popup is open) with left accent bar */
    /* Right-side-only radius for clean accent bar integration */
    .notifications:active,
    .notifications.active,
    .notifications.open {
      opacity: ${opacity.full};
      background-color: ${interactionColors.activeBg};
      border-left: 3px solid ${colors."accent-focus".hex};
      border-top-left-radius: 0;
      border-bottom-left-radius: 0;
      border-top-right-radius: ${radius.md};
      border-bottom-right-radius: ${radius.md};
      padding-left: calc(${spacing.sm} - 3px);
    }

    /* ===== TYPOGRAPHY DEFAULTS ===== */

    label {
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
    }

    box > label,
    button > label {
    }

    /* ===== INTERACTIVE ELEMENTS ===== */

    /* Generic button base state */
    button {
      min-width: ${sizing.buttonMinWidth};
      min-height: ${sizing.widgetHeight};
      padding: ${spacing.none} ${spacing.lg};
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
    }

    /* Generic button active state with left accent bar */
    button:active,
    button.active {
      border-left: 3px solid ${colors."accent-focus".hex};
      padding-left: calc(${spacing.lg} - 3px);
    }

    button label {
      background: transparent;
    }

    /* ===== ICONS ===== */
    /* Target both 'image' (GTK3) and 'picture' (GTK4) widgets */

    image,
    picture {
      min-height: ${sizing.iconSmall};
      min-width: ${sizing.iconSmall};
      -gtk-icon-size: ${sizing.iconSmall};
    }

    .tray image,
    .tray picture {
      min-height: 18px;
      min-width: 18px;
      -gtk-icon-size: 18px;
    }

    .notifications image,
    .notifications picture {
      min-height: ${sizing.iconSmall};
      min-width: ${sizing.iconSmall};
      -gtk-icon-size: ${sizing.iconSmall};
      margin-right: ${spacing.xs};
    }

    /* ===== POPUPS ===== */

    .popup {
      padding: ${widget.paddingSpacious};
      border-radius: ${radius.xl};
      margin-top: ${spacing.md};
      font-size: ${typography.size.sm};
      box-shadow: ${shadow.popup};
      animation: fadeIn ${transition.duration.normal} ${transition.easing.out};
    }

    /* GTK CSS doesn't support transform, using opacity-only animation */
    @keyframes fadeIn {
      from {
        opacity: ${opacity.invisible};
      }
      to {
        opacity: ${opacity.full};
      }
    }

    .popup label {
      line-height: ${typography.lineHeight.popup};
    }

    .popup label:first-child {
      font-weight: ${typography.weight.bold};
      font-size: ${typography.size.lg};
      margin-bottom: 10px;
      line-height: ${typography.lineHeight.popupHeader};
    }

    .popup-clock {
      padding: ${spacing."2xl"};
      min-width: ${sizing.popupWidth};
      font-size: ${typography.size.md};
    }

    /* ===== POWER BUTTON ===== */
    /* Destructive action - positioned rightmost */
    .power-btn {
      margin-left: ${spacing.sm};
    }

    .power-btn button {
      min-width: ${sizing.buttonMinWidth};
      min-height: ${sizing.widgetHeight};
      padding: ${spacing.xs} ${spacing.md};
      font-size: ${typography.size.md};
      line-height: ${typography.lineHeight.widget};
      color: ${colors."accent-danger".hex};
      margin-left: ${spacing.sm};
      border-radius: ${radius.md};
      transition: ${transition.control};
    }

    .power-btn button:hover {
      background-color: ${interactionColors.hoverBg};
    }

    /* Active power button state with danger-colored left accent bar */
    .power-btn button:active,
    .power-btn button.active {
      border-left: 3px solid ${colors."accent-danger".hex};
      padding-left: calc(${spacing.md} - 3px);
    }

  '';
in
baseCss + themeCss + widgetThemeCss + layoutCss
