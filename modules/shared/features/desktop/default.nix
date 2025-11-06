{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: let
  inherit (lib) mkIf mkMerge optionalAttrs;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.desktop;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  inherit (platformLib) isLinux;
in {
  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs isLinux {
      environment.systemPackages = optionals cfg.utilities (
        with pkgs; [
          grim
          slurp
          wl-clipboard

          wlr-randr
          brightnessctl

          xdg-utils

          argyllcms
          colord-gtk
          wl-gammactl
        ]
      );

      users.users.${config.host.username}.extraGroups =
        [
          "audio"
          "video"
          "input"
          "networkmanager"
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
          assertion = cfg.theming -> cfg.enable;
          message = "Theming requires desktop feature to be enabled";
        }
      ];
    }
  ]);
}
