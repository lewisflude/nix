# Desktop Environment Configuration
# Session management via UWSM and display manager integration
{
  flake.modules.nixos.desktopEnvironment =
    { lib, config, ... }:
    {
      environment.pathsToLink = [ "/share/wayland-sessions" ];

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
      ];
    };
}
