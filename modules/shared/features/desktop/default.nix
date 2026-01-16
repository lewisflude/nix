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

    # Signal theme integration (configured at home-manager level)
    (mkIf cfg.signalTheme.enable {
      home-manager.users.${config.host.username} = {
        theming.signal = {
          enable = true;
          inherit (cfg.signalTheme) mode;

          # Signal flake applications
          gtk.enable = lib.mkDefault isLinux;
          ironbar.enable = false; # Using local ironbar module instead
          fuzzel.enable = false; # Using local fuzzel module instead

          editors = {
            helix.enable = true;
          };

          terminals = {
            ghostty.enable = true;
          };

          cli = {
            bat.enable = true;
            fzf.enable = true;
            lazygit.enable = true;
            yazi.enable = true;
          };

          # Local applications (not in signal flake)
          local.applications = {
            cursor.enable = true;
            zed.enable = true;
            satty.enable = lib.mkDefault isLinux;
          };
        };

        # Enable local ironbar module
        theming.ironbar.enable = lib.mkDefault isLinux;
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
