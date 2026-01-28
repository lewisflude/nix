{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    optionalAttrs
    ;
  cfg = config.host.services.containersSupplemental;
  jellystatCfg = cfg.jellystat;
in
{
  options.host.services.containersSupplemental.jellystat = {
    enable = mkEnableOption "Jellystat statistics dashboard for Jellyfin" // {
      default = false;
    };

    openFirewall = mkEnableOption "Open firewall ports for Jellystat" // {
      default = true;
    };

    port = mkOption {
      type = types.int;
      default = 3004;
      description = "Port to expose Jellystat on";
    };

    useSops = mkOption {
      type = types.bool;
      default = true;
      description = "Use sops-nix for Jellystat secrets management";
    };

  };

  config = mkIf (cfg.enable && jellystatCfg.enable) (
    let
      # Define secret with proper ownership for container access
      secretEntries = optionalAttrs jellystatCfg.useSops {
        "jellystat-jellyfin-api-key" = {
          owner = toString cfg.uid;
          group = toString cfg.gid;
          mode = "0440";
        };
      };
    in
    {
      virtualisation.oci-containers.containers.jellystat = {
        image = "cyfershepard/jellystat:latest";
        user = "${toString cfg.uid}:${toString cfg.gid}";
        environment = {
          TZ = cfg.timezone;
          PORT = toString jellystatCfg.port;
          JELLYFIN_HOST = "https://jellyfin.blmt.io";
          DISABLE_AUTH = "true"; # Disable authentication for local access
        }
        # Pass secret file path when using SOPS
        # App reads the API key from this file
        // optionalAttrs jellystatCfg.useSops {
          JELLYFIN_API_KEY_FILE = config.sops.secrets."jellystat-jellyfin-api-key".path;
        };
        volumes = [
          "${cfg.configPath}/jellystat:/app/backend/userData"
        ];
        ports = [ "${toString jellystatCfg.port}:${toString jellystatCfg.port}" ];
        extraOptions = [
          "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:${toString jellystatCfg.port}/ || exit 1"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=3"
          "--health-start-period=60s"
        ];
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.configPath}/jellystat 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ];

      sops.secrets = secretEntries;

      networking.firewall.allowedTCPPorts = mkIf jellystatCfg.openFirewall [ jellystatCfg.port ];
    }
  );
}
