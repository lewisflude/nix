{
  config,
  lib,
  pkgs,
  ...
}:
# Hytale Server Feature Module
#
# High-level feature flag for enabling Hytale game server.
# Bridges to services.hytaleServer configuration.
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.hytaleServer;
  constants = import ../../../lib/constants.nix;
in
{
  config = mkIf cfg.enable {
    services.hytaleServer = {
      enable = true;
      port = cfg.port or constants.ports.services.hytaleServer;
      authMode = cfg.authMode or "authenticated";
      openFirewall = cfg.openFirewall or true;
      disableSentry = cfg.disableSentry or false;

      serverFiles = {
        jarPath = cfg.serverFiles.jarPath or null;
        assetsPath = cfg.serverFiles.assetsPath or null;
        flatpakSourceDir = cfg.serverFiles.flatpakSourceDir or null;
        symlinkFromFlatpak = cfg.serverFiles.symlinkFromFlatpak or true;
      };

      backup = {
        enable = cfg.backup.enable or false;
        directory = cfg.backup.directory or "/var/lib/hytale-server/backups";
        frequency = cfg.backup.frequency or 30;
      };

      jvmArgs = [
        "-XX:AOTCache=/var/lib/hytale-server/HytaleServer.aot"
        "-Xmx${cfg.memory.max or "4G"}"
        "-Xms${cfg.memory.min or "2G"}"
      ];

      extraArgs = cfg.extraArgs or [ ];
    };
  };
}
