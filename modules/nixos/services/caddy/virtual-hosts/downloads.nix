# Download Services Virtual Hosts
# qBittorrent, Transmission, SABnzbd, etc.
_:
# let
#   helpers = import ../helpers.nix { inherit lib; };
#   inherit (helpers) mkReverseProxyWithHeaders;
# in
{
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
      reverse_proxy 127.0.0.1:9091 {
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

  # SABnzbd (Usenet)
  "usenet.blmt.io" = {
    extraConfig = ''
      reverse_proxy 127.0.0.1:8082 {
        header_up X-Real-IP {remote_host}
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
      encode zstd gzip
    '';
  };
}
