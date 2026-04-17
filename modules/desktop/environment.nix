# Desktop Environment Configuration
# Session management via UWSM and display manager integration
{
  flake.modules.nixos.desktopEnvironment = _: {
    environment.pathsToLink = [ "/share/wayland-sessions" ];
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
