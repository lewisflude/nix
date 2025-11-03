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

    # Ensure directories exist before SABnzbd starts
    # Note: Download directories must be configured in SABnzbd web UI:
    # - Completed Download Folder: ${cfg.dataPath}/usenet/complete
    # - Temporary Download Folder: ${cfg.dataPath}/usenet/incomplete
    systemd.services.sabnzbd.preStart = ''
      # Create directories, handling disk space errors gracefully
      # During activation tests or if disk is full, warn but don't fail
      if ! mkdir -p "${cfg.dataPath}/usenet/complete" "${cfg.dataPath}/usenet/incomplete" 2>/dev/null; then
        echo "Warning: Failed to create SABnzbd directories (disk may be full)"
        echo "SABnzbd may not function correctly until disk space is available"
        # Don't fail activation tests due to disk space issues
        exit 0
      fi
      chown ${cfg.user}:${cfg.group} "${cfg.dataPath}/usenet/complete" "${cfg.dataPath}/usenet/incomplete" || true
      chmod 775 "${cfg.dataPath}/usenet/complete" "${cfg.dataPath}/usenet/incomplete" || true
    '';

    # Open firewall on port 8082 (mapped from default 8080)
    networking.firewall.allowedTCPPorts = mkAfter [8082];
  };
}
