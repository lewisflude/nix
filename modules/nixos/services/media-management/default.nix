# Native NixOS Media Management Stack
# Uses official NixOS modules instead of containers
{...}: {
  imports = [
    ./options.nix
    ./common.nix
    ./qbittorrent.nix
    ./prowlarr.nix
    ./radarr.nix
    ./sonarr.nix
    ./lidarr.nix
    ./readarr.nix
    ./whisparr.nix
    ./sabnzbd.nix
    ./jellyfin.nix
    ./jellyseerr.nix
    ./flaresolverr.nix
    ./unpackerr.nix
  ];
}
