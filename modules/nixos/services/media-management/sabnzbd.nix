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
      inherit (cfg) user group;

      settings = {
        misc = {
          port = constants.ports.services.sabnzbd;
          host_whitelist = "usenet.blmt.io";

          # Use NVMe for incomplete downloads to prevent I/O bottleneck
          # Complete downloads move to HDD storage after extraction
          download_dir = "/var/lib/sabnzbd/incomplete";
          complete_dir = "/mnt/storage/usenet";
        };
      };
    };

    # Override the systemd service to remove the pre-start script that wipes config
    # Add I/O and CPU nice priorities to prevent starving compositor
    systemd.services.sabnzbd = {
      serviceConfig = {
        ExecStartPre = lib.mkForce "";
        # Nice priority: 19 = lowest CPU priority (background process)
        Nice = 19;
        # I/O priority: best-effort class 7 = lowest I/O priority
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 7;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.sabnzbd.openFirewall [
      constants.ports.services.sabnzbd
    ];
  };
}
