{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.host.services.mediaManagement;
in
{
  options.host.services.mediaManagement.sabnzbd = {
    enable = mkEnableOption "SABnzbd usenet downloader" // {
      default = true;
    };

    openFirewall = mkEnableOption "Open firewall ports for SABnzbd" // {
      default = true;
    };
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

        # Fix SABnzbd port conflict with qBittorrent (8080)
        # Force SABnzbd to 8082 and ensure correct host whitelist
        CFG_FILE="/var/lib/${cfg.user}/.sabnzbd/sabnzbd.ini"
        if [ -f "$CFG_FILE" ]; then
          # Update port to 8082
          ${pkgs.gnused}/bin/sed -i 's/^port = .*/port = 8082/' "$CFG_FILE"
          # Update host whitelist
          ${pkgs.gnused}/bin/sed -i 's/^host_whitelist = .*/host_whitelist = usenet.blmt.io, sabnzbd.org, localhost/' "$CFG_FILE"
        fi
      '';

      serviceConfig = {
        ProtectSystem = false;
        ProtectHome = false;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.sabnzbd.openFirewall [
      constants.ports.services.sabnzbd
    ];
  };
}
