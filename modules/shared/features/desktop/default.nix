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
      environment.systemPackages = optionals cfg.utilities (
        with pkgs;
        [
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

      users.users.${config.host.username}.extraGroups = [
        "audio"
        "video"
        "input"
        "networkmanager"
      ]
      ++ optional cfg.niri "render";
    })

    # Signal theme integration (configured at home-manager level)
    (mkIf cfg.signalTheme.enable {
      home-manager.users.${config.host.username} = {
        theming.signal = {
          enable = true;
          inherit (cfg.signalTheme) mode;

          applications = {
            # Code editors and terminals
            cursor.enable = true;
            helix.enable = true;
            zed.enable = true;
            ghostty.enable = true;

            # Desktop environment (Linux)
            gtk.enable = lib.mkDefault isLinux;
            ironbar.enable = lib.mkDefault isLinux;

            # Command-line tools
            bat.enable = true;
            fzf.enable = true;
            lazygit.enable = true;
            yazi.enable = true;
            zellij.enable = true;
          };
        };
      };
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
        {
          assertion = cfg.signalTheme.enable -> cfg.enable;
          message = "Signal theme requires desktop feature to be enabled";
        }
      ];
    }
  ]);
}
