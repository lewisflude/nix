# SABnzbd Service Module - Dendritic Pattern
# Usenet downloader for automated media retrieval
# Usage: Import flake.modules.nixos.sabnzbd in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.sabnzbd = { lib, ... }:
  let
    inherit (lib) mkDefault mkForce;

    # Default configuration (can be overridden by hosts)
    user = "media";
    group = "media";
    port = constants.ports.services.sabnzbd;
    downloadDir = "/var/lib/sabnzbd/incomplete";
    completeDir = "/mnt/storage/usenet";
  in
  {
    # Ensure media user/group exist
    users.users.${user} = mkDefault {
      isSystemUser = true;
      group = group;
      description = "Media management user";
    };
    users.groups.${group} = mkDefault { };

    # Ensure required directories exist
    systemd.tmpfiles.rules = [
      "d '${downloadDir}' 0750 ${user} ${group} - -"
      "d '${completeDir}' 0750 ${user} ${group} - -"
    ];

    services.sabnzbd = {
      enable = true;
      inherit user group;

      # Explicitly disable deprecated configFile to use settings
      configFile = null;

      settings = {
        misc = {
          inherit port;
          host_whitelist = mkDefault "usenet.blmt.io";

          # Use NVMe for incomplete downloads to prevent I/O bottleneck
          # Complete downloads move to HDD storage after extraction
          download_dir = downloadDir;
          complete_dir = completeDir;
        };
      };
    };

    # Override the systemd service to remove the pre-start script that wipes config
    # Add I/O and CPU nice priorities to prevent starving compositor
    systemd.services.sabnzbd = {
      serviceConfig = {
        ExecStartPre = mkForce "";
        # Nice priority: 19 = lowest CPU priority (background process)
        Nice = 19;
        # I/O priority: best-effort class 7 = lowest I/O priority
        IOSchedulingClass = "best-effort";
        IOSchedulingPriority = 7;
      };
    };

    networking.firewall.allowedTCPPorts = mkDefault [
      port
    ];
  };
}
