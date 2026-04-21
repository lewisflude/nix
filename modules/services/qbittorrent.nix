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
      ...
    }@nixosArgs:
    let
      namespace = "qbt";
      torrentPort = 62000;
      webuiPort = constants.ports.services.qbittorrent;

      # BitTorrent session configuration
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
        # Enable peer exchange and DHT (auto-disabled for private torrents)
        UsePEX = true;
        UseDHT = true;
        # TCP+uTP: avoids TCP-only stalling bugs over VPN, reaches uTP-only peers.
        # WireGuard is UDP-based so no TCP-over-TCP meltdown risk.
        BTProtocol = "TCP and uTP";
        uTPMixedMode = 0; # prefer_tcp: don't throttle TCP when uTP detects congestion
        Encryption = 0; # Prefer (not Force) — VPN provides real encryption
        AnonymousMode = false;
        AddTrackersEnabled = false;
        # Queue settings: unlimited active uploads/torrents so all can seed.
        # IgnoreSlowTorrents handles idle ones naturally.
        QueueingSystemEnabled = true;
        MaxActiveDownloads = 5;
        MaxActiveUploads = -1;
        MaxActiveTorrents = -1;
        # Connection limits tuned for 100 Mbps upload
        MaxConnections = 500;
        MaxConnectionsPerTorrent = 100;
        MaxUploads = 200; # ~60 KB/s per slot at full upload
        MaxUploadsPerTorrent = 10;
        # Performance
        AddTorrentToTopOfQueue = true;
        Preallocation = false; # Required: ZFS CoW makes preallocation wasteful
        AddExtensionToIncompleteFiles = true;
        UseCategoryPathsInManualMode = true;
        SaveResumeDataInterval = 15;
        SuggestMode = false; # Ineffective in libtorrent v2 (no managed disk cache)
        AnnounceToAllTrackers = true;
        ReannounceWhenAddressChanged = true;
        ConnectionSpeed = 30; # Outgoing connections/sec (libtorrent default, qbt defaults to 20)
        # I/O: POSIX mode avoids ZFS ARC memory leak with mmap
        DiskIOType = 2; # 0=default, 1=mmap, 2=POSIX
        AsyncIOThreadsCount = 10; # 32 causes HDD thrashing; NVMe handles parallelism in hardware
        HashingThreadsCount = 4; # v2 ties hashing to disk reads; 8 thrashes HDDs on recheck
        FilePoolSize = 5000; # Leave headroom for socket FDs
        CheckingMemUsageSize = 512; # MiB — faster rechecks, plenty of RAM available
        # Send buffer tuning for 100 Mbps upload throughput
        SendBufferWatermark = 2048; # KiB
        SendBufferLowWatermark = 32; # KiB
        SendBufferWatermarkFactor = 150; # Percent
        # Seeding behavior
        IgnoreLimitsOnLAN = true;
        AddTorrentStopped = false;
        IgnoreSlowTorrents = true;
        IgnoreSlowTorrentsForQueueing = true;
        SlowTorrentsDownloadRate = 10;
        SlowTorrentsUploadRate = 5;
        SlowTorrentsInactivityTimer = 60;
        MaxRatio = 2;
        MaxSeedingTime = 10080; # 7 days
        ShareLimitAction = "Remove";
        # VPN interface binding
        Interface = "${namespace}0";
        InterfaceName = "${namespace}0";
        InterfaceAddress = "10.2.0.2";
        DisableIPv6 = true;
      };
    in
    {
      boot.kernelModules = [ "tcp_bbr" ];

      # Kernel tuning for high-throughput networking
      boot.kernel.sysctl = {
        "net.core.rmem_default" = 262144;
        "net.core.wmem_default" = 262144;
        "net.core.rmem_max" = 33554432;
        "net.core.wmem_max" = 33554432;
        "net.ipv4.udp_rmem_min" = 16384;
        "net.ipv4.udp_wmem_min" = 16384;
        # TCP tuning for BitTorrent over WireGuard
        "net.ipv4.tcp_rmem" = "4096 131072 33554432";
        "net.ipv4.tcp_wmem" = "4096 16384 33554432";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_fin_timeout" = 15;
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
        wireguardConfigFile = nixosArgs.config.sops.secrets."vpn-confinement-qbittorrent".path;
        accessibleFrom = [ constants.networks.lan.primary ];
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

      # qBittorrent service with VPN confinement.
      # SOPS credentials are injected AFTER the upstream module's ExecStartPre
      # (which overwrites qBittorrent.conf from the Nix store on every start).
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
          ExecStartPre = lib.mkAfter [
            (pkgs.writeShellScript "qbittorrent-inject-credentials" ''
              set -eu
              config=/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
              username=$(cat ${nixosArgs.config.sops.secrets."qbittorrent/webui/username".path})
              password=$(cat ${nixosArgs.config.sops.secrets."qbittorrent/webui/password-pbkdf2".path})
              ${pkgs.gnused}/bin/sed -i \
                -e '/^WebUI\\Username=/d' \
                -e '/^WebUI\\Password_PBKDF2=/d' \
                -e "/^\[Preferences\]$/a WebUI\\\\Username=$username\nWebUI\\\\Password_PBKDF2=$password" \
                "$config"
            '')
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
          ExecStart = "${pkgs.iproute2}/bin/ip netns exec ${namespace} ${pkgs.iproute2}/bin/tc qdisc replace dev ${namespace}0 root cake bandwidth 100mbit overhead 78 mpu 64 flows besteffort";
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
            set -euo pipefail

            NAMESPACE="${namespace}"
            VPN_INTERFACE="${namespace}0"

            echo "Checking qBittorrent VPN binding..."

            if ! ${pkgs.systemd}/bin/systemctl is-active --quiet qbittorrent.service; then
              echo "INFO: qBittorrent is not running, skipping check"
              exit 0
            fi

            # Check namespace exists
            if ! ${pkgs.iproute2}/bin/ip netns list | grep -q "^$NAMESPACE"; then
              echo "ERROR: VPN namespace '$NAMESPACE' does not exist"
              echo "Restarting VPN namespace service..."
              ${pkgs.systemd}/bin/systemctl restart ${namespace}.service
              exit 0
            fi

            # Check WireGuard interface exists (WireGuard reports "state UNKNOWN" not "state UP")
            if ! ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iproute2}/bin/ip link show "$VPN_INTERFACE" 2>/dev/null | grep -qE "state (UP|UNKNOWN)"; then
              echo "ERROR: VPN interface '$VPN_INTERFACE' is not up in namespace '$NAMESPACE'"
              echo "Restarting VPN namespace service..."
              ${pkgs.systemd}/bin/systemctl restart ${namespace}.service
              exit 0
            fi

            # Check internet reachability through VPN
            VPN_IP=$(${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.curl}/bin/curl -s --max-time 10 https://api.ipify.org || echo "")
            if [ -z "$VPN_IP" ]; then
              echo "ERROR: Cannot reach internet through VPN namespace"
              echo "Restarting VPN namespace service..."
              ${pkgs.systemd}/bin/systemctl restart ${namespace}.service
              exit 0
            fi

            echo "VPN health check passed (IP: $VPN_IP)"
          '';
          StandardOutput = "journal";
          StandardError = "journal";
          SyslogIdentifier = "qbittorrent-vpn-health";
          TimeoutStartSec = "30s";
          PrivateTmp = false;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateNetwork = false;
        };
      };
    };
}
