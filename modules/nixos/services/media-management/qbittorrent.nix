{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    types
    optionalAttrs
    mapAttrs
    ;
  cfg = config.host.services.mediaManagement;
  qbittorrentCfg = cfg.qbittorrent;
  inherit (qbittorrentCfg) webUI;
in
{
  options.host.services.mediaManagement.qbittorrent = {
    enable = mkEnableOption "qBittorrent BitTorrent client" // {
      default = true;
    };

    webUI = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            username = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "WebUI username (plain text or SOPS secret path)";
            };
            password = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "WebUI password (PBKDF2 format, plain text or SOPS secret path)";
            };
            useSops = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to use SOPS secrets for WebUI credentials";
            };
            port = mkOption {
              type = types.port;
              default = constants.ports.services.qbittorrent;
              description = "WebUI port";
            };
            bindAddress = mkOption {
              type = types.str;
              default = "*";
              description = "WebUI bind address (* for all interfaces, or specific IP)";
            };
            alternativeUIEnabled = mkOption {
              type = types.bool;
              default = false;
              description = "Enable alternative WebUI (e.g., vuetorrent)";
            };
            rootFolder = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Root folder for alternative WebUI (absolute path). If null and alternativeUIEnabled is true, uses vuetorrent from Nix store";
            };
          };
        }
      );
      default = null;
      description = "WebUI configuration";
    };

    categories = mkOption {
      type = types.nullOr (types.attrsOf types.str);
      default = null;
      description = "Category save paths";
    };

    diskCacheSize = mkOption {
      type = types.int;
      default = 512;
      description = ''
        Disk cache size in MiB.
        - 0 = disabled
        - -1 = auto (qBittorrent decides)
        - >0 = fixed size in MiB
        Recommended: 512-1024 MiB for HDD-heavy setups with SSD incomplete staging.
      '';
    };

    diskCacheTTL = mkOption {
      type = types.int;
      default = 60;
      description = "Disk cache TTL in seconds (how long to keep data in cache)";
    };

    incompleteDownloadPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Path to store incomplete downloads.
        Recommended: Fast SSD path (e.g., /mnt/nvme/qbittorrent/incomplete) for staging before Radarr/Sonarr moves to final location.
        Final download paths are configured per-category.
      '';
    };

    maxActiveTorrents = mkOption {
      type = types.int;
      default = 150;
      description = "Maximum active torrents (recommended: 150 for HDD-based storage to avoid saturation)";
    };

    maxActiveUploads = mkOption {
      type = types.int;
      default = 75;
      description = "Maximum active uploads (recommended: 75 to prevent HDD thrashing with Jellyfin streaming)";
    };

    maxUploads = mkOption {
      type = types.int;
      default = 300;
      description = "Maximum upload slots (recommended: 300 for better slot allocation across many torrents)";
    };

    maxUploadsPerTorrent = mkOption {
      type = types.int;
      default = 10;
      description = "Maximum upload slots per torrent (recommended: 10 to improve seeding)";
    };

    torrentPort = mkOption {
      type = types.port;
      default = 62000;
      description = "Port for BitTorrent traffic";
    };

    autoTMMEnabled = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic torrent management (AutoTMM)";
    };

    defaultSavePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default folder for completed torrents (when AutoTMM is disabled or no category is set)";
    };

    maxRatio = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "Maximum seeding ratio (0 = unlimited, >0 = ratio limit). When reached, MaxRatioAction is triggered";
    };

    maxRatioAction = mkOption {
      type = types.int;
      default = 0;
      description = "Action when max ratio is reached: 0 = pause torrent, 1 = remove torrent, 2 = remove torrent with files";
    };

    uploadSpeedLimit = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Upload speed limit in KB/s (recommended: ~80% of upload capacity).
        Set to null for unlimited. Use speedtest.net to determine your upload speed in kB/s,
        then set this to approximately 80% of that value to allow room for outgoing communications.
      '';
    };

    addToTopOfQueue = mkOption {
      type = types.bool;
      default = false;
      description = "Add new torrents to the top of the queue";
    };

    preallocation = mkOption {
      type = types.bool;
      default = false;
      description = "Pre-allocate disk space for all files";
    };

    addExtensionToIncompleteFiles = mkOption {
      type = types.bool;
      default = false;
      description = "Append .!qB extension to incomplete files";
    };

    useCategoryPathsInManualMode = mkOption {
      type = types.bool;
      default = false;
      description = "Use category paths even in manual torrent management mode";
    };

    deleteTorrentFilesAfterwards = mkOption {
      type = types.enum [
        "Never"
        "Always"
        "IfAdded"
      ];
      default = "Never";
      description = ''
        Delete .torrent files after adding:
        - Never: Keep torrent files
        - Always: Always delete torrent files
        - IfAdded: Delete if torrent was successfully added
      '';
    };
  };

  config = mkIf (cfg.enable && qbittorrentCfg.enable) {
    # Firewall configuration
    # When VPN is enabled, only WebUI port needs to be open on host
    # When VPN is disabled, both WebUI and torrent ports need to be open
    networking.firewall = {
      allowedTCPPorts = [
        (if webUI != null then webUI.port else constants.ports.services.qbittorrent)
      ] # WebUI always accessible
      ++ lib.optionals (!(qbittorrentCfg.vpn.enable or false)) [
        qbittorrentCfg.torrentPort # Torrent port only when VPN disabled
      ];
      allowedUDPPorts = lib.optionals (!(qbittorrentCfg.vpn.enable or false)) [
        qbittorrentCfg.torrentPort # Torrent port only when VPN disabled
      ];
    };

    # SOPS secrets for WebUI credentials
    sops.secrets = mkIf (webUI != null && webUI.useSops) {
      "qbittorrent/webui/username" = {
        neededForUsers = true;
      };
      "qbittorrent/webui/password" = {
        neededForUsers = true;
      };
    };

    # Set umask for qBittorrent service to ensure group-writable files
    systemd.services.qbittorrent.serviceConfig.UMask = "0002";

    # Alternative UI support (vuetorrent)
    # No need to copy files - qBittorrent can read directly from Nix store
    environment.systemPackages = lib.optionals (webUI != null && webUI.alternativeUIEnabled) [
      pkgs.vuetorrent
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
      serverConfig =
        let
          # Build WebUI config cleanly
          webUICfg =
            if webUI != null then
              mkMerge [
                {
                  Address = webUI.bindAddress;
                  Port = webUI.port;
                  HostHeaderValidation = false;
                  LocalHostAuth = false;
                  AlternativeUIEnabled = webUI.alternativeUIEnabled;
                }
                (optionalAttrs (webUI.alternativeUIEnabled && webUI.rootFolder == null) {
                  RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
                })
                (optionalAttrs (webUI.rootFolder != null) {
                  RootFolder = webUI.rootFolder;
                })
                (optionalAttrs (webUI.username != null) {
                  Username =
                    if webUI.useSops then config.sops.secrets."qbittorrent/webui/username".path else webUI.username;
                })
                (optionalAttrs (webUI.password != null) {
                  Password_PBKDF2 =
                    if webUI.useSops then config.sops.secrets."qbittorrent/webui/password".path else webUI.password;
                })
              ]
            else
              { };

          # Build Preferences with optional fields
          # Note: Modern qBittorrent uses Session\ prefixed keys in [BitTorrent] section
          # This section only needs WebUI config and AutoTMM, plus optional path/ratio settings
          preferencesCfg = {
            AutoTMMEnabled = qbittorrentCfg.autoTMMEnabled;
            WebUI = webUICfg;
          }
          // optionalAttrs (qbittorrentCfg.incompleteDownloadPath != null) {
            SavePath = qbittorrentCfg.incompleteDownloadPath;
          }
          // optionalAttrs (qbittorrentCfg.defaultSavePath != null) {
            DefaultSavePath = qbittorrentCfg.defaultSavePath;
          }
          // optionalAttrs (qbittorrentCfg.uploadSpeedLimit != null) {
            GlobalMaxUploadSpeed = qbittorrentCfg.uploadSpeedLimit;
          }
          // optionalAttrs (qbittorrentCfg.maxRatio != null) {
            MaxRatio = qbittorrentCfg.maxRatio;
            MaxRatioAction = qbittorrentCfg.maxRatioAction;
          };
        in
        {
          Preferences = preferencesCfg;
          # BitTorrent configuration
          BitTorrent = {
            Session = {
              Port = qbittorrentCfg.torrentPort;

              # Automatic port forwarding (disabled in VPN mode)
              # When VPN is enabled, UPnP and NAT-PMP are disabled because:
              # 1. VPN gateways don't support these protocols
              # 2. External NAT-PMP automation (protonvpn-portforward.service) handles port forwarding
              # 3. This prevents "no router found" errors in logs
              # When VPN is disabled, enable UPnP for automatic port forwarding on local router
              UseUPnP = if (qbittorrentCfg.vpn.enable or false) then false else true;
              UseNATPMP = if (qbittorrentCfg.vpn.enable or false) then false else true;

              # Protocol settings
              UsePEX = true; # Peer exchange for better peer discovery
              UseDHT = true; # DHT for trackerless torrents
              UseLSD = true; # Local Peer Discovery - useful on LAN or extended network

              # Encryption: 0 = disabled, 1 = enabled (allow legacy), 2 = forced
              # Set to 1 (enabled, allow legacy) to thwart ISP interference and access larger peer pool
              BT_protocol = 1; # Encryption enabled, allow legacy connections

              # uTP/TCP mixed mode: Proportional balances both protocols
              # Prevents TCP from starving uTP connections
              uTPMixedMode = "Proportional";

              # Torrent queueing system
              QueueingSystemEnabled = true;
              # Maximum active uploads (optimized for HDD + Jellyfin streaming)
              MaxActiveUploads = qbittorrentCfg.maxActiveUploads;
              # Maximum active torrents (optimized for HDD capacity)
              MaxActiveTorrents = qbittorrentCfg.maxActiveTorrents;
              # Global maximum number of connections
              # Optimized: Reduced from 2000 to 600 to prevent router/gateway overload
              MaxConnections = 600;
              # Maximum number of connections per torrent
              # Optimized: Reduced from 200 to 80 for better peer management
              MaxConnectionsPerTorrent = 80;
              # Global maximum number of upload slots (optimized for balanced seeding)
              # Increased default to 300 for better slot allocation across many torrents
              MaxUploads = qbittorrentCfg.maxUploads;
              # Maximum number of upload slots per torrent (improved from 5 to 10)
              MaxUploadsPerTorrent = qbittorrentCfg.maxUploadsPerTorrent;

              # Additional torrent behavior settings
              AddTorrentToTopOfQueue = qbittorrentCfg.addToTopOfQueue;
              Preallocation = qbittorrentCfg.preallocation;
              AddExtensionToIncompleteFiles = qbittorrentCfg.addExtensionToIncompleteFiles;
              UseCategoryPathsInManualMode = qbittorrentCfg.useCategoryPathsInManualMode;
            }
            # VPN Interface binding - ONLY when VPN is enabled
            # This ensures all BitTorrent traffic uses the VPN interface
            // optionalAttrs (qbittorrentCfg.vpn.enable or false) {
              Interface = "qbt0";
              InterfaceName = "qbt0";
              InterfaceAddress = "10.2.0.2";
            }
            # Add DefaultSavePath to Session if configured
            // optionalAttrs (qbittorrentCfg.defaultSavePath != null) {
              DefaultSavePath = qbittorrentCfg.defaultSavePath;
            };
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

  };
}
