# qBittorrent - BitTorrent client
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types concatStringsSep mapAttrsToList isBool isList toString map filterAttrs;
  inherit (lib.lists) optional;
  cfg = config.host.services.mediaManagement;

  # Generate qBittorrent configuration file from Nix options
  # Following the pattern from the article
  generateConfig = attrs:
    concatStringsSep "\n\n" (
      mapAttrsToList (
        section: keys: let
          lines = mapAttrsToList (
            key: value: "${key}=${
              if isBool value
              then
                (
                  if value
                  then "true"
                  else "false"
                )
              else if isList value
              then concatStringsSep ", " (map toString value)
              else toString value
            }"
          ) (filterAttrs (_: v: v != null) keys);
        in
          if lines == []
          then ""
          else "[${section}]\n" + concatStringsSep "\n" lines
      ) (filterAttrs (_: v: v != {}) attrs)
    );

  # Helper to get interfaceName
  # When VPN-Confinement is enabled, it handles routing automatically, so we don't need to set interfaceName
  interfaceNameValue =
    if cfg.qbittorrent.bittorrent.interfaceName != null
    then cfg.qbittorrent.bittorrent.interfaceName
    # VPN-Confinement handles routing via namespace, so no need to set interfaceName
    else null;

  # Check if VPN is enabled (needed for config generation)
  vpnEnabled = cfg.qbittorrent.vpn.enable;

  # Helper to get Connection\NetworkInterface value
  # When VPN-Confinement is enabled, bind to WireGuard interface name inside the namespace
  # (typically wg0). This creates a kill switch at the application level - if VPN disconnects,
  # qBittorrent can't access the internet because it's bound to the VPN interface.
  # VPN-Confinement provides network isolation at the system level, while this setting
  # provides an additional application-level kill switch.
  connectionNetworkInterfaceValue =
    if cfg.qbittorrent.connection.networkInterface != null
    then cfg.qbittorrent.connection.networkInterface
    else if vpnEnabled
    then cfg.qbittorrent.vpn.wireGuardInterfaceName
    else null;

  # Create the qBittorrent configuration file
  qbittorrentConf = pkgs.writeText "qBittorrent.conf" (generateConfig {
    BitTorrent = filterAttrs (_: v: v != null) {
      "Session\\BTProtocol" = cfg.qbittorrent.bittorrent.protocol;
      "Session\\Port" = cfg.qbittorrent.bittorrent.port;
      "Session\\GlobalDLSpeedLimit" = cfg.qbittorrent.bittorrent.globalDownloadSpeedLimit;
      "Session\\GlobalUPSpeedLimit" = cfg.qbittorrent.bittorrent.globalUploadSpeedLimit;
      "Session\\Interface" = cfg.qbittorrent.bittorrent.interface;
      "Session\\InterfaceName" = interfaceNameValue;
      "Session\\Preallocation" = cfg.qbittorrent.bittorrent.preallocation;
      "Session\\QueueingSystemEnabled" = cfg.qbittorrent.bittorrent.queueingEnabled;
      "Session\\MaxActiveDownloads" = cfg.qbittorrent.bittorrent.maxActiveDownloads;
      "Session\\MaxActiveTorrents" = cfg.qbittorrent.bittorrent.maxActiveTorrents;
      "Session\\MaxActiveUploads" = cfg.qbittorrent.bittorrent.maxActiveUploads;
      "Session\\DefaultSavePath" = cfg.qbittorrent.bittorrent.defaultSavePath;
      "Session\\DisableAutoTMMByDefault" = cfg.qbittorrent.bittorrent.disableAutoTMMByDefault;
      "Session\\DisableAutoTMMTriggers\\CategorySavePathChanged" =
        cfg.qbittorrent.bittorrent.disableAutoTMMTriggersCategorySavePathChanged;
      "Session\\DisableAutoTMMTriggers\\DefaultSavePathChanged" =
        cfg.qbittorrent.bittorrent.disableAutoTMMTriggersDefaultSavePathChanged;
      "Session\\ExcludedFileNamesEnabled" = cfg.qbittorrent.bittorrent.excludedFileNamesEnabled;
      "Session\\ExcludedFileNames" = cfg.qbittorrent.bittorrent.excludedFileNames;
      "Session\\FinishedTorrentExportDirectory" =
        cfg.qbittorrent.bittorrent.finishedTorrentExportDirectory;
      "Session\\SubcategoriesEnabled" = cfg.qbittorrent.bittorrent.subcategoriesEnabled;
      "Session\\TempPath" = cfg.qbittorrent.bittorrent.tempPath;
    };
    Core = filterAttrs (_: v: v != null) {
      "AutoDeleteAddedTorrentFile" = cfg.qbittorrent.core.autoDeleteTorrentFile;
    };
    Network = filterAttrs (_: v: v != null) {
      "PortForwardingEnabled" = cfg.qbittorrent.network.portForwardingEnabled;
    };
    Preferences = filterAttrs (_: v: v != null) {
      # WebUI must be explicitly enabled for the WebUI server to start
      "WebUI\\Enabled" = true;
      "WebUI\\LocalHostAuth" = cfg.qbittorrent.webUI.localHostAuth;
      "WebUI\\AuthSubnetWhitelist" = cfg.qbittorrent.webUI.authSubnetWhitelist;
      "WebUI\\AuthSubnetWhitelistEnabled" = cfg.qbittorrent.webUI.authSubnetWhitelistEnabled;
      "WebUI\\Username" = cfg.qbittorrent.webUI.username;
      "WebUI\\Port" = cfg.qbittorrent.webUI.port;
      "WebUI\\Address" =
        if cfg.qbittorrent.webUI.address != null
        then cfg.qbittorrent.webUI.address
        else
          (
            if vpnEnabled
            then "*"
            else null
          );
      "WebUI\\Password_PBKDF2" = cfg.qbittorrent.webUI.password;
      "WebUI\\CSRFProtection" = cfg.qbittorrent.webUI.csrfProtection;
      "WebUI\\ClickjackingProtection" = cfg.qbittorrent.webUI.clickjackingProtection;
      # Connection settings for VPN kill switch and network configuration
      "Connection\\NetworkInterface" = connectionNetworkInterfaceValue;
      "Connection\\NetworkInterfaceAddress" = cfg.qbittorrent.connection.networkInterfaceAddress;
      "Connection\\IPFilter\\Enabled" = cfg.qbittorrent.connection.ipFilterEnabled;
      "Connection\\PortRangeMin" = cfg.qbittorrent.connection.portRangeMin;
      "Connection\\UPnP" = cfg.qbittorrent.connection.upnp;
      "Connection\\DHTEnabled" = cfg.qbittorrent.connection.dhtEnabled;
      "Connection\\LSDEnabled" = cfg.qbittorrent.connection.lsdEnabled;
      "Connection\\PEXEnabled" = cfg.qbittorrent.connection.pexEnabled;
      "Bittorrent\\EnableAutoTMM" = cfg.qbittorrent.connection.enableAutoTMM;
    };
  });

  inherit (cfg.qbittorrent) configDir;
  # VPN namespace name (must match qbittorrent-vpn-confinement.nix)
  vpnNamespace = "qbittor"; # Max 7 chars for VPN-Confinement
in {
  options.host.services.mediaManagement.qbittorrent = {
    enable =
      mkEnableOption "qBittorrent BitTorrent client"
      // {
        default = true;
      };

    configDir = mkOption {
      type = types.str;
      default = "/var/lib/qbittorrent";
      description = "Directory where qBittorrent stores its configuration.";
    };

    package = mkPackageOption pkgs "qbittorrent" {};

    bittorrent = {
      protocol = mkOption {
        type = types.enum [
          "TCP"
          "UDP"
          "Both"
        ];
        default = "TCP";
        description = "BitTorrent protocol to use.";
      };

      port = mkOption {
        type = types.port;
        default = 6881;
        description = "Port for BitTorrent traffic.";
      };

      globalDownloadSpeedLimit = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global download speed limit in KB/s (0 for unlimited, null to not set).";
      };

      globalUploadSpeedLimit = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Global upload speed limit in KB/s (0 for unlimited, null to not set).";
      };

      interface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Network interface to bind to (IP address).";
      };

      interfaceName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Network interface name to bind to. Set automatically when VPN is enabled.";
      };

      preallocation = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Preallocate disk space for all files.";
      };

      queueingEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable torrent queueing.";
      };

      maxActiveDownloads = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of active downloads.";
      };

      maxActiveTorrents = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of active torrents.";
      };

      maxActiveUploads = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum number of active uploads.";
      };

      defaultSavePath = mkOption {
        type = types.nullOr types.str;
        default = "${cfg.dataPath}/torrents";
        description = "Default path for saving torrents.";
      };

      disableAutoTMMByDefault = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Disable automatic torrent management by default.";
      };

      disableAutoTMMTriggersCategorySavePathChanged = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Disable AutoTMM when category save path changes.";
      };

      disableAutoTMMTriggersDefaultSavePathChanged = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Disable AutoTMM when default save path changes.";
      };

      excludedFileNamesEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable file name exclusion filters.";
      };

      excludedFileNames = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "List of excluded file names.";
      };

      finishedTorrentExportDirectory = mkOption {
        type = types.nullOr types.str;
        default = "${cfg.dataPath}/torrents/complete";
        description = "Directory to export finished torrents.";
      };

      subcategoriesEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable subcategories.";
      };

      tempPath = mkOption {
        type = types.nullOr types.str;
        default = "${cfg.dataPath}/torrents/incomplete";
        description = "Temporary download path.";
      };
    };

    core = {
      autoDeleteTorrentFile = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Automatically delete .torrent files after adding.";
      };
    };

    network = {
      portForwardingEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable UPnP/NAT-PMP port forwarding.";
      };
    };

    webUI = {
      localHostAuth = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Require authentication for localhost connections.";
      };

      authSubnetWhitelist = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Subnet whitelist for authentication bypass (CIDR notation).";
      };

      authSubnetWhitelistEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable subnet whitelist for authentication.";
      };

      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI username.";
      };

      port = mkOption {
        type = types.port;
        default = 8083;
        description = "WebUI port.";
      };

      address = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI bind address. Use '*' or '0.0.0.0' to bind to all interfaces. Defaults to '*' when VPN is enabled.";
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI password (PBKDF2 hash).";
      };

      csrfProtection = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable CSRF protection.";
      };

      clickjackingProtection = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable clickjacking protection.";
      };
    };

    connection = {
      networkInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Network interface name to bind all torrent traffic to (e.g., 'wg0'). Creates a kill switch - if VPN disconnects, qBittorrent can't access the internet. Automatically set to WireGuard interface name when VPN is enabled.";
      };

      networkInterfaceAddress = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Network interface IP address to bind to (e.g., '10.x.x.x/32'). Optional - binding to interface name is generally safer as IP might change upon reconnection.";
      };

      ipFilterEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable built-in IP filtering. Requires manual management of blocklist in GUI or via another tool.";
      };

      portRangeMin = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = "Minimum port for BitTorrent connections. Recommended to set to specific port from VPN provider if port forwarding is enabled.";
      };

      upnp = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable UPnP/NAT-PMP port forwarding. Recommended to disable when using VPN provider's port forwarding feature.";
      };

      dhtEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable DHT (Distributed Hash Table). Disabling can improve privacy but may slow down finding peers on older/less popular torrents.";
      };

      lsdEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable LSD (Local Service Discovery). Disabling can improve privacy but may reduce peer discovery.";
      };

      pexEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable PEX (Peer Exchange). Disabling can improve privacy but may reduce peer discovery.";
      };

      enableAutoTMM = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Enable automatic torrent management. Disable if using a specific directory structure for downloads.";
      };
    };

    vpn = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VPN routing via network namespace.";
      };

      wireGuardInterfaceName = mkOption {
        type = types.str;
        default = "wg0";
        description = "WireGuard interface name inside the VPN namespace (e.g., 'wg0'). This is the interface that qBittorrent will bind to for the kill switch. Defaults to 'wg0' which is typical for VPN-Confinement.";
      };

      namespace = mkOption {
        type = types.str;
        default = "wg-qbittorrent";
        description = "Network namespace name for VPN isolation.";
      };

      vethHostIP = mkOption {
        type = types.str;
        default = "10.200.200.1/24";
        description = "IP address for veth-host interface.";
      };

      vethVPNIP = mkOption {
        type = types.str;
        default = "10.200.200.2/24";
        description = "IP address for veth-vpn interface.";
      };
    };
  };

  config = mkIf (cfg.enable && cfg.qbittorrent.enable) {
    # Create config directory and qBittorrent directories
    # qBittorrent expects its config at $XDG_CONFIG_HOME/qBittorrent/qBittorrent.conf
    # With XDG_CONFIG_HOME=${configDir}, that's ${configDir}/qBittorrent/qBittorrent.conf
    systemd.tmpfiles.rules =
      [
        "d '${configDir}' 0700 ${cfg.user} ${cfg.group} -"
        "d '${configDir}/qBittorrent' 0700 ${cfg.user} ${cfg.group} -"
        # Create qBittorrent directory in user home (qBittorrent expects this)
        "d '/var/lib/${cfg.user}/qBittorrent' 0755 ${cfg.user} ${cfg.group} -"
        "d '/var/lib/${cfg.user}/.config/qBittorrent' 0755 ${cfg.user} ${cfg.group} -"
        "d '/var/lib/${cfg.user}/.cache/qBittorrent' 0755 ${cfg.user} ${cfg.group} -"
        "d '/var/lib/${cfg.user}/.local/share/qBittorrent' 0755 ${cfg.user} ${cfg.group} -"
      ]
      # Create download directories if they have defaults
      ++ optional (
        cfg.qbittorrent.bittorrent.tempPath != null
      ) "d '${cfg.qbittorrent.bittorrent.tempPath}' 0775 ${cfg.user} ${cfg.group} -"
      ++ optional (cfg.qbittorrent.bittorrent.finishedTorrentExportDirectory != null)
      "d '${cfg.qbittorrent.bittorrent.finishedTorrentExportDirectory}' 0775 ${cfg.user} ${cfg.group} -";

    # Systemd service for qBittorrent
    systemd.services.qbittorrent = {
      description = "qBittorrent BitTorrent client";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      # VPN-Confinement integration
      # VPN-Confinement handles namespace setup automatically - no need to manually depend on a service
      vpnConfinement = lib.mkIf vpnEnabled {
        enable = true;
        inherit vpnNamespace;
      };

      preStart = ''
        # Copy configuration file only if it doesn't exist
        # This allows qBittorrent to manage the config file after initial setup
        # (saving WebUI preferences, session state, etc.)
        CONFIG_FILE="${configDir}/qBittorrent/qBittorrent.conf"
        if [ ! -f "$CONFIG_FILE" ]; then
          cp ${qbittorrentConf} "$CONFIG_FILE"
          chown ${cfg.user}:${cfg.group} "$CONFIG_FILE"
        fi
      '';

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        # VPN-Confinement handles namespace setup automatically via vpnConfinement option
        # No need to set NetworkNamespacePath manually
        ExecStart = "${lib.getExe cfg.qbittorrent.package} --webui-port=${toString cfg.qbittorrent.webUI.port}";
        Restart = "on-failure";
        RestartSec = "10s";

        # Security hardening - no need for CAP_SYS_ADMIN when using NetworkNamespacePath
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        # Don't protect home since we need to write to /var/lib/media for qBittorrent
        # Access is controlled via ReadWritePaths
        ProtectHome = false;
        # Create cache directory for qBittorrent (needed for Qt application cache)
        CacheDirectory = "qbittorrent";
        CacheDirectoryMode = "0755";
        # Allow access to config directory, data path, and user home
        ReadWritePaths = [
          configDir
          cfg.dataPath
          "/var/lib/${cfg.user}"
        ];
      };

      environment = {
        TZ = cfg.timezone;
        # Prevent Qt from trying to initialize GUI components
        QT_QPA_PLATFORM = "offscreen";
        DISPLAY = "";
        # Set XDG directories to use proper locations
        # qBittorrent expects config at $XDG_CONFIG_HOME/qBittorrent/qBittorrent.conf
        # So with XDG_CONFIG_HOME=${configDir}, config is at ${configDir}/qBittorrent/qBittorrent.conf
        XDG_CONFIG_HOME = "${configDir}";
        XDG_CACHE_HOME = "/var/cache/qbittorrent";
        XDG_DATA_HOME = "/var/lib/${cfg.user}";
      };
    };

    # Open firewall port only when VPN is disabled
    # When VPN is enabled, VPN-Confinement handles port mappings via veth interface
    networking.firewall.allowedTCPPorts = mkIf (!vpnEnabled) [cfg.qbittorrent.webUI.port];
  };
}
