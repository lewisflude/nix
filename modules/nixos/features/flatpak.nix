{ config, lib, ... }:

let
  cfg = config.host.features.flatpak;
in
{
  options.host.features.flatpak = {
    enable = lib.mkEnableOption "flatpak support with nix-flatpak declarative management";
  };

  config = lib.mkIf cfg.enable {
    # Enable flatpak system-wide
    services.flatpak.enable = true;

    # XDG portals are already configured in modules/nixos/system/integration/xdg.nix
    # This ensures flatpak apps can use portals for file choosers, screenshots, etc.

    # nix-flatpak provides declarative package management
    # Individual flatpak packages should be declared in home-manager modules
    # See home/nixos/apps/ for application-specific flatpak configurations
  };
}
