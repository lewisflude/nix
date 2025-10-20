# Whisparr - Adult content management
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  config = mkIf (cfg.enable && cfg.whisparr.enable) {
    services.whisparr = {
      enable = true;
      openFirewall = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    # Set timezone
    systemd.services.whisparr.environment = {
      TZ = cfg.timezone;
    };

    # Soft dependency on prowlarr for startup order
    systemd.services.whisparr = {
      after = mkAfter (optional cfg.prowlarr.enable "prowlarr.service");
    };
  };
}
