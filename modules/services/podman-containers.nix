# Podman Containers Module - Dendritic Pattern
# OCI container services using Podman
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.podmanContainers =
    nixosArgs:
    let
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
      uid = 1000;
      gid = 100;
    in
    {
      # Enable Podman
      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      virtualisation.oci-containers.backend = "podman";

      # Homarr Dashboard
      virtualisation.oci-containers.containers.homarr = {
        image = "ghcr.io/ajnart/homarr:0.15.3";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/homarr/configs:/app/data/configs"
          "${configPath}/homarr/icons:/app/public/icons"
          "${configPath}/homarr/data:/data"
        ];
        ports = [ "${toString constants.ports.services.homarr}:7575" ];
        extraOptions = [
          "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:7575/ || exit 1"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=3"
        ];
      };

      # Wizarr - Invitation management
      virtualisation.oci-containers.containers.wizarr = {
        image = "ghcr.io/wizarrrr/wizarr:4.1.1";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/wizarr:/data/database"
        ];
        ports = [ "${toString constants.ports.services.wizarr}:5690" ];
      };

      # Termix - Terminal web UI
      virtualisation.oci-containers.containers.termix = {
        image = "ghcr.io/lukegus/termix:latest";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/termix:/app/data"
        ];
        ports = [ "${toString constants.ports.services.termix}:8080" ];
      };

      # Janitorr - Media cleanup
      virtualisation.oci-containers.containers.janitorr = {
        image = "ghcr.io/schaka/janitorr:jvm-v2.0.7";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${nixosArgs.config.sops.templates."janitorr-application.yml".path}:/config/application.yml:ro"
          "/mnt/storage/media:/data/media"
        ];
        extraOptions = [
          "--network=host"
          "--user=${toString uid}:976"
        ];
      };

      # Janitorr SOPS secrets
      sops.secrets."janitorr-sonarr-api-key".restartUnits = [ "podman-janitorr.service" ];
      sops.secrets."janitorr-radarr-api-key".restartUnits = [ "podman-janitorr.service" ];
      sops.secrets."janitorr-jellyfin-api-key".restartUnits = [ "podman-janitorr.service" ];
      sops.secrets."janitorr-jellyfin-password".restartUnits = [ "podman-janitorr.service" ];
      sops.secrets."janitorr-jellystat-api-key".restartUnits = [ "podman-janitorr.service" ];
      sops.secrets."janitorr-jellyseerr-api-key".restartUnits = [ "podman-janitorr.service" ];

      # Janitorr config generated from sops template (replaces sed-based preStart injection)
      sops.templates."janitorr-application.yml" = {
        restartUnits = [ "podman-janitorr.service" ];
        content = ''
          file-system:
            access: true
            validate-seeding: false
            leaving-soon-dir: "/data/media/leaving-soon"
            media-server-leaving-soon-dir: "/mnt/storage/media/leaving-soon"
            from-scratch: false
            free-space-check-dir: "/data/media"

          application:
            dry-run: false
            whole-tv-show: false
            leaving-soon: 14d
            leaving-soon-threshold-offset-percent: 5
            exclusion-tags:
              - "janitorr_keep"

            media-deletion:
              enabled: true
              movie-expiration:
                5: 15d
                10: 30d
                15: 30d
                20: 90d
              season-expiration:
                5: 15d
                10: 20d
                15: 60d
                20: 120d

            tag-based-deletion:
              enabled: false
              minimum-free-disk-percent: 100
              schedules: []

            episode-deletion:
              enabled: false

          clients:
            default:
              connect-timeout: 60s
              read-timeout: 60s

            sonarr:
              enabled: true
              url: "http://localhost:${toString constants.ports.services.sonarr}"
              api-key: "${nixosArgs.config.sops.placeholder."janitorr-sonarr-api-key"}"
              delete-empty-shows: true
            radarr:
              enabled: true
              url: "http://localhost:${toString constants.ports.services.radarr}"
              api-key: "${nixosArgs.config.sops.placeholder."janitorr-radarr-api-key"}"
            jellyfin:
              enabled: true
              url: "http://localhost:${toString constants.ports.services.jellyfin}"
              api-key: "${nixosArgs.config.sops.placeholder."janitorr-jellyfin-api-key"}"
              username: Janitorr
              password: "${nixosArgs.config.sops.placeholder."janitorr-jellyfin-password"}"
              delete: true
              exclude-favorited: false
              leaving-soon-type: MOVIES_AND_TV
            emby:
              enabled: false
              url: ""
              api-key: ""
              username: ""
              password: ""
              delete: false
            jellyseerr:
              enabled: true
              url: "http://localhost:${toString constants.ports.services.seerr}"
              api-key: "${nixosArgs.config.sops.placeholder."janitorr-jellyseerr-api-key"}"
              match-server: false
            jellystat:
              enabled: true
              url: "http://localhost:${toString constants.ports.services.jellystat}"
              api-key: "${nixosArgs.config.sops.placeholder."janitorr-jellystat-api-key"}"
        '';
      };

      # Janitorr depends on Sonarr/Radarr/Jellyfin/Jellystat being ready
      systemd.services.podman-janitorr = {
        after = [
          "sonarr.service"
          "radarr.service"
          "jellyfin.service"
          "podman-jellystat.service"
        ];
        wants = [
          "sonarr.service"
          "radarr.service"
          "jellyfin.service"
          "podman-jellystat.service"
        ];
      };

      # Jellystat - Jellyfin statistics (PostgreSQL runs natively, not containerized)
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "jellystat" ];
        ensureUsers = [
          {
            name = "jellystat";
            ensureDBOwnership = true;
          }
        ];
        # Allow password auth from localhost for the jellystat container
        authentication = ''
          host jellystat jellystat 127.0.0.1/32 md5
          host jellystat jellystat ::1/128 md5
        '';
      };

      # Set the jellystat PostgreSQL password from SOPS after ensureUsers creates the role
      systemd.services.jellystat-db-password = {
        after = [ "postgresql.service" ];
        requires = [ "postgresql.service" ];
        before = [ "podman-jellystat.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          PASSWORD=$(cat ${nixosArgs.config.sops.secrets."jellystat-postgres-password".path})
          ${nixosArgs.config.services.postgresql.package}/bin/psql -U postgres -c \
            "ALTER USER jellystat WITH PASSWORD '$PASSWORD';"
        '';
      };

      virtualisation.oci-containers.containers.jellystat = {
        image = "docker.io/cyfershepard/jellystat:1.1.9";
        environment = {
          POSTGRES_USER = "jellystat";
          POSTGRES_IP = "localhost";
          POSTGRES_PORT = "5432";
          TZ = timezone;
        };
        environmentFiles = [
          nixosArgs.config.sops.templates."jellystat.env".path
        ];
        volumes = [
          "${configPath}/jellystat/backup:/app/backend/backup-data"
        ];
        extraOptions = [ "--network=host" ];
      };

      # Jellystat SOPS secrets
      sops.secrets."jellystat-postgres-password" = {
        restartUnits = [ "podman-jellystat.service" ];
      };
      sops.secrets."jellystat-jwt-secret" = {
        restartUnits = [ "podman-jellystat.service" ];
      };

      # Jellystat env template
      sops.templates."jellystat.env".content = ''
        POSTGRES_PASSWORD=${nixosArgs.config.sops.placeholder."jellystat-postgres-password"}
        JWT_SECRET=${nixosArgs.config.sops.placeholder."jellystat-jwt-secret"}
      '';

      # Jellystat depends on PostgreSQL and its password being set
      systemd.services.podman-jellystat = {
        after = [
          "postgresql.service"
          "jellystat-db-password.service"
        ];
        requires = [
          "postgresql.service"
          "jellystat-db-password.service"
        ];
      };

      # Profilarr - Profile management
      virtualisation.oci-containers.containers.profilarr = {
        image = "docker.io/santiagosayshey/profilarr:latest";
        environment = {
          TZ = timezone;
          PUID = toString uid;
          PGID = toString gid;
        };
        volumes = [
          "${configPath}/profilarr:/config"
        ];
        ports = [ "${toString constants.ports.services.profilarr}:6868" ];
      };

      # Listenarr - Music tracker
      virtualisation.oci-containers.containers.listenarr = {
        image = "ghcr.io/therobbiedavis/listenarr:canary";
        environment = {
          TZ = timezone;
          PUID = toString uid;
          PGID = toString gid;
        };
        volumes = [
          "${configPath}/listenarr:/config"
        ];
        ports = [ "${toString constants.ports.services.listenarr}:8686" ];
      };

      # Create config directories
      systemd.tmpfiles.rules = [
        "d ${configPath} 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/homarr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/homarr/configs 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/homarr/icons 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/homarr/data 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/wizarr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/janitorr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/jellystat 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/jellystat/backup 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/termix 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/profilarr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/listenarr 0755 ${toString uid} ${toString gid} -"
      ];

      # Firewall ports
      networking.firewall.allowedTCPPorts = [
        constants.ports.services.homarr
        constants.ports.services.wizarr
        constants.ports.services.termix
        constants.ports.services.janitorr
        constants.ports.services.jellystat
        constants.ports.services.profilarr
        constants.ports.services.listenarr
      ];

      # Enable automatic image pruning (nixpkgs provides podman-prune service)
      virtualisation.podman.autoPrune.enable = true;
    };
}
