# SABnzbd - Usenet downloader
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
in {
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

    # Set timezone
    systemd.services.sabnzbd.environment = {
      TZ = cfg.timezone;
    };

    # Allow write access to data path (required for downloads)
    # The NixOS sabnzbd module applies ProtectSystem=strict by default,
    # which prevents writes outside /var/lib/sabnzbd
    systemd.services.sabnzbd.serviceConfig = {
      ReadWritePaths = [cfg.dataPath];
      # Also allow access to user home directory
      ProtectHome = false;
    };

    # Note: Download directories are created by systemd-tmpfiles (see common.nix)
    # Configure in SABnzbd web UI:
    # - Completed Download Folder: ${cfg.dataPath}/usenet/complete
    # - Temporary Download Folder: ${cfg.dataPath}/usenet/incomplete

    # Open firewall on port 8082 (non-standard port to avoid conflict with qBittorrent on 8080)
    networking.firewall.allowedTCPPorts = mkAfter [8082];
  };
}
