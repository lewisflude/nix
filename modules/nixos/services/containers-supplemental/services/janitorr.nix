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

    leavingSoonDir = mkOption {
      type = types.str;
      default = "/mnt/storage/leaving-soon";
      description = "Container path where Janitorr creates leaving-soon symlinks.";
    };

    mediaServerLeavingSoonDir = mkOption {
      type = types.str;
      default = "/mnt/storage/leaving-soon";
      description = "Media server path that should match Jellyfin/Emby volume mapping.";
    };

    freeSpaceCheckDir = mkOption {
      type = types.str;
      default = "/mnt/storage";
      description = "Directory Janitorr uses to determine free disk space.";
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
      yamlFormat = pkgs.formats.yaml { };
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

      # Import base config from separate file for lazy loading
      baseConfig =
        (import ../../containers/janitorr-config.nix {
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
      janitorrConfigFile = yamlFormat.generate "janitorr-application.yml" janitorrConfig;
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
          "--network=host"
        ] # Use host network to access native services
        ++ mkHealthFlags {
          cmd = "/workspace/health-check";
          interval = "5s";
          timeout = "10s";
          retries = "3";
          startPeriod = "30s"; # Give Java app time to start before health checks
        }
        ++ mkResourceFlags cfg.janitorr.resources;
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.configPath}/janitorr 0755 root root -"
        "d ${cfg.configPath}/janitorr/config 0755 ${toString cfg.uid} ${toString cfg.gid} -"
        "d ${cfg.configPath}/janitorr/logs 0755 ${toString cfg.uid} ${toString cfg.gid} -"
      ];

      # Add config copy to the service's pre-start sequence
      systemd.services."podman-janitorr" = {
        preStart = lib.mkAfter ''
          # Copy the sops-rendered config file to the container's config directory
          ${coreutils}/bin/install -m 644 -o ${toString cfg.uid} -g ${toString cfg.gid} \
            ${config.sops.templates."janitorr-application.yml".path} \
            ${cfg.configPath}/janitorr/config/application.yml
        '';
      };

      sops.secrets = mkIf cfg.janitorr.useSops secretEntries;

      sops.templates."janitorr-application.yml" = {
        content = builtins.readFile janitorrConfigFile;
        mode = "0400";
        owner = "root";
      };
    }
  );
}
