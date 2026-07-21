# Podman Containers Module - Dendritic Pattern
# OCI container services using Podman
{ config, ... }:
let
  inherit (config) constants;
  media = config.mediaLib;
in
{
  flake.modules.nixos.podmanContainers =
    nixosArgs@{ pkgs, ... }:
    let
      inherit (nixosArgs) lib;
      cfg = nixosArgs.config;
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
      # uid/gid for supplemental containers that run as the primary interactive user.
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
            environment = {
              TZ = timezone;
            }
            // extraEnv;
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
        # Huntarr — backfills missing content and quality-cutoff upgrades that arr
        # RSS monitoring never revisits, in indexer-safe batches. Talks to the arr
        # APIs over localhost only, so no media mount is needed.
        huntarr = mkSupplementalContainer {
          name = "huntarr";
          # Docker Hub only (no ghcr mirror). Docker Hub blocks anonymous digest
          # resolution from this network, so pinned by tag; run
          # `podman inspect huntarr --format '{{.ImageDigest}}'` after first pull to pin.
          image = "docker.io/huntarr/huntarr:latest";
          port = constants.ports.services.huntarr;
          internalPort = 9705;
          extraEnv = {
            PUID = toString uid;
            PGID = toString gid;
          };
        };
        # Cleanuparr — removes stalled/orphaned/malware-injected downloads and manages
        # seeding across qBittorrent + the arrs via their APIs (no media mount).
        # PRIVATE TRACKER SAFETY: configure removal/seeding rules in the web UI to
        # respect ratio/seed-time obligations, and do NOT enable orphan file cleanup
        # without a media mount. See [[user_private_trackers]].
        cleanuparr = mkSupplementalContainer {
          name = "cleanuparr";
          # Pinned to digest of :latest as of 2026-07-21.
          image = "ghcr.io/cleanuparr/cleanuparr@sha256:efd08729a33223a6a5bae267afcbeffe4bd2876b3f03144a025968adb8e3cc7e";
          port = constants.ports.services.cleanuparr;
          internalPort = 11011;
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

      # Wizarr — stores DB under /data/database (override default volume mapping)
      virtualisation.oci-containers.containers.wizarr = supplemental.wizarr.container // {
        volumes = [ "${configPath}/wizarr:/data/database" ];
      };

      # Termix — stores state under /app/data (override default volume mapping)
      virtualisation.oci-containers.containers.termix = supplemental.termix.container // {
        volumes = [ "${configPath}/termix:/app/data" ];
      };

      # Profilarr — default /config layout
      virtualisation.oci-containers.containers.profilarr = supplemental.profilarr.container;

      # Listenarr — default /config layout
      virtualisation.oci-containers.containers.listenarr = supplemental.listenarr.container;

      # Huntarr — default /config layout
      virtualisation.oci-containers.containers.huntarr = supplemental.huntarr.container;

      # Cleanuparr — default /config layout
      virtualisation.oci-containers.containers.cleanuparr = supplemental.cleanuparr.container;

      # Calibre-Web-Automated — ebook library + auto-ingest watch folder. Runs as the
      # media user so it can read/write /mnt/storage/books; replaces the ebook side of
      # the retired Readarr. Exposed via Caddy only (127.0.0.1 bind). Drop ebooks into
      # the ingest dir and CWA imports + converts them into the Calibre library.
      virtualisation.oci-containers.containers.calibre-web-automated = {
        # Pinned to digest of :latest as of 2026-07-21.
        image = "ghcr.io/crocodilestick/calibre-web-automated@sha256:c31a738b6d5ec6982c050063dd3f063b6943eb1051fc81144789f840d9093a8d";
        environment = {
          TZ = timezone;
          PUID = toString mediaUid;
          PGID = toString mediaGid;
        };
        volumes = [
          "${configPath}/calibre-web-automated:/config"
          "/mnt/storage/books/library:/calibre-library"
          "/mnt/storage/books/ingest:/cwa-book-ingest"
        ];
        ports = [ "127.0.0.1:${toString constants.ports.services.calibreWeb}:8083" ];
      };

      # Janitorr - Media cleanup (bespoke: host network, sops template, complex deps).
      # `--user` derives uid/gid from the media user declared in media-user.nix.
      # Previous code hardcoded `1000:976` — uid 1000 was the interactive user (not media)
      # and gid 976 was whatever the media group happened to be allocated at runtime.
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

      # Janitorr + Jellystat SOPS secrets — bulk-defined.
      # Janitorr restartUnits use the media-lib helper; jellystat needs a postgres owner
      # so it's defined separately.
      sops.secrets =
        (media.restartUnits
          [ "podman-janitorr.service" ]
          [
            "janitorr-sonarr-api-key"
            "janitorr-radarr-api-key"
            "janitorr-jellyfin-api-key"
            "janitorr-jellyfin-password"
            "janitorr-jellystat-api-key"
            "janitorr-jellyseerr-api-key"
          ]
        )
        // {
          "jellystat-postgres-password" = {
            owner = "postgres";
            restartUnits = [ "podman-jellystat.service" ];
          };
          "jellystat-jwt-secret" = {
            restartUnits = [ "podman-jellystat.service" ];
          };
        };

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

      # Janitorr probes Jellyseerr's API at startup to build its jellyseerrRestService
      # bean; if seerr isn't answering yet the bean construction throws and the whole
      # Spring context aborts, so the process exits and systemd restarts it. systemd
      # considering seerr.service "started" (process launched) is not enough — the Node
      # app needs time to become API-ready — so on a slow boot janitorr crash-loops until
      # seerr responds (this reached a restart counter of 1001 on the 2026-06-17 boot).
      # Gate janitorr on seerr's API actually answering, not just its unit starting.
      systemd.services.janitorr-wait-seerr = {
        description = "Wait for Jellyseerr API before starting Janitorr";
        after = [ "seerr.service" ];
        wants = [ "seerr.service" ];
        before = [ "podman-janitorr.service" ];
        requiredBy = [ "podman-janitorr.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        # Best-effort: poll up to ~5min, then start janitorr anyway (no worse than the
        # old crash-loop). seerr's /api/v1/status needs no auth and returns 200 when ready.
        script = ''
          for _ in $(seq 1 60); do
            if ${pkgs.curl}/bin/curl -fsS -o /dev/null --max-time 5 \
                "http://localhost:${toString constants.ports.services.seerr}/api/v1/status"; then
              echo "Jellyseerr API is ready"
              exit 0
            fi
            sleep 5
          done
          echo "Jellyseerr API still not ready after ~5min; starting Janitorr anyway" >&2
          exit 0
        '';
      };

      # Janitorr depends on Sonarr/Radarr/Jellyfin/Jellystat/Jellyseerr being ready
      systemd.services.podman-janitorr = {
        after = [
          "sonarr.service"
          "radarr.service"
          "jellyfin.service"
          "seerr.service"
          "podman-jellystat.service"
        ];
        wants = [
          "sonarr.service"
          "radarr.service"
          "jellyfin.service"
          "seerr.service"
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

      # Jellystat env template (secrets are defined above alongside janitorr's)
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
        supplemental.huntarr.tmpfilesDir
        supplemental.cleanuparr.tmpfilesDir
        # Calibre-Web-Automated: config owned by media user; book library + ingest
        # under /mnt/storage/books (0770 media media, like the rest of the stack).
        (media.mkContainerDir "${configPath}/calibre-web-automated" mediaUid mediaGid)
        (media.mkDir "${media.storageRoot}/books/library")
        (media.mkDir "${media.storageRoot}/books/ingest")
      ];

      networking.firewall.allowedTCPPorts = lib.mkDefault [
        constants.ports.services.homarr
        supplemental.wizarr.firewallPort
        supplemental.termix.firewallPort
        constants.ports.services.janitorr
        constants.ports.services.jellystat
        supplemental.profilarr.firewallPort
        supplemental.listenarr.firewallPort
        supplemental.huntarr.firewallPort
        supplemental.cleanuparr.firewallPort
      ];

      # Enable automatic image pruning (nixpkgs provides podman-prune service)
      virtualisation.podman.autoPrune.enable = true;
    };
}
