# Desktop Environment Configuration
# Session management via UWSM, seatd, and display manager integration
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
  isLinux = pkgs.stdenv.isLinux;
in
{
  config = lib.mkIf (cfg.enable && isLinux) {
    environment.pathsToLink = [ "/share/wayland-sessions" ];

    # seatd is required for libseat-based applications (niri, some games, etc.)
    # Provides seat management for Wayland compositors
    services.seatd.enable = true;

    # Add greeter user to seat group for display manager access
    # The greeter runs Cage (Wayland compositor) which needs seatd access
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
    # UWSM (Universal Wayland Session Manager) requires exclusive session control.
    # Niri's default session registration conflicts with UWSM's session management,
    # causing duplicate session entries and potential startup issues.
    # We use mkForce to ensure only UWSM-managed sessions are registered.
    services.displayManager.sessionPackages = lib.mkForce [ ];

    # ReGreet greeter is configured in ./greeter.nix with Signal theme
  };
}
