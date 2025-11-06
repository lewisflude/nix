{ ... }:
{
  imports = [
    ./options.nix
    ./common.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sonarr.nix
    ./lidarr.nix
    ./readarr.nix
    ./sabnzbd.nix

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
