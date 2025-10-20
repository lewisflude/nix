# Readarr - Book management
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  config = mkIf (cfg.enable && cfg.readarr.enable) {
    services.readarr = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    # Set timezone
    systemd.services.readarr.environment = {
      TZ = cfg.timezone;
    };

    # Soft dependency on prowlarr for startup order
    systemd.services.readarr = {
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
