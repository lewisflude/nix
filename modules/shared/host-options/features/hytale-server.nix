# Hytale Server Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  hytaleServer = {
    enable = mkEnableOption "Hytale game server" // {
      example = true;
    };

    port = mkOption {
      type = types.port;
      default = 5520;
      description = "UDP port for the Hytale server (QUIC protocol)";
      example = 3500;
    };

    authMode = mkOption {
      type = types.enum [
        "authenticated"
        "offline"
      ];
      default = "authenticated";
      description = "Authentication mode (authenticated or offline)";
    };

    memory = {
      max = mkOption {
        type = types.str;
        default = "4G";
        description = "Maximum heap size for the JVM";
        example = "8G";
      };

      min = mkOption {
        type = types.str;
        default = "2G";
        description = "Initial heap size for the JVM";
        example = "4G";
      };
    };

    serverFiles = {
      jarPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to HytaleServer.jar file (null for auto-detect from Flatpak)";
        example = "/var/lib/hytale-server/HytaleServer.jar";
      };

      assetsPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to Assets.zip file (null for auto-detect from Flatpak)";
        example = "/var/lib/hytale-server/Assets.zip";
      };

      flatpakSourceDir = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Override Flatpak source directory detection";
        example = "/home/user/.var/app/com.hypixel.HytaleLauncher/data/Hytale/install/release/package/game/latest";
      };

      symlinkFromFlatpak = mkOption {
        type = types.bool;
        default = true;
        description = "Symlink from Flatpak instead of copying (saves space, auto-updates)";
      };
    };

    backup = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable automatic backups";
      };

      directory = mkOption {
        type = types.str;
        default = "/var/lib/hytale-server/backups";
        description = "Backup directory";
      };

      frequency = mkOption {
        type = types.int;
        default = 30;
        description = "Backup interval in minutes";
      };
    };

    disableSentry = mkOption {
      type = types.bool;
      default = false;
      description = "Disable Sentry crash reporting";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra server arguments";
      example = [ "--accept-early-plugins" ];
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically open firewall port";
    };
  };
}
