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

  qbProfileDir = "/var/lib/qBittorrent";
  namespacePath = "/run/netns/${vpnCfg.namespace}";
  ipCommand = "${pkgs.iproute2}/bin/ip";
  netnsUnitName = "qbittorrent-netns";
  wgUnitName = "wg-quick-${vpnCfg.interfaceName}";

  qbtEnabled = cfg.enable && qbCfg.enable;
  qbtVpnEnabled = qbtEnabled && vpnCfg.enable;

  vpnSecretAttr =
    if qbtVpnEnabled && vpnCfg.privateKeySecret != null && config ? sops && config.sops ? secrets
    then config.sops.secrets."${vpnCfg.privateKeySecret}" or null
    else null;

  vpnPrivateKeyFile =
    if !qbtVpnEnabled
    then null
    else if vpnCfg.privateKeySecret != null
    then
      (
        if vpnSecretAttr != null
        then vpnSecretAttr.path
        else throw "qBittorrent VPN privateKeySecret '${vpnCfg.privateKeySecret}' is not defined under config.sops.secrets."
      )
    else vpnCfg.privateKeyFile;

  vpnPostUpCommands =
    if !qbtVpnEnabled
    then ""
    else
      concatStringsSep "\n" (
        [
          "${ipCommand} link set dev ${vpnCfg.interfaceName} netns ${vpnCfg.namespace}"
          "${ipCommand} -n ${vpnCfg.namespace} link set dev ${vpnCfg.interfaceName} up"
        ]
        ++ map (
          addr: "${ipCommand} -n ${vpnCfg.namespace} addr add ${addr} dev ${vpnCfg.interfaceName} 2>/dev/null || true"
        )
        vpnCfg.addresses
        ++ [
          "${ipCommand} -n ${vpnCfg.namespace} route replace default dev ${vpnCfg.interfaceName}"
        ]
      );

  vpnPreDownCommands =
    if !qbtVpnEnabled
    then ""
    else ''
      ${ipCommand} -n ${vpnCfg.namespace} route del default dev ${vpnCfg.interfaceName} 2>/dev/null || true
      ${ipCommand} -n ${vpnCfg.namespace} link set dev ${vpnCfg.interfaceName} down 2>/dev/null || true
      ${ipCommand} -n ${vpnCfg.namespace} link set dev ${vpnCfg.interfaceName} netns 1 2>/dev/null || true
    '';

  netnsSetupScript =
    if !qbtVpnEnabled
    then null
    else
      pkgs.writeShellScript "qbittorrent-netns-setup" ''
        set -euo pipefail
        mkdir -p /run/netns
        if ! ${ipCommand} netns list | grep -q "^${vpnCfg.namespace}\b"; then
          ${ipCommand} netns add ${vpnCfg.namespace}
        fi
        ${ipCommand} netns exec ${vpnCfg.namespace} ${ipCommand} link set lo up
        if ! ${ipCommand} link show ${vpnCfg.veth.hostInterface} >/dev/null 2>&1; then
          ${ipCommand} link add ${vpnCfg.veth.hostInterface} type veth peer name ${vpnCfg.veth.namespaceInterface}
        fi
        ${ipCommand} link set ${vpnCfg.veth.namespaceInterface} netns ${vpnCfg.namespace}
        ${ipCommand} addr add ${vpnCfg.veth.hostAddress} dev ${vpnCfg.veth.hostInterface} 2>/dev/null || true
        ${ipCommand} link set ${vpnCfg.veth.hostInterface} up
        ${ipCommand} -n ${vpnCfg.namespace} addr add ${vpnCfg.veth.namespaceAddress} dev ${vpnCfg.veth.namespaceInterface} 2>/dev/null || true
        ${ipCommand} -n ${vpnCfg.namespace} link set ${vpnCfg.veth.namespaceInterface} up
      '';

  netnsTeardownScript =
    if !qbtVpnEnabled
    then null
    else
      pkgs.writeShellScript "qbittorrent-netns-teardown" ''
        set -euo pipefail
        ${ipCommand} link delete ${vpnCfg.veth.hostInterface} 2>/dev/null || true
        ${ipCommand} netns delete ${vpnCfg.namespace} 2>/dev/null || true
      '';

  wgPeers =
    if !qbtVpnEnabled
    then []
    else
      map (
        peer:
          {
            inherit (peer) publicKey allowedIPs;
          }
          // optionalAttrs (peer.endpoint != null) {inherit (peer) endpoint;}
          // optionalAttrs (peer.persistentKeepalive != null) {inherit (peer) persistentKeepalive;}
          // optionalAttrs (peer.presharedKeyFile != null) {inherit (peer) presharedKeyFile;}
      )
      vpnCfg.peers;

  # Password hash (always use direct hash if provided)
  inherit (qbCfg) webUiPasswordHash;

  # Script to update qBittorrent credentials (only needed if username comes from secret)
  qbCredsUpdateScript =
    if
      !qbtEnabled
      || (qbCfg.webUiUsername == null && qbCfg.webUiUsernameSecret == null)
      || webUiPasswordHash == null
    then null
    else if qbCfg.webUiUsernameSecret != null
    then
      pkgs.writeShellScript "qbittorrent-update-creds" ''
        set -euo pipefail
        CONFIG_FILE="${qbProfileDir}/qBittorrent/config/qBittorrent.conf"

        # Read username from secret
        USERNAME=$(cat "${config.sops.secrets."${qbCfg.webUiUsernameSecret}".path}")
        PASSWORD_HASH="${webUiPasswordHash}"

        # Ensure config file exists (created by NixOS module)
        if [ ! -f "''${CONFIG_FILE}" ]; then
          echo "Error: qBittorrent config file not found at ''${CONFIG_FILE}" >&2
          exit 1
        fi

        # Use a temporary file approach to avoid sed escaping issues
        TMP_FILE=$(mktemp)
        IN_SECTION=false
        USERNAME_SET=false
        PASSWORD_SET=false

        # Process the config file line by line
        while IFS= read -r line || [ -n "$line" ]; do
          # Check if we're entering the [WebUI] section
          if [[ "$line" =~ ^\[WebUI\] ]]; then
            echo "[WebUI]" >> "$TMP_FILE"
            IN_SECTION=true
            USERNAME_SET=false
            PASSWORD_SET=false
            continue
          fi

          # Check if we're leaving the section (next [section])
          if [[ "$line" =~ ^\[ ]] && [[ ! "$line" =~ ^\[WebUI\] ]]; then
            # Add credentials before leaving section if they weren't set
            if [ "$IN_SECTION" = true ] && [ "$USERNAME_SET" = false ]; then
              echo "Username=''${USERNAME}" >> "$TMP_FILE"
              echo "Password_PBKDF2=''${PASSWORD_HASH}" >> "$TMP_FILE"
              USERNAME_SET=true
              PASSWORD_SET=true
            fi
            IN_SECTION=false
          fi

          # In [WebUI] section, replace existing credentials
          if [ "$IN_SECTION" = true ]; then
            if [[ "$line" =~ ^Username= ]]; then
              echo "Username=''${USERNAME}" >> "$TMP_FILE"
              USERNAME_SET=true
              continue
            elif [[ "$line" =~ ^Password_PBKDF2= ]]; then
              echo "Password_PBKDF2=''${PASSWORD_HASH}" >> "$TMP_FILE"
              PASSWORD_SET=true
              continue
            fi
          fi

          # Write other lines as-is
          echo "$line" >> "$TMP_FILE"
        done < "''${CONFIG_FILE}"

        # If credentials weren't set in [WebUI] section, add them before closing
        if [ "$IN_SECTION" = true ] && [ "$USERNAME_SET" = false ]; then
          echo "Username=''${USERNAME}" >> "$TMP_FILE"
          echo "Password_PBKDF2=''${PASSWORD_HASH}" >> "$TMP_FILE"
        fi

        # If [WebUI] section doesn't exist at all, add it at the end
        if ! grep -q "^\[WebUI\]" "''${CONFIG_FILE}" 2>/dev/null; then
          echo "" >> "$TMP_FILE"
          echo "[WebUI]" >> "$TMP_FILE"
          echo "Username=''${USERNAME}" >> "$TMP_FILE"
          echo "Password_PBKDF2=''${PASSWORD_HASH}" >> "$TMP_FILE"
        fi

        # Replace original file with updated version
        mv "$TMP_FILE" "''${CONFIG_FILE}"

        # Ensure correct ownership
        chown "${cfg.user}:${cfg.group}" "''${CONFIG_FILE}"
        chmod 600 "''${CONFIG_FILE}"
      ''
    else null;
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
      description = "WebUI password PBKDF2 hash (safe to store in Nix store since it's hashed). The hash must be in the format: @ByteArray(salt_base64:hash_base64). Generate using: python3 -c 'import hashlib, base64, os; password = b\"your_password\"; salt = os.urandom(16); hash_obj = hashlib.pbkdf2_hmac(\"sha512\", password, salt, 100000); print(f\"@ByteArray({base64.b64encode(salt).decode()}:{base64.b64encode(hash_obj).decode()})\")'";
      example = "@ByteArray(...)";
    };

    webUiUsernameSecret = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the sops secret containing the WebUI username. Used if webUiUsername is not set.";
      example = "qbittorrent/webui/username";
    };

    webUiPasswordHashSecret = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "DEPRECATED: Name of the sops secret containing the WebUI password PBKDF2 hash. Use webUiPasswordHash directly instead (hashes are safe to store in Nix store).";
      example = "qbittorrent/webui/password_hash";
    };

    webUiAuthSubnetWhitelist = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of IP subnets (CIDR notation) that bypass WebUI authentication. Common examples: [\"127.0.0.1/32\"] for localhost, [\"192.168.1.0/24\"] for local network.";
      example = [
        "127.0.0.1/32"
        "192.168.1.0/24"
      ];
    };

    categoryPaths = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Map of category names to their save paths. Used for organizing downloads (e.g., movies -> /mnt/storage/torrents/movies for Radarr, tv -> /mnt/storage/torrents/tv for Sonarr).";
      example = {
        movies = "/mnt/storage/torrents/movies";
        tv = "/mnt/storage/torrents/tv";
      };
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
            default = "qbittorrent";
            description = "Name of the network namespace dedicated to qBittorrent.";
          };

          interfaceName = mkOption {
            type = types.str;
            default = "wg-qbtvpn";
            description = "Name of the WireGuard interface dedicated to qBittorrent.";
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
            description = "DNS servers pushed into the qBittorrent namespace.";
          };

          privateKeyFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Path to a file containing the WireGuard private key.";
          };

          privateKeySecret = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Sops secret path containing the WireGuard private key. Accepts nested paths like qbittorrent/vpn.";
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
                    description = "WireGuard persistent keepalive interval (seconds). Set to null to disable.";
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

          veth = mkOption {
            type = types.submodule (_: {
              options = {
                hostInterface = mkOption {
                  type = types.str;
                  default = "qbt-host";
                  description = "Name of the veth interface visible in the host namespace.";
                };
                namespaceInterface = mkOption {
                  type = types.str;
                  default = "qbt-veth";
                  description = "Name of the veth interface inside the qBittorrent namespace.";
                };
                hostAddress = mkOption {
                  type = types.str;
                  default = "10.200.0.2/30";
                  description = "Address assigned to the host-side veth interface.";
                };
                namespaceAddress = mkOption {
                  type = types.str;
                  default = "10.200.0.1/30";
                  description = "Address assigned to the namespace-side veth interface.";
                };
              };
            });
            default = {};
            description = "Settings for the veth pair that exposes the qBittorrent namespace to the host.";
          };
        };
      });
      default = {
        enable = false;
      };
      description = "VPN and network namespace settings for qBittorrent.";
    };
  };

  config = mkIf cfg.enable (
    let
      vpnEnabledAssertions = optionals qbtVpnEnabled [
        {
          assertion = vpnCfg.addresses != [];
          message = "Enable qBittorrent VPN requires host.services.mediaManagement.qbittorrent.vpn.addresses to contain at least one address.";
        }
        {
          assertion = vpnCfg.peers != [];
          message = "Enable qBittorrent VPN requires at least one peer entry under host.services.mediaManagement.qbittorrent.vpn.peers.";
        }
        {
          assertion = vpnCfg.privateKeyFile != null || vpnCfg.privateKeySecret != null;
          message = "Provide either host.services.mediaManagement.qbittorrent.vpn.privateKeyFile or vpn.privateKeySecret when enabling the qBittorrent VPN.";
        }
        {
          assertion = !((vpnCfg.privateKeyFile != null) && (vpnCfg.privateKeySecret != null));
          message = "Only one of privateKeyFile or privateKeySecret may be set for the qBittorrent VPN.";
        }
        {
          assertion = all (peer: peer.allowedIPs != []) vpnCfg.peers;
          message = "Each qBittorrent VPN peer must declare at least one allowedIPs entry.";
        }
      ];
    in
      mkMerge [
        {
          assertions =
            optionals (qbCfg.enable && qbCfg.webUiUsernameSecret != null) [
              {
                assertion =
                  config ? sops && config.sops ? secrets && config.sops.secrets ? "${qbCfg.webUiUsernameSecret}";
                message = ''
                  host.services.mediaManagement.qbittorrent.webUiUsernameSecret is set to "${qbCfg.webUiUsernameSecret}" but the secret is not defined under config.sops.secrets.
                '';
              }
            ]
            ++ optionals (qbCfg.enable && qbCfg.webUiPasswordHashSecret != null) [
              {
                assertion = false;
                message = "webUiPasswordHashSecret is deprecated. Use webUiPasswordHash directly instead (hashes are safe to store in Nix store).";
              }
            ]
            ++ optionals
            (
              qbCfg.enable
              && webUiPasswordHash != null
              && (qbCfg.webUiUsername == null && qbCfg.webUiUsernameSecret == null)
            )
            [
              {
                assertion = false;
                message = "webUiPasswordHash is set but neither webUiUsername nor webUiUsernameSecret is set. Set one of them.";
              }
            ]
            ++ vpnEnabledAssertions
            ++ optionals (qbtVpnEnabled && vpnCfg.privateKeySecret != null) [
              {
                assertion = vpnSecretAttr != null;
                message = "qBittorrent VPN privateKeySecret '${vpnCfg.privateKeySecret}' is not defined under config.sops.secrets.";
              }
            ];
        }

        (mkIf qbtEnabled {
          services.qbittorrent = mkMerge [
            {
              enable = true;
              inherit (cfg) user;
              inherit (cfg) group;
              profileDir = qbProfileDir;
              webuiPort = 8080;
              torrentingPort = 6881;
              openFirewall = true;
              serverConfig = mkMerge [
                {
                  LegalNotice.Accepted = true;
                  Preferences = {
                    WebUI = {
                      Address = "0.0.0.0";
                      Port = 8080;
                      AlternativeUIEnabled = true;
                      RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
                    };
                    General.Locale = "en";
                  };
                }
                # Set credentials directly if username and password hash are provided directly
                # According to NixOS qbittorrent module docs, Username and Password_PBKDF2 go under Preferences.WebUI
                (mkIf (qbCfg.webUiUsername != null && webUiPasswordHash != null) {
                  Preferences.WebUI = {
                    Username = qbCfg.webUiUsername;
                    Password_PBKDF2 = webUiPasswordHash;
                  };
                })
                # Set authentication bypass subnets if provided
                (mkIf (qbCfg.webUiAuthSubnetWhitelist != []) {
                  Preferences.WebUI.AuthSubnetWhitelist = concatStringsSep "," qbCfg.webUiAuthSubnetWhitelist;
                })
                # Set category paths if provided
                (mkIf (qbCfg.categoryPaths != {}) {
                  Preferences.Category =
                    mapAttrs' (
                      name: path: nameValuePair "Category\\${name}\\SavePath" path
                    )
                    qbCfg.categoryPaths;
                })
                # Note: If webUiUsernameSecret is used, credentials are set at runtime via ExecStartPre script
              ];
            }
            (mkIf qbtVpnEnabled {
              openFirewall = mkForce false;
            })
          ];

          systemd = {
            services = {
              qbittorrent = mkMerge [
                {
                  environment.TZ = cfg.timezone;
                }
                (mkIf (qbCfg.webUiUsernameSecret != null && webUiPasswordHash != null) {
                  after = ["sops-nix.service"];
                  serviceConfig = {
                    ExecStartPre = [
                      "+${qbCredsUpdateScript}"
                    ];
                  };
                })
                (mkIf qbtVpnEnabled {
                  wants = [
                    "${netnsUnitName}.service"
                    "${wgUnitName}.service"
                  ];
                  after =
                    [
                      "${netnsUnitName}.service"
                      "${wgUnitName}.service"
                    ]
                    ++ optionals (qbCfg.webUiUsernameSecret != null) [
                      "sops-nix.service"
                    ];
                  requires = [
                    "${netnsUnitName}.service"
                    "${wgUnitName}.service"
                  ];
                  serviceConfig = mkMerge [
                    {
                      NetworkNamespacePath = namespacePath;
                    }
                    (mkIf (qbCfg.webUiUsernameSecret != null && webUiPasswordHash != null) {
                      ExecStartPre = [
                        "+${qbCredsUpdateScript}"
                      ];
                    })
                  ];
                })
              ];

              ${netnsUnitName} = mkIf qbtVpnEnabled {
                description = "qBittorrent network namespace";
                wantedBy = ["multi-user.target"];
                before = [
                  "${wgUnitName}.service"
                  "qbittorrent.service"
                ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = [netnsSetupScript];
                  ExecStop = [netnsTeardownScript];
                };
              };

              ${wgUnitName} = mkIf qbtVpnEnabled {
                after = ["${netnsUnitName}.service"];
                requires = ["${netnsUnitName}.service"];
              };

              privoxy-qbvpn = mkIf qbtVpnEnabled {
                description = "Privoxy HTTP proxy via qBittorrent VPN";
                after = [
                  "${netnsUnitName}.service"
                  "${wgUnitName}.service"
                ];
                requires = ["${netnsUnitName}.service"];
                wantedBy = ["multi-user.target"];
                serviceConfig = {
                  Type = "simple";
                  NetworkNamespacePath = namespacePath;
                  ExecStart = "${pkgs.privoxy}/bin/privoxy --no-daemon /etc/privoxy/config";
                  Restart = "on-failure";
                  RestartSec = 5;
                  User = "privoxy";
                  Group = "privoxy";
                };
              };
            };

            tmpfiles.rules =
              [
                (mkDirRule {
                  path = qbProfileDir;
                  mode = "0750";
                  inherit (cfg) user;
                  inherit (cfg) group;
                })
                (mkDirRule {
                  path = "${qbProfileDir}/qBittorrent";
                  mode = "0750";
                  inherit (cfg) user;
                  inherit (cfg) group;
                })
                (mkDirRule {
                  path = "${qbProfileDir}/qBittorrent/config";
                  mode = "0750";
                  inherit (cfg) user;
                  inherit (cfg) group;
                })
              ]
              ++ optionals qbtVpnEnabled [
                (mkDirRule {
                  path = "/run/netns";
                  mode = "0755";
                  user = "root";
                  group = "root";
                })
              ];
          };

          networking = {
            firewall = {
              allowedTCPPorts = mkAfter (
                optionals (!qbtVpnEnabled) [
                  8080
                  6881
                ]
              );
              allowedUDPPorts = mkAfter (optionals (!qbtVpnEnabled) [6881]);

              extraCommands = mkIf qbtVpnEnabled ''
                # Forward WebUI port from host to namespace
                iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 10.200.0.1:8080
                iptables -t nat -A OUTPUT -p tcp --dport 8080 ! -d 10.200.0.0/30 -j DNAT --to-destination 10.200.0.1:8080
                iptables -A FORWARD -d 10.200.0.1 -p tcp --dport 8080 -j ACCEPT
                iptables -A FORWARD -s 10.200.0.1 -p tcp --sport 8080 -j ACCEPT
                iptables -t nat -A POSTROUTING -d 10.200.0.1 -p tcp --dport 8080 -j MASQUERADE

                # Forward Privoxy port from host to namespace
                iptables -t nat -A PREROUTING -p tcp --dport 8118 -j DNAT --to-destination 10.200.0.1:8118
                iptables -t nat -A OUTPUT -p tcp --dport 8118 ! -d 10.200.0.0/30 -j DNAT --to-destination 10.200.0.1:8118
                iptables -A FORWARD -d 10.200.0.1 -p tcp --dport 8118 -j ACCEPT
                iptables -A FORWARD -s 10.200.0.1 -p tcp --sport 8118 -j ACCEPT
                iptables -t nat -A POSTROUTING -d 10.200.0.1 -p tcp --dport 8118 -j MASQUERADE
              '';

              extraStopCommands = mkIf qbtVpnEnabled ''
                iptables -t nat -D PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 10.200.0.1:8080 2>/dev/null || true
                iptables -t nat -D OUTPUT -p tcp --dport 8080 ! -d 10.200.0.0/30 -j DNAT --to-destination 10.200.0.1:8080 2>/dev/null || true
                iptables -D FORWARD -d 10.200.0.1 -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
                iptables -D FORWARD -s 10.200.0.1 -p tcp --sport 8080 -j ACCEPT 2>/dev/null || true
                iptables -t nat -D POSTROUTING -d 10.200.0.1 -p tcp --dport 8080 -j MASQUERADE 2>/dev/null || true

                iptables -t nat -D PREROUTING -p tcp --dport 8118 -j DNAT --to-destination 10.200.0.1:8118 2>/dev/null || true
                iptables -t nat -D OUTPUT -p tcp --dport 8118 ! -d 10.200.0.0/30 -j DNAT --to-destination 10.200.0.1:8118 2>/dev/null || true
                iptables -D FORWARD -d 10.200.0.1 -p tcp --dport 8118 -j ACCEPT 2>/dev/null || true
                iptables -D FORWARD -s 10.200.0.1 -p tcp --sport 8118 -j ACCEPT 2>/dev/null || true
                iptables -t nat -D POSTROUTING -d 10.200.0.1 -p tcp --dport 8118 -j MASQUERADE 2>/dev/null || true
              '';
            };

            wg-quick.interfaces.${vpnCfg.interfaceName} = mkIf qbtVpnEnabled {
              address = vpnCfg.addresses;
              inherit (vpnCfg) dns;
              privateKeyFile = vpnPrivateKeyFile;
              peers = wgPeers;
              table = "off";
              postUp = vpnPostUpCommands;
              preDown = vpnPreDownCommands;
            };
          };

          sops.secrets =
            mkIf (qbCfg.webUiUsernameSecret != null && config ? sops) (
              let
                usernameSecretName = qbCfg.webUiUsernameSecret;
              in {
                "${usernameSecretName}" = mkMerge [
                  {
                    restartUnits = mkBefore ["qbittorrent.service"];
                  }
                  {
                    owner = mkForce "root";
                    group = mkForce "root";
                    mode = mkForce "0400";
                  }
                ];
              }
            )
            // mkIf (qbtVpnEnabled && vpnCfg.privateKeySecret != null && config ? sops) (
              let
                vpnSecretName = vpnCfg.privateKeySecret;
              in {
                "${vpnSecretName}" = mkMerge [
                  {
                    restartUnits = mkBefore ["${wgUnitName}.service"];
                  }
                  {
                    owner = mkForce "root";
                    group = mkForce "root";
                    mode = mkForce "0400";
                  }
                ];
              }
            );
        })
      ]
  );
}
