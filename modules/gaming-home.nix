# Gaming home-manager configuration (NixOS only)
# Dendritic pattern: Full implementation as flake.modules.homeManager.gamingHome
{ config, ... }:
{
  flake.modules.homeManager.gamingHome = { lib, pkgs, osConfig ? {}, ... }:
    let
      gamingEnabled = osConfig.host.features.gaming.enable or false;

      install-mf-codecs = pkgs.writeShellApplication {
        name = "install-mf-codecs";
        text = ''
          if [ $# -eq 0 ]; then
            echo "Usage: install-mf-codecs <STEAM_APP_ID>"
            echo "Find App ID: right-click game → Properties, or check steamapps/"
            exit 1
          fi
          echo "Installing Media Foundation codecs for App ID: $1"
          ${pkgs.protontricks}/bin/protontricks "$1" -q mf
          echo "Done. Restart the game if needed."
        '';
        runtimeInputs = [ pkgs.protontricks ];
      };
    in
    lib.mkIf (gamingEnabled && pkgs.stdenv.isLinux) {
      programs.mangohud = {
        enable = true;
        enableSessionWide = false;
      };

      home.packages = [
        pkgs.moonlight-qt
        pkgs.wine
        pkgs.winetricks
        install-mf-codecs
        pkgs.protonup-qt
      ] ++ lib.optionals (osConfig.host.features.gaming.steam or false) [
        pkgs.steamcmd
        pkgs.steam-run
      ];

      home.file.".steam/steam/steam_dev.cfg".text = ''
        unShaderBackgroundProcessingThreads 16
        @nClientDownloadEnableHTTP2PlatformLinux 0
      '';

      systemd.user.services.steam-bwrap-setup = {
        Unit = {
          Description = "Replace Steam's bubblewrap with patched version for VR";
          Before = [ "steam-autostart.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "setup-steam-bwrap" ''
            STEAM_RUNTIME="$HOME/.local/share/Steam/ubuntu12_32/steam-runtime"
            PATCHED_BWRAP="/run/current-system/sw/bin/bwrap"
            for ARCH in amd64 i386; do
              STEAM_BWRAP="$STEAM_RUNTIME/$ARCH/usr/libexec/steam-runtime-tools-0/srt-bwrap"
              if [ ! -d "$(dirname "$STEAM_BWRAP")" ]; then continue; fi
              if [ -f "$STEAM_BWRAP" ] && [ ! -L "$STEAM_BWRAP" ]; then
                mv "$STEAM_BWRAP" "$STEAM_BWRAP.original"
              fi
              if [ ! -L "$STEAM_BWRAP" ]; then
                ln -sf "$PATCHED_BWRAP" "$STEAM_BWRAP"
              fi
            done
          '';
        };
      };

      systemd.user.services.steam-autostart = {
        Unit = {
          Description = "Auto-start Steam on login";
          After = [ "graphical-session.target" "steam-bwrap-setup.service" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.steam}/bin/steam -silent";
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
