{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkAfter;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.sabnzbd.enable =
    mkEnableOption "SABnzbd usenet downloader"
    // {
      default = true;
    };

  config = mkIf (cfg.enable && cfg.sabnzbd.enable) {
    services.sabnzbd = {
      enable = true;
      inherit (cfg) user;
      inherit (cfg) group;
    };

    systemd.services.sabnzbd = {

      environment = {
        TZ = cfg.timezone;
      };

      preStart = ''


        mkdir -p ${cfg.dataPath}/usenet/complete || true
        mkdir -p ${cfg.dataPath}/usenet/incomplete || true

        chown -R ${cfg.user}:${cfg.group} ${cfg.dataPath}/usenet 2>/dev/null || true
        chmod -R 775 ${cfg.dataPath}/usenet 2>/dev/null || true
      '';

      serviceConfig = {

        ProtectSystem = false;

        ProtectHome = false;
      };
    };

    networking.firewall.allowedTCPPorts = mkAfter [ 8082 ];
  };
}
