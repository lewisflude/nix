# Jellyfin Service Module - Dendritic Pattern
# Media server with hardware transcoding
# Usage: Import config.flake.modules.nixos.jellyfin in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.jellyfin =
    { lib, ... }:
    let
      inherit (lib) mkDefault;
      user = "media";
      group = "media";
    in
    {
      users.users.${user} = {
        isSystemUser = true;
        group = group;
        description = "Media management user";
        # Add to render/video groups for hardware acceleration
        extraGroups = [
          "render"
          "video"
        ];
      };
      users.groups.${group} = { };

      services.jellyfin = {
        enable = true;
        openFirewall = false;
        inherit user group;
      };

      networking.firewall = {
        allowedTCPPorts = mkDefault [
          constants.ports.services.jellyfin # 8096 - HTTP
          8920 # HTTPS
        ];
        allowedUDPPorts = mkDefault [
          1900 # DLNA discovery
          7359 # Client discovery
        ];
      };
    };
}
