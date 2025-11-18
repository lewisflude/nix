{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  containersLib = import ../lib.nix { inherit lib; };
  inherit (containersLib) mkResourceOptions mkResourceFlags mkHealthFlags;

  cfg = config.host.services.containersSupplemental;
  constants = import ../../../../../lib/constants.nix;
in
{
  options.host.services.containersSupplemental.cleanuparr = {
    enable = mkEnableOption "Cleanuparr download queue cleanup" // {
      default = false;
    };

    port = mkOption {
      type = types.port;
      default = constants.ports.services.cleanuparr;
      description = "Port for Cleanuparr web interface.";
    };

    dataPath = mkOption {
      type = types.str;
      default = "/mnt/storage";
      description = "Path to media storage directory.";
    };

    resources = mkResourceOptions {
      memory = "512m";
      cpus = "1.0";
    };
  };

  config = mkIf (cfg.enable && cfg.cleanuparr.enable) {
    virtualisation.oci-containers.containers.cleanuparr = {
      image = "ghcr.io/cleanuparr/cleanuparr:latest";
      # NOTE: Removed 'user' setting to allow container to run as root.
      # The container's entrypoint needs to chown files in /app during startup.
      # PUID/PGID environment variables are still set for the application's
      # internal user management after initial setup.
      environment = {
        PORT = toString cfg.cleanuparr.port;
        PUID = toString cfg.uid;
        PGID = toString cfg.gid;
        TZ = cfg.timezone;
      };
      ports = [
        "${toString cfg.cleanuparr.port}:${toString cfg.cleanuparr.port}"
      ];
      volumes = [
        "${cfg.configPath}/cleanuparr:/config"
        "${cfg.cleanuparr.dataPath}:${cfg.cleanuparr.dataPath}:ro"
      ];
      extraOptions = [
        "--network=host"
      ]
      ++ mkHealthFlags {
        cmd = "curl -f http://localhost:${toString cfg.cleanuparr.port}/health || exit 1";
        interval = "30s";
        timeout = "10s";
        retries = "3";
        startPeriod = "60s";
      }
      ++ mkResourceFlags cfg.cleanuparr.resources;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/cleanuparr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    # Ensure curl is available for health check
    systemd.services."podman-cleanuparr" = {
      path = [ pkgs.curl ];
    };
  };
}
