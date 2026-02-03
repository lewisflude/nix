# Flatpak home-manager integration (NixOS only)
# Dendritic pattern: Full implementation as flake.modules.homeManager.flatpakHome
{ config, ... }:
{
  flake.modules.homeManager.flatpakHome = { lib, pkgs, config, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      xdg.systemDirs.data = [
        "/var/lib/flatpak/exports/share"
        "$HOME/.local/share/flatpak/exports/share"
      ];
    };
}
