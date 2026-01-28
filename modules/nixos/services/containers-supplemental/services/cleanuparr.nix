{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.host.services.containersSupplemental;
in
{
  options.host.services.containersSupplemental.cleanuparr = {
    enable = mkEnableOption "Cleanuparr download queue cleanup" // {
      default = false;
    };

    openFirewall = mkEnableOption "Open firewall ports for Cleanuparr" // {
      default = true;
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
        # NOTE: Using host network mode for media management service access
        # Host networking reduces isolation but simplifies communication with Sonarr/Radarr/etc
        # Acceptable for internal services on trusted home network
        "--network=host"
        "--health-cmd=curl -f http://localhost:${toString cfg.cleanuparr.port}/health || exit 1"
        "--health-interval=30s"
        "--health-timeout=10s"
        "--health-retries=3"
        "--health-start-period=60s"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.configPath}/cleanuparr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
    ];

    # Ensure curl is available for health check
    systemd.services."podman-cleanuparr" = {
      path = [ pkgs.curl ];
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.cleanuparr.openFirewall [ cfg.cleanuparr.port ];
  };
}
