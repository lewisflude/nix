{
  colors,
  ...
}:
let
  # Import design tokens
  tokens = import ./tokens.nix;

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
  interactionColors = tokens.colors;

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
           Main bar background is transparent WITH BLUR.
           Border-radius creates "floating capsule" aesthetic.
           Creates depth: windows slide "under" a frosted glass layer. */
        window {
          background-color: transparent;
          backdrop-filter: blur(10px);
          -webkit-backdrop-filter: blur(10px); /* Fallback for compatibility */
          border-radius: ${radius.lg}; /* 12px (compact) or 16px (relaxed) */
        }

        /* Global text color from theme */
        * {
          color: ${colors."text-primary".hex};
        }

        /* ===== FLOATING ISLANDS ===== */
        /* Common island styling - Gestalt Law of Common Region */
        /* FIX #1: Etched Glass Border - alpha() creates transparent glaze effect */
        #bar #start,
        #bar #center,
        #bar #end {
          background-color: ${colors."surface-base".hex};
          border: 1px solid alpha(${colors."surface-subtle".hex}, 0.3);
          border-radius: ${radius.lg};
          box-shadow: ${shadow.island}, inset 0 1px 0 alpha(${colors."text-primary".hex}, 0.05);
        }

        /* Island 1: Navigation (left) - Workspaces + System Info */
        #bar #start {
          padding: ${island.padding};
          margin-right: ${spacing.md};
        }

        /* Island 2: Focus (center) - Window Title */
        #bar #center {
          padding: ${island.paddingCenter};
          box-shadow: ${shadow.islandCenter};
        }

        /* Island 3: Status (right) - Controls + Clock + Power */
        #bar #end {
          padding: ${island.padding};
          margin-left: ${spacing.md};
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
          padding: 0px ${spacing.sm};
          min-width: ${sizing.workspaceItem};
          border-radius: ${radius.md};
          transition: ${transition.interactive};
        }

        .workspaces button:hover {
          color: ${colors."text-primary".hex};
          background-color: ${interactionColors.hoverBgSubtle};
        }

        /* Active workspace - accent color with glow effect */
        /* FIX #3: Visual Hierarchy - Interactive controls get heavier weight */
        /* ADDED: Bottom border indicator for spatial permanence */
        /* Implements NeXTSTEP "light under the dock" metaphor */
        .workspaces button.focused,
        .workspaces button.active {
          color: ${colors."accent-focus".hex};
          background-color: ${colors."surface-subtle".hex};
          border-radius: ${radius.md};
          font-weight: ${typography.weight.bold};
          
          /* The "light under the dock" - physical indicator */
          border-bottom: 2px solid ${colors."accent-focus".hex};
          box-shadow: 0 2px 8px alpha(${colors."accent-focus".hex}, 0.3);
        }

        /* Occupied but not focused */
        .workspaces button.visible {
          color: ${colors."text-secondary".hex};
        }

        /* ===== SEPARATOR STYLING ===== */
        /* Subtle etched divider - low opacity to not compete with content */
        .separator {
          color: ${colors."divider-primary".hex};
          opacity: 0.3;
          padding: 0px ${spacing.xs};
          font-size: ${typography.size.sm};
          font-weight: ${typography.weight.normal};
        }

        /* ===== PRINCIPLE 9: FOCUS CONTEXT (Window Title) ===== */
        .label {
          color: ${colors."text-secondary".hex};
          transition: ${transition.opacity};
        }

        .label.focused,
        .label.active {
          color: ${colors."text-primary".hex};
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
          font-variant-numeric: ${typography.features.tabularNums};
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
        /* Keyboard navigation accessibility */
        *:focus-visible {
          outline: 2px solid ${colors."accent-focus".hex};
          outline-offset: 2px;
          border-radius: ${radius.md};
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
      margin: ${spacing.none} ${spacing.xs};
      padding: ${spacing.none} ${spacing.sm};
      border: none;
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

    /* FIX #3: Visual Hierarchy - Interactive controls get heavier weight */
    .workspaces .item.focused,
    .workspaces .item.active {
      opacity: ${opacity.full};
      font-weight: ${typography.weight.bold};
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

    /* Focused window title */
    .label {
      padding: ${spacing.none} 14px;
      border: none;
      font-size: ${typography.size.xs};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      max-width: ${sizing.labelMaxWidth};
      opacity: ${opacity.tertiary};
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
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
    .label:empty {
      min-width: 0px;
      min-height: 0px;
      padding: 0px;
      margin: 0px;
      opacity: 0;
    }

    /* ===== ISLAND 2: FOCUS CONTEXT ===== */
    /* Focused window title - "what am I working on" indicator */
    /* Native 'focused' widget with built-in truncation */

    #center .label {
      padding: ${spacing.none} ${spacing.lg};
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.widget};
      min-height: ${sizing.widgetHeight};
      max-width: ${sizing.labelMaxWidth};
      opacity: ${opacity.emphasis};
    }

    /* FIX #4: Empty Desktop Collapse - center island collapses when no window focused */
    #center .label:empty,
    #center box:empty {
      min-width: 0px;
      min-height: 0px;
      padding: 0px;
      margin: 0px;
      opacity: 0;
    }

    /* ===== CLOCK (Now in End Island) ===== */
    /* Ambient data - lighter weight than interactive workspaces */
    /* FIX #2: Font Stability - Monospace prevents jitter as time changes */

    .clock {
      padding: ${spacing.sm} ${spacing.lg};
      border: none;
      font-family: ${typography.fontMono};
      font-size: ${typography.size.lg};
      font-weight: ${typography.weight.medium};
      font-variant-numeric: ${typography.features.tabularNums};
      letter-spacing: ${typography.letterSpacing.clock};
      min-width: ${sizing.clockWidth};
      min-height: ${sizing.widgetHeight};
      line-height: ${typography.lineHeight.widget};
      text-align: center;
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
      font-variant-numeric: ${typography.features.tabularNums};
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

    /* Niri layout indicator - Group 1 */
    .niri-layout {
      padding: ${spacing.none} 10px;
      margin-right: ${widget.gapSection};
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

    /* Brightness control - Group 2 */
    .brightness {
      padding: ${spacing.sm} 10px;
      margin-right: ${widget.gapTight};
      min-width: ${sizing.controlWidget};
      border: none;
      border-radius: ${radius.md};
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.compact};
      min-height: ${sizing.widgetHeight};
      text-align: center;
      transition: ${transition.control};
    }

    /* Volume control - Group 2 */
    .volume {
      padding: ${spacing.sm} 10px;
      margin-right: ${widget.gapSection};
      min-width: ${sizing.controlWidget};
      border: none;
      border-radius: ${radius.md};
      font-size: ${typography.size.sm};
      font-weight: ${typography.weight.normal};
      line-height: ${typography.lineHeight.compact};
      min-height: ${sizing.widgetHeight};
      text-align: center;
      transition: ${transition.control};
    }

    /* System tray - Group 3 */
    .tray {
      padding: ${widget.paddingComfortable};
      margin-right: ${widget.gapNormal};
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

    .tray button image {
      min-height: 20px;
      min-width: 20px;
      padding: ${spacing.none};
      margin: ${spacing.none};
    }

    /* Notifications - Group 3 */
    .notifications {
      padding: ${spacing.none} 10px;
      border: none;
      min-width: ${sizing.notificationWidth};
      min-height: ${sizing.widgetHeight};
      line-height: ${typography.lineHeight.widget};
      opacity: ${opacity.primary};
      transition: ${transition.all};
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

    image {
      min-height: ${sizing.iconSmall};
      min-width: ${sizing.iconSmall};
      -gtk-icon-size: ${sizing.iconSmall};
      margin-top: auto;
      margin-bottom: auto;
    }

    .tray image {
      min-height: ${sizing.iconLarge};
      min-width: ${sizing.iconLarge};
      -gtk-icon-size: ${sizing.iconLarge};
      margin-top: auto;
      margin-bottom: auto;
    }

    .notifications image {
      min-height: ${sizing.iconSmall};
      min-width: ${sizing.iconSmall};
      -gtk-icon-size: ${sizing.iconSmall};
      margin-top: auto;
      margin-bottom: auto;
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
    .separator {
      padding: ${spacing.none} ${spacing.xs};
      min-height: ${sizing.widgetHeight};
      line-height: ${typography.lineHeight.widget};
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
