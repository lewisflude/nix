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

        /* ===== PRINCIPLE 4 & 7: WORKSPACE STRIP VISUALIZATION ===== */
        /* Workspaces styled as a filmstrip with clear active state */
        .workspaces button {
          background: transparent;
          color: ${colors."text-tertiary".hex};
          padding: ${spacing.xs} ${spacing.sm};
          margin: 0 1px; /* Minimal gap for visual separation */
          min-width: ${sizing.workspaceItem};
          border-radius: ${radius.md};
          transition: ${transition.interactive};
          border: none;
          box-shadow: none;
          outline: none;
        }

        .workspaces button:hover {
          color: ${colors."text-primary".hex};
          background-color: ${interactionColors.hoverBgSubtle};
        }

        /* Active workspace - clean accent with subtle bottom indicator */
        /* Visual Hierarchy: Bold weight for active state */
        /* Implements subtle "light under" metaphor without distracting glow */
        .workspaces button.focused,
        .workspaces button.active {
          color: ${colors."accent-focus".hex};
          background-color: ${colors."surface-subtle".hex};
          border-radius: ${radius.md};
          font-weight: ${typography.weight.bold};
          border: none;
          border-bottom: 2px solid ${colors."accent-focus".hex};
          box-shadow: none;
          outline: none;
        }

        /* Occupied but not focused */
        .workspaces button.visible {
          color: ${colors."text-secondary".hex};
        }

        /* ===== SEPARATOR STYLING ===== */
        /* Visual divider between widget groups */
        /* FIX: Explicit transparent background to prevent artifact */
        .separator {
          color: ${colors."divider-primary".hex};
          opacity: 0.5;
          padding: 0px ${spacing.xs};
          font-size: ${typography.size.sm};
          font-weight: ${typography.weight.normal};
          background: transparent;
          background-color: transparent;
          border: none;
          box-shadow: none;
        }

        /* ===== PRINCIPLE 9: FOCUS CONTEXT (Window Title) ===== */
        /* Consistent typography for crisp rendering */
        .label {
          color: ${colors."text-secondary".hex};
          transition: ${transition.opacity};
          font-family: sans-serif;
          font-weight: ${typography.weight.medium};
        }

        .label.focused,
        .label.active {
          color: ${colors."text-primary".hex};
          font-weight: ${typography.weight.semibold};
        }

        /* ===== CLOCK - AMBIENT DATA ===== */
        /* FIX #3: Visual Hierarchy - Passive data gets lighter weight than interactive controls */
        .clock {
          background-color: ${colors."surface-subtle".hex};
          padding: ${spacing.sm} ${spacing.lg};
          border-radius: ${radius.md};
          color: ${colors."text-primary".hex};
          font-weight: ${typography.weight.medium};
          opacity: 0.9;
        }

        /* ===== POWER BUTTON - DESTRUCTIVE ACTION ===== */
        /* Red accent for destructive action, rightmost position */
        .power-btn button {
          color: ${colors."accent-danger".hex};
          background: transparent;
          padding: ${spacing.xs} ${spacing.md};
          margin-left: ${spacing.sm};
          border-radius: ${radius.md};
          transition: ${transition.control};
        }

        .power-btn button:hover {
          background-color: ${interactionColors.hoverBg};
        }

        /* ===== POPUP STYLING ===== */
        /* Match island aesthetic for consistency */
        .popup {
          background-color: ${colors."surface-base".hex};
          border: 1px solid ${colors."surface-emphasis".hex};
          border-radius: ${radius.xl};
          box-shadow: ${shadow.popup};
        }

        /* ===== INTERACTIVE CONTROLS ===== */
        /* FIX #1: Remove Blue Bracket Glitch - force remove borders/shadows */
        /* FIX: Explicit border removal to prevent disjointed container borders */
        .brightness,
        .volume,
        .popup-button {
          border: none;
          border-left: none;
          border-right: none;
          border-top: none;
          border-bottom: none;
          box-shadow: none;
          outline: none;
          background: transparent;
        }

        /* Hover states for brightness/volume */
        .brightness:hover,
        .volume:hover {
          background-color: ${interactionColors.hoverBg};
          border-radius: ${radius.md};
        }

        /* Active/pressed states */
        .brightness:active,
        .volume:active {
          background-color: ${interactionColors.activeBg};
          opacity: 0.9;
        }

        /* ===== TRAY STYLING ===== */
        /* FIX #2: Give tray its own "pill" container to match other groups */
        .tray {
          background-color: ${colors."surface-subtle".hex};
          border-radius: ${radius.md};
          padding: ${spacing.xs} ${spacing.sm};
        }

        .tray button {
          background: transparent;
          border-radius: ${radius.sm};
          transition: ${transition.control};
        }

        .tray button:hover {
          background-color: ${interactionColors.activeBg};
        }

        .tray button:active {
          opacity: 0.9;
        }

        /* ===== BATTERY WIDGET ===== */
        /* Only shown on laptop hosts (conditional via hasBattery option) */
        /* FIX #2: Font Stability - Monospace ensures physical stability */
        .battery {
          padding: ${spacing.xs} ${spacing.md};
          font-family: ${typography.fontMono};
          transition: ${transition.all};
        }

        /* Low battery warning states */
        .battery.warning {
          color: ${interactionColors.warning};
        }

        .battery.critical {
          color: ${interactionColors.critical};
          animation: pulse 1s ease-in-out infinite;
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
      border: none;
    }

    /* ===== ISLAND 1: NAVIGATION ===== */
    /* Workspaces + Separator + System Info */

    .workspaces {
      padding: ${widget.paddingTight};
      margin-right: ${spacing.sm};
    }

    .workspaces .item {
      min-width: ${sizing.workspaceItem};
      min-height: ${sizing.itemHeight};
      margin: 0 1px; /* Consistent minimal gap */
      padding: ${spacing.xs} ${spacing.sm};
      border: none;
      box-shadow: none;
      outline: none;
      font-size: ${typography.size.md};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.item};
      opacity: ${opacity.disabled};
      border-radius: ${radius.md};
      transition: ${transition.interactive};
    }

    .workspaces .item:hover {
      opacity: ${opacity.hoverSubtle};
      background-color: ${interactionColors.hoverBgSubtle};
    }

    /* Visual Hierarchy: Bold weight for active state, clean appearance */
    .workspaces .item.focused,
    .workspaces .item.active {
      opacity: ${opacity.full};
      font-weight: ${typography.weight.bold};
      border: none;
      border-bottom: 2px solid ${colors."accent-focus".hex};
      box-shadow: none;
      outline: none;
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
      border: none;
      font-family: sans-serif;
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.medium};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      opacity: ${opacity.tertiary};
      transition: ${transition.opacity};
    }

    .label image {
      margin-right: 9px;
    }

    .label.active,
    .label.focused {
      opacity: ${opacity.emphasis};
      font-weight: ${typography.weight.medium};
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

    #center .label {
      padding: ${spacing.xs} ${spacing.lg};
      font-family: sans-serif;
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.medium};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      opacity: ${opacity.emphasis};
    }

    /* FIX #4: Empty Desktop Collapse - center island collapses when no window focused */
    /* Note: GTK CSS doesn't support :empty pseudo-class, handled by Ironbar config */

    /* ===== CLOCK (Now in End Island) ===== */
    /* Ambient data - lighter weight than interactive workspaces
       FIX #2: Font Stability - Monospace prevents jitter as time changes
       Visual centering achieved through symmetric padding */

    .clock {
      padding: 0 ${spacing.lg};
      border: none;
      font-family: ${typography.fontMono};
      font-size: ${typography.size.lg};
      font-weight: ${typography.weight.medium};
      min-width: ${sizing.clockWidth};
      min-height: ${sizing.widgetHeight};
      line-height: ${typography.lineHeight.widget};
      opacity: 0.9;
    }

    /* ===== ISLAND 3: SYSTEM STATUS ===== */
    /* Widget order: Tray → Layout → Brightness → Volume → Notifications → Clock → Power
       Grouped by function: Communications → State → Controls → Time → Action */

    /* System info (in Start island, after separator) */
    /* FIX #2: Font Stability - Monospace prevents jitter as CPU/RAM values change */
    .sys-info {
      padding: ${spacing.none} ${spacing.md};
      border: none;
      font-family: ${typography.fontMono};
      font-size: ${typography.size.xs};
      font-weight: ${typography.weight.semibold};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      opacity: ${opacity.primary};
      transition: ${transition.all};
    }

    .sys-info:hover {
      opacity: ${opacity.hoverFull};
      background-color: ${interactionColors.hoverBg};
      border-radius: ${radius.md};
    }

    .sys-info.warning {
      color: ${interactionColors.warning};
      opacity: ${opacity.full};
      animation: pulse 2s ease-in-out infinite;
    }

    .sys-info.critical {
      color: ${interactionColors.critical};
      opacity: ${opacity.full};
      font-weight: ${typography.weight.bold};
      animation: pulse 1s ease-in-out infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: ${opacity.full}; }
      50% { opacity: ${opacity.secondary}; }
    }

    /* Niri layout indicator - State indicator group */
    .niri-layout {
      padding: ${spacing.none} 10px;
      margin-right: ${spacing.md};
      border: none;
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

    /* Brightness control - Hardware controls group */
    /* FIX: Explicit border removal on all sides to prevent visual seams */
    .brightness {
      padding: 0 10px;
      margin-right: ${spacing.sm};
      min-width: ${sizing.controlWidget};
      border: none;
      border-left: none;
      border-right: none;
      border-radius: ${radius.md};
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      transition: ${transition.control};
      background: transparent;
    }

    /* Volume control - Hardware controls group */
    /* FIX: Explicit border removal on all sides to prevent visual seams */
    .volume {
      padding: 0 10px;
      margin-right: ${spacing.lg};
      min-width: ${sizing.controlWidget};
      border: none;
      border-left: none;
      border-right: none;
      border-radius: ${radius.md};
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      transition: ${transition.control};
      background: transparent;
    }

    /* System tray - Communications group */
    .tray {
      padding: ${widget.paddingComfortable};
      margin-right: ${spacing.sm};
      border: none;
      min-height: ${sizing.widgetHeight};
    }

    .tray button {
      min-height: ${sizing.touchTarget};
      min-width: ${sizing.touchTarget};
      padding: ${spacing.xs};
      margin: ${spacing.none} 3px;
      background: transparent;
      border: none;
      border-radius: ${radius.sm};
      transition: ${transition.control};
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
      border: none;
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

    /* ===== TYPOGRAPHY DEFAULTS ===== */

    label {
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
    }

    box > label,
    button > label {
      line-height: ${typography.lineHeight.widget};
    }

    /* ===== INTERACTIVE ELEMENTS ===== */

    button {
      min-width: ${sizing.buttonMinWidth};
      min-height: ${sizing.widgetHeight};
      padding: ${spacing.none} ${spacing.lg};
      background: transparent;
      border: none;
      box-shadow: none;
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
    }

    button label {
      line-height: ${typography.lineHeight.widget};
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
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

    /* ===== SEPARATOR ===== */
    /* Visual divider between widget groups within an island */
    /* FIX: High-specificity rules to prevent background artifacts */
    .separator,
    label.separator,
    #bar .separator {
      padding: ${spacing.none} ${spacing.xs};
      min-height: ${sizing.widgetHeight};
      line-height: ${typography.lineHeight.widget};
      background: transparent;
      background-color: transparent;
      border: none;
      box-shadow: none;
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
      background: transparent;
      border: none;
      font-size: ${typography.size.md};
      line-height: ${typography.lineHeight.widget};
    }

  '';
in
baseCss + themeCss + widgetThemeCss + layoutCss
