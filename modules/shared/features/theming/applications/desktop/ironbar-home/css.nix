{
  colors,
  ...
}:
let
  # Base CSS - minimal, let Signal theme do the work
  baseCss = ''
    /* Let Signal GTK theme handle all base styling */
    #bar {
      padding: 6px 20px;
      min-height: 44px;
    }
  '';

  # Signal theme colors - Floating island containers
  themeCss =
    if colors != null then
      ''
        /* Signal Theme: Floating Islands Design */
        color: ${colors."text-primary".hex};

        /* ===== FLOATING ISLANDS ===== */
        /* Three distinct floating sections with backgrounds */

        /* Island 1: Navigation block (left) */
        #bar #start {
          background-color: ${colors."surface-base".hex};
          border-radius: 12px;
          padding: 4px 8px;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
        }

        /* Island 2: Time block (center) */
        #bar #center {
          background-color: ${colors."surface-base".hex};
          border-radius: 12px;
          padding: 4px 8px;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
        }

        /* Island 3: Status block (right) */
        #bar #end {
          background-color: ${colors."surface-base".hex};
          border-radius: 12px;
          padding: 4px 8px;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
        }
      ''
    else
      "";

  # Signal theme colors - Widget styling (transparent by default)
  widgetThemeCss =
    if colors != null then
      ''

        /* Let Signal GTK theme style widgets by default */

        /* Only style the focused workspace - let Signal theme handle the rest */
        #bar #start .workspaces button.focused {
          background-color: ${colors."surface-subtle".hex} !important;
          border-radius: 8px;
        }

        /* Popup styling - match island aesthetic */
        .popup {
          background-color: ${colors."surface-base".hex};
          border: 1px solid ${colors."surface-emphasis".hex};
        }

        /* Interactive widget hover states */
        .brightness:hover,
        .volume:hover {
          background-color: rgba(37, 38, 47, 0.25);
          border-radius: 8px;
          cursor: pointer;
        }

        /* Interactive widget active states */
        .brightness:active,
        .volume:active {
          transform: scale(0.98);
        }

        /* Tray button hover states */
        .tray button:hover {
          background-color: rgba(37, 38, 47, 0.25);
          border-radius: 6px;
        }

        /* Tray button active states */
        .tray button:active {
          transform: scale(0.95);
        }

        /* Universal focus indicator for keyboard navigation */
        *:focus-visible {
          outline: 2px solid ${colors."accent-focus".hex};
          outline-offset: 2px;
          border-radius: 8px;
        }
      ''
    else
      "";

  layoutCss = ''

    /* ===== FLOATING ISLAND SPACING ===== */
    /* Islands are separated by natural bar gap */
    #bar #start,
    #bar #center,
    #bar #end {
      min-height: 36px;
    }

    /* Center island gets slightly more visual weight */
    #bar #center {
      padding: 6px 12px;
      box-shadow: 0 3px 16px rgba(0, 0, 0, 0.12);
    }

    /* ===== MODULE POSITIONING ===== */
    /* Widget containers - minimal spacing within islands */
    .widget-container {
      margin: 0;
      min-height: 36px;
    }

    /* Widget containers - ensure flex children are centered */
    .widget-container > box {
      min-height: 36px;
    }

    /* All widgets - consistent height */
    .widget {
      min-height: 36px;
      border: none;
    }

    /* ===== ISLAND 1: NAVIGATION (Workspaces + Focused Window) ===== */
    /* Gestalt: Proximity - Workspaces grouped tightly, separated from window title */

    /* Workspace widget - tight internal spacing */
    .workspaces {
      padding: 2px 4px;
      margin-right: 16px;
    }

    /* Individual workspace items - icon-based with semantic meaning */
    .workspaces .item {
      min-width: 36px;
      min-height: 32px;
      margin: 0 3px;
      padding: 0 8px;
      border: none;
      font-size: 16px;
      font-weight: 400;
      line-height: 32px;
      opacity: 0.5;
      transition: opacity 150ms ease, background-color 150ms ease, transform 100ms ease;
    }

    /* Workspace item hover state */
    .workspaces .item:hover {
      opacity: 0.7;
      background-color: rgba(37, 38, 47, 0.15);
      border-radius: 8px;
    }

    /* Active workspace - full opacity with subtle highlight */
    .workspaces .item.focused,
    .workspaces .item.active {
      opacity: 1;
      font-weight: 600;
    }

    /* Workspace with windows - medium opacity to show occupancy */
    .workspaces .item.occupied {
      opacity: 0.8;
    }

    /* Urgent workspace - pulsing indicator (matches niri urgent border) */
    .workspaces .item.urgent {
      opacity: 1;
      animation: urgentPulse 1.5s ease-in-out infinite;
    }

    @keyframes urgentPulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.6; }
    }

    /* First workspace item - no leading margin */
    .workspaces .item:first-child {
      margin-left: 0;
    }

    /* Last workspace item - no trailing margin */
    .workspaces .item:last-child {
      margin-right: 0;
    }

    /* Focused window title - icon + text with better spacing */
    .label {
      padding: 0 12px;
      border: none;
      font-size: 13px;
      font-weight: 400;
      line-height: 36px;
      min-height: 36px;
      opacity: 0.9;
      transition: opacity 150ms ease, color 150ms ease;
    }

    /* Icon in focused window title */
    .label image {
      margin-right: 8px;
    }

    /* Focused window title when window is active */
    .label.active,
    .label.focused {
      opacity: 1;
      font-weight: 500;
    }

    /* Focused window title when window is inactive or no window */
    .label.inactive,
    .label:empty {
      opacity: 0.5;
    }

    /* ===== ISLAND 2: TIME (Clock as Visual Anchor) ===== */
    /* Gestalt: Figure-ground - Clock is the primary visual anchor */

    /* Clock widget - largest and most prominent element */
    .clock {
      padding: 0 20px;
      border: none;
      font-size: 17px;
      font-weight: 600;
      letter-spacing: 0.05em;
      min-width: 110px;
      min-height: 36px;
      line-height: 36px;
    }

    /* ===== ISLAND 3: SYSTEM STATUS (Monitoring + Controls) ===== */
    /* Gestalt: Proximity - Three sub-groups with varying spacing */
    /* Sub-group 1: Monitoring (CPU/RAM) - tight spacing */
    /* Sub-group 2: Controls (Brightness/Volume) - medium spacing */
    /* Sub-group 3: Communications (Tray/Notifications) - separate with more space */

    /* System info - monitoring sub-group */
    /* UX: Cleaner numeric display without % clutter */
    .sys-info {
      padding: 0 12px;
      margin-right: 14px;
      border: none;
      font-size: 14px;
      font-weight: 500;
      line-height: 36px;
      min-height: 36px;
      opacity: 0.85;
      transition: opacity 150ms ease;
    }

    /* Emphasize on hover */
    .sys-info:hover {
      opacity: 1;
    }

    /* Alert state for high resource usage */
    .sys-info.warning {
      color: #fab387; /* Orange for high usage */
      opacity: 1;
      animation: pulse 2s ease-in-out infinite;
    }

    .sys-info.critical {
      color: #f38ba8; /* Red for critical usage */
      opacity: 1;
      font-weight: 600;
      animation: pulse 1s ease-in-out infinite;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.7; }
    }

    /* Niri layout indicator - shows window state */
    .niri-layout {
      padding: 0 10px;
      margin-right: 14px;
      border: none;
      font-size: 16px;
      font-weight: 400;
      line-height: 36px;
      min-height: 36px;
      opacity: 0.7;
      transition: opacity 150ms ease;
    }

    .niri-layout:hover {
      opacity: 1;
    }

    /* Brightness control - interactive sub-group start */
    /* UX: Progressive disclosure - icon only, details on hover */
    .brightness {
      padding: 0 12px;
      margin-right: 4px;
      min-width: 50px; /* Reduced from 80px - icon only */
      border: none;
      font-size: 16px; /* Larger icon for better visibility */
      font-weight: 400;
      line-height: 36px;
      min-height: 36px;
      transition: background-color 150ms ease, transform 50ms ease, min-width 200ms ease;
    }

    /* Show details on hover - progressive disclosure */
    .brightness:hover {
      min-width: 90px; /* Expand to show percentage */
    }

    /* Volume control - interactive sub-group (paired with brightness) */
    /* UX: Progressive disclosure - icon only, details on hover */
    .volume {
      padding: 0 12px;
      margin-right: 16px;
      min-width: 45px; /* Reduced from 80px - icon only */
      border: none;
      font-size: 16px; /* Larger icon for better visibility */
      font-weight: 400;
      line-height: 36px;
      min-height: 36px;
      transition: background-color 150ms ease, transform 50ms ease, min-width 200ms ease;
    }

    /* Show details on hover - progressive disclosure */
    .volume:hover {
      min-width: 90px; /* Expand to show percentage */
    }

    /* System tray - communications sub-group start */
    .tray {
      padding: 7px 10px;
      margin-right: 8px;
      border: none;
      min-height: 36px;
    }

    /* Tray buttons - larger touch targets */
    .tray button {
      min-height: 22px;
      min-width: 22px;
      padding: 0;
      margin: 0 4px;
      background: transparent;
      border: none;
      transition: background-color 150ms ease, transform 50ms ease;
    }

    /* Tray button images - increased size for accessibility */
    .tray button image {
      min-height: 22px;
      min-width: 22px;
      padding: 0;
      margin: 0;
    }

    /* Notifications - end of communications sub-group */
    .notifications {
      padding: 0 12px;
      border: none;
      min-width: 45px;
      min-height: 36px;
      line-height: 36px;
    }

    /* ===== TYPOGRAPHY & ALIGNMENT ===== */
    /* Gestalt: Similarity - Similar elements use similar typography */
    /* Size hierarchy: Clock (17px) > System info (14px) > Controls (14px) > Context (13px) */

    /* All labels - consistent baseline alignment */
    label {
      font-size: 14px;
      font-weight: 400;
      line-height: 36px;
    }

    /* Icon-label combinations - ensure vertical centering */
    box > label,
    button > label {
      line-height: 36px;
    }

    /* ===== INTERACTIVE ELEMENTS ===== */
    /* All buttons - accessible touch targets with feedback */
    button {
      min-width: 36px;
      min-height: 36px;
      padding: 0 12px;
      background: transparent;
      border: none;
      box-shadow: none;
      font-size: 14px;
      font-weight: 400;
      line-height: 36px;
      cursor: pointer;
    }

    /* Button labels - vertically centered, no styling */
    button label {
      line-height: 36px;
      font-size: 14px;
      font-weight: 400;
      background: transparent;
    }

    /* ===== ICON ALIGNMENT ===== */
    /* Icons in status widgets - centered vertically */
    image {
      min-height: 18px;
      min-width: 18px;
      -gtk-icon-size: 18px;
      margin-top: auto;
      margin-bottom: auto;
    }

    /* Tray icons - larger for accessibility */
    .tray image {
      min-height: 22px;
      min-width: 22px;
      -gtk-icon-size: 22px;
      margin-top: auto;
      margin-bottom: auto;
    }

    /* Notification icon - standard sizing */
    .notifications image {
      min-height: 18px;
      min-width: 18px;
      -gtk-icon-size: 18px;
      margin-top: auto;
      margin-bottom: auto;
    }

    /* ===== POPUPS ===== */
    /* Popup windows - match floating island style with entrance animation */
    .popup {
      padding: 16px;
      border-radius: 12px;
      margin-top: 8px;
      font-size: 14px;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
      animation: slideDown 150ms ease-out;
    }

    /* Popup entrance animation */
    @keyframes slideDown {
      from {
        opacity: 0;
        transform: translateY(-8px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    /* Popup labels - proper line height */
    .popup label {
      line-height: 1.5;
    }

    /* Popup headers - clear hierarchy */
    .popup label:first-child {
      font-weight: 600;
      font-size: 16px;
      margin-bottom: 10px;
      line-height: 1.4;
    }

    /* Clock popup - calendar view */
    .popup-clock {
      padding: 20px;
      min-width: 320px;
      font-size: 15px;
    }

    /* ===== VISUAL SEPARATORS ===== */
    /* Gestalt: Common region - Use subtle separators to show sub-grouping */
    /* Add visual separator between workspaces and window title */
    .workspaces::after {
      content: "";
      position: absolute;
      right: 8px;
      top: 50%;
      transform: translateY(-50%);
      width: 1px;
      height: 20px;
      opacity: 0;
    }

    /* Subtle visual breathing room through spacing (proximity) */
    /* Already implemented via margin-right variations */
  '';
in
baseCss + themeCss + widgetThemeCss + layoutCss
