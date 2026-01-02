{
  lib,
  config,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  imports = [
    ./regreet.nix
    ./console-theme.nix
  ];

  config = lib.mkIf cfg.enable {
    environment.pathsToLink = [ "/share/wayland-sessions" ];

    # seatd is required for libseat-based applications (niri, some games, etc.)
    # Provides seat management for Wayland compositors
    services.seatd.enable = true;

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
    # Disable the plain niri session, only use UWSM-managed session
    services.displayManager.sessionPackages = lib.mkForce [ ];

    # ReGreet greeter is configured in ./regreet.nix with Signal theme
  };
}
