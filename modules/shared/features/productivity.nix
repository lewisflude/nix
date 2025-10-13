# Productivity feature module (cross-platform)
# Controlled by host.features.productivity.*
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.productivity;
in {
  config = mkIf cfg.enable {
    home-manager.users.${config.host.username} = {
      home.packages = with pkgs;
        optionals cfg.office [
          libreoffice-fresh
        ]
        ++ optionals cfg.notes [
          obsidian
        ]
        ++ optionals cfg.email [
          thunderbird
        ];
    };
  };
}
