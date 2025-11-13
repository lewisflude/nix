{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.mediaManagement;
  constants = import ../../../../lib/constants.nix;
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
      port = constants.ports.services.flaresolverr;
    };

    systemd.services.flaresolverr.environment = {
      TZ = cfg.timezone;
      LOG_LEVEL = "info";
    };
  };
}
