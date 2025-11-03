# Native NixOS Media Management Stack
# Uses official NixOS modules instead of containers
{...}: {
  imports = [
    ./options.nix
    ./common.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sonarr.nix
    ./lidarr.nix
    ./readarr.nix
    ./sabnzbd.nix
    # Use standard NixOS qBittorrent module instead of custom one
    # ./qbittorrent.nix  # Disabled - using standard module
    ./qbittorrent-standard.nix
    ./qbittorrent-vpn-confinement.nix
    ./qbittorrent-proxy.nix
    ./jellyfin.nix
    ./jellyseerr.nix
    ./flaresolverr.nix
    ./unpackerr.nix
    ./navidrome.nix
  ];
}
