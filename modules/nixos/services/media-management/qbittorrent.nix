# qBittorrent module with VPN-Confinement integration
# Provides qBittorrent behind a WireGuard VPN with proxy access for other services
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  mediaLib = import ./lib.nix {inherit lib;};
  inherit (mediaLib) mkDirRule;

  cfg = config.host.services.mediaManagement;
  qbCfg = cfg.qbittorrent;
  vpnCfg = qbCfg.vpn;

  # State
  qbProfileDir = "/var/lib/qBittorrent";
  qbtEnabled = cfg.enable && qbCfg.enable;
  qbtVpnEnabled = qbtEnabled && vpnCfg.enable;
  wireguardConfigPath = "/run/qbittorrent-wg.conf";
  vpnNamespace =
    if (stringLength vpnCfg.namespace) <= 7
    then vpnCfg.namespace
    else "qbt";

  # Auto-enable proxy if explicitly enabled or if Prowlarr needs it
  proxyAutoEnabled =
    qbtVpnEnabled && (vpnCfg.proxy.enable || (cfg.prowlarr.enable && cfg.prowlarr.useVpnProxy));

  # Helper: Resolve secret path or return file path
  resolveSecretPath = secretName: filePath:
    if secretName != null
    then
      if config ? sops && config.sops ? secrets && config.sops.secrets ? "${secretName}"
      then config.sops.secrets."${secretName}".path
      else throw "Secret '${secretName}' is not defined under config.sops.secrets."
    else filePath;

  # Helper: Resolve VPN private key path
  vpnPrivateKeyFile =
    if !qbtVpnEnabled
    then null
    else resolveSecretPath vpnCfg.privateKeySecret vpnCfg.privateKeyFile;

  # Helper: Generate WireGuard config at runtime
  wireguardConfigScript =
    if !qbtVpnEnabled || vpnPrivateKeyFile == null
    then null
    else let
      formatPeer = peer: ''
        echo "[Peer]" >> "$CONFIG_FILE"
        echo "PublicKey = ${peer.publicKey}" >> "$CONFIG_FILE"
        ${optionalString (peer.endpoint != null) ''echo "Endpoint = ${peer.endpoint}" >> "$CONFIG_FILE"''}
        ${optionalString (
          peer.allowedIPs != []
        ) ''echo "AllowedIPs = ${concatStringsSep ", " peer.allowedIPs}" >> "$CONFIG_FILE"''}
        ${optionalString (
          peer.persistentKeepalive != null
        ) ''echo "PersistentKeepalive = ${toString peer.persistentKeepalive}" >> "$CONFIG_FILE"''}
        ${optionalString (
          peer.presharedKeyFile != null
        ) ''echo "PresharedKey = $(cat ${peer.presharedKeyFile})" >> "$CONFIG_FILE"''}
        echo "" >> "$CONFIG_FILE"
      '';
    in
      pkgs.writeShellScript "generate-qbt-wg-config" ''
        set -euo pipefail
        CONFIG_FILE="${wireguardConfigPath}"
        PRIVATE_KEY_FILE="${vpnPrivateKeyFile}"

        if [ ! -f "$PRIVATE_KEY_FILE" ]; then
          echo "Error: Private key file not found: $PRIVATE_KEY_FILE" >&2
          exit 1
        fi

        cat > "$CONFIG_FILE" <<EOF
        [Interface]
        PrivateKey = $(cat "$PRIVATE_KEY_FILE")
        ${optionalString (vpnCfg.addresses != []) "Address = ${concatStringsSep ", " vpnCfg.addresses}"}
        ${optionalString (vpnCfg.dns != []) "DNS = ${concatStringsSep ", " vpnCfg.dns}"}

        EOF

        ${concatStringsSep "\n" (map formatPeer vpnCfg.peers)}

        chmod 600 "$CONFIG_FILE"
      '';

  # Helper: Generate 3proxy config
  proxy3ConfigFile =
    if !proxyAutoEnabled
    then null
    else let
      passwordFile =
        if vpnCfg.proxy.auth.enable && vpnCfg.proxy.auth.passwordSecret != null
        then resolveSecretPath vpnCfg.proxy.auth.passwordSecret null
        else null;
      usersLine =
        if vpnCfg.proxy.auth.enable
        then
          if passwordFile != null
          then "users ${vpnCfg.proxy.auth.username}:CL:$(cat ${passwordFile})"
          else if vpnCfg.proxy.auth.password != null
          then "users ${vpnCfg.proxy.auth.username}:CL:${vpnCfg.proxy.auth.password}"
          else ""
        else "";
    in
      pkgs.writeText "3proxy.cfg" ''
        # 3proxy configuration for VPN namespace
        proxy -p${toString vpnCfg.proxy.httpPort}
        socks -p${toString vpnCfg.proxy.socksPort}

        ${usersLine}

        allow * * * ${toString vpnCfg.proxy.httpPort} * *
        allow * * * ${toString vpnCfg.proxy.socksPort} * *
      '';

  # Helper: Update qBittorrent credentials from secret
  qbCredsUpdateScript =
    if !qbtEnabled || qbCfg.webUiUsernameSecret == null || qbCfg.webUiPasswordHash == null
    then null
    else let
      usernameFile = config.sops.secrets."${qbCfg.webUiUsernameSecret}".path;
    in
      pkgs.writeShellScript "qbittorrent-update-creds" ''
        set -euo pipefail
        CONFIG_FILE="${qbProfileDir}/qBittorrent/config/qBittorrent.conf"
        USERNAME=$(cat "${usernameFile}")
        PASSWORD_HASH="${qbCfg.webUiPasswordHash}"

        if [ ! -f "$CONFIG_FILE" ]; then
          echo "Error: Config file not found: $CONFIG_FILE" >&2
          exit 1
        fi

        # Use awk to update or add credentials in [WebUI] section
        awk -v username="$USERNAME" -v password="$PASSWORD_HASH" '
          /^\[WebUI\]/ { in_section = 1; print; next }
          /^\[/ && !/^\[WebUI\]/ {
            if (in_section && !username_set) {
              print "Username=" username
              print "Password_PBKDF2=" password
              username_set = 1
            }
            in_section = 0
            print
            next
          }
          in_section && /^Username=/ {
            print "Username=" username
            username_set = 1
            next
          }
          in_section && /^Password_PBKDF2=/ {
            print "Password_PBKDF2=" password
            next
          }
          { print }
          END {
            if (in_section && !username_set) {
              print "Username=" username
              print "Password_PBKDF2=" password
            }
          }
        ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"

        # Add [WebUI] section if it doesn't exist
        if ! grep -q "^\[WebUI\]" "$CONFIG_FILE.tmp" 2>/dev/null; then
          echo "" >> "$CONFIG_FILE.tmp"
          echo "[WebUI]" >> "$CONFIG_FILE.tmp"
          echo "Username=$USERNAME" >> "$CONFIG_FILE.tmp"
          echo "Password_PBKDF2=$PASSWORD_HASH" >> "$CONFIG_FILE.tmp"
        fi

        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        chown "${cfg.user}:${cfg.group}" "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
      '';

  # Helper: Verify namespace readiness before qBittorrent binds UDP sockets
  # This prevents "Device or resource busy" errors from UDP tracker queries
  # by ensuring the VPN namespace networking stack is fully initialized
  verifyNamespaceReady =
    if !qbtVpnEnabled
    then null
    else
      pkgs.writeShellScript "verify-namespace-ready" ''
        set -euo pipefail
        NAMESPACE="${vpnNamespace}"

        # Wait for namespace networking stack to be ready
        # UDP socket binding can fail if attempted too early
        i=0
        while [ $i -lt 10 ]; do
          # Check if UDP stack is accessible (indicates namespace networking is initialized)
          if ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.coreutils}/bin/test -e /proc/net/udp 2>/dev/null; then
            # Also verify DNS is configured (WireGuard DNS should be set)
            # This helps ensure tracker hostname resolution will work
            if ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.gnugrep}/bin/grep -q "nameserver" /etc/resolv.conf 2>/dev/null || \
               ${pkgs.iproute2}/bin/ip netns exec "$NAMESPACE" ${pkgs.iproute2}/bin/ip addr show | ${pkgs.gnugrep}/bin/grep -q "inet.*10\." 2>/dev/null; then
              exit 0
            fi
          fi
          sleep 0.5
          i=$((i + 1))
        done

        echo "Warning: Namespace $NAMESPACE not fully ready after 5s" >&2
        # Don't fail - let qBittorrent start and rely on its retry logic
        exit 0
      '';

  # Helper: Validate VPN configuration
  validateVpnConfig = {
    assertion =
      !qbtVpnEnabled
      || (
        (stringLength vpnNamespace)
        <= 7
        && vpnCfg.addresses != []
        && vpnCfg.peers != []
        && all (peer: peer.allowedIPs != []) vpnCfg.peers
        && (vpnCfg.privateKeyFile != null || vpnCfg.privateKeySecret != null)
        && !((vpnCfg.privateKeyFile != null) && (vpnCfg.privateKeySecret != null))
      );
    message = ''
      Invalid qBittorrent VPN configuration:
      ${optionalString (
        (stringLength vpnNamespace) > 7
      ) "- Namespace must be <= 7 chars (current: '${vpnCfg.namespace}')"}
      ${optionalString (vpnCfg.addresses == []) "- At least one address must be specified"}
      ${optionalString (vpnCfg.peers == []) "- At least one peer must be configured"}
      ${optionalString (!all (peer: peer.allowedIPs != []) vpnCfg.peers) "- All peers must have allowedIPs"}
      ${optionalString (
        vpnCfg.privateKeyFile == null && vpnCfg.privateKeySecret == null
      ) "- Either privateKeyFile or privateKeySecret must be set"}
      ${optionalString (
        (vpnCfg.privateKeyFile != null) && (vpnCfg.privateKeySecret != null)
      ) "- Only one of privateKeyFile or privateKeySecret may be set"}
    '';
  };

  validateProxyConfig = {
    assertion =
      !qbtVpnEnabled
      || !vpnCfg.proxy.enable
      || (
        (!vpnCfg.proxy.auth.enable || vpnCfg.proxy.auth.username != null)
        && (
          !vpnCfg.proxy.auth.enable
          || (vpnCfg.proxy.auth.password != null || vpnCfg.proxy.auth.passwordSecret != null)
        )
        && !(vpnCfg.proxy.auth.password != null && vpnCfg.proxy.auth.passwordSecret != null)
        && vpnCfg.proxy.httpPort != vpnCfg.proxy.socksPort
      );
    message = ''
      Invalid 3proxy configuration:
      ${optionalString (
        vpnCfg.proxy.auth.enable && vpnCfg.proxy.auth.username == null
      ) "- Username required when auth is enabled"}
      ${optionalString (
        vpnCfg.proxy.auth.enable
        && vpnCfg.proxy.auth.password == null
        && vpnCfg.proxy.auth.passwordSecret == null
      ) "- Password or passwordSecret required when auth is enabled"}
      ${optionalString (
        (vpnCfg.proxy.auth.password != null) && (vpnCfg.proxy.auth.passwordSecret != null)
      ) "- Only one of password or passwordSecret may be set"}
      ${optionalString (
        vpnCfg.proxy.httpPort == vpnCfg.proxy.socksPort
      ) "- HTTP and SOCKS ports must be different"}
    '';
  };
in {
  options.host.services.mediaManagement.qbittorrent = {
    enable =
      mkEnableOption "qBittorrent torrent client"
      // {
        default = true;
      };

    webUiUsername = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WebUI username. Can be set directly or via webUiUsernameSecret.";
      example = "admin";
    };

    webUiPasswordHash = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "WebUI password PBKDF2 hash (safe to store in Nix store since it's hashed).";
      example = "@ByteArray(...)";
    };

    webUiUsernameSecret = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the sops secret containing the WebUI username.";
      example = "qbittorrent/webui/username";
    };

    webUiAuthSubnetWhitelist = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of IP subnets (CIDR notation) that bypass WebUI authentication.";
      example = [
        "127.0.0.1/32"
        "192.168.1.0/24"
      ];
    };

    categoryPaths = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Map of category names to their save paths.";
      example = {
        movies = "/mnt/storage/torrents/movies";
      };
    };

    downloadPath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Default download/save path for torrents.";
    };

    useIncompleteFolder = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to use a separate folder for incomplete downloads.";
    };

    incompletePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Path for incomplete downloads (only used if useIncompleteFolder is true).";
    };

    preallocateDiskSpace = mkOption {
      type = types.bool;
      default = true;
      description = "Pre-allocate disk space for added torrents to limit fragmentation.";
    };

    deleteTorrentFile = mkOption {
      type = types.bool;
      default = false;
      description = "Delete the .torrent file after it has been added to qBittorrent.";
    };

    torrentingPort = mkOption {
      type = types.port;
      default = 6881;
      description = "Port used for incoming torrent connections.";
    };

    randomizePort = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to randomize the torrent port on each startup. Should be disabled when using VPN namespace.";
    };

    globalUploadLimit = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Global upload speed limit in KiB/s (null = unlimited).";
    };

    globalDownloadLimit = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Global download speed limit in KiB/s (null = unlimited).";
    };

    encryptionPolicy = mkOption {
      type = types.enum [
        "Disabled"
        "Enabled"
        "Forced"
      ];
      default = "Enabled";
      description = "BitTorrent encryption policy.";
    };

    anonymousMode = mkOption {
      type = types.bool;
      default = false;
      description = "When enabled, hides qBittorrent fingerprint.";
    };

    maxActiveDownloads = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Maximum number of simultaneously active downloads (null = unlimited).";
    };

    maxActiveUploads = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Maximum number of simultaneously active uploads (null = unlimited).";
    };

    maxActiveTorrents = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Maximum number of simultaneously active torrents (null = unlimited).";
    };

    vpn = mkOption {
      type = types.submodule (_: {
        options = {
          enable =
            mkEnableOption "WireGuard-backed VPN isolation for qBittorrent"
            // {
              default = false;
            };

          namespace = mkOption {
            type = types.str;
            default = "qbt";
            description = "Name of the network namespace (max 7 chars for VPN-Confinement).";
          };

          addresses = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Address assignments for the WireGuard interface (CIDR notation).";
            example = ["10.8.0.2/32"];
          };

          dns = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "DNS servers for the VPN namespace.";
          };

          privateKeyFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Path to a file containing the WireGuard private key.";
          };

          privateKeySecret = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Sops secret path containing the WireGuard private key.";
          };

          peers = mkOption {
            type = types.listOf (
              types.submodule (_: {
                options = {
                  publicKey = mkOption {
                    type = types.str;
                    description = "Peer public key.";
                  };
                  endpoint = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Remote endpoint in the form host:port.";
                  };
                  allowedIPs = mkOption {
                    type = types.listOf types.str;
                    default = [];
                    description = "Allowed IP ranges routed through this peer.";
                  };
                  persistentKeepalive = mkOption {
                    type = types.nullOr types.int;
                    default = 25;
                    description = "WireGuard persistent keepalive interval (seconds).";
                  };
                  presharedKeyFile = mkOption {
                    type = types.nullOr types.str;
                    default = null;
                    description = "Optional preshared key file for this peer.";
                  };
                };
              })
            );
            default = [];
            description = "WireGuard peers for the qBittorrent VPN tunnel.";
          };

          accessibleFrom = mkOption {
            type = types.listOf types.str;
            default = [
              "127.0.0.1/32"
              "192.168.0.0/16"
              "10.0.0.0/8"
            ];
            description = "IP subnets that can access services in the VPN namespace.";
          };

          proxy = mkOption {
            type = types.submodule (_: {
              options = {
                enable = mkEnableOption "3proxy HTTP and SOCKS proxy (replaces Privoxy/Dante)";

                httpPort = mkOption {
                  type = types.port;
                  default = 8118;
                  description = "HTTP proxy port.";
                };

                socksPort = mkOption {
                  type = types.port;
                  default = 1080;
                  description = "SOCKS5 proxy port.";
                };

                auth = mkOption {
                  type = types.submodule (_: {
                    options = {
                      enable = mkEnableOption "Authentication for proxy access";
                      username = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "Proxy username (required if auth.enable is true).";
                      };
                      password = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "Proxy password (required if auth.enable is true).";
                      };
                      passwordSecret = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                        description = "Sops secret path containing the proxy password.";
                      };
                    };
                  });
                  default = {
                    enable = false;
                  };
                  description = "Authentication settings for proxy access.";
                };
              };
            });
            default = {
              enable = false;
            };
            description = "3proxy configuration for routing traffic through VPN (supports HTTP and SOCKS5).";
          };
        };
      });
      default = {
        enable = false;
      };
      description = "VPN and network namespace settings for qBittorrent (uses VPN-Confinement).";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        (mkIf (qbCfg.enable && qbCfg.webUiUsernameSecret != null) {
          assertion =
            config ? sops && config.sops ? secrets && config.sops.secrets ? "${qbCfg.webUiUsernameSecret}";
          message = "webUiUsernameSecret '${qbCfg.webUiUsernameSecret}' is not defined under config.sops.secrets.";
        })
        (
          mkIf
          (
            qbCfg.enable
            && qbCfg.webUiPasswordHash != null
            && qbCfg.webUiUsername == null
            && qbCfg.webUiUsernameSecret == null
          )
          {
            assertion = false;
            message = "webUiPasswordHash is set but neither webUiUsername nor webUiUsernameSecret is set.";
          }
        )
        validateVpnConfig
        validateProxyConfig
      ];
    }

    # VPN-Confinement namespace configuration
    {
      vpnNamespaces.${vpnNamespace} = mkIf qbtVpnEnabled {
        enable = true;
        wireguardConfigFile = wireguardConfigPath;
        accessibleFrom = vpnCfg.accessibleFrom;
        portMappings =
          [
            {
              from = 8080;
              to = 8080;
              protocol = "tcp";
            } # WebUI - accessible from host network
          ]
          ++ optionals proxyAutoEnabled [
            {
              from = vpnCfg.proxy.httpPort;
              to = vpnCfg.proxy.httpPort;
              protocol = "tcp";
            } # 3proxy HTTP - accessible from host network
            {
              from = vpnCfg.proxy.socksPort;
              to = vpnCfg.proxy.socksPort;
              protocol = "tcp";
            } # 3proxy SOCKS - accessible from host network
          ];
        # openVPNPorts: Expose ports on the VPN interface itself
        # This allows external peers to connect through the VPN
        openVPNPorts = [
          {
            port = qbCfg.torrentingPort;
            protocol = "both"; # TCP and UDP for torrent connections
          }
        ];
      };

      # Generate WireGuard config before VPN namespace service starts
      # VPN-Confinement creates a service named after the namespace (e.g., "qbt.service")
      systemd.services."${vpnNamespace}" = mkIf qbtVpnEnabled {
        requires = ["generate-qbt-wg-config.service"];
        after = ["generate-qbt-wg-config.service"];
      };

      # Oneshot service to generate WireGuard config
      systemd.services."generate-qbt-wg-config" = mkIf qbtVpnEnabled (mkMerge [
        {
          description = "Generate WireGuard config for qBittorrent VPN";
          before = ["${vpnNamespace}.service"];
          requiredBy = ["${vpnNamespace}.service"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "+${wireguardConfigScript}";
            RemainAfterExit = true;
          };
        }
        # sops secrets are decrypted at activation time, no service dependency needed
      ]);
    }

    # qBittorrent service
    (mkIf qbtEnabled {
      services.qbittorrent = {
        enable = true;
        inherit (cfg) user group;
        profileDir = qbProfileDir;
        webuiPort = 8080;
        torrentingPort = qbCfg.torrentingPort;
        openFirewall = !qbtVpnEnabled;
        serverConfig = mkMerge [
          {
            LegalNotice.Accepted = true;
            Preferences = {
              Downloads = {
                SavePath = mkIf (qbCfg.downloadPath != null) qbCfg.downloadPath;
                TempPath = mkIf (qbCfg.useIncompleteFolder && qbCfg.incompletePath != null) qbCfg.incompletePath;
                TempPathEnabled = qbCfg.useIncompleteFolder;
                PreAllocationEnabled = qbCfg.preallocateDiskSpace;
                DeleteTorrentFileAfterAdded = qbCfg.deleteTorrentFile;
              };
              WebUI = {
                Address = "0.0.0.0";
                Port = 8080;
                AlternativeUIEnabled = true;
                RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
                BypassLocalAuth = true;
              };
              General.Locale = "en";
              Connection = {
                ProxyOnlyForTorrents = false;
                InterfaceAddress = "0.0.0.0";
                ListenInterfaceValue = "0.0.0.0";
                UseRandomPort = qbCfg.randomizePort;
                UPnP = false;
                NatPmp = false;
                ConnectionSpeed = 0;
              };
              BitTorrent = {
                Encryption =
                  if qbCfg.encryptionPolicy == "Disabled"
                  then 0
                  else if qbCfg.encryptionPolicy == "Forced"
                  then 2
                  else 1;
                AnonymousMode = qbCfg.anonymousMode;
                MaxConnecsPerTorrent = 500;
                MaxUploadsPerTorrent = 100;
              };
              Speed = {
                UploadRateLimit = mkIf (qbCfg.globalUploadLimit != null) (qbCfg.globalUploadLimit * 1024);
                DownloadRateLimit = mkIf (qbCfg.globalDownloadLimit != null) (qbCfg.globalDownloadLimit * 1024);
              };
            };
          }
          (
            mkIf
            (
              qbCfg.maxActiveDownloads
              != null
              || qbCfg.maxActiveUploads != null
              || qbCfg.maxActiveTorrents != null
            )
            {
              Preferences.Bittorrent = {
                MaxActiveDownloads = mkIf (qbCfg.maxActiveDownloads != null) qbCfg.maxActiveDownloads;
                MaxActiveUploads = mkIf (qbCfg.maxActiveUploads != null) qbCfg.maxActiveUploads;
                MaxActiveTorrents = mkIf (qbCfg.maxActiveTorrents != null) qbCfg.maxActiveTorrents;
              };
            }
          )
          (mkIf (qbCfg.webUiUsername != null && qbCfg.webUiPasswordHash != null) {
            Preferences.WebUI = {
              Username = qbCfg.webUiUsername;
              Password_PBKDF2 = qbCfg.webUiPasswordHash;
            };
          })
          (mkIf (qbCfg.webUiAuthSubnetWhitelist != []) {
            Preferences.WebUI = {
              AuthSubnetWhitelist = concatStringsSep "," qbCfg.webUiAuthSubnetWhitelist;
              BypassLocalAuth = true;
            };
          })
          (mkIf (qbCfg.categoryPaths != {}) (
            lib.foldl' lib.recursiveUpdate {} (
              lib.mapAttrsToList (name: path: {
                Preferences."Category\\${name}" = {
                  SavePath = path;
                };
              })
              qbCfg.categoryPaths
            )
          ))
        ];
      };

      systemd.services.qbittorrent = mkMerge [
        {environment.TZ = cfg.timezone;}
        (mkIf (qbCfg.webUiUsernameSecret != null && qbCfg.webUiPasswordHash != null) {
          # sops secrets are decrypted at activation time, no service dependency needed
          serviceConfig.ExecStartPre = ["+${qbCredsUpdateScript}"];
        })
        (mkIf qbtVpnEnabled {
          vpnConfinement = {
            enable = true;
            vpnNamespace = vpnNamespace;
          };
          # VPN-Confinement creates a service named after the namespace (qbt.service)
          after = ["${vpnNamespace}.service"];
          requires = ["${vpnNamespace}.service"];
          # Verify namespace is ready before qBittorrent starts binding UDP sockets
          # Merge with any existing ExecStartPre (e.g., credentials update)
          serviceConfig.ExecStartPre = (
            if qbCfg.webUiUsernameSecret != null && qbCfg.webUiPasswordHash != null
            then [
              "+${verifyNamespaceReady}"
              "+${qbCredsUpdateScript}"
            ]
            else ["+${verifyNamespaceReady}"]
          );
          # Allow transient UDP socket binding failures; qBittorrent will retry
          serviceConfig.Restart = "on-failure";
          serviceConfig.RestartSec = "5s";
          serviceConfig.StartLimitIntervalSec = "60s";
          serviceConfig.StartLimitBurst = 3;
        })
      ];

      # 3proxy service (replaces Privoxy + Dante)
      systemd.services."3proxy-qbvpn" = mkIf proxyAutoEnabled {
        description = "3proxy HTTP/SOCKS proxy via qBittorrent VPN";
        # VPN-Confinement creates a service named after the namespace (qbt.service)
        after = ["${vpnNamespace}.service"];
        requires = ["${vpnNamespace}.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "simple";
          NetworkNamespacePath = "/run/netns/${vpnNamespace}";
          ExecStart = "${pkgs._3proxy}/bin/3proxy ${proxy3ConfigFile}";
          Restart = "on-failure";
          RestartSec = 5;
          DynamicUser = true;
          NoNewPrivileges = true;
          AmbientCapabilities = "CAP_NET_BIND_SERVICE";
          CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        };
      };

      systemd.tmpfiles.rules = [
        (mkDirRule {
          path = qbProfileDir;
          inherit (cfg) user group;
          mode = "0750";
        })
        (mkDirRule {
          path = "${qbProfileDir}/qBittorrent";
          inherit (cfg) user group;
          mode = "0750";
        })
        (mkDirRule {
          path = "${qbProfileDir}/qBittorrent/config";
          inherit (cfg) user group;
          mode = "0750";
        })
      ];

      sops.secrets = mkMerge [
        (mkIf (qbCfg.webUiUsernameSecret != null && config ? sops) {
          "${qbCfg.webUiUsernameSecret}" = {
            restartUnits = mkBefore ["qbittorrent.service"];
            owner = mkForce "root";
            group = mkForce "root";
            mode = mkForce "0400";
          };
        })
        (mkIf (qbtVpnEnabled && vpnCfg.privateKeySecret != null && config ? sops) {
          "${vpnCfg.privateKeySecret}" = {
            restartUnits = mkBefore ["vpn-namespace-${vpnNamespace}.service"];
            owner = mkForce "root";
            group = mkForce "root";
            mode = mkForce "0400";
          };
        })
      ];
    })
  ]);
}
