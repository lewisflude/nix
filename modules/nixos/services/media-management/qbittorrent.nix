{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    optionalAttrs
    mapAttrs
    ;
  cfg = config.host.services.mediaManagement;
  qbittorrentCfg = cfg.qbittorrent or { };
  # VPN namespace interface IP - VPN-Confinement typically assigns 192.168.15.1 to namespace interfaces
  vpnNamespaceIP = "192.168.15.1";
  # VPN WireGuard interface name and IP
  vpnInterfaceName = "qbittor0";
  vpnInterfaceIP = "10.2.0.2";
  webUI = qbittorrentCfg.webUI or null;
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
              description = "WebUI username";
            };
            password = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "WebUI password (PBKDF2 format)";
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
  };

  config = mkIf (cfg.enable && qbittorrentCfg.enable) {
    services.qbittorrent = {
      enable = true;
      inherit (cfg) user group;
      webuiPort = 8080;
      torrentingPort = 6881;
      openFirewall = false; # VPN namespace handles firewall
      serverConfig = {
        # Bind WebUI to VPN network namespace address (always use VPN IP, not "*")
        Preferences = {
          WebUI = {
            Address = vpnNamespaceIP;
            Port = 8080;
            # WebUI access control - allow access from default network namespace and local network
            HostHeaderValidation = false;
            LocalHostAuth = false;
          }
          // optionalAttrs (webUI != null && webUI.username != null) {
            Username = webUI.username;
          }
          // optionalAttrs (webUI != null && webUI.password != null) {
            Password_PBKDF2 = webUI.password;
          };
        };
        # Bind BitTorrent session to VPN interface
        BitTorrent = {
          Session = {
            Interface = vpnInterfaceName;
            InterfaceAddress = vpnInterfaceIP;
            InterfaceName = vpnInterfaceName;
          };
        };
      }
      // optionalAttrs (qbittorrentCfg.categories != null) {
        Category = mapAttrs (_: path: {
          SavePath = path;
        }) qbittorrentCfg.categories;
      };
    };

    systemd.services.qbittorrent = {
      vpnConfinement = {
        enable = true;
        vpnNamespace = "qbittor";
      };
    };
  };
}
