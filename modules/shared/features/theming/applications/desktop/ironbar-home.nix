{
  config,
  inputs,
  lib,
  pkgs,
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
    })
    # Ironbar custom CSS disabled - using default GTK theme instead
    # (mkIf (ironbarEnabled && cssBody != null) {
    #   xdg.configFile."ironbar/style.css" = {
    #     text = cssBody;
    #   };
    # })
  ];
}
