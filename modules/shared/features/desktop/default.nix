{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  inherit (lib) mkIf mkMerge optionalAttrs;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.desktop;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  inherit (platformLib) isLinux;
in
{
  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs isLinux {
      # Enable colord service for color management
      # This provides system-wide color profile management and improves color accuracy
      services.colord.enable = mkIf cfg.utilities true;

      environment.systemPackages = optionals cfg.utilities [
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.wlr-randr
        pkgs.brightnessctl
        pkgs.xdg-utils
        pkgs.argyllcms
        pkgs.colord-gtk
        pkgs.wl-gammactl
      ];

      users.users.${config.host.username}.extraGroups = [
        "audio"
        "video"
        "input"
      ]
      ++ optional cfg.niri "render";
    })

    {
      assertions = [
        {
          assertion = cfg.niri -> !cfg.hyprland || isLinux;
          message = "Niri and Hyprland cannot both be enabled";
        }
        {
          assertion = cfg.signalTheme.enable -> cfg.enable;
          message = "Signal theme requires desktop feature to be enabled";
        }
      ];
    }
  ]);
}
