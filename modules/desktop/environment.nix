# Desktop Environment Configuration
# Session management via UWSM, seatd, and display manager integration
{ config, ... }:
let
  # Capture flake-parts config modules
  nixos = config.flake.modules.nixos;
in
{
  flake.modules.nixos.desktopEnvironment =
    nixosArgs:
    let
      inherit (nixosArgs) pkgs lib;
      nixosConfig = nixosArgs.config;
    in
    {
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
            binPath = lib.getExe nixosConfig.programs.niri.package;
          };
        };
      };

      services.displayManager.sessionPackages = lib.mkForce [ ];
    };

  # Desktop user groups configuration
  # Dendritic pattern: NO imports - hosts import features directly
  flake.modules.nixos.desktopUserGroups =
    nixosArgs:
    let
      inherit (nixosArgs) pkgs lib;
      nixosConfig = nixosArgs.config;
    in
    {
      users.users.${nixosConfig.host.username}.extraGroups = [
        "audio"
        "video"
        "input"
        "networkmanager"
        "seat"
      ];
    };
}
