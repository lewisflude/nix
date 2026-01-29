{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf mkMerge types optionalAttrs optionals mapAttrs;
  cfg = config.host.services.mediaManagement;
  qbt = cfg.qbittorrent;
  webUI = qbt.webUI;

  # Build WebUI config
  webUICfg = if webUI != null then mkMerge [
    {
      Address = webUI.bindAddress;
      Port = webUI.port;
      HostHeaderValidation = false;
      LocalHostAuth = false;
      AlternativeUIEnabled = webUI.alternativeUIEnabled;
      CSRFProtection = false;
      ServerDomains = "*";
    }
    (optionalAttrs (webUI.alternativeUIEnabled && webUI.rootFolder == null) {
      RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
    })
    (optionalAttrs (webUI.rootFolder != null) { RootFolder = webUI.rootFolder; })
    (optionalAttrs (webUI.username != null && !webUI.useSops) { Username = webUI.username; })
    (optionalAttrs (webUI.password != null && !webUI.useSops) { Password_PBKDF2 = webUI.password; })
  ] else {};

  # Preferences config
  preferencesCfg = {
    AutoTMMEnabled = true;
    WebUI = webUICfg;
    Advanced = {
      PhysicalMemoryLimit = qbt.physicalMemoryLimit;
      SendUploadPieceSuggestions = qbt.sendUploadPieceSuggestions;
    };
  }
  // optionalAttrs (qbt.incompleteDownloadPath != null) { SavePath = qbt.incompleteDownloadPath; }
  // optionalAttrs (qbt.defaultSavePath != null) { DefaultSavePath = qbt.defaultSavePath; }
  // optionalAttrs (qbt.uploadSpeedLimit != null) { GlobalMaxUploadSpeed = qbt.uploadSpeedLimit; }
  // optionalAttrs (qbt.maxRatio != null) { MaxRatio = qbt.maxRatio; };

  # BitTorrent Session config
  bittorrentSession = {
    Port = qbt.torrentPort;
    UseUPnP = if (qbt.vpn.enable or false) then false else true;
    UseNATPMP = if (qbt.vpn.enable or false) then false else true;
    UsePEX = true;
    UseDHT = true;
    UseLSD = if (qbt.vpn.enable or false) then false else true;
    BTProtocol = qbt.ipProtocol;
    Encryption = qbt.encryption;
    uTPMixedMode = qbt.utpTcpMixedMode;
    QueueingSystemEnabled = true;
    MaxActiveDownloads = qbt.maxActiveDownloads;
    MaxActiveUploads = qbt.maxActiveUploads;
    MaxActiveTorrents = qbt.maxActiveTorrents;
    MaxConnections = qbt.maxConnections;
    MaxConnectionsPerTorrent = qbt.maxConnectionsPerTorrent;
    MaxUploads = qbt.maxUploads;
    MaxUploadsPerTorrent = qbt.maxUploadsPerTorrent;
    AddTorrentToTopOfQueue = qbt.addToTopOfQueue;
    Preallocation = false;
    AddExtensionToIncompleteFiles = true;
    UseCategoryPathsInManualMode = true;
    SaveResumeDataInterval = 15;
    SuggestMode = qbt.sendUploadPieceSuggestions;
    AnnounceToAllTrackers = qbt.reannounceWhenAddressChanged;
    ReannounceWhenAddressChanged = qbt.reannounceWhenAddressChanged;
    AsyncIOThreadsCount = 32;
    HashingThreadsCount = 8;
    FilePoolSize = 10000;
    DiskCacheSize = 4096;
    DiskCacheTTL = 60;
    CheckingMemUsageSize = 128;
    use_os_cache = true;
    IgnoreLimitsOnLAN = qbt.ignoreLimitsOnLAN;
    AddTorrentStopped = qbt.addTorrentStopped;
    IgnoreSlowTorrents = qbt.ignoreSlowTorrents;
    IgnoreSlowTorrentsForQueueing = qbt.ignoreSlowTorrents;
    SlowTorrentsDownloadRate = 5;
    SlowTorrentsUploadRate = 5;
    SlowTorrentsInactivityTimer = 60;
    ShareLimitAction = qbt.shareLimitAction;
  }
  // optionalAttrs (qbt.maxRatio != null) { GlobalMaxRatio = qbt.maxRatio; }
  // optionalAttrs (qbt.maxInactiveSeedingTime != null) { GlobalMaxInactiveSeedingMinutes = qbt.maxInactiveSeedingTime; }
  // optionalAttrs (qbt.vpn.enable or false) {
    Interface = "qbt0";
    InterfaceName = "qbt0";
    InterfaceAddress = "10.2.0.2";
    DisableIPv6 = true;
  }
  // optionalAttrs (qbt.defaultSavePath != null) { DefaultSavePath = qbt.defaultSavePath; }
  // optionalAttrs (qbt.uploadSpeedLimit != null) { GlobalUPSpeedLimit = qbt.uploadSpeedLimit; };
in
{
  imports = [ ./vpn-health-check.nix ];

  options.host.services.mediaManagement.qbittorrent = {
    enable = mkEnableOption "qBittorrent BitTorrent client" // { default = true; };
    openFirewall = mkEnableOption "Open firewall ports for qBittorrent" // { default = true; };

    categories = mkOption {
      type = types.nullOr (types.attrsOf types.str);
      default = null;
      description = "Category save paths";
    };

    incompleteDownloadPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path for incomplete downloads";
    };

    defaultSavePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default folder for completed torrents";
    };

    maxRatio = mkOption {
      type = types.nullOr types.float;
      default = null;
      description = "Maximum seeding ratio";
    };

    maxInactiveSeedingTime = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Maximum inactive seeding time in minutes";
    };

    shareLimitAction = mkOption {
      type = types.enum [ "Stop" "Remove" "DeleteFiles" ];
      default = "Stop";
      description = "Action when share limits are reached";
    };

    uploadSpeedLimit = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Upload speed limit in KB/s";
    };

    webUI = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          username = mkOption { type = types.nullOr types.str; default = null; };
          password = mkOption { type = types.nullOr types.str; default = null; };
          useSops = mkOption { type = types.bool; default = false; };
          port = mkOption { type = types.port; default = constants.ports.services.qbittorrent; };
          bindAddress = mkOption { type = types.str; default = "*"; };
          alternativeUIEnabled = mkOption { type = types.bool; default = false; };
          rootFolder = mkOption { type = types.nullOr types.str; default = null; };
        };
      });
      default = null;
    };

    torrentPort = mkOption { type = types.port; default = 62000; };
    ipProtocol = mkOption { type = types.enum [ "IPv4" "IPv6" "Both" ]; default = "IPv4"; };
    encryption = mkOption { type = types.enum [ 0 1 2 ]; default = 1; };
    utpTcpMixedMode = mkOption { type = types.enum [ "TCP" "Proportional" ]; default = "TCP"; };
    maxConnections = mkOption { type = types.int; default = 600; };
    maxConnectionsPerTorrent = mkOption { type = types.int; default = 80; };
    maxActiveTorrents = mkOption { type = types.int; default = 150; };
    maxActiveDownloads = mkOption { type = types.int; default = 3; };
    maxActiveUploads = mkOption { type = types.int; default = 75; };
    maxUploads = mkOption { type = types.int; default = 300; };
    maxUploadsPerTorrent = mkOption { type = types.int; default = 10; };
    addToTopOfQueue = mkOption { type = types.bool; default = true; };
    addTorrentStopped = mkOption { type = types.bool; default = false; };
    reannounceWhenAddressChanged = mkOption { type = types.bool; default = true; };
    sendUploadPieceSuggestions = mkOption { type = types.bool; default = true; };
    ignoreLimitsOnLAN = mkOption { type = types.bool; default = true; };
    physicalMemoryLimit = mkOption { type = types.int; default = 8192; };
    ignoreSlowTorrents = mkOption { type = types.bool; default = true; };
  };

  config = mkIf (cfg.enable && qbt.enable) (mkMerge [
    # Firewall
    {
      networking.firewall = mkIf qbt.openFirewall {
        allowedTCPPorts = [
          (if webUI != null then webUI.port else constants.ports.services.qbittorrent)
        ] ++ optionals (!(qbt.vpn.enable or false)) [ qbt.torrentPort ];
        allowedUDPPorts = optionals (!(qbt.vpn.enable or false)) [ qbt.torrentPort ];
      };
    }

    # Service config
    {
      systemd.services.qbittorrent = {
        unitConfig = {
          StartLimitBurst = 5;
          StartLimitIntervalSec = "5min";
        };
        serviceConfig = mkMerge [
          {
            UMask = "0002";
            CPUSchedulingPolicy = "batch";
            Nice = 5;
            IOSchedulingClass = "best-effort";
            IOSchedulingPriority = 5;
            Restart = "on-failure";
            RestartSec = "10s";
          }
          (mkIf (webUI != null && webUI.useSops) {
            ExecStartPre = pkgs.writeShellScript "qbittorrent-inject-credentials" ''
              set -euo pipefail
              CONFIG_DIR="/var/lib/qbittorrent/.config/qBittorrent"
              CONFIG_FILE="$CONFIG_DIR/qBittorrent.conf"
              if [ ! -f "$CONFIG_FILE" ]; then
                echo "Config file not found, will be created on first run"
                exit 0
              fi
              USERNAME=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."qbittorrent/webui/username".path})
              PASSWORD=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."qbittorrent/webui/password".path})
              ${pkgs.gnused}/bin/sed -i \
                -e "s|^WebUI\\\\Username=.*|WebUI\\\\Username=$USERNAME|" \
                -e "s|^WebUI\\\\Password_PBKDF2=.*|WebUI\\\\Password_PBKDF2=$PASSWORD|" \
                "$CONFIG_FILE"
              echo "Injected SOPS credentials into qBittorrent config"
            '';
          })
        ];
      };

      services.qbittorrent = {
        enable = true;
        user = "qbittorrent";
        group = "media";
        webuiPort = if webUI != null then webUI.port else constants.ports.services.qbittorrent;
        torrentingPort = qbt.torrentPort;
        extraArgs = [ "--confirm-legal-notice" ];
        openFirewall = false;
        serverConfig = {
          Preferences = preferencesCfg;
          Application.MemoryWorkingSetLimit = qbt.physicalMemoryLimit;
          Network.PortForwardingEnabled = if (qbt.vpn.enable or false) then false else true;
          BitTorrent.Session = bittorrentSession;
        }
        // optionalAttrs (qbt.categories != null) {
          Category = mapAttrs (_: path: { SavePath = path; }) qbt.categories;
        };
      };
    }

    # SOPS secrets
    (mkIf (webUI != null && webUI.useSops) {
      sops.secrets = {
        "qbittorrent/webui/username" = {
          owner = "qbittorrent";
          group = "qbittorrent";
          mode = "0440";
        };
        "qbittorrent/webui/password" = {
          owner = "qbittorrent";
          group = "qbittorrent";
          mode = "0440";
        };
      };
    })

    # Alternative UI
    (mkIf (webUI != null && webUI.alternativeUIEnabled) {
      environment.systemPackages = [ pkgs.vuetorrent ];
    })
  ]);
}
