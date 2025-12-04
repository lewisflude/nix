{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.host.services.caddy;
in
{
  options.host.services.caddy = {
    enable = mkEnableOption "Caddy web server with reverse proxy configuration" // {
      default = false;
    };

    email = mkOption {
      type = types.str;
      default = "";
      description = "Email address for ACME/Let's Encrypt certificates";
    };
  };

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      inherit (cfg) email;

      virtualHosts = {
        # Pi-hole admin interface
        "pihole.blmt.io" = {
          extraConfig = ''
            reverse_proxy 192.168.10.10:8080 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
            redir / /admin{uri}
          '';
        };

        # Home Assistant
        "home.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8123 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Cal.com
        "cal.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:3000 {
              header_up Host {host}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
              header_up X-Forwarded-Host {host}
            }
            encode zstd gzip
          '';
        };

        # Cockpit
        "cockpit.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:9090 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Navidrome (Music)
        "music.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8095 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Jellyfin
        "jellyfin.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8096 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # qBittorrent (VPN namespace)
        "torrent.blmt.io" = {
          extraConfig = ''
            reverse_proxy 192.168.15.1:8080 {
              # Standard proxy headers (no Host rewriting - let qBittorrent see original host)
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
              header_up X-Forwarded-Host {host}
            }
            encode zstd gzip
          '';
        };

        # Transmission (Host network - not VPN)
        "transmission.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:9091 {
              # CSRF Protection Fix: Tell Transmission the request is coming from localhost
              header_up Host localhost:9091
              header_up Origin http://localhost:9091
              header_up Referer http://localhost:9091

              # Standard proxy headers
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Prowlarr
        "prowlarr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:9696 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Sonarr
        "sonarr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8989 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Radarr
        "radarr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:7878 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # FlareSolverr
        "flaresolverr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8191 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Dockge (Local)
        "dockge.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:5001 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Jellyseerr
        "jellyseer.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:5055 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Lidarr
        "lidarr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8686 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Sunshine (Gaming) - special transport config
        "sunshine.blmt.io" = {
          extraConfig = ''
            reverse_proxy https://localhost:47990 {
              transport http {
                tls_insecure_skip_verify
              }
              header_up Host {host}
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Open WebUI (AI)
        "ai.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:7000 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # ComfyUI
        "comfy.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8188 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Checkrr
        "checkrr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8585 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Time tracking
        "time.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8001 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Termix (SSH Management)
        "termix.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8083 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # SABnzbd (Usenet)
        "usenet.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8082 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # UniFi Controller
        "unifi.blmt.io" = {
          extraConfig = ''
            reverse_proxy 192.168.10.1:443 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Wizarr (Invite system)
        "invite.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:5690 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Homarr (Dashboard)
        "blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:7575 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Readarr
        "readarr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:8787 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Listenarr (Audiobooks)
        "listenarr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:5000 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Cleanuparr (Download Queue Cleanup)
        "cleanuparr.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:11011 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Komga (Comics)
        "comics.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:5656 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
          '';
        };

        # Ollama - with CORS headers
        "ollama.blmt.io" = {
          extraConfig = ''
            reverse_proxy localhost:11434 {
              header_up X-Real-IP {remote_host}
              header_up X-Forwarded-For {remote_host}
              header_up X-Forwarded-Proto {scheme}
            }
            encode zstd gzip
            @options {
              method OPTIONS
            }
            header {
              Access-Control-Allow-Origin *
              Access-Control-Allow-Credentials true
              Access-Control-Allow-Methods *
              Access-Control-Allow-Headers *
              defer
            }
          '';
        };
      };
    };

    # Open firewall for HTTP and HTTPS
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
