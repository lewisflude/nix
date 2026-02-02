# Flatpak Aspect
#
# Combines all Flatpak-related configuration in a single file.
# Reads options from config.host.features.flatpak
#
# Platform support:
# - NixOS: Flatpak service with nix-flatpak declarative management
# - Darwin: Not supported (Flatpak is Linux-only)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.flatpak;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  options.host.features.flatpak = {
    enable = lib.mkEnableOption "flatpak support with nix-flatpak declarative management";
  };

  config = lib.mkMerge [
    # ================================================================
    # NixOS Configuration
    # ================================================================
    (lib.mkIf (cfg.enable && isLinux) {
      # Enable flatpak system-wide
      services.flatpak.enable = true;

      # XDG portals are already configured in modules/nixos/system/integration/xdg.nix
      # This ensures flatpak apps can use portals for file choosers, screenshots, etc.

      # nix-flatpak provides declarative package management
      # Individual flatpak packages should be declared in home-manager modules
      # See home/nixos/apps/ for application-specific flatpak configurations
    })

    # ================================================================
    # Darwin Configuration
    # ================================================================
    (lib.mkIf (cfg.enable && isDarwin) {
      # Flatpak is not available on macOS
      # This is a no-op placeholder
    })

    # ================================================================
    # Assertions (both platforms)
    # ================================================================
    {
      assertions = [
        {
          assertion = !(cfg.enable && isDarwin);
          message = "Flatpak is not available on macOS";
        }
      ];
    }
  ];
}
