# FlareSolverr - Cloudflare bypass
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
  options.host.services.mediaManagement.flaresolverr.enable =
    mkEnableOption "FlareSolverr cloudflare bypass"
    // {
      default = true;
    };

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
