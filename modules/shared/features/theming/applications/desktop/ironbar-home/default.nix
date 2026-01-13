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

  # Import modular components
  defaultIronbarConfig = import ./monitors.nix { inherit pkgs; };
  ironbarCss = import ./css.nix { inherit colors; };

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

      # UI/UX optimized positioning styles
      xdg.configFile."ironbar/style.css" = {
        text = ironbarCss;
      };
    })
  ];
}
