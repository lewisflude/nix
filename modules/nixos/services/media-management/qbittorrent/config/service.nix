{
  config,
  lib,
  pkgs,
  constants,
  qbittorrentCfg,
  webUI,
  preferencesCfg,
  bittorrentSession,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    optionals
    optionalAttrs
    mapAttrs
    ;
in
{
  # Firewall configuration
  # When VPN is enabled, only WebUI port needs to be open on host
  # When VPN is disabled, both WebUI and torrent ports need to be open
  networking.firewall = mkIf qbittorrentCfg.openFirewall {
    allowedTCPPorts = [
      (if webUI != null then webUI.port else constants.ports.services.qbittorrent)
    ] # WebUI always accessible
    ++ optionals (!(qbittorrentCfg.vpn.enable or false)) [
      qbittorrentCfg.torrentPort # Torrent port only when VPN disabled
    ];
    allowedUDPPorts = optionals (!(qbittorrentCfg.vpn.enable or false)) [
      qbittorrentCfg.torrentPort # Torrent port only when VPN disabled
    ];
  };

  # Set umask for qBittorrent service to ensure group-writable files
  systemd.services.qbittorrent.serviceConfig = mkMerge [
    {
      UMask = "0002";

      # CPU Scheduling: Use "batch" policy for smoother network throughput
      # Batch scheduling prevents qBittorrent from interrupting the networking stack
      # Nice=5 gives slightly lower priority than system processes (Nice=0)
      # but higher than background tasks (Nice=19)
      CPUSchedulingPolicy = "batch";
      Nice = 5;

      # I/O Scheduling: Best-effort with priority 5 (middle priority)
      # This prevents qBittorrent I/O from blocking Jellyfin streaming
      # but still prioritizes it over background tasks
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 5;

      # Restart configuration for resilience to transient failures
      # Restart on failure (e.g., when VPN namespace isn't ready yet)
      Restart = "on-failure";
      # Wait 10 seconds before retrying to give VPN time to establish
      RestartSec = "10s";
      # Limit restart attempts to prevent infinite loops
      StartLimitBurst = 5;
      StartLimitIntervalSec = "5min";
    }
    # Conditional ExecStartPre for SOPS credential injection
    (mkIf (webUI != null && webUI.useSops) {
      # Inject SOPS secrets into qBittorrent config at runtime
      # This follows the best practice of never reading secrets into the Nix store
      ExecStartPre = pkgs.writeShellScript "qbittorrent-inject-credentials" ''
        set -euo pipefail

        CONFIG_DIR="/var/lib/qbittorrent/.config/qBittorrent"
        CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"

        # Wait for config file to be created by qBittorrent service
        if [ ! -f "$CONFIG_FILE" ]; then
          echo "Config file not found, will be created on first run"
          exit 0
        fi

        # Read secrets from SOPS-managed files
        USERNAME=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."qbittorrent/webui/username".path})
        PASSWORD=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."qbittorrent/webui/password".path})

        # Use sed to update config file with actual secret values
        ${pkgs.gnused}/bin/sed -i \
          -e "s|^WebUI\\\\Username=.*|WebUI\\\\Username=$USERNAME|" \
          -e "s|^WebUI\\\\Password_PBKDF2=.*|WebUI\\\\Password_PBKDF2=$PASSWORD|" \
          "$CONFIG_FILE"

        echo "Injected SOPS credentials into qBittorrent config"
      '';
    })
  ];

  services.qbittorrent = {
    enable = true;
    # Run qBittorrent with media group for file access
    user = "qbittorrent";
    group = "media";
    webuiPort = if webUI != null then webUI.port else constants.ports.services.qbittorrent;
    torrentingPort = qbittorrentCfg.torrentPort;
    # Add --confirm-legal-notice flag to prevent service from exiting
    extraArgs = [ "--confirm-legal-notice" ];
    openFirewall = false; # Firewall handled explicitly above
    serverConfig = {
      Preferences = preferencesCfg;

      # Application configuration
      Application = {
        MemoryWorkingSetLimit = qbittorrentCfg.physicalMemoryLimit;
      };

      # Network configuration
      # PortForwardingEnabled is the master switch for UPnP/NAT-PMP in the WebUI
      # When VPN is enabled, disable port forwarding (handled by external NAT-PMP service)
      # When VPN is disabled, enable port forwarding for local router
      Network = {
        PortForwardingEnabled = if (qbittorrentCfg.vpn.enable or false) then false else true;
      };

      # BitTorrent configuration
      BitTorrent = {
        Session = bittorrentSession;
      };
    }
    # Core configuration - at same level as BitTorrent and Preferences
    // optionalAttrs (qbittorrentCfg.deleteTorrentFilesAfterwards != "Never") {
      Core = {
        AutoDeleteAddedTorrentFile = qbittorrentCfg.deleteTorrentFilesAfterwards;
      };
    }
    // optionalAttrs (qbittorrentCfg.categories != null) {
      Category = mapAttrs (_: path: {
        SavePath = path;
      }) qbittorrentCfg.categories;
    };
  };
}
