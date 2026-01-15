{
  lib,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  gamingEnabled = osConfig.host.features.gaming.enable or false;

  # Helper script to install Media Foundation codecs for Proton/Steam games
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
mkIf gamingEnabled {
  programs.mangohud = {
    enable = true;
    enableSessionWide = false; # Enable per-game via MANGOHUD=1
  };

  home.packages = [
    pkgs.moonlight-qt
    pkgs.wine
    pkgs.winetricks
    install-mf-codecs
  ];

  # Auto-start Steam on login (for gaming PC use case)
  systemd.user.services.steam-autostart = {
    Unit = {
      Description = "Auto-start Steam on login";
      After = [ "graphical-session.target" ];
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
}
