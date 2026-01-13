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
  options.host.services.mediaManagement.flaresolverr = {
    enable = mkEnableOption "FlareSolverr cloudflare bypass" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for FlareSolverr" // {
      default = true;
    };
  };

  config = mkIf (cfg.enable && cfg.flaresolverr.enable) {
    services.flaresolverr = {
      enable = true;
      inherit (cfg.flaresolverr) openFirewall;
      port = constants.ports.services.flaresolverr;
    };

    systemd.services.flaresolverr.environment = {
      TZ = cfg.timezone;
      LOG_LEVEL = "info";
    };
  };
}
