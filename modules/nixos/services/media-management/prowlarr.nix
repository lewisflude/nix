# Prowlarr - Indexer manager
# Supports routing traffic through qBittorrent VPN via HTTP or SOCKS5 proxy (3proxy)
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
  prowlarrCfg = cfg.prowlarr;
  qbCfg = cfg.qbittorrent;

  # Check if qBittorrent VPN is enabled and proxies are available
  qbtVpnEnabled = cfg.enable && qbCfg.enable && qbCfg.vpn.enable;

  # Proxy configuration for Prowlarr
  # If VPN is enabled, use the VPN proxies; otherwise allow manual configuration
  proxyHost =
    if prowlarrCfg.useVpnProxy && qbtVpnEnabled
    then "127.0.0.1"
    else prowlarrCfg.proxyHost;

  proxyPort =
    if prowlarrCfg.useVpnProxy && qbtVpnEnabled
    then
      (
        if prowlarrCfg.proxyType == "socks5"
        then 1080
        else 8118
      )
    else prowlarrCfg.proxyPort;
in {
  options.host.services.mediaManagement.prowlarr = {
    enable =
      mkEnableOption "Prowlarr indexer manager"
      // {
        default = true;
      };

    useVpnProxy = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Use the qBittorrent VPN proxy (HTTP or SOCKS5). Requires qBittorrent VPN to be enabled.
        When enabled, automatically uses the VPN proxy at 127.0.0.1:8118 (HTTP) or 127.0.0.1:1080 (SOCKS5).
        This routes Prowlarr traffic through the same VPN as qBittorrent.
      '';
      example = true;
    };

    proxyType = mkOption {
      type = types.enum [
        "http"
        "socks5"
      ];
      default = "http";
      description = "Proxy type: 'http' for HTTP proxy or 'socks5' for SOCKS5 proxy (both via 3proxy).";
      example = "socks5";
    };

    proxyHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Proxy hostname or IP address. Ignored if useVpnProxy is true.";
      example = "127.0.0.1";
    };

    proxyPort = mkOption {
      type = types.nullOr types.port;
      default = null;
      description = "Proxy port. Ignored if useVpnProxy is true.";
      example = 8118;
    };

    proxyUsername = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Proxy username (if authentication is required).";
    };

    proxyPassword = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Proxy password (if authentication is required).";
    };

    proxyPasswordSecret = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the sops secret containing the proxy password. Used if proxyPassword is not set.";
      example = "prowlarr/proxy/password";
    };
  };

  config = mkIf (cfg.enable && cfg.prowlarr.enable) {
    assertions = [
      {
        assertion = !(prowlarrCfg.useVpnProxy && !qbtVpnEnabled);
        message = "Prowlarr useVpnProxy requires qBittorrent VPN to be enabled (host.services.mediaManagement.qbittorrent.vpn.enable = true).";
      }
      {
        assertion = !(prowlarrCfg.useVpnProxy && prowlarrCfg.proxyHost != null);
        message = "Prowlarr proxyHost is ignored when useVpnProxy is true.";
      }
      {
        assertion = !(prowlarrCfg.useVpnProxy && prowlarrCfg.proxyPort != null);
        message = "Prowlarr proxyPort is ignored when useVpnProxy is true.";
      }
      {
        assertion = !(prowlarrCfg.proxyPassword != null && prowlarrCfg.proxyPasswordSecret != null);
        message = "Only one of proxyPassword or proxyPasswordSecret may be set for Prowlarr.";
      }
      {
        assertion =
          !(prowlarrCfg.proxyPasswordSecret != null)
          || (
            config ? sops && config.sops ? secrets && config.sops.secrets ? "${prowlarrCfg.proxyPasswordSecret}"
          );
        message = "Prowlarr proxyPasswordSecret '${prowlarrCfg.proxyPasswordSecret}' is not defined under config.sops.secrets.";
      }
    ];

    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };

    # Run as common media user and set timezone
    systemd.services.prowlarr = mkMerge [
      {
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
        };
        environment = {
          TZ = cfg.timezone;
        };
      }
      # Configure proxy via environment variables if using VPN proxy
      (mkIf (prowlarrCfg.useVpnProxy && qbtVpnEnabled) {
        after = ["3proxy-qbvpn.service"];
        wants = ["3proxy-qbvpn.service"];
        environment = {
          HTTP_PROXY = mkIf (prowlarrCfg.proxyType == "http") "http://${proxyHost}:${toString proxyPort}";
          HTTPS_PROXY = mkIf (prowlarrCfg.proxyType == "http") "http://${proxyHost}:${toString proxyPort}";
          http_proxy = mkIf (prowlarrCfg.proxyType == "http") "http://${proxyHost}:${toString proxyPort}";
          https_proxy = mkIf (prowlarrCfg.proxyType == "http") "http://${proxyHost}:${toString proxyPort}";
          SOCKS_PROXY = mkIf (
            prowlarrCfg.proxyType == "socks5"
          ) "socks5://${proxyHost}:${toString proxyPort}";
          socks_proxy = mkIf (
            prowlarrCfg.proxyType == "socks5"
          ) "socks5://${proxyHost}:${toString proxyPort}";
          ALL_PROXY = mkIf (prowlarrCfg.proxyType == "socks5") "socks5://${proxyHost}:${toString proxyPort}";
          all_proxy = mkIf (prowlarrCfg.proxyType == "socks5") "socks5://${proxyHost}:${toString proxyPort}";
        };
      })
    ];

    # Note: Prowlarr proxy configuration is done via the web UI:
    # Settings > Indexers > Proxies > Add Proxy
    # - HTTP Proxy: http://127.0.0.1:8118 (when useVpnProxy = true and proxyType = "http")
    # - SOCKS5 Proxy: socks5://127.0.0.1:1080 (when useVpnProxy = true and proxyType = "socks5")
    # Both proxies are provided by 3proxy and route traffic through the qBittorrent VPN namespace
  };
}
