{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalAttrs
    mapAttrs
    mkOverride
    optionalString
    ;
  cfg = config.host.services.mediaManagement;
  vpnEnabled = cfg.enable && cfg.qbittorrent.enable && cfg.qbittorrent.vpn.enable;

  vpnNamespace = "qbittor";

  webUIPort = cfg.qbittorrent.webUI.port or 8080;
  torrentingPort = (cfg.qbittorrent.bittorrent or { }).port or 6881;
in
{

  options.host.services.mediaManagement.qbittorrent = {
    enable = mkEnableOption "qBittorrent BitTorrent client" // {
      default = true;
    };

    webUI = {
      port = mkOption {
        type = types.port;
        default = 8080;
        description = "WebUI port.";
      };

      address = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI bind address. Use '*' or '0.0.0.0' to bind to all interfaces. Defaults to '*' when VPN is enabled.";
      };

      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI username.";
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "WebUI password (PBKDF2 hash).";
      };
    };

    bittorrent = {
      port = mkOption {
        type = types.port;
        default = 6881;
        description = "Port for BitTorrent traffic.";
      };

      protocol = mkOption {
        type = types.enum [
          "TCP"
          "UDP"
          "Both"
        ];
        default = "TCP";
        description = "BitTorrent protocol to use.";
      };
    };

    categories = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Category path mappings. Maps category names to their save paths. Example: { movies = \"/mnt/storage/movies\"; tv = \"/mnt/storage/tv\"; }";
      example = {
        movies = "/mnt/storage/movies";
        tv = "/mnt/storage/tv";
        music = "/mnt/storage/music";
      };
    };

    vpn = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VPN routing via network namespace.";
      };

      interfaceName = mkOption {
        type = types.str;
        default = "wg-mullvad";
        description = "WireGuard interface name for VPN routing.";
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

    users.users.qbittorrent.extraGroups = [ cfg.group ];

    systemd.tmpfiles.rules = [
      "d /var/lib/qBittorrent 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/config 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/data 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/logs 0755 qbittorrent ${cfg.group} -"
    ];

    services.qbittorrent = {
      enable = true;
      openFirewall = !vpnEnabled;
      webuiPort = webUIPort;
      inherit torrentingPort;

      profileDir = "/var/lib/qBittorrent";

      serverConfig = {
        LegalNotice.Accepted = true;

        Core = {

          AutoDeleteAddedTorrentFile = true;
        };

        Network = {

          PortForwardingEnabled = true;
        };

        Preferences = {
          WebUI = {
            Enabled = true;
            Port = webUIPort;
            Address =
              if cfg.qbittorrent.webUI.address != null then
                cfg.qbittorrent.webUI.address
              else
                (if vpnEnabled then "*" else null);
          }
          // optionalAttrs (cfg.qbittorrent.webUI.username != null) {
            Username = cfg.qbittorrent.webUI.username;
          }
          // optionalAttrs (cfg.qbittorrent.webUI.password != null) {
            Password_PBKDF2 = cfg.qbittorrent.webUI.password;
          }
          // {

            AlternativeUIEnabled = true;
            RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";

            CSRFProtection = false;
          };

          Downloads = {

            Preallocation = true;

            SubcategoriesEnabled = true;

            DisableAutoTMMByDefault = false;

            DisableAutoTMMTriggersCategorySavePathChanged = false;

            DisableAutoTMMTriggersDefaultSavePathChanged = false;
          };

          Connection = {

            uTP_rate_limit_enabled = true;

            Bittorrent_rate_limit_utp = false;

            LimitLANPeers = true;
          };

          Bittorrent = {

            Encryption = 1;

            AnonymousMode = false;
          };

          Queueing = {

            MaxRatio = -1;

            MaxSeedingTime = -1;

            MaxRatioAction = 3;
          };
        };

        BitTorrent = {
          Session = {
            DefaultSavePath = "${cfg.dataPath}/torrents";
            TempPath = "${cfg.dataPath}/torrents/incomplete";
            FinishedTorrentExportDirectory = "${cfg.dataPath}/torrents/complete";
            BTProtocol = (cfg.qbittorrent.bittorrent or { }).protocol or "TCP";

            Preallocation = true;

            SubcategoriesEnabled = true;
          }
          // (

            if vpnEnabled then
              {
                InterfaceName = "qbittor0";
              }
            else
              { }
          );
        };

        Category = mapAttrs (_: path: {
          SavePath = path;
        }) (cfg.qbittorrent.categories or { });
      };
    };

    systemd.services.qbittorrent = {

      preStart = ''


        if [ -d /var/lib/qBittorrent ]; then
          chown -R qbittorrent:${cfg.group} /var/lib/qBittorrent || true
        fi
      ''
      + optionalString vpnEnabled ''





        ${pkgs.iproute2}/bin/ip route add 10.2.0.1/32 dev qbittor0 2>/dev/null || true
      '';

      serviceConfig.Group = mkOverride 1000 cfg.group;
    }
    // optionalAttrs vpnEnabled {
      after = [ "network.target" ];

      vpnConfinement = {
        enable = true;
        inherit vpnNamespace;
      };
    };

  };
}
