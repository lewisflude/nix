# Navidrome Service Module - Dendritic Pattern
# Music streaming server compatible with Subsonic clients
# Usage: Import config.flake.modules.nixos.navidrome in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.navidrome = { lib, ... }:
  let
    inherit (lib) mkDefault;
    user = "media";
    group = "media";
    dataPath = "/mnt/storage";
  in
  {
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      description = "Media management user";
      extraGroups = [ "audio" ];
    };
    users.groups.${group} = { };

    services.navidrome = {
      enable = true;
      openFirewall = false;
      inherit user group;
      settings = {
        Port = constants.ports.services.navidrome;
        Address = "0.0.0.0";
        MusicFolder = "${dataPath}/media/music";
        DataFolder = "/var/lib/navidrome";
        EnableInsightsCollector = false;
      };
    };

    networking.firewall.allowedTCPPorts = mkDefault [
      constants.ports.services.navidrome
    ];

    systemd.services.navidrome = {
      environment.TZ = mkDefault constants.defaults.timezone;
    };
  };
}
