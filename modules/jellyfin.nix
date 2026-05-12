# Jellyfin Service Module - Dendritic Pattern
# Media server with hardware transcoding
# User/group declared centrally in media-user.nix (with render/video extraGroups).
{ config, ... }:
let
  inherit (config) constants;
  inherit (config.lib) media;
in
{
  flake.modules.nixos.jellyfin =
    { lib, ... }:
    {
      services.jellyfin = {
        enable = true;
        openFirewall = false;
        inherit (media) user group;
      };

      systemd.services.jellyfin = media.serviceDefaults;

      networking.firewall = {
        allowedTCPPorts = lib.mkDefault [
          constants.ports.services.jellyfin # 8096 - HTTP
          8920 # HTTPS
        ];
        allowedUDPPorts = lib.mkDefault [
          1900 # DLNA discovery
          7359 # Client discovery
        ];
      };
    };
}
