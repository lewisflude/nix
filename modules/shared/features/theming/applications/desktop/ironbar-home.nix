{
  config,
  inputs,
  lib,
  pkgs,
  themeContext ? null,
  ...
}:
let
  inherit (lib)
    hasAttr
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.theming.signal or { };
  appsCfg = cfg.applications or { };
  appCfg = appsCfg.ironbar or { };
  configEnabled = appCfg.enable or false;

  # Extract theme colors from themeContext
  theme = if themeContext != null then themeContext.theme else null;
  colors = if theme != null then theme.colors else null;

  defaultIronbarConfig = {
    monitors = {
      "DP-3" = {
        position = "top";
        height = 44;
        layer = "top";
        exclusive_zone = true;
        popup_gap = 10;
        popup_autohide = false;
        start_hidden = false;
        anchor_to_edges = false;
        icon_theme = "Papirus";
        margin = {
          top = 8;
          bottom = 0;
          left = 0;
          right = 0;
        };
        start = [
          {
            type = "workspaces";
            class = "workspaces";
            name_map = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
            };
          }
          {
            type = "focused";
            class = "label";
            truncate = "end";
            length = 40;
          }
        ];
        center = [
          {
            type = "clock";
            class = "clock";
            format = "%H:%M";
            format_popup = "%A, %B %d, %Y";
          }
        ];
        end = [
          {
            type = "sys_info";
            class = "sys-info";
            format = [
              "  {cpu_percent}%"
              "  {memory_percent}%"
            ];
          }
          {
            type = "script";
            class = "brightness";
            mode = "poll";
            format = "󰃠 {}%";
            cmd = "brightnessctl -m | awk -F '[(),%]' '{print $6}'";
            interval = 1000;
            on_click_left = "brightnessctl set 10%-";
            on_click_right = "brightnessctl set +10%";
            tooltip = "Brightness: {}%";
          }
          {
            type = "volume";
            class = "volume";
            format = "{icon} {percentage}%";
            max_volume = 100;
            icons = {
              volume_high = " ";
              volume_medium = " ";
              volume_low = " ";
              muted = "󰝟 ";
            };
          }
          {
            type = "tray";
            class = "tray";
            icon_size = 22;
          }
          {
            type = "notifications";
            class = "notifications";
            icon_size = 22;
          }
        ];
      };
    };
  };

  hostSystem =
    if pkgs ? stdenv && pkgs.stdenv ? hostPlatform && pkgs.stdenv.hostPlatform ? system then
      pkgs.stdenv.hostPlatform.system
    else
      pkgs.stdenv.system;

  flakePackage =
    if inputs ? ironbar && inputs.ironbar ? packages && hasAttr hostSystem inputs.ironbar.packages then
      let
        systemPackages = inputs.ironbar.packages.${hostSystem};
      in
      systemPackages.default or (systemPackages.ironbar or null)
    else
      null;

  packageOverride = appCfg.package or null;

  resolvedPackage =
    if packageOverride != null then
      packageOverride
    else if flakePackage != null then
      flakePackage
    else
      pkgs.ironbar;

  # UI/UX optimized positioning styles for 3440x1440 ultrawide
  ironbarCss =
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
    in
    baseCss
    + themeCss
    + widgetThemeCss
    + ''

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

      /* Individual workspace items - larger touch targets */
      .workspaces .item {
        min-width: 40px;
        min-height: 32px;
        margin: 0 2px;
        padding: 0 12px;
        border: none;
        font-size: 14px;
        font-weight: 400;
        line-height: 32px;
      }

      /* First workspace item - no leading margin */
      .workspaces .item:first-child {
        margin-left: 0;
      }

      /* Last workspace item - no trailing margin */
      .workspaces .item:last-child {
        margin-right: 0;
      }

      /* Focused window title - smaller and lighter (contextual info) */
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

      /* Focused window title when window is active */
      .label.active,
      .label.focused {
        opacity: 1;
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
      .sys-info {
        padding: 0 12px;
        margin-right: 14px;
        border: none;
        font-size: 14px;
        font-weight: 500;
        line-height: 36px;
        min-height: 36px;
      }

      /* Brightness control - interactive sub-group start */
      .brightness {
        padding: 0 12px;
        margin-right: 4px;
        min-width: 80px;
        border: none;
        font-size: 14px;
        font-weight: 400;
        line-height: 36px;
        min-height: 36px;
        transition: background-color 150ms ease, transform 50ms ease;
      }

      /* Volume control - interactive sub-group (paired with brightness) */
      .volume {
        padding: 0 12px;
        margin-right: 16px;
        min-width: 80px;
        border: none;
        font-size: 14px;
        font-weight: 400;
        line-height: 36px;
        min-height: 36px;
        transition: background-color 150ms ease, transform 50ms ease;
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
{
  options.theming.signal.applications.ironbar = {
    config = mkOption {
      type = types.attrs;
      default = defaultIronbarConfig;
      description = ''
        Ironbar configuration forwarded directly to `programs.ironbar.config`.
        The default ships with the Signal desktop layout (workspaces & title on the
        left, clock centered, status indicators on the right). Override this per-host
        to match the monitor names reported by your compositor.
      '';
    };

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      description = ''
        Optional override for the Ironbar package. When unset, the module uses the
        Ironbar flake input (matching upstream releases) and falls back to
        `pkgs.ironbar` if the flake is unavailable.
      '';
    };

    systemd = mkOption {
      type = types.bool;
      default = true;
      description = "Launch Ironbar as a user systemd service.";
    };

    features = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Compile-time Ironbar features to enable (for example "battery" or "lua").
        Passed through to `programs.ironbar.features`.
      '';
    };
  };

  config = mkMerge [
    (mkIf configEnabled {
      programs.ironbar = {
        enable = true;
        package = resolvedPackage;
        inherit (appCfg) systemd features config;
      };

      # UI/UX optimized positioning styles
      xdg.configFile."ironbar/style.css" = {
        text = ironbarCss;
      };
    })
  ];
}
