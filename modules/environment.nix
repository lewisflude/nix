# Desktop Environment Configuration
# Session management via UWSM and display manager integration.
# User group membership lives in modules/users.nix (single owner for the account).
{
  flake.modules.nixos.desktopEnvironment = _: {
    environment.pathsToLink = [ "/share/wayland-sessions" ];
  };
}
