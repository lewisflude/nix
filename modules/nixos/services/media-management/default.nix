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
    ./listenarr.nix
    ./sabnzbd.nix
    ./qbittorrent.nix
    ./qbittorrent-vpn-confinement.nix
    ./protonvpn-portforward.nix
    ./transmission.nix
    ./jellyfin.nix
    ./jellyseerr.nix
    ./flaresolverr.nix
    ./unpackerr.nix
    ./navidrome.nix
  ];
}
