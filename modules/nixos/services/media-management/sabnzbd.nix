# SABnzbd - Usenet downloader
{
  config,
  lib,
  ...
}:
with lib;
let
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

    # Configure systemd service for sabnzbd
    systemd.services.sabnzbd = {
      # Set timezone
      environment = {
        TZ = cfg.timezone;
      };

      # Ensure directories have correct permissions before starting
      # Fix any permission issues that might prevent writes
      # Note: If directories already exist, we still fix permissions
      # If mkdir fails due to no space, chown/chmod will still run on existing dirs
      preStart = ''
        # Ensure usenet directories exist with correct ownership and permissions
        # mkdir -p will succeed if directories already exist, or fail if no space
        mkdir -p ${cfg.dataPath}/usenet/complete || true
        mkdir -p ${cfg.dataPath}/usenet/incomplete || true
        # Fix permissions on existing directories (ignore errors if dirs don't exist)
        chown -R ${cfg.user}:${cfg.group} ${cfg.dataPath}/usenet 2>/dev/null || true
        chmod -R 775 ${cfg.dataPath}/usenet 2>/dev/null || true
      '';

      # Allow write access to data path (required for downloads)
      # The NixOS sabnzbd module applies ProtectSystem=strict by default,
      # which prevents writes outside /var/lib/sabnzbd
      # For FUSE mounts like mergerfs, ProtectSystem=strict interferes with writes
      # even when ReadWritePaths is set, so we disable it and rely on other
      # security measures (non-root user, proper permissions, etc.)
      serviceConfig = {
        # Disable ProtectSystem for FUSE mount compatibility
        # FUSE mounts (like mergerfs) don't work well with ProtectSystem=strict
        # even with ReadWritePaths, so we disable it entirely
        # Security is still maintained via:
        # - Running as non-root user (media)
        # - Proper file/directory permissions
        # - Other systemd protections (NoNewPrivileges, etc.)
        ProtectSystem = false;
        # Also allow access to user home directory
        ProtectHome = false;
      };
    };

    # Note: Download directories are created by systemd-tmpfiles (see common.nix)
    # Configure in SABnzbd web UI:
    # - Completed Download Folder: ${cfg.dataPath}/usenet/complete
    # - Temporary Download Folder: ${cfg.dataPath}/usenet/incomplete

    # Open firewall on port 8082 (non-standard port to avoid conflict with qBittorrent on 8080)
    networking.firewall.allowedTCPPorts = mkAfter [ 8082 ];
  };
}
