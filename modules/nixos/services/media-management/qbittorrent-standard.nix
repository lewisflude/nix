# Standard NixOS qBittorrent service with VPN-Confinement integration
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.services.mediaManagement;
  vpnEnabled = cfg.enable && cfg.qbittorrent.enable && cfg.qbittorrent.vpn.enable;

  # VPN namespace name (limited to 7 characters by VPN-Confinement)
  vpnNamespace = "qbittor"; # Max 7 chars, shortened from qbittorrent
  # Standard NixOS module defaults to 8080, but we allow override via config
  webUIPort = cfg.qbittorrent.webUI.port or 8080;
  torrentingPort = (cfg.qbittorrent.bittorrent or {}).port or 6881;
in {
  # Define options for compatibility with bridge module
  options.host.services.mediaManagement.qbittorrent = {
    enable =
      mkEnableOption "qBittorrent BitTorrent client"
      // {
        default = true;
      };

    webUI = {
      port = mkOption {
        type = types.port;
        default = 8080; # Match standard NixOS module default
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
      default = {};
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
    # Add qbittorrent user to media group to allow writing to media-owned directories
    users.users.qbittorrent.extraGroups = [cfg.group];

    # Ensure profile directory and subdirectories exist with correct permissions
    # Use media group so qbittorrent can write when running with Group=media
    systemd.tmpfiles.rules = [
      "d /var/lib/qBittorrent 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/config 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/data 0755 qbittorrent ${cfg.group} -"
      "d /var/lib/qBittorrent/logs 0755 qbittorrent ${cfg.group} -"
    ];

    # Enable standard NixOS qBittorrent service
    services.qbittorrent = {
      enable = true;
      openFirewall = !vpnEnabled; # VPN-Confinement handles firewall when VPN is enabled
      webuiPort = webUIPort;
      inherit torrentingPort;
      # Use the standard profile directory
      profileDir = "/var/lib/qBittorrent";

      # Configure additional settings via serverConfig
      # Note: webuiPort and torrentingPort are handled by the module options above
      serverConfig = {
        LegalNotice.Accepted = true;

        # Core settings
        Core = {
          # Auto-delete .torrent file after adding (from guide: personal preference, but useful)
          AutoDeleteAddedTorrentFile = true;
        };

        # Network settings
        Network = {
          # Enable UPnP/NAT-PMP port forwarding
          # This allows qBittorrent to automatically configure port forwarding on supported routers/VPNs
          PortForwardingEnabled = true;
        };

        Preferences = {
          WebUI =
            {
              Enabled = true; # Explicitly enable WebUI
              Port = webUIPort; # Explicitly set port in config to match webuiPort option
              Address =
                if cfg.qbittorrent.webUI.address != null
                then cfg.qbittorrent.webUI.address
                else
                  (
                    if vpnEnabled
                    then "*"
                    else null
                  );
            }
            // optionalAttrs (cfg.qbittorrent.webUI.username != null) {
              Username = cfg.qbittorrent.webUI.username;
            }
            // optionalAttrs (cfg.qbittorrent.webUI.password != null) {
              Password_PBKDF2 = cfg.qbittorrent.webUI.password;
            }
            // {
              # Enable VueTorrent as alternative WebUI
              AlternativeUIEnabled = true;
              RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
              # Disable CSRF protection (can cause issues per guide)
              CSRFProtection = false;
            };

          # Downloads settings (from guide recommendations)
          Downloads = {
            # Pre-allocate disk space (recommended to limit fragmentation)
            Preallocation = true;
            # Use subcategories (for better organization)
            SubcategoriesEnabled = true;
            # Automatic Torrent Management enabled (DisableAutoTMMByDefault = false means ATM is enabled)
            DisableAutoTMMByDefault = false;
            # Save resume data when category save path changes
            DisableAutoTMMTriggersCategorySavePathChanged = false;
            # Save resume data when default save path changes
            DisableAutoTMMTriggersDefaultSavePathChanged = false;
          };

          # Connection/Rate Limits settings (from guide recommendations)
          Connection = {
            # uTP rate limit (prevents flooding)
            uTP_rate_limit_enabled = true;
            # Apply rate limit to transport overhead (disable for best speeds)
            Bittorrent_rate_limit_utp = false;
            # Apply rate limit to peers on LAN (enable to limit LAN traffic)
            LimitLANPeers = true;
          };

          # BitTorrent privacy settings (from guide recommendations)
          Bittorrent = {
            # Encryption mode: "Allow encryption" (not enforce) for better peer connectivity
            Encryption = 1; # 0=prefer, 1=allow, 2=require
            # Anonymous mode disabled (can cause worse speeds and issues with private trackers)
            AnonymousMode = false;
          };

          # Seeding limits (from guide: disabled, managed by Starr apps instead)
          Queueing = {
            # Maximum ratio (disabled)
            MaxRatio = -1;
            # Maximum seeding time (disabled)
            MaxSeedingTime = -1;
            # When ratio/time reached: Paused and Disabled
            MaxRatioAction = 3; # 0=none, 1=pause, 2=remove, 3=pause and disable
          };
        };

        # BitTorrent session settings
        BitTorrent = {
          Session =
            {
              DefaultSavePath = "${cfg.dataPath}/torrents";
              TempPath = "${cfg.dataPath}/torrents/incomplete";
              FinishedTorrentExportDirectory = "${cfg.dataPath}/torrents/complete";
              BTProtocol = (cfg.qbittorrent.bittorrent or {}).protocol or "TCP";
              # Pre-allocate disk space (from guide: recommended)
              Preallocation = true;
              # Use subcategories (from guide: recommended)
              SubcategoriesEnabled = true;
            }
            // (
              # Bind to VPN interface when VPN is enabled
              # This ensures all traffic (including UDP tracker announces) goes through the VPN
              # VPN-Confinement creates the WireGuard interface as "qbittor0" in the namespace
              # This corresponds to Options > Advanced > Network Interface in qBittorrent WebUI
              if vpnEnabled
              then {
                InterfaceName = "qbittor0";
              }
              else {}
            );
        };

        # Category path mappings
        # qBittorrent config format: Category\CategoryName\SavePath=/path/to/save
        # NixOS module converts nested attrsets to backslash-separated keys
        Category = mapAttrs (_: path: {
          SavePath = path;
        }) (cfg.qbittorrent.categories or {});
      };
    };

    # VPN-Confinement integration and directory setup for standard qBittorrent service
    systemd.services.qbittorrent =
      {
        # Ensure directories have correct ownership before starting
        preStart =
          ''
            # Fix ownership if directories exist with wrong permissions
            # Use media group so qbittorrent can write when running with Group=media
            if [ -d /var/lib/qBittorrent ]; then
              chown -R qbittorrent:${cfg.group} /var/lib/qBittorrent || true
            fi
          ''
          + optionalString vpnEnabled ''
            # CRITICAL: Add route to ProtonVPN NAT-PMP gateway via WireGuard interface
            # VPN-Confinement's routing sends 10.2.0.1 through the bridge instead of WireGuard
            # This route ensures qBittorrent's built-in NAT-PMP client can reach the gateway
            # to detect and use the forwarded port. Without this, qBittorrent shows "firewalled"
            # and cannot receive incoming connections because it doesn't know the forwarded port.
            ${pkgs.iproute2}/bin/ip route add 10.2.0.1/32 dev qbittor0 2>/dev/null || true
          '';

        # Use media as primary group so qbittorrent can write to media-owned directories
        # This is necessary because mergerfs with default_permissions checks primary group
        # Use mkOverride to ensure this takes precedence over the standard module's Group setting
        serviceConfig.Group = mkOverride 1000 cfg.group;
      }
      // optionalAttrs vpnEnabled {
        after = ["network.target"];
        # VPN-Confinement integration
        # VPN-Confinement handles namespace setup automatically - no need to manually depend on a service
        vpnConfinement = {
          enable = true;
          inherit vpnNamespace;
        };
      };

    # Note: Per VPN-Confinement docs, ports in portMappings shouldn't be open on default netns
    # However, port 8080 may be used by other services, so we rely on VPN-Confinement's
    # port mapping to route traffic correctly. The standard module's openFirewall option
    # is already set to false when VPN is enabled, which prevents qBittorrent from opening
    # its own firewall rules.
  };
}
