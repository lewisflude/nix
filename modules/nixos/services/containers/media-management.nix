# Media Management Stack
# Converts services from /opt/stacks/media-management
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.services.containers;
  mmCfg = cfg.mediaManagement;

  # Common environment for all media apps
  commonEnv = {
    PUID = toString cfg.uid;
    PGID = toString cfg.gid;
    UMASK = "002";
    TZ = cfg.timezone;
  };

  # Helper to create volume paths
  mkVolumes = appName: [
    "${mmCfg.configPath}/${appName}:/config"
    "${mmCfg.dataPath}:/mnt/storage"
  ];

  mediaContainers = [
    "prowlarr"
    "radarr"
    "sonarr"
    "lidarr"
    "whisparr"
    "readarr"
    "sabnzbd"
    "jellyfin"
    "flaresolverr"
    "unpackerr"
    "kapowarr"
    "doplarr"
  ];

  frontendContainers = [
    "jellyseerr"
    "homarr"
    "wizarr"
  ];

  mkNetworkDeps = network: names:
    genAttrs (map (name: "podman-${name}") names) (_: {
      after = mkAfter ["podman-network-${network}.service"];
      requires = mkAfter ["podman-network-${network}.service"];
    });

  inherit (cfg) secrets;

  mkSecretEnv = name: secret:
    if secret != null
    then {"${name}" = secret;}
    else {};
in {
  config = mkIf (cfg.enable && mmCfg.enable) (mkMerge [
    {
      virtualisation.oci-containers.containers = {
        # Prowlarr - Indexer manager
        prowlarr = {
          image = "ghcr.io/hotio/prowlarr:latest";
          environment = commonEnv;
          volumes = mkVolumes "prowlarr";
          ports = ["9696:9696"];
          extraOptions = ["--network=media"];
        };

        # Radarr - Movie management
        radarr = {
          image = "ghcr.io/hotio/radarr:latest";
          environment = commonEnv;
          volumes = mkVolumes "radarr";
          ports = ["7878:7878"];
          extraOptions = ["--network=media"];
          # dependsOn removed - using soft After= dependency instead via systemd overrides
        };

        # Sonarr - TV show management
        sonarr = {
          image = "ghcr.io/hotio/sonarr:latest";
          environment = commonEnv;
          volumes = mkVolumes "sonarr";
          ports = ["8989:8989"];
          extraOptions = ["--network=media"];
          # dependsOn removed - using soft After= dependency instead via systemd overrides
        };

        # Lidarr - Music management
        lidarr = {
          image = "ghcr.io/hotio/lidarr:nightly";
          environment = commonEnv;
          volumes = mkVolumes "lidarr";
          ports = ["8686:8686"];
          extraOptions = ["--network=media"];
          dependsOn = ["prowlarr"];
        };

        # Whisparr - Adult content management
        whisparr = {
          image = "ghcr.io/hotio/whisparr:latest";
          environment = commonEnv // {UMASK = "022";};
          volumes = mkVolumes "whisparr";
          ports = ["6969:6969"];
          extraOptions = ["--network=media"];
        };

        # Readarr - Book management
        readarr = {
          image = "ghcr.io/hotio/readarr:nightly";
          environment = commonEnv;
          volumes = mkVolumes "readarr";
          ports = ["8787:8787"];
          extraOptions = ["--network=media"];
          dependsOn = ["prowlarr"];
        };

        # SABnzbd - Usenet downloader
        sabnzbd = {
          image = "ghcr.io/hotio/sabnzbd:latest";
          environment = commonEnv;
          volumes = [
            "${mmCfg.configPath}/sabnzbd:/config"
            "${mmCfg.dataPath}/usenet:/downloads"
            "${mmCfg.dataPath}:/mnt/storage"
          ];
          ports = ["8082:8080"];
          extraOptions = ["--network=media"];
        };

        # Jellyfin - Media server
        jellyfin = {
          image = "jellyfin/jellyfin:latest";
          user = "${toString cfg.uid}:${toString cfg.gid}";
          environment = {
            TZ = cfg.timezone;
          };
          volumes = [
            "${mmCfg.configPath}/jellyfin/config:/config"
            "${mmCfg.configPath}/jellyfin/cache:/cache"
            "${mmCfg.dataPath}:/mnt/storage"
          ];
          ports = [
            "8096:8096" # HTTP
            "8920:8920" # HTTPS
            "7359:7359/udp" # Service discovery
            # "1900:1900/udp" # DLNA - commented out due to port conflict
          ];
          extraOptions = [
            "--network=media"
            "--device=/dev/dri:/dev/dri" # Hardware acceleration
          ];
        };

        # Jellyseerr - Request management
        jellyseerr = {
          image = "fallenbagel/jellyseerr:latest";
          environment =
            commonEnv
            // {
              LOG_LEVEL = "info";
            };
          volumes = ["${mmCfg.configPath}/jellyseerr:/app/config"];
          ports = ["5055:5055"];
          extraOptions = ["--network=frontend"];
          dependsOn = ["jellyfin"];
        };

        # FlareSolverr - Cloudflare bypass
        flaresolverr = {
          image = "ghcr.io/flaresolverr/flaresolverr:latest";
          environment = {
            LOG_LEVEL = "info";
            TZ = cfg.timezone;
          };
          ports = ["8191:8191"];
          extraOptions = ["--network=media"];
        };

        # Unpackerr - Extract downloads
        unpackerr = {
          image = "ghcr.io/hotio/unpackerr:latest";
          environment = commonEnv;
          volumes = [
            "${mmCfg.configPath}/unpackerr:/config"
            "${mmCfg.dataPath}:/mnt/storage"
          ];
          extraOptions = ["--network=media"];
          # dependsOn removed - using soft After= dependency instead via systemd overrides
        };

        # Homarr - Dashboard
        homarr = {
          image = "ghcr.io/ajnart/homarr:latest";
          environment = {
            TZ = cfg.timezone;
          };
          volumes = [
            "${mmCfg.configPath}/homarr/configs:/app/data/configs"
            "${mmCfg.configPath}/homarr/icons:/app/public/icons"
            "${mmCfg.configPath}/homarr/data:/data"
          ];
          ports = ["7575:7575"];
          extraOptions = ["--network=frontend"];
        };

        # Wizarr - Invitation system
        wizarr = {
          image = "ghcr.io/wizarrrr/wizarr:latest";
          environment = {
            TZ = cfg.timezone;
          };
          volumes = ["${mmCfg.configPath}/wizarr:/data/database"];
          ports = ["5690:5690"];
          extraOptions = ["--network=frontend"];
        };

        # Janitorr - Cleanup tool (image repo doesn't exist - disabled)
        # janitorr = {
        #   image = "ghcr.io/islamsuite/janitorr:latest";
        #   environment = commonEnv // {
        #     SONARR_API_KEY = "/run/secrets/sonarr_api_key";
        #     RADARR_API_KEY = "/run/secrets/radarr_api_key";
        #   };
        #   volumes = ["${mmCfg.configPath}/janitorr:/config"];
        #   extraOptions = ["--network=media"];
        #   dependsOn = ["radarr" "sonarr"];
        # };

        # Recommendarr - Recommendation engine (image repo doesn't exist - disabled)
        # recommendarr = {
        #   image = "ghcr.io/hotio/recommendarr:latest";
        #   environment = commonEnv;
        #   volumes = ["${mmCfg.configPath}/recommendarr:/config"];
        #   ports = ["3579:3579"];
        #   extraOptions = ["--network=media"];
        # };

        # Autopulse - Automation (image repo doesn't exist - disabled)
        # autopulse = {
        #   image = "ghcr.io/autopulse/autopulse:latest";
        #   environment = commonEnv;
        #   volumes = ["${mmCfg.configPath}/autopulse:/config"];
        #   extraOptions = ["--network=media"];
        #   dependsOn = ["radarr" "sonarr"];
        # };

        # Kapowarr - Comic management
        kapowarr = {
          image = "mrcas/kapowarr:latest";
          environment = commonEnv;
          volumes = [
            "${mmCfg.configPath}/kapowarr:/app/db"
            "${mmCfg.dataPath}:/mnt/storage"
          ];
          ports = ["5656:5656"];
          extraOptions = ["--network=media"];
        };

        # Doplarr - Discord bot
        doplarr = {
          image = "ghcr.io/hotio/doplarr:latest";
          environment =
            commonEnv
            // mkSecretEnv "DISCORD_TOKEN" secrets.discordToken
            // mkSecretEnv "SONARR_API_KEY" secrets.sonarrApiKey
            // mkSecretEnv "RADARR_API_KEY" secrets.radarrApiKey;
          volumes = ["${mmCfg.configPath}/doplarr:/config"];
          extraOptions = ["--network=media"];
          # dependsOn removed - using soft After= dependency instead via systemd overrides
        };
      };
    }
    {
      systemd.services = mkMerge [
        # Ensure Podman storage and networks exist before containers start
        {
          podman-storage-check = {
            description = "Check and repair Podman storage";
            before = ["podman-network-media.service" "podman-network-frontend.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.podman}/bin/podman system check";
            };
          };

          podman-network-media = {
            description = "Create podman media network";
            after = ["podman.service" "podman-storage-check.service"];
            requires = ["podman-storage-check.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.podman}/bin/podman network exists media || ${pkgs.podman}/bin/podman network create media'";
              ExecStop = "${pkgs.podman}/bin/podman network rm -f media";
            };
          };

          podman-network-frontend = {
            description = "Create podman frontend network";
            after = ["podman.service" "podman-storage-check.service"];
            requires = ["podman-storage-check.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.podman}/bin/podman network exists frontend || ${pkgs.podman}/bin/podman network create frontend'";
              ExecStop = "${pkgs.podman}/bin/podman network rm -f frontend";
            };
          };
        }
        (mkNetworkDeps "media" mediaContainers)
        (mkNetworkDeps "frontend" frontendContainers)
        # Override service dependencies to use soft After= instead of hard Requires=
        # This prevents cascading failures on boot while maintaining startup order
        {
          podman-radarr = {
            after = mkAfter ["podman-prowlarr.service" "podman-sabnzbd.service"];
            # Make restart more resilient
            serviceConfig = {
              RestartSec = "30s";
              StartLimitBurst = 10;
              StartLimitIntervalSec = 600;
            };
          };
          podman-sonarr = {
            after = mkAfter ["podman-prowlarr.service" "podman-sabnzbd.service"];
            serviceConfig = {
              RestartSec = "30s";
              StartLimitBurst = 10;
              StartLimitIntervalSec = 600;
            };
          };
          podman-doplarr = {
            after = mkAfter ["podman-radarr.service" "podman-sonarr.service"];
            serviceConfig = {
              RestartSec = "30s";
              StartLimitBurst = 10;
              StartLimitIntervalSec = 600;
            };
          };
          podman-unpackerr = {
            after = mkAfter ["podman-radarr.service" "podman-sonarr.service"];
            serviceConfig = {
              RestartSec = "30s";
              StartLimitBurst = 10;
              StartLimitIntervalSec = 600;
            };
          };
          # Add resilient restart for base services too
          podman-prowlarr.serviceConfig = {
            RestartSec = "10s";
            StartLimitBurst = 10;
            StartLimitIntervalSec = 600;
          };
          podman-sabnzbd.serviceConfig = {
            RestartSec = "10s";
            StartLimitBurst = 10;
            StartLimitIntervalSec = 600;
          };
        }
      ];
    }
  ]);
}
