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
    ;
  cfg = config.host.services.mediaManagement;
  qbittorrentCfg = cfg.qbittorrent or { };
  # VPN namespace interface IP - VPN-Confinement typically assigns 192.168.15.1 to namespace interfaces
  vpnNamespaceIP = "192.168.15.1";
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
            address = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "WebUI bind address";
            };
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

  config = mkIf (cfg.enable && qbittorrentCfg.enable) (
    let
      baseConfig = {
        # Bind WebUI to VPN network namespace address (always use VPN IP, not "*")
        "WebUI\\Address" = vpnNamespaceIP;
        "WebUI\\Port" = 8080;

        # WebUI access control - allow access from default network namespace and local network
        "WebUI\\HostHeaderValidation" = false;
        "WebUI\\LocalHostAuth" = false;
      };

      webUIConfig = lib.optionalAttrs (qbittorrentCfg.webUI != null) (
        lib.optionalAttrs (qbittorrentCfg.webUI.username != null) {
          "WebUI\\Username" = qbittorrentCfg.webUI.username;
        }
        // lib.optionalAttrs (qbittorrentCfg.webUI.password != null) {
          "WebUI\\Password_PBKDF2" = qbittorrentCfg.webUI.password;
        }
      );

      categoriesConfig =
        if qbittorrentCfg.categories != null then
          builtins.listToAttrs (
            lib.mapAttrsToList (name: path: {
              name = "Category\\${name}\\SavePath";
              value = path;
            }) qbittorrentCfg.categories
          )
        else
          { };

      serverConfig = baseConfig // webUIConfig // categoriesConfig;
    in
    {
      services.qbittorrent = {
        enable = true;
        inherit (cfg) user;
        inherit (cfg) group;
        webuiPort = 8080;
        torrentingPort = 6881;
        openFirewall = false; # VPN namespace handles firewall
        inherit serverConfig;
      };

      systemd.services.qbittorrent = {
        environment = {
          TZ = cfg.timezone;
        };

        preStart = ''
          mkdir -p ${cfg.dataPath}/torrents/complete || true
          mkdir -p ${cfg.dataPath}/torrents/incomplete || true

          chown -R ${cfg.user}:${cfg.group} ${cfg.dataPath}/torrents 2>/dev/null || true
          chmod -R 775 ${cfg.dataPath}/torrents 2>/dev/null || true
        '';

        serviceConfig = {
          ProtectSystem = false;
          ProtectHome = false;
        };

        # VPN Confinement configuration
        vpnConfinement = {
          enable = true;
          vpnNamespace = "qbittor";
        };
      };
    }
  );
}
