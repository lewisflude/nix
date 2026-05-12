# Podman Containers Module - Dendritic Pattern
# OCI container services using Podman
{ config, ... }:
let
  inherit (config) constants;
  inherit (config.lib) media;
in
{
  flake.modules.nixos.podmanContainers =
    nixosArgs:
    let
      inherit (nixosArgs) lib;
      cfg = nixosArgs.config;
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
      # uid/gid used for supplemental containers that run as the primary interactive user.
      uid = 1000;
      gid = 100;
      # Media user/group resolved from the central media-user module — used by janitorr.
      mediaUid = cfg.users.users.${media.user}.uid;
      mediaGid = cfg.users.groups.${media.group}.gid;

      mkSupplementalContainer =
        {
          name,
          image,
          port,
          internalPort,
          extraEnv ? { },
          extraVolumes ? [ ],
        }:
        {
          container = {
            inherit image;
            environment = { TZ = timezone; } // extraEnv;
            volumes = [ "${configPath}/${name}:/config" ] ++ extraVolumes;
            ports = [ "${toString port}:${toString internalPort}" ];
          };
          tmpfilesDir = media.mkContainerDir "${configPath}/${name}" uid gid;
          firewallPort = port;
        };

      supplemental = {
        wizarr = mkSupplementalContainer {
          name = "wizarr";
          image = "ghcr.io/wizarrrr/wizarr:4.1.1";
          port = constants.ports.services.wizarr;
          internalPort = 5690;
        };
        termix = mkSupplementalContainer {
          name = "termix";
          # Pinned to digest of :latest as of 2026-04-30 (upstream tags only :latest)
          image = "ghcr.io/lukegus/termix@sha256:52e45c1ea3fb85be5b3ade5ff42eed0946fe81131cbd834f6960e00797f17f86";
          port = constants.ports.services.termix;
          internalPort = 8080;
        };
        profilarr = mkSupplementalContainer {
          name = "profilarr";
          # Pinned to digest of :latest as of 2026-04-30
          image = "docker.io/santiagosayshey/profilarr@sha256:8a514f8429cd33885166facc9eb6504fa9ded056c737609e5e8ef32ae0afb350";
          port = constants.ports.services.profilarr;
          internalPort = 6868;
          extraEnv = {
            PUID = toString uid;
            PGID = toString gid;
          };
        };
        listenarr = mkSupplementalContainer {
          name = "listenarr";
          # Pinned to digest of :canary as of 2026-04-30
          image = "ghcr.io/therobbiedavis/listenarr@sha256:c917f40d7a79f89e10ecef754cf4fd189f018a55ad561f3a8f95f6766e47086b";
          port = constants.ports.services.listenarr;
          internalPort = 8686;
          extraEnv = {
            PUID = toString uid;
            PGID = toString gid;
          };
        };
      };
    in
    {
      virtualisation.podman.enable = true;
      virtualisation.oci-containers.backend = "podman";

      # Homarr Dashboard — bespoke (custom healthcheck and multi-volume layout)
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
        # sdnotify=healthy makes podman send READY=1 to systemd only after the
        # first successful healthcheck, so podman-homarr.service is only marked
        # active once healthy. Without this, the transient healthcheck unit can
        # fail during activation and propagate as exit 4 from nixos-rebuild.
        podman.sdnotify = "healthy";
        extraOptions = [
          "--health-cmd=wget --no-verbose --tries=1 --spider http://localhost:7575/ || exit 1"
          "--health-interval=30s"
          "--health-timeout=10s"
          "--health-retries=3"
          "--health-start-period=60s"
        ];
      };

      # Wizarr — stores DB under /data/database, override default volume mapping
      virtualisation.oci-containers.containers.wizarr = supplemental.wizarr.container // {
        volumes = [ "${configPath}/wizarr:/data/database" ];
      };

      # Termix — stores state under /app/data, override default volume mapping
      virtualisation.oci-containers.containers.termix = supplemental.termix.container // {
        volumes = [ "${configPath}/termix:/app/data" ];
      };

      # Profilarr — default /config layout
      virtualisation.oci-containers.containers.profilarr = supplemental.profilarr.container;

      # Listenarr — default /config layout
      virtualisation.oci-containers.containers.listenarr = supplemental.listenarr.container;

      # Janitorr - Media cleanup (bespoke: host network, sops template, complex deps).
      # `--user` derives uid/gid from the media user declared in media-user.nix.
      # Previous code hardcoded `1000:976` — 1000 is the interactive user, not media; the bug
      # only worked because the media group happened to be GID 976 at runtime.
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
          "--user=${toString mediaUid}:${toString mediaGid}"
        ];
      };

      # Janitorr SOPS secrets — bulk restart-units config
      sops.secrets = media.restartUnits [ "podman-janitorr.service" ] [
        "janitorr-sonarr-api-key"
        "janitorr-radarr-api-key"
        "janitorr-jellyfin-api-key"
        "janitorr-jellyfin-password"
        "janitorr-jellystat-api-key"
        "janitorr-jellyseerr-api-key"
      ];

      # Janitorr config generated from sops template (replaces sed-based preStart injection)
      sops.templates."janitorr-application.yml" = {
        restartUnits = [ "podman-janitorr.service" ];
        group = "media";
        mode = "0440";
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
      # The container hardcodes its database name as `jfstat` and runs
      # `CREATE DATABASE jfstat` if missing — but the unprivileged `jellystat`
      # role can't create databases, so we provision it declaratively here.
      # `ensureDBOwnership` only works when DB name == user name, so ownership
      # is granted by the jellystat-db-password oneshot below.
      services.postgresql = {
        enable = true;
        ensureDatabases = [ "jfstat" ];
        ensureUsers = [ { name = "jellystat"; } ];
        authentication = ''
          host jfstat jellystat 127.0.0.1/32 md5
          host jfstat jellystat ::1/128 md5
        '';
      };

      # Set the jellystat password and grant DB ownership after ensureUsers
      # / ensureDatabases have run. Both statements are idempotent.
      # `ensureDatabases` runs in postgresql-setup.service, NOT in
      # postgresql.service's postStart, so we must order against the setup
      # unit explicitly — otherwise the ALTER DATABASE races with DB creation.
      systemd.services.jellystat-db-password = {
        after = [ "postgresql-setup.service" ];
        requires = [ "postgresql-setup.service" ];
        before = [ "podman-jellystat.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "postgres";
          Group = "postgres";
        };
        script = ''
          PASSWORD=$(cat ${nixosArgs.config.sops.secrets."jellystat-postgres-password".path})
          psql=${nixosArgs.config.services.postgresql.package}/bin/psql
          $psql -c "ALTER USER jellystat WITH PASSWORD '$PASSWORD';"
          $psql -c "ALTER DATABASE jfstat OWNER TO jellystat;"
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
        owner = "postgres";
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

      # Create config directories
      systemd.tmpfiles.rules = [
        (media.mkContainerDir configPath uid gid)
        (media.mkContainerDir "${configPath}/homarr" uid gid)
        (media.mkContainerDir "${configPath}/homarr/configs" uid gid)
        (media.mkContainerDir "${configPath}/homarr/icons" uid gid)
        (media.mkContainerDir "${configPath}/homarr/data" uid gid)
        (media.mkContainerDir "${configPath}/janitorr" uid gid)
        (media.mkContainerDir "${configPath}/jellystat" uid gid)
        (media.mkContainerDir "${configPath}/jellystat/backup" uid gid)
        supplemental.wizarr.tmpfilesDir
        supplemental.termix.tmpfilesDir
        supplemental.profilarr.tmpfilesDir
        supplemental.listenarr.tmpfilesDir
      ];

      networking.firewall.allowedTCPPorts = lib.mkDefault [
        constants.ports.services.homarr
        supplemental.wizarr.firewallPort
        supplemental.termix.firewallPort
        constants.ports.services.janitorr
        constants.ports.services.jellystat
        supplemental.profilarr.firewallPort
        supplemental.listenarr.firewallPort
      ];

      # Enable automatic image pruning (nixpkgs provides podman-prune service)
      virtualisation.podman.autoPrune.enable = true;
    };
}
