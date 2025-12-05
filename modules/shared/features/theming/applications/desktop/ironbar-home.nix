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
    optionalString
    types
    ;

  cfg = config.theming.signal or { };
  appsCfg = cfg.applications or { };
  appCfg = appsCfg.ironbar or { };
  configEnabled = appCfg.enable or false;
  ironbarEnabled = (cfg.enable or false) && configEnabled;

  theme = if themeContext != null && themeContext ? theme then themeContext.theme else null;

  colors = if theme != null && theme ? colors then theme.colors else null;

  spacing = {
    xxs = "2px"; # Ultra-tight trim spacing
    xs = "4px"; # Tight internal spacing
    sm = "8px"; # Module container padding
    md = "12px"; # Standard element padding
    lg = "16px"; # Wider element padding
    xl = "20px"; # Extra spacing
    xxl = "24px"; # Maximum spacing
  };

  radius = {
    sm = "8px"; # Small elements (buttons, chips)
    md = "12px"; # Module pills
  };

  defaultIronbarConfig = {
    monitors = {
      "DP-3" = {
        position = "top";
        height = 40;
        layer = "top";
        exclusive_zone = true;
        popup_gap = 8;
        popup_autohide = false;
        start_hidden = false;
        anchor_to_edges = false;
        icon_theme = "Papirus";
        margin = {
          top = 8;
          bottom = 0;
          left = 16;
          right = 16;
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
            icon_size = 16;
          }
          {
            type = "notifications";
            class = "notifications";
            icon_size = 16;
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

  extraCssText = appCfg.extraCss or "";

  baseCss =
    if colors == null then
      null
    else
      ''
        /* ============================================
           SIGNAL THEME COLORS
           ============================================ */
        @define-color surface_subtle ${colors."surface-subtle".hex};
        @define-color surface_base ${colors."surface-base".hex};
        @define-color surface_emphasis ${colors."surface-emphasis".hex};
        @define-color text_primary ${colors."text-primary".hex};
        @define-color text_secondary ${colors."text-secondary".hex};
        @define-color divider_primary ${colors."divider-primary".hex};
        @define-color accent_primary ${colors."accent-primary".hex};
        @define-color accent_focus ${colors."accent-focus".hex};
        @define-color accent_info ${colors."accent-info".hex};
        @define-color accent_danger ${colors."accent-danger".hex};

        @define-color panel_bg alpha(@surface_base, 0.92);
        @define-color panel_border alpha(@divider_primary, 0.55);
        @define-color widget_bg alpha(@surface_subtle, 0.98);
        @define-color widget_border alpha(@divider_primary, 0.35);
        @define-color widget_hover alpha(@surface_emphasis, 0.90);

        /* ============================================
           IRONBAR GTK CSS STYLING
           Generated by Signal theme. Use `ironbar inspect`
           to explore nodes and iterate safely.
           ============================================ */

        * {
          font-family: "JetBrainsMono Nerd Font", "Iosevka Nerd Font", sans-serif;
          font-size: 14px;
          font-weight: 600;
          border: none;
          border-radius: 0;
          min-height: 0;
          box-shadow: none;
          text-shadow: none;
          outline-offset: 0;
          -gtk-icon-effect: none;
        }

        window#ironbar,
        .background,
        #bar {
          background-color: transparent;
          background-image: none;
        }

        .background {
          padding: ${spacing.sm};
        }

        #bar {
          padding: ${spacing.xs} ${spacing.xl};
          min-height: 0;
        }

        #bar #start,
        #bar #center,
        #bar #end,
        .container {
          margin: 0 ${spacing.sm};
          padding: ${spacing.xs} ${spacing.sm};
          border-radius: ${radius.md};
          background-color: @panel_bg;
          border: 1px solid @panel_border;
          box-shadow: 0 10px 32px rgba(0, 0, 0, 0.28);
        }

        #bar #start {
          margin-left: 0;
        }

        #bar #end {
          margin-right: 0;
        }

        .container > widget,
        .container > .widget-container {
          min-height: 0;
        }

        .widget-container {
          padding: ${spacing.xxs};
          margin: 0 ${spacing.xs};
        }

        .widget-container:first-child {
          margin-left: 0;
        }

        .widget-container:last-child {
          margin-right: 0;
        }

        .widget {
          background-color: @widget_bg;
          border-radius: ${radius.md};
          border: 1px solid @widget_border;
          padding: ${spacing.xs} ${spacing.lg};
          color: @text_primary;
          min-height: 28px;
          transition: background-color 120ms ease, border-color 120ms ease, color 120ms ease;
        }

        .widget.compact {
          padding: ${spacing.xs} ${spacing.md};
        }

        .widget:hover,
        .widget-container:focus-within .widget {
          background-color: @widget_hover;
          border-color: @divider_primary;
          color: @text_primary;
        }

        .widget.warning {
          color: @accent_info;
        }

        .widget.danger {
          color: @accent_danger;
        }

        .widget.success {
          color: @accent_primary;
        }

        .widget label {
          color: inherit;
        }

        /* Workspaces -------------------------------------------------- */
        .workspaces {
          background: none;
          border: none;
          padding: ${spacing.xxs} ${spacing.sm};
        }

        .workspaces box {
          min-height: 0;
        }

        .workspaces button {
          background: transparent;
          color: @text_secondary;
          min-height: 26px;
          min-width: 28px;
          padding: ${spacing.xs} ${spacing.md};
          margin: 0 ${spacing.xxs};
          border-radius: ${radius.sm};
          transition: background-color 120ms ease, color 120ms ease;
        }

        .workspaces button.visible {
          color: @text_primary;
        }

        .workspaces button.focused {
          background-color: @accent_focus;
          color: @surface_base;
        }

        .workspaces button.urgent {
          background-color: alpha(@accent_danger, 0.18);
          color: @accent_danger;
        }

        .workspaces button:hover:not(.focused) {
          background-color: alpha(@surface_emphasis, 0.6);
          color: @text_primary;
        }

        .workspaces button:focus-visible {
          outline: 2px solid @accent_primary;
          outline-offset: 2px;
        }

        /* Common module tweaks --------------------------------------- */
        .label,
        .clock,
        .sys-info,
        .brightness,
        .volume,
        .notifications,
        .tray {
          background-color: @widget_bg;
          border-radius: ${radius.md};
          border: 1px solid @widget_border;
          padding: ${spacing.xs} ${spacing.lg};
          margin: 0;
        }

        .label {
          font-style: italic;
          min-width: 0;
        }

        .clock {
          color: @text_secondary;
          letter-spacing: 0.08em;
        }

        .clock:hover {
          color: @text_primary;
        }

        .sys-info {
          color: @accent_info;
          font-variant-numeric: tabular-nums;
          gap: ${spacing.sm};
        }

        .sys-info > * {
          margin: 0;
          padding: 0 ${spacing.sm};
        }

        .brightness {
          color: @accent_info;
        }

        .volume {
          color: @accent_primary;
        }

        .notifications.notification-count {
          color: @accent_danger;
        }

        .tray {
          padding: ${spacing.xs} ${spacing.md};
          gap: ${spacing.xs};
        }

        .tray image,
        .notifications image {
          min-width: 16px;
          min-height: 16px;
        }

        tooltip {
          background-color: @surface_base;
          border: 1px solid @divider_primary;
          border-radius: ${radius.md};
          padding: ${spacing.sm} ${spacing.md};
          color: @text_primary;
        }

        /* Popup styling ---------------------------------------------- */
        .popup {
          background-color: @surface_base;
          border: 1px solid @divider_primary;
          border-radius: ${radius.md};
          padding: ${spacing.md};
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.45);
        }

        .popup list,
        .popup row,
        .popup .item {
          background-color: transparent;
          border-radius: ${radius.sm};
          padding: ${spacing.xs} ${spacing.md};
          color: @text_primary;
        }

        .popup .item:not(:last-child) {
          margin-bottom: ${spacing.xxs};
        }

        .popup .item label {
          color: inherit;
        }

        .popup row:selected,
        .popup .item:selected,
        .popup .item:hover {
          background-color: alpha(@surface_emphasis, 0.7);
        }

        .popup separator {
          background-color: alpha(@divider_primary, 0.45);
          min-height: 1px;
          margin: ${spacing.xs} 0;
        }

        .popup button {
          background-color: @widget_bg;
          border-radius: ${radius.md};
          border: 1px solid @widget_border;
          padding: ${spacing.xs} ${spacing.lg};
          margin: ${spacing.xs} 0;
        }

        .popup button:hover {
          background-color: @widget_hover;
        }

        /* Notifications overlay ------------------------------------- */
        revealer,
        overlay.notifications {
          margin: 0;
          padding: 0;
          min-height: 0;
        }

        overlay.notifications button.text-button {
          background-color: @widget_bg;
          border-radius: ${radius.md};
          border: 1px solid @widget_border;
          padding: 6px ${spacing.md};
          margin: ${spacing.xs};
          background-image: none;
          box-shadow: none;
          min-width: 16px;
          min-height: 16px;
        }

        overlay.notifications button.text-button label {
          padding: 0;
          margin: 0;
          min-height: 16px;
          min-width: 16px;
          font-size: 14px;
        }

        overlay.notifications button.text-button:active,
        overlay.notifications button.text-button:focus {
          border: 1px solid @divider_primary;
          box-shadow: none;
          outline: none;
        }
      '';

  cssBody =
    if baseCss == null then
      null
    else
      baseCss + optionalString (extraCssText != "") ("\n" + extraCssText);
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

    extraCss = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Additional GTK4 CSS appended after the generated Signal stylesheet.
        Handy for rapid tweaks without forking the managed file.
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
    })
    (mkIf (ironbarEnabled && cssBody != null) {
      xdg.configFile."ironbar/style.css" = {
        text = cssBody;
      };
    })
  ];
}
