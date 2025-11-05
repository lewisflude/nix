# Container services feature module
# Bridges host.features.containers to host.services.containers
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.host.features.containers;
in
{
  options.host.features.containers = {
    enable = mkEnableOption "container services";

    mediaManagement = {
      enable = mkEnableOption "media management stack";
      dataPath = mkOption {
        type = types.str;
        default = "/mnt/storage";
        description = "Path to media storage directory";
      };
      configPath = mkOption {
        type = types.str;
        default = "/var/lib/containers/media-management";
        description = "Path to store container configurations";
      };
    };

    productivity = {
      enable = mkEnableOption "productivity stack";
      configPath = mkOption {
        type = types.str;
        default = "/var/lib/containers/productivity";
        description = "Path to store container configurations";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable container services
    host.services.containers = {
      enable = true;

      mediaManagement = mkIf cfg.mediaManagement.enable {
        enable = true;
        inherit (cfg.mediaManagement) dataPath;
        inherit (cfg.mediaManagement) configPath;
      };

      productivity = mkIf cfg.productivity.enable {
        enable = true;
        inherit (cfg.productivity) configPath;
      };

      # Set timezone and user/group IDs from system config
      timezone = mkDefault (config.time.timeZone or "Europe/London");
      uid = mkDefault 1000;
      gid = mkDefault 100;
    };

    # Ensure Podman is enabled
    host.features.virtualisation = {
      enable = true;
      podman = true;
    };
  };
}
