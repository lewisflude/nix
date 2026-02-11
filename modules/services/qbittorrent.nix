# qBittorrent Service Module - Dendritic Pattern
# Full qBittorrent service with VPN confinement and health checks
# Usage: Import flake.modules.nixos.qbittorrent in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.qbittorrent =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib) mkIf;
      namespace = "qbt";
      torrentPort = 62000;
      webuiPort = constants.ports.services.qbittorrent;

      # BitTorrent session configuration optimized for seeding
      bittorrentSession = {
        # Download paths: NVMe for incomplete (fast I/O), HDD for complete (capacity)
        DefaultSavePath = "/mnt/storage/torrents";
        TempPathEnabled = true;
        TempPath = "/var/lib/qbittorrent/incomplete";
        Port = torrentPort;
        # Disable auto port discovery when using VPN
        UseUPnP = false;
        UseNATPMP = false;
        UseLSD = false;
        # Enable peer exchange and DHT
        UsePEX = true;
        UseDHT = true;
        # Protocol settings (TRASHguides: TCP has superior performance)
        BTProtocol = "TCP";
        Encryption = 0; # TRASHguides: Prefer (not Force) encryption for better compatibility
        uTPMixedMode = "TCP";
        # TRASHguides: Disable anonymous mode for better speeds on private trackers
        AnonymousMode = false;
        # TRASHguides: Never auto-add external trackers (critical for private trackers)
        AddTrackersEnabled = false;
        # Queue settings
        QueueingSystemEnabled = true;
        MaxActiveDownloads = 3;
        MaxActiveUploads = 75;
        MaxActiveTorrents = 150;
        # Connection limits
        MaxConnections = 600;
        MaxConnectionsPerTorrent = 80;
        MaxUploads = 300;
        MaxUploadsPerTorrent = 10;
        # Performance
        AddTorrentToTopOfQueue = true;
        Preallocation = false;
        AddExtensionToIncompleteFiles = true;
        UseCategoryPathsInManualMode = true;
        SaveResumeDataInterval = 15;
        SuggestMode = true;
        AnnounceToAllTrackers = true;
        ReannounceWhenAddressChanged = true;
        # I/O optimization
        AsyncIOThreadsCount = 32;
        HashingThreadsCount = 8;
        FilePoolSize = 10000;
        DiskCacheSize = 4096;
        DiskCacheTTL = 60;
        CheckingMemUsageSize = 128;
        use_os_cache = true;
        # Seeding behavior
        IgnoreLimitsOnLAN = true;
        AddTorrentStopped = false;
        IgnoreSlowTorrents = true;
        IgnoreSlowTorrentsForQueueing = true;
        SlowTorrentsDownloadRate = 5;
        SlowTorrentsUploadRate = 5;
        SlowTorrentsInactivityTimer = 60;
        ShareLimitAction = "Stop";
        # VPN interface binding
        Interface = "${namespace}0";
        InterfaceName = "${namespace}0";
        InterfaceAddress = "10.2.0.2";
        DisableIPv6 = true;
      };
    in
    {
      # Kernel tuning for high-throughput networking
      boot.kernel.sysctl = {
        "net.core.rmem_default" = 262144;
        "net.core.wmem_default" = 262144;
        "net.core.rmem_max" = 33554432;
        "net.core.wmem_max" = 33554432;
        "net.ipv4.udp_rmem_min" = 16384;
        "net.ipv4.udp_wmem_min" = 16384;
      };

      environment.systemPackages = [
        pkgs.wireguard-tools
        pkgs.libnatpmp
        pkgs.iproute2
        pkgs.vuetorrent
      ];

      # Configure SOPS secrets
      sops.secrets."vpn-confinement-qbittorrent" = {
        restartUnits = [ "${namespace}.service" ];
      };

      # SOPS secrets for WebUI credentials
      sops.secrets."qbittorrent/webui/username" = {
        owner = "qbittorrent";
        group = "media";
        restartUnits = [ "qbittorrent.service" ];
      };
      sops.secrets."qbittorrent/webui/password-pbkdf2" = {
        owner = "qbittorrent";
        group = "media";
        restartUnits = [ "qbittorrent.service" ];
      };

      # nsswitch for namespace
      environment.etc."netns/${namespace}/nsswitch.conf".text = ''
        passwd:    files
        group:     files
        shadow:    files
        hosts:     files dns
        networks:  files
        ethers:    files
        services:  files
        protocols: files
        rpc:       files
      '';

      # VPN namespace configuration
      vpnNamespaces.${namespace} = {
        enable = true;
        wireguardConfigFile = config.sops.secrets."vpn-confinement-qbittorrent".path;
        accessibleFrom = [ "192.168.10.0/24" ];
        portMappings = [
          {
            from = webuiPort;
            to = 8080;
          }
        ];
        openVPNPorts = [
          {
            port = torrentPort;
            protocol = "both";
          }
        ];
      };

      # qBittorrent service
      services.qbittorrent = {
        enable = true;
        user = "qbittorrent";
        group = "media";
        webuiPort = 8080; # Internal port, mapped via VPN namespace
        torrentingPort = torrentPort;
        openFirewall = false; # Handled by VPN namespace
        serverConfig = {
          Preferences = {
            WebUI = {
              LocalHostAuth = false; # Allow localhost API access without auth (secure: only accessible within VPN namespace)
            };
            AutoTMMEnabled = true;
            Advanced = {
              PhysicalMemoryLimit = 8192;
              SendUploadPieceSuggestions = true;
            };
          };
          Application.MemoryWorkingSetLimit = 8192;
          Network.PortForwardingEnabled = false;
          BitTorrent.Session = bittorrentSession;
        };
      };

      # User and group
      users.users.qbittorrent = {
        isSystemUser = true;
        group = "media";
        home = "/var/lib/qbittorrent";
        createHome = true;
      };

      # Ensure media group exists
      users.groups.media = { };

      # Ensure download directories exist with correct ownership
      systemd.tmpfiles.rules = [
        "d '/mnt/storage/torrents' 0770 qbittorrent media - -"
        # Category subdirectories (matching SABnzbd pattern)
        "d '/mnt/storage/torrents/movies' 0770 qbittorrent media - -"
        "d '/mnt/storage/torrents/tv' 0770 qbittorrent media - -"
        "d '/mnt/storage/torrents/music' 0770 qbittorrent media - -"
        "d '/var/lib/qbittorrent/incomplete' 0770 qbittorrent media - -"
      ];

      # qBittorrent service with VPN confinement
      systemd.services.qbittorrent = {
        vpnConfinement = {
          enable = true;
          vpnNamespace = namespace;
        };
        after = [ "mnt-storage.mount" ];
        requires = [ "mnt-storage.mount" ];
        wants = [ "network-online.target" ];
        unitConfig = {
          StartLimitBurst = 5;
          StartLimitIntervalSec = "5min";
        };
        serviceConfig = {
          UMask = "0002";
          CPUSchedulingPolicy = "batch";
          Nice = 5;
          IOSchedulingClass = "best-effort";
          IOSchedulingPriority = 5;
          Restart = "on-failure";
          RestartSec = "10s";
        };
        # Inject SOPS credentials into config under [Preferences] section
        preStart = mkIf (config.sops.secrets ? "qbittorrent/webui/username") ''
          CONFIG_FILE="/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"

          if [ -f "${config.sops.secrets."qbittorrent/webui/username".path}" ] && \
             [ -f "${config.sops.secrets."qbittorrent/webui/password-pbkdf2".path}" ]; then

            USERNAME=$(cat "${config.sops.secrets."qbittorrent/webui/username".path}")
            PASSWORD_HASH=$(cat "${config.sops.secrets."qbittorrent/webui/password-pbkdf2".path}")

            TEMP_FILE=$(mktemp)

            if [ -f "$CONFIG_FILE" ]; then
              # Strip existing credential lines, then insert them after [Preferences]
              INSERTED=false
              while IFS= read -r line; do
                # Skip old credential lines
                case "$line" in
                  "WebUI\\Username="*|"WebUI\\Password_PBKDF2="*) continue ;;
                esac
                echo "$line" >> "$TEMP_FILE"
                # Insert credentials right after [Preferences] header
                if [ "$line" = "[Preferences]" ] && [ "$INSERTED" = false ]; then
                  echo "WebUI\\Username=$USERNAME" >> "$TEMP_FILE"
                  echo "WebUI\\Password_PBKDF2=$PASSWORD_HASH" >> "$TEMP_FILE"
                  INSERTED=true
                fi
              done < "$CONFIG_FILE"

              # If no [Preferences] section existed, add one with credentials
              if [ "$INSERTED" = false ]; then
                echo "[Preferences]" >> "$TEMP_FILE"
                echo "WebUI\\Username=$USERNAME" >> "$TEMP_FILE"
                echo "WebUI\\Password_PBKDF2=$PASSWORD_HASH" >> "$TEMP_FILE"
              fi
            else
              echo "[Preferences]" > "$TEMP_FILE"
              echo "WebUI\\Username=$USERNAME" >> "$TEMP_FILE"
              echo "WebUI\\Password_PBKDF2=$PASSWORD_HASH" >> "$TEMP_FILE"
            fi

            # Atomic move
            mv "$TEMP_FILE" "$CONFIG_FILE"
            chown qbittorrent:media "$CONFIG_FILE"
            chmod 640 "$CONFIG_FILE"
          fi
        '';
      };

      # Configure routes for VPN namespace
      systemd.services."configure-qbt-routes" = {
        description = "Configure routes for qBittorrent VPN namespace";
        after = [ "qbittorrent.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${namespace} ${pkgs.iproute2}/bin/ip route add 10.2.0.0/16 dev ${namespace}0";
          SuccessExitStatus = [
            0
            2
          ];
        };
      };

      # Traffic control for fair queuing
      systemd.services."configure-qbt-qdisc" = {
        description = "Configure traffic control qdisc for qBittorrent WireGuard interface";
        after = [ "${namespace}.service" ];
        before = [ "qbittorrent.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = "yes";
          ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${namespace} ${pkgs.iproute2}/bin/tc qdisc replace dev ${namespace}0 root cake bandwidth 100mbit overhead 60 mpu 64";
          ExecStop = "${pkgs.iproute2}/bin/ip netns exec ${namespace} ${pkgs.iproute2}/bin/tc qdisc del dev ${namespace}0 root || true";
        };
      };

      # VPN Health Check Timer
      systemd.timers.qbittorrent-vpn-health = {
        description = "qBittorrent VPN Health Check Timer";
        wantedBy = [ "timers.target" ];
        after = [ "qbittorrent.service" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "2min";
          Persistent = true;
          RandomizedDelaySec = "30s";
          Unit = "qbittorrent-vpn-health.service";
        };
      };

      # VPN Health Check Service
      systemd.services.qbittorrent-vpn-health = {
        description = "Verify qBittorrent VPN Binding";
        after = [ "qbittorrent.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "check-qbt-vpn" ''
            #!/bin/sh
            set -euo pipefail

            NAMESPACE="${namespace}"
            VPN_INTERFACE="${namespace}0"

            echo "Checking qBittorrent VPN binding..."

            # Check if qBittorrent is running
            if ! ${pkgs.systemd}/bin/systemctl is-active --quiet qbittorrent.service; then
              echo "INFO: qBittorrent is not running, skipping check"
              exit 0
            fi

            # Check if VPN namespace exists
            if ! ${pkgs.iproute2}/bin/ip netns list | grep -q "^$NAMESPACE"; then
              echo "ERROR: VPN namespace '$NAMESPACE' does not exist"
              echo "Restarting qBittorrent service..."
              ${pkgs.systemd}/bin/systemctl restart qbittorrent.service
              exit 0
            fi

            # Check if VPN interface is up in the namespace
            if ! ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ip link show "$VPN_INTERFACE" 2>/dev/null | grep -q "state UP"; then
              echo "ERROR: VPN interface '$VPN_INTERFACE' is not up in namespace '$NAMESPACE'"
              echo "Restarting qBittorrent service..."
              ${pkgs.systemd}/bin/systemctl restart qbittorrent.service
              exit 0
            fi

            # Check if we can get external IP through VPN
            VPN_IP=$(${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.curl}/bin/curl -s --max-time 10 https://api.ipify.org || echo "")
            if [ -z "$VPN_IP" ]; then
              echo "ERROR: Cannot determine external IP through VPN namespace"
              echo "Restarting qBittorrent service..."
              ${pkgs.systemd}/bin/systemctl restart qbittorrent.service
              exit 0
            fi

            echo "✓ VPN health check passed"
            echo "  Namespace: $NAMESPACE"
            echo "  Interface: $VPN_INTERFACE"
            echo "  External IP: $VPN_IP"
          '';
          StandardOutput = "journal";
          StandardError = "journal";
          SyslogIdentifier = "qbittorrent-vpn-health";
          TimeoutStartSec = "30s";
          PrivateTmp = true;
          NoNewPrivileges = false;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateNetwork = false;
        };
      };
    };
}
