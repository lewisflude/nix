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
    mapAttrs
    mapAttrs'
    nameValuePair
    recursiveUpdate
    ;
  containersLib = import ../lib.nix { inherit lib; };
  inherit (containersLib) mkResourceOptions mkResourceFlags mkHealthFlags;

  cfg = config.host.services.containersSupplemental;
in
{
  options.host.services.containersSupplemental.janitorr = {
    enable = mkEnableOption "Janitorr media cleanup" // {
      default = true;
    };

    useSops = mkOption {
      type = types.bool;
      default = true;
      description = "Render Janitorr configuration via sops-nix placeholders (required to inject secrets safely).";
    };

    loggingLevel = mkOption {
      type = types.str;
      default = "INFO";
      description = "Log level for com.github.schaka.";
    };

    loggingFile = mkOption {
      type = types.nullOr types.str;
      default = "/logs/janitorr.log";
      description = "Log file path inside the container. Set to null to disable file logging.";
    };

    dataPath = mkOption {
      type = types.str;
      default = "/mnt/storage";
      description = "Path to media storage directory.";
    };

    port = mkOption {
      type = types.port;
      default = 8090;
      description = "Port for Janitorr web interface (default: 8090 to avoid conflict with qBittorrent on 8080).";
    };

    extraConfig = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Recursive overrides applied to the generated Janitorr configuration.";
    };

    resources = mkResourceOptions {
      memory = "512m";
      cpus = "1.0";
    };
  };

  config = mkIf (cfg.enable && cfg.janitorr.enable) (
    let
      secretNames = {
        sonarr = "janitorr-sonarr-api-key";
        radarr = "janitorr-radarr-api-key";
        bazarr = "janitorr-bazarr-api-key";
        jellyfinApiKey = "janitorr-jellyfin-api-key";
        jellyfinPassword = "janitorr-jellyfin-password";
        embyApiKey = "janitorr-emby-api-key";
        embyPassword = "janitorr-emby-password";
        jellyseerr = "janitorr-jellyseerr-api-key";
        jellystat = "janitorr-jellystat-api-key";
        streamystats = "janitorr-streamystats-api-key";
      };
      placeholders =
        if cfg.janitorr.useSops then
          mapAttrs (_: secret: config.sops.placeholder.${secret}) secretNames
        else
          throw "Janitorr requires useSops enabled to reference secrets.";

      baseConfig =
        (import ../janitorr-config.nix {
          inherit lib;
          inherit placeholders;
          janitorrCfg = cfg.janitorr;
        })
        // {
          server = {
            inherit (cfg.janitorr) port;
          };
        };

      janitorrConfig = recursiveUpdate baseConfig cfg.janitorr.extraConfig;
      # Generate YAML content directly as a string to avoid derivation issues during flake check
      janitorrConfigContent = lib.generators.toYAML { } janitorrConfig;
      secretEntries = mapAttrs' (
        _name: secret:
        nameValuePair secret {
          mode = "0400";
          owner = "root";
          group = "root";
        }
      ) secretNames;
      inherit (pkgs) coreutils;
    in
    {
      assertions = [
        {
          assertion = cfg.janitorr.useSops;
          message = "Janitorr requires host.services.containersSupplemental.janitorr.useSops = true so secrets can be injected safely.";
        }
      ];

      virtualisation.oci-containers.containers.janitorr = {
        image = "ghcr.io/schaka/janitorr:jvm-stable";
        user = "${toString cfg.uid}:${toString cfg.gid}";
        environment = {
          PUID = toString cfg.uid;
          PGID = toString cfg.gid;
          TZ = cfg.timezone;
          THC_PATH = "/health";
          THC_PORT = "8081";
          SPRING_CONFIG_ADDITIONAL_LOCATION = "/config/application.yml";
        };
        volumes = [
          "${cfg.configPath}/janitorr/config:/config"
          "${cfg.configPath}/janitorr/logs:/logs"
          "${cfg.janitorr.dataPath}:${cfg.janitorr.dataPath}"
        ];
        extraOptions = [
          # NOTE: Using host network mode for media management service access
          # Host networking reduces isolation but simplifies communication with Jellyfin/Sonarr/Radarr
          # Acceptable for internal media cleanup services on trusted home network
          "--network=host"
        ]
        ++ mkHealthFlags {
          cmd = "/workspace/health-check";
          interval = "5s";
          timeout = "10s";
          retries = "3";
          startPeriod = "45s";
        }
        ++ mkResourceFlags cfg.janitorr.resources;
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.configPath}/janitorr 0755 ${toString cfg.uid} ${toString cfg.gid} -"
        "d ${cfg.configPath}/janitorr/config 0755 ${toString cfg.uid} ${toString cfg.gid} -"
        "d ${cfg.configPath}/janitorr/logs 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ];

      systemd.services."podman-janitorr" = {
        preStart = lib.mkAfter ''

          ${coreutils}/bin/install -m 644 -o ${toString cfg.uid} -g ${toString cfg.gid} \
            ${config.sops.templates."janitorr-application.yml".path} \
            ${cfg.configPath}/janitorr/config/application.yml
        '';
      };

      sops.secrets = mkIf cfg.janitorr.useSops secretEntries;

      sops.templates."janitorr-application.yml" = {
        content = janitorrConfigContent;
        mode = "0400";
        owner = "root";
      };
    }
  );
}
