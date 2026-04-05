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
        image = "ghcr.io/schaka/janitorr:v1.3.0";
        environment = {
          TZ = timezone;
        };
        volumes = [
          "${configPath}/janitorr/application.yml:/config/application.yml"
        ];
        ports = [ "${toString constants.ports.services.janitorr}:8978" ];
        extraOptions = [ "--add-host=host.containers.internal:host-gateway" ];
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

      # Generate janitorr application.yml from template with injected secrets
      systemd.services.podman-janitorr.preStart =
        let
          template = pkgs.writeText "janitorr-template.yml" ''
            server:
              port: 8978

            file-system:
              access: false
              validate-seeding: false
              leaving-soon-dir: "/data/media/leaving-soon"
              from-scratch: false
              free-space-check-dir: "/"

            application:
              dry-run: true
              leaving-soon: 14d
              exclusion-tag: "janitorr_keep"

              media-deletion:
                enabled: false
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

            clients:
              sonarr:
                enabled: true
                url: "http://host.containers.internal:${toString constants.ports.services.sonarr}"
                api-key: "@SONARR_KEY@"
                delete-empty-shows: true
              radarr:
                enabled: true
                url: "http://host.containers.internal:${toString constants.ports.services.radarr}"
                api-key: "@RADARR_KEY@"
              jellyfin:
                enabled: true
                url: "http://host.containers.internal:${toString constants.ports.services.jellyfin}"
                api-key: "@JELLYFIN_KEY@"
                username: Janitorr
                password: "@JELLYFIN_PASS@"
                delete: true
              emby:
                enabled: false
                url: ""
                api-key: ""
                username: ""
                password: ""
                delete: false
              jellyseerr:
                enabled: true
                url: "http://host.containers.internal:${toString constants.ports.services.seerr}"
                api-key: "@JELLYSEERR_KEY@"
                match-server: false
              jellystat:
                enabled: true
                url: "http://host.containers.internal:${toString constants.ports.services.jellystat}"
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
          chmod 600 "${configPath}/janitorr/application.yml"
        '';

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
        "d ${configPath}/profilarr 0755 ${toString uid} ${toString gid} -"
        "d ${configPath}/listenarr 0755 ${toString uid} ${toString gid} -"
      ];

      # Firewall ports
      networking.firewall.allowedTCPPorts = [
        constants.ports.services.homarr
        constants.ports.services.wizarr
        constants.ports.services.termix
        constants.ports.services.janitorr
        constants.ports.services.profilarr
        constants.ports.services.listenarr
      ];

      # Enable automatic image pruning (nixpkgs provides podman-prune service)
      virtualisation.podman.autoPrune.enable = true;
    };
}
