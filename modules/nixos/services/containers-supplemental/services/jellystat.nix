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
  containersLib = import ../lib.nix { inherit lib; };
  inherit (containersLib) mkResourceOptions mkResourceFlags mkHealthFlags;
  cfg = config.host.services.containersSupplemental;
  jellystatCfg = cfg.jellystat;
in
{
  options.host.services.containersSupplemental.jellystat = {
    enable = mkEnableOption "Jellystat statistics dashboard for Jellyfin" // {
      default = false;
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

    resources = mkResourceOptions {
      memory = "256m";
      cpus = "0.25";
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
        extraOptions =
          mkHealthFlags {
            cmd = "wget --no-verbose --tries=1 --spider http://localhost:${toString jellystatCfg.port}/ || exit 1";
            interval = "30s";
            timeout = "10s";
            retries = "3";
            startPeriod = "60s";
          }
          ++ mkResourceFlags jellystatCfg.resources;
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.configPath}/jellystat 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ];

      sops.secrets = secretEntries;
    }
  );
}
