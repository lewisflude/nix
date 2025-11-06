{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.jellyfin.enable = mkEnableOption "Jellyfin media server" // {
    default = true;
  };

  config = mkIf (cfg.enable && cfg.jellyfin.enable) {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    networking.firewall = {
      allowedTCPPorts = [
        8096
        8920
      ];
      allowedUDPPorts = [
        7359

      ];
    };

    users.users.${cfg.user}.extraGroups = [
      "render"
      "video"
    ];
  };
}
