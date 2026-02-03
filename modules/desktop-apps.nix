# Desktop applications (NixOS only)
# Dendritic pattern: Full implementation as flake.modules.homeManager.desktopApps
{ config, ... }:
{
  flake.modules.homeManager.desktopApps = { lib, pkgs, config, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [
        pkgs.gimp
        pkgs.discord
        pkgs.telegram-desktop
        pkgs.file-roller
        pkgs.font-awesome
        pkgs.aseprite
        pkgs.thunar
        pkgs.thunar-archive-plugin
        pkgs.thunar-volman
        pkgs.nautilus
      ];

      services.cliphist.enable = false;

      xdg.desktopEntries.ghostty = {
        name = "Ghostty";
        exec = "${pkgs.ghostty}/bin/ghostty";
        terminal = false;
        type = "Application";
        categories = [ "TerminalEmulator" "System" ];
      };
    };
}
