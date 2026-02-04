# Desktop Environment Configuration
# Session management via UWSM, seatd, and display manager integration
{
  flake.modules.nixos.desktopEnvironment =
    { lib, config, ... }:
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
            binPath = lib.getExe config.programs.niri.package;
          };
        };
      };

      services.displayManager.sessionPackages = lib.mkForce [ ];
    };

  # Desktop user groups configuration
  # Dendritic pattern: NO imports - hosts import features directly
  flake.modules.nixos.desktopUserGroups =
    { config, ... }:
    {
      users.users.${config.host.username}.extraGroups = [
        "audio"
        "video"
        "input"
        "networkmanager"
        "seat"
      ];
    };
}
