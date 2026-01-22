{
  config,
  lib,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.jellyfin = {
    enable = mkEnableOption "Jellyfin media server" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for Jellyfin" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.jellyfin.enable) {
    services.jellyfin = {
      enable = true;
      openFirewall = false; # We manage it manually to ensure consistency
      inherit (cfg) user;
      inherit (cfg) group;
    };

    networking.firewall = mkIf cfg.jellyfin.openFirewall {
      allowedTCPPorts = [
        constants.ports.services.jellyfin # 8096
        8920 # HTTPS
      ];
      allowedUDPPorts = [
        1900 # DLNA
        7359 # Discovery
      ];
    };

    users.users.${cfg.user}.extraGroups = [
      "render"
      "video"
    ];
  };
}
