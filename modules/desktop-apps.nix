# Desktop applications (NixOS only)
# Dendritic pattern: Full implementation as flake.modules.homeManager.desktopApps
_: {
  flake.modules.homeManager.desktopApps =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [
        pkgs.blender
        pkgs.gimp
        pkgs.telegram-desktop
        pkgs.file-roller
        pkgs.font-awesome
        pkgs.aseprite
        pkgs.nautilus
      ];

      # Discord with Vencord (better Wayland, screen sharing, plugins)
      programs.vesktop = {
        enable = true;
        settings = {
          discordBranch = "stable";
          minimizeToTray = true;
          arRPC = true; # Rich presence
        };
        vencord.settings = {
          autoUpdate = false; # Managed by Nix
          enableReactDevtools = false;
          themeLinks = [ ];
          enabledThemes = [ ];
        };
      };

      services.cliphist.enable = false;

      xdg.desktopEntries.ghostty = {
        name = "Ghostty";
        exec = "${pkgs.ghostty}/bin/ghostty";
        terminal = false;
        type = "Application";
        categories = [
          "TerminalEmulator"
          "System"
        ];
      };
    };
}
