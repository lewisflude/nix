# FlareSolverr - Cloudflare bypass
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
  config = mkIf (cfg.enable && cfg.flaresolverr.enable) {
    services.flaresolverr = {
      enable = true;
      openFirewall = true;
      port = 8191;
    };

    # Set timezone
    systemd.services.flaresolverr.environment = {
      TZ = cfg.timezone;
      LOG_LEVEL = "info";
    };
  };
}
