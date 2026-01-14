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

  # ============================================================================
  # BASE CSS
  # ============================================================================
  # Minimal reset, let Signal GTK theme handle defaults
  baseCss = ''
    /* Base bar styling */
    #bar {
      padding: 7px ${spacing."3xl"};
      min-height: ${sizing.barHeight};
    }
  '';

  # ============================================================================
  # THEME CSS (Signal Colors)
  # ============================================================================
  # Floating islands design - requires theme colors
  themeCss =
    if colors != null then
      ''
        /* Signal Theme: Floating Islands Design */
        color: ${colors."text-primary".hex};

        /* ===== FLOATING ISLANDS ===== */

        /* Island 1: Navigation (left) */
        #bar #start {
          background-color: ${colors."surface-base".hex};
          border-radius: ${radius.lg};
          padding: ${island.padding};
          box-shadow: ${shadow.island};
        }

        /* Island 2: Time (center) - visual anchor */
        #bar #center {
          background-color: ${colors."surface-base".hex};
          border-radius: ${radius.lg};
          padding: ${island.paddingCenter};
          box-shadow: ${shadow.islandCenter};
        }

        /* Island 3: Status (right) */
        #bar #end {
          background-color: ${colors."surface-base".hex};
          border-radius: ${radius.lg};
          padding: ${island.padding};
          box-shadow: ${shadow.island};
        }
      ''
    else
      "";

  # ============================================================================
  # WIDGET THEME CSS (Interactive States)
  # ============================================================================
  widgetThemeCss =
    if colors != null then
      ''

        /* Signal GTK theme handles default widget styling */

        /* Focused workspace highlight */
        #bar #start .workspaces button.focused {
          background-color: ${colors."surface-subtle".hex} !important;
          border-radius: ${radius.md};
        }

        /* Popup styling - match island aesthetic */
        .popup {
          background-color: ${colors."surface-base".hex};
          border: 1px solid ${colors."surface-emphasis".hex};
        }

        /* Interactive controls - hover states */
        .brightness:hover,
        .volume:hover {
          background-color: ${interactionColors.hoverBg};
        }

        /* Interactive controls - active/pressed states */
        .brightness:active,
        .volume:active {
          background-color: ${interactionColors.activeBg};
          opacity: 0.9;
        }

        /* Tray button hover */
        .tray button:hover {
          background-color: ${interactionColors.activeBg};
          border-radius: ${radius.sm};
        }

        /* Tray button active */
        .tray button:active {
          opacity: 0.9;
        }

        /* Focus indicator for keyboard navigation */
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
    /* Workspaces + Focused Window Title */

    .workspaces {
      padding: ${widget.paddingTight};
      margin-right: ${widget.gapLarge};
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

    .workspaces .item.focused,
    .workspaces .item.active {
      opacity: ${opacity.full};
      font-weight: ${typography.weight.semibold};
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

    .label.inactive,
    .label:empty {
      opacity: ${opacity.muted};
    }

    /* ===== ISLAND 2: TIME ===== */
    /* Clock as visual anchor */

    .clock {
      padding: ${spacing.none} ${spacing."3xl"};
      border: none;
      font-size: ${typography.size.lg};
      font-weight: ${typography.weight.bold};
      font-variant-numeric: ${typography.features.tabularNums};
      letter-spacing: ${typography.letterSpacing.clock};
      min-width: ${sizing.clockWidth};
      min-height: ${sizing.widgetHeight};
      line-height: ${typography.lineHeight.widget};
      text-align: center;
      opacity: ${opacity.emphasis};
    }

    /* ===== ISLAND 3: SYSTEM STATUS ===== */
    /* Three logical groups:
       1. Monitoring: sys-info + niri-layout
       2. Controls: brightness + volume
       3. Communications: tray + notifications */

    /* Visual separators between widget groups
       Note: GTK CSS doesn't support ::before/::after pseudo-elements or positioning.
       Separators are achieved via margin/padding spacing instead. */

    /* System info - Group 1 */
    .sys-info {
      padding: ${spacing.none} ${spacing.lg};
      margin-right: ${widget.gapSection};
      border: none;
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

  '';
in
baseCss + themeCss + widgetThemeCss + layoutCss
