# Flatpak - Dendritic Pattern
# Single file containing NixOS service and home-manager XDG integration
_:
{
  # ===========================================================================
  # NixOS: Flatpak service
  # ===========================================================================
  flake.modules.nixos.flatpak =
    _:
    {
      services.flatpak.enable = true;
    };

  # ===========================================================================
  # Home-manager: XDG data directories for Flatpak apps
  # ===========================================================================
  flake.modules.homeManager.flatpak =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      xdg.systemDirs.data = [
        "/var/lib/flatpak/exports/share"
        "$HOME/.local/share/flatpak/exports/share"
      ];
    };
}
