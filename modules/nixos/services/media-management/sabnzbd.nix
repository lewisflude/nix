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

      # Override config settings to prevent port conflict with qBittorrent
      configFile = pkgs.writeText "sabnzbd.ini" ''
        __encoding__ = utf-8
        __version__ = 19

        [misc]
        auto_browser = 0
        bandwidth_max = ""
        bandwidth_perc = 0
        cache_limit = ""
        check_new_rel = 0
        config_conversion_version = 4
        config_lock = 0
        email_endjob = 0
        email_from = ""
        email_full = 0
        email_rss = 0
        email_server = ""
        email_to = ""
        enable_https = 0
        host = 127.0.0.1
        html_login = 1
        inet_exposure = 0
        notified_new_skin = 1
        port = ${toString constants.ports.services.sabnzbd}
        host_whitelist = usenet.blmt.io, sabnzbd.org, localhost

        [ntfosd]
        ntfosd_enable = 0

        [servers]
      '';
    };

    systemd.services.sabnzbd = {
      environment = {
        TZ = cfg.timezone;
      };

      preStart = ''
        mkdir -p ${cfg.dataPath}/usenet/complete || true
        mkdir -p ${cfg.dataPath}/usenet/incomplete || true

        # Fix SABnzbd port conflict with qBittorrent (8080)
        # Force SABnzbd to 8082 and ensure correct host whitelist in [misc] section
        # Note: StateDirectory is 'sabnzbd', not cfg.user ('media')
        CFG_FILE="/var/lib/sabnzbd/sabnzbd.ini"
        if [ -f "$CFG_FILE" ]; then
          # Update port to 8082 in [misc] section
          ${pkgs.gnused}/bin/sed -i '/^\[misc\]/,/^\[/ s/^port = .*/port = 8082/' "$CFG_FILE"

          # Update or add host_whitelist in [misc] section
          if ${pkgs.gnugrep}/bin/grep -q "^host_whitelist = " "$CFG_FILE"; then
            ${pkgs.gnused}/bin/sed -i '/^\[misc\]/,/^\[/ s/^host_whitelist = .*/host_whitelist = usenet.blmt.io, sabnzbd.org, localhost/' "$CFG_FILE"
          else
            # Add host_whitelist after the port line in [misc] section
            ${pkgs.gnused}/bin/sed -i '/^\[misc\]/,/^\[/ s/^port = .*/&\nhost_whitelist = usenet.blmt.io, sabnzbd.org, localhost/' "$CFG_FILE"
          fi
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
