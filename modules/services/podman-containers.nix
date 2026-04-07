# Podman Containers Module - Dendritic Pattern
# OCI container services using Podman
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.podmanContainers =
    { pkgs, ... }@nixosArgs:
    let
      configPath = "/var/lib/containers/supplemental";
      inherit (constants.defaults) timezone;
      uid = 1000;
      gid = 100;

      # Janitorr secret paths
      janitorrSecrets = {
        sonarr = nixosArgs.config.sops.secrets."janitorr-sonarr-api-key".path;
        radarr = nixosArgs.config.sops.secrets."janitorr-radarr-api-key".path;
        jellyfin = nixosArgs.config.sops.secrets."janitorr-jellyfin-api-key".path;
        jellyfinPassword = nixosArgs.config.sops.secrets."janitorr-jellyfin-password".path;
        jellystat = nixosArgs.config.sops.secrets."janitorr-jellystat-api-key".path;
        jellyseerr = nixosArgs.config.sops.secrets."janitorr-jellyseerr-api-key".path;
      };
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
        ports = [ "${toString constants.ports.services.termix}:8080" ];
      };

      # Janitorr - Media cleanup
      virtualisation.oci-containers.containers.janitorr = {
        image = "ghcr.io/schaka/janitorr:jvm-v2.0.7";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/janitorr/application.yml:/config/application.yml"
          "/mnt/storage/media:/data/media"
        ];
        extraOptions = [ "--network=host" "--user=${toString uid}:976" ];
      };

      # Janitorr SOPS secrets
      sops.secrets."janitorr-sonarr-api-key" = {
        restartUnits = [ "podman-janitorr.service" ];
      };
      sops.secrets."janitorr-radarr-api-key" = {
        restartUnits = [ "podman-janitorr.service" ];
      };
      sops.secrets."janitorr-jellyfin-api-key" = {
        restartUnits = [ "podman-janitorr.service" ];
      };
      sops.secrets."janitorr-jellyfin-password" = {
        restartUnits = [ "podman-janitorr.service" ];
      };
      sops.secrets."janitorr-jellystat-api-key" = {
        restartUnits = [ "podman-janitorr.service" ];
      };
      sops.secrets."janitorr-jellyseerr-api-key" = {
        restartUnits = [ "podman-janitorr.service" ];
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

      # Generate janitorr application.yml from template with injected secrets
      systemd.services.podman-janitorr.preStart =
        let
          template = pkgs.writeText "janitorr-template.yml" ''
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
                api-key: "@SONARR_KEY@"
                delete-empty-shows: true
              radarr:
                enabled: true
                url: "http://localhost:${toString constants.ports.services.radarr}"
                api-key: "@RADARR_KEY@"
              jellyfin:
                enabled: true
                url: "http://localhost:${toString constants.ports.services.jellyfin}"
                api-key: "@JELLYFIN_KEY@"
                username: Janitorr
                password: "@JELLYFIN_PASS@"
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
                api-key: "@JELLYSEERR_KEY@"
                match-server: false
              jellystat:
                enabled: true
                url: "http://localhost:${toString constants.ports.services.jellystat}"
                api-key: "@JELLYSTAT_KEY@"
          '';
        in
        ''
          ${pkgs.gnused}/bin/sed \
            -e "s|@SONARR_KEY@|$(cat '${janitorrSecrets.sonarr}')|g" \
            -e "s|@RADARR_KEY@|$(cat '${janitorrSecrets.radarr}')|g" \
            -e "s|@JELLYFIN_KEY@|$(cat '${janitorrSecrets.jellyfin}')|g" \
            -e "s|@JELLYFIN_PASS@|$(cat '${janitorrSecrets.jellyfinPassword}')|g" \
            -e "s|@JELLYSTAT_KEY@|$(cat '${janitorrSecrets.jellystat}')|g" \
            -e "s|@JELLYSEERR_KEY@|$(cat '${janitorrSecrets.jellyseerr}')|g" \
            "${template}" > "${configPath}/janitorr/application.yml"
          chmod 644 "${configPath}/janitorr/application.yml"
        '';

      # Jellystat - Jellyfin statistics
      virtualisation.oci-containers.containers.jellystat-db = {
        image = "docker.io/postgres:16-alpine";
        environment = {
          POSTGRES_USER = "jellystat";
          POSTGRES_DB = "jellystat";
        };
        environmentFiles = [
          nixosArgs.config.sops.templates."jellystat-db.env".path
        ];
        volumes = [
          "${configPath}/jellystat-db:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--network=host"
          "--shm-size=256m"
        ];
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
        dependsOn = [ "jellystat-db" ];
      };

      # Jellystat SOPS secrets
      sops.secrets."jellystat-postgres-password" = {
        restartUnits = [
          "podman-jellystat.service"
          "podman-jellystat-db.service"
        ];
      };
      sops.secrets."jellystat-jwt-secret" = {
        restartUnits = [ "podman-jellystat.service" ];
      };

      # Jellystat env templates (inject secrets into env files)
      sops.templates."jellystat-db.env".content = ''
        POSTGRES_PASSWORD=${nixosArgs.config.sops.placeholder."jellystat-postgres-password"}
      '';
      sops.templates."jellystat.env".content = ''
        POSTGRES_PASSWORD=${nixosArgs.config.sops.placeholder."jellystat-postgres-password"}
        JWT_SECRET=${nixosArgs.config.sops.placeholder."jellystat-jwt-secret"}
      '';

      # Jellystat depends on its database
      systemd.services.podman-jellystat = {
        after = [ "podman-jellystat-db.service" ];
        requires = [ "podman-jellystat-db.service" ];
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
        "d ${configPath}/jellystat-db 0755 999 999 -"
        "d ${configPath}/jellystat 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/jellystat/backup 0755 ${toString uid} ${toString gid} -"
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
