# Jellyfin - Media server
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  config = mkIf (cfg.enable && cfg.jellyfin.enable) {
    services.jellyfin = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    # Additional ports for HTTPS and service discovery
    networking.firewall = {
      allowedTCPPorts = [
        8096 # HTTP
        8920 # HTTPS
      ];
      allowedUDPPorts = [
        7359 # Service discovery
        # 1900 # DLNA - commented out due to potential port conflict
      ];
    };

    # Grant access to GPU for hardware transcoding
    users.users.${cfg.user}.extraGroups = [
      "render"
      "video"
    ];
  };
}
