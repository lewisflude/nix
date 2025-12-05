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
        height = 42;
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
            icon_size = 20;
          }
          {
            type = "notifications";
            class = "notifications";
            icon_size = 20;
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
      # Base CSS with GTK resets and positioning
      baseCss = ''
        /* ===== GTK4 THEME RESETS ===== */
        /* Reset all GTK4 theme defaults to ensure consistent styling */

        /* Universal reset */
        * {
          all: unset;
          box-sizing: border-box;
        }

        /* Reset all widgets - remove GTK theme styling */
        button,
        label,
        box,
        image,
        eventbox {
          background: none;
          background-color: transparent;
          background-image: none;
          border: none;
          border-radius: 0;
          box-shadow: none;
          outline: none;
          text-shadow: none;
          padding: 0;
          margin: 0;
          min-width: 0;
          min-height: 0;
        }

        /* Remove button states from GTK theme */
        button:hover,
        button:active,
        button:focus,
        button:checked {
          background: none;
          background-color: transparent;
          border: none;
          box-shadow: none;
          outline: none;
        }

        /* ===== ROOT CONTAINERS ===== */
        /* Bar window - completely transparent */
        .background {
          background: transparent;
        }

        /* Main bar container - no background, just spacing */
        #bar {
          background: transparent;
          padding: 6px 20px;
          min-height: 42px;
          font-size: 14px;
          font-weight: 400;
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

            /* ===== TRANSPARENT WIDGETS WITHIN ISLANDS ===== */
            /* Widgets are transparent - only focused/active states get emphasis */

            /* All widgets - transparent by default */
            .workspaces,
            .label,
            .clock,
            .sys-info,
            .brightness,
            .volume,
            .tray,
            .notifications {
              background: transparent;
            }

            /* Workspace buttons - transparent by default */
            .workspaces button {
              background: transparent;
              transition: background-color 150ms ease;
            }

            /* Focused workspace - only element with background emphasis */
            .workspaces button.focused {
              background-color: ${colors."surface-subtle".hex};
              border-radius: 8px;
            }

            /* Hover states for interactivity feedback */
            .workspaces button:hover:not(.focused) {
              background-color: rgba(255, 255, 255, 0.05);
              border-radius: 8px;
            }

            /* Popup styling - match island aesthetic */
            .popup {
              background-color: ${colors."surface-base".hex};
              border: 1px solid rgba(255, 255, 255, 0.1);
            }
          ''
        else
          "";
    in
    baseCss
    + themeCss
    + ''
      }
    ''
    + widgetThemeCss
    + ''

      /* ===== FLOATING ISLAND SPACING ===== */
      /* Islands are separated by natural bar gap */
      #bar #start,
      #bar #center,
      #bar #end {
        min-height: 34px;
      }

      /* ===== MODULE POSITIONING ===== */
      /* Widget containers - minimal spacing within islands */
      .widget-container {
        margin: 0;
        min-height: 34px;
      }

      /* Widget containers - ensure flex children are centered */
      .widget-container > box {
        min-height: 34px;
      }

      /* All widgets - consistent height */
      .widget {
        min-height: 34px;
        border: none;
      }

      /* ===== ISLAND 1: NAVIGATION (Workspaces + Focused Window) ===== */

      /* Workspace widget - minimal spacing */
      .workspaces {
        padding: 2px 4px;
        margin-right: 8px;
      }

      /* Individual workspace buttons - clean and minimal */
      .workspaces button {
        min-width: 38px;
        min-height: 30px;
        margin: 0 2px;
        padding: 0 12px;
        border: none;
        font-size: 14px;
        font-weight: 500;
        line-height: 30px;
      }

      /* First workspace button - no leading margin */
      .workspaces button:first-child {
        margin-left: 0;
      }

      /* Last workspace button - no trailing margin */
      .workspaces button:last-child {
        margin-right: 0;
      }

      /* Focused window title - minimal padding */
      .label {
        padding: 0 12px;
        border: none;
        font-size: 14px;
        font-weight: 400;
        line-height: 34px;
        min-height: 34px;
      }

      /* ===== ISLAND 2: TIME (Clock as Visual Anchor) ===== */

      /* Clock widget - emphasized through typography alone */
      .clock {
        padding: 0 16px;
        border: none;
        font-size: 15px;
        font-weight: 600;
        letter-spacing: 0.02em;
        min-width: 100px;
        min-height: 34px;
        line-height: 34px;
      }

      /* ===== ISLAND 3: SYSTEM STATUS (Monitoring + Controls) ===== */

      /* System info - clean text display */
      .sys-info {
        padding: 0 12px;
        margin-right: 6px;
        border: none;
        font-size: 13px;
        font-weight: 400;
        line-height: 34px;
        min-height: 34px;
      }

      /* Brightness control - minimal spacing */
      .brightness {
        padding: 0 10px;
        margin-right: 6px;
        min-width: 75px;
        border: none;
        font-size: 13px;
        font-weight: 400;
        line-height: 34px;
        min-height: 34px;
      }

      /* Volume control - minimal spacing */
      .volume {
        padding: 0 10px;
        margin-right: 8px;
        min-width: 75px;
        border: none;
        font-size: 13px;
        font-weight: 400;
        line-height: 34px;
        min-height: 34px;
      }

      /* System tray - icon group */
      .tray {
        padding: 7px 8px;
        margin-right: 6px;
        border: none;
        min-height: 34px;
      }

      /* Tray buttons - minimal spacing */
      .tray button {
        min-height: 20px;
        min-width: 20px;
        padding: 0;
        margin: 0 4px;
        background: transparent;
        border: none;
      }

      /* Tray button images */
      .tray button image {
        min-height: 20px;
        min-width: 20px;
        padding: 0;
        margin: 0;
      }

      /* Notifications - end of island */
      .notifications {
        padding: 0 10px;
        border: none;
        min-width: 40px;
        min-height: 34px;
        line-height: 34px;
      }

      /* ===== TYPOGRAPHY & ALIGNMENT ===== */
      /* All labels - consistent baseline alignment */
      label {
        font-size: 14px;
        font-weight: 400;
        line-height: 34px;
      }

      /* Icon-label combinations - ensure vertical centering */
      box > label,
      button > label {
        line-height: 34px;
      }

      /* ===== INTERACTIVE ELEMENTS ===== */
      /* All buttons - minimal, transparent by default */
      button {
        min-width: 34px;
        min-height: 34px;
        padding: 0 12px;
        background: transparent;
        border: none;
        box-shadow: none;
        font-size: 14px;
        font-weight: 400;
        line-height: 34px;
      }

      /* Button labels - vertically centered, no styling */
      button label {
        line-height: 34px;
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

      /* Tray icons - consistent sizing and vertical centering */
      .tray image {
        min-height: 20px;
        min-width: 20px;
        margin-top: auto;
        margin-bottom: auto;
      }

      /* Notification icon - consistent sizing */
      .notifications image {
        min-height: 18px;
        min-width: 18px;
        margin-top: auto;
        margin-bottom: auto;
      }

      /* ===== POPUPS ===== */
      /* Popup windows - match floating island style */
      .popup {
        padding: 16px;
        border-radius: 12px;
        margin-top: 8px;
        font-size: 14px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
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
