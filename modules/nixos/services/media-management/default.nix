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
    ./qbittorrent.nix
    ./qbittorrent-vpn-confinement.nix
    ./jellyfin.nix
    ./jellyseerr.nix
    ./flaresolverr.nix
    ./unpackerr.nix
    ./navidrome.nix
  ];
}
