# Podman Containers Module - Dendritic Pattern
# OCI container services using Podman
{ config, ... }:
let
  inherit (config) constants containerLib;
  media = config.mediaLib;
in
{
  flake.modules.nixos.podmanContainers =
    nixosArgs@{ pkgs, ... }:
    let
      cfg = nixosArgs.config;
      inherit (containerLib) configRoot;
      inherit (constants.defaults) timezone;
      # uid/gid for supplemental containers that run as the primary interactive user.
      uid = 1000;
      gid = 100;
      # Media user/group resolved from the central media-user module — used by janitorr.
      mediaUid = cfg.users.users.${media.user}.uid;
      mediaGid = cfg.users.groups.${media.group}.gid;

      # Supplemental containers: the single source for their container definitions,
      # state directories and firewall ports (derived by containerLib.mkContainers).
      supplemental = {
        wizarr = {
          image = "ghcr.io/wizarrrr/wizarr:4.1.1";
          port = constants.ports.services.wizarr;
          internalPort = 5690;
          configMount = "/data/database";
          openFirewall = true;
        };
        termix = {
          # Pinned to digest of :latest as of 2026-04-30 (upstream tags only :latest)
          image = "ghcr.io/lukegus/termix@sha256:52e45c1ea3fb85be5b3ade5ff42eed0946fe81131cbd834f6960e00797f17f86";
          port = constants.ports.services.termix;
          internalPort = 8080;
          configMount = "/app/data";
          openFirewall = true;
        };
        listenarr = {
          # Pinned to digest of :canary as of 2026-04-30
          image = "ghcr.io/therobbiedavis/listenarr@sha256:c917f40d7a79f89e10ecef754cf4fd189f018a55ad561f3a8f95f6766e47086b";
          port = constants.ports.services.listenarr;
          internalPort = 8686;
          openFirewall = true;
          extraEnv = {
            PUID = toString uid;
            PGID = toString gid;
          };
        };
        # Huntarr was removed on 2026-08-11. In February 2026 critical
        # unauthenticated auth-bypass vulnerabilities were disclosed in 9.4.2 and
        # earlier — settings reachable without authentication, stored passwords
        # readable in plaintext, and the API keys of every connected arr app
        # exposed. Upstream deleted the GitHub repo, the Docker Hub image and the
        # docs site rather than patch it; only a third-party read-only archive
        # survives, marked "not under active development, use at your own risk".
        # The image pull had been failing since, so it never actually ran here.
        # Do not reinstate from the archive: it would hand out arr credentials.

        # Cleanuparr — removes stalled/orphaned/malware-injected downloads and manages
        # seeding across qBittorrent + the arrs via their APIs (no media mount).
        # PRIVATE TRACKER SAFETY: configure removal/seeding rules in the web UI to
        # respect ratio/seed-time obligations, and do NOT enable orphan file cleanup
        # without a media mount. See [[user_private_trackers]].
        cleanuparr = {
          # Pinned to digest of :latest as of 2026-07-21.
          image = "ghcr.io/cleanuparr/cleanuparr@sha256:efd08729a33223a6a5bae267afcbeffe4bd2876b3f03144a025968adb8e3cc7e";
          port = constants.ports.services.cleanuparr;
          internalPort = 11011;
          openFirewall = true;
          extraEnv = {
            PUID = toString uid;
            PGID = toString gid;
          };
        };
      };
    in
    {
      imports = [ (containerLib.mkContainers supplemental) ];

      virtualisation.podman.enable = true;
      virtualisation.oci-containers.backend = "podman";

      # Homarr Dashboard — bespoke (custom healthcheck and multi-volume layout)
      virtualisation.oci-containers.containers.homarr = {
        image = "ghcr.io/ajnart/homarr:0.15.3";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configRoot}/homarr/configs:/app/data/configs"
          "${configRoot}/homarr/icons:/app/public/icons"
          "${configRoot}/homarr/data:/data"
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
          "${configRoot}/calibre-web-automated:/config"
          "${media.storageRoot}/books/library:/calibre-library"
          "${media.storageRoot}/books/ingest:/cwa-book-ingest"
        ];
        ports = [ "127.0.0.1:${toString constants.ports.services.calibreWeb}:8083" ];
        # Same reason as homarr above: the image ships its own HEALTHCHECK, and CWA
        # needs ~90s to boot, so the transient healthcheck unit fails a couple of
        # times while the container is still "starting". Without sdnotify=healthy
        # the activation script snapshots that failure and nixos-rebuild exits 4.
        podman.sdnotify = "healthy";
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
          "${media.mediaRoot}:/data/media"
        ];
        extraOptions = [
          "--network=host"
          "--user=${toString mediaUid}:${toString mediaGid}"
        ];
      };

      # Janitorr SOPS secrets — bulk-defined via the media-lib helper.
      sops.secrets =
        media.restartUnits
          [ "podman-janitorr.service" ]
          [
            "janitorr-sonarr-api-key"
            "janitorr-radarr-api-key"
            "janitorr-jellyfin-api-key"
            "janitorr-jellyfin-password"
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
            media-server-leaving-soon-dir: "${media.mediaRoot}/leaving-soon"
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

      # Janitorr depends on Sonarr/Radarr/Jellyfin/Jellyseerr being ready
      systemd.services.podman-janitorr = {
        after = [
          "sonarr.service"
          "radarr.service"
          "jellyfin.service"
          "seerr.service"
        ];
        wants = [
          "sonarr.service"
          "radarr.service"
          "jellyfin.service"
          "seerr.service"
        ];
      };

      # Create config directories
      systemd.tmpfiles.rules = [
        (media.mkContainerDir configRoot uid gid)
        (media.mkContainerDir "${configRoot}/homarr" uid gid)
        (media.mkContainerDir "${configRoot}/homarr/configs" uid gid)
        (media.mkContainerDir "${configRoot}/homarr/icons" uid gid)
        (media.mkContainerDir "${configRoot}/homarr/data" uid gid)
        (media.mkContainerDir "${configRoot}/janitorr" uid gid)
        # Calibre-Web-Automated: config owned by media user; book library + ingest
        # under /mnt/storage/books (0770 media media, like the rest of the stack).
        (media.mkContainerDir "${configRoot}/calibre-web-automated" mediaUid mediaGid)
        (media.mkDir "${media.storageRoot}/books/library")
        (media.mkDir "${media.storageRoot}/books/ingest")
      ];

      # Not mkDefault: see the note in jellyfin.nix — mkDefault port lists lose to
      # networking.nix's normal-priority definition instead of merging with it.
      # (the supplemental containers' ports are opened by containerLib.mkContainers)
      networking.firewall.allowedTCPPorts = [
        constants.ports.services.homarr
        constants.ports.services.janitorr
      ];

      # Enable automatic image pruning (nixpkgs provides podman-prune service)
      virtualisation.podman.autoPrune.enable = true;
    };
}
