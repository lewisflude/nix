# Desktop Environment Configuration
# Session management via UWSM, seatd, and display manager integration
{ config, ... }:
let
  # Capture flake-parts config modules
  nixos = config.flake.modules.nixos;
in
{
  flake.modules.nixos.desktopEnvironment = { pkgs, lib, config, ... }: {
    environment.pathsToLink = [ "/share/wayland-sessions" ];

    services.seatd.enable = true;
    users.users.greeter.extraGroups = [ "seat" ];

    programs.niri.enable = true;
    programs.uwsm = {
      enable = true;
      waylandCompositors = {
        niri = {
          prettyName = "Niri";
          comment = "Niri compositor managed by UWSM";
          binPath = lib.getExe config.programs.niri.package;
        };
      };
    };

    services.displayManager.sessionPackages = lib.mkForce [ ];
  };

  # Desktop aggregation module - combines all desktop components
  flake.modules.nixos.desktop = { pkgs, lib, config, ... }: {
    imports = [
      nixos.niri
      nixos.graphics
      nixos.fonts
      nixos.greeter
      nixos.theme
      nixos.console
      nixos.xwayland
      nixos.hardwareSupport
      nixos.desktopEnvironment
    ];

    # Desktop user groups
    users.users.${config.host.username}.extraGroups = [
      "audio"
      "video"
      "input"
      "networkmanager"
      "seat"
    ];
  };
}
