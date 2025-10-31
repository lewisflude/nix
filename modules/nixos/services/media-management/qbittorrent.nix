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

  # Script to setup qBittorrent credentials from sops secret
  qbSetupScript =
    if !qbtEnabled || qbCfg.webUiCredentialsSecret == null
    then null
    else
      pkgs.writeShellScript "qbittorrent-setup-creds" ''
        set -euo pipefail
        CREDS_FILE="${config.sops.secrets."${qbCfg.webUiCredentialsSecret}".path}"

        # Extract username and password from the credentials file
        USERNAME=$(head -n1 "''${CREDS_FILE}")
        PASSWORD=$(tail -n1 "''${CREDS_FILE}")

        # Generate PBKDF2 hash
        PASSWORD_HASH=$(echo "''${PASSWORD}" | ${pkgs.python3}/bin/python3 << 'PYSCRIPT'
        import hashlib, base64, sys, os
        password = sys.stdin.read().strip().encode('utf-8')
        salt = os.urandom(16)
        hash_obj = hashlib.pbkdf2_hmac('sha256', password, salt, 32000)
        salt_b64 = base64.b64encode(salt).decode('utf-8')
        hash_b64 = base64.b64encode(hash_obj).decode('utf-8')
        print(f"@ByteArray({salt_b64}:{hash_b64})")
        PYSCRIPT
        )

        # Update qBittorrent config file with credentials
        CONFIG_FILE="${qbProfileDir}/qBittorrent/config/qBittorrent.conf"

        # Create config backup if it doesn't exist
        if [ ! -f "''${CONFIG_FILE}" ]; then
          mkdir -p "$(dirname "''${CONFIG_FILE}")"
          touch "''${CONFIG_FILE}"
        fi

        # Use sed to update credentials (or add them if missing)
        ${pkgs.gnused}/bin/sed -i "/^\[WebUI\]/,/^\[/ {
          /^Username=/c\Username=''${USERNAME}
          T
          :a
          /^Password_PBKDF2=/c\Password_PBKDF2=''${PASSWORD_HASH}
          T
        }" "''${CONFIG_FILE}" || true

        # If credentials weren't found, add them to the WebUI section
        if ! grep -q "^Username=" "''${CONFIG_FILE}"; then
          ${pkgs.gnused}/bin/sed -i "/^\[WebUI\]/a\\Username=''${USERNAME}\nPassword_PBKDF2=''${PASSWORD_HASH}" "''${CONFIG_FILE}" || true
        fi

        # Ensure correct ownership
        chown "${cfg.user}:${cfg.group}" "''${CONFIG_FILE}"
        chmod 600 "''${CONFIG_FILE}"
      '';
in {
  options.host.services.mediaManagement.qbittorrent = {
    enable =
      mkEnableOption "qBittorrent torrent client"
      // {
        default = true;
      };

    webUiCredentialsSecret = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Name of the sops secret containing WebUI credentials (username on line 1, password on line 2).";
      example = "qbittorrent/webui";
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
            optionals (qbCfg.enable && qbCfg.webUiCredentialsSecret != null) [
              {
                assertion =
                  config ? sops && config.sops ? secrets && config.sops.secrets ? "${qbCfg.webUiCredentialsSecret}";
                message = ''
                  host.services.mediaManagement.qbittorrent.webUiCredentialsSecret is set to "${qbCfg.webUiCredentialsSecret}" but the secret is not defined under config.sops.secrets.
                '';
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
              serverConfig = {
                LegalNotice.Accepted = true;
                Preferences = {
                  WebUI = {
                    Address = "0.0.0.0";
                    Port = 8080;
                  };
                  General = {
                    Locale = "en";
                  };
                };
              };
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
                  serviceConfig = mkMerge [
                    (mkIf (qbCfg.webUiCredentialsSecret != null) {
                      ExecPreStart = [qbSetupScript];
                    })
                  ];
                }
                (mkIf qbtVpnEnabled {
                  wants = [
                    "${netnsUnitName}.service"
                    "${wgUnitName}.service"
                  ];
                  after = [
                    "${netnsUnitName}.service"
                    "${wgUnitName}.service"
                  ];
                  requires = [
                    "${netnsUnitName}.service"
                    "${wgUnitName}.service"
                  ];
                  serviceConfig = {
                    NetworkNamespacePath = namespacePath;
                  };
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
              '';

              extraStopCommands = mkIf qbtVpnEnabled ''
                iptables -t nat -D PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 10.200.0.1:8080 2>/dev/null || true
                iptables -t nat -D OUTPUT -p tcp --dport 8080 ! -d 10.200.0.0/30 -j DNAT --to-destination 10.200.0.1:8080 2>/dev/null || true
                iptables -D FORWARD -d 10.200.0.1 -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
                iptables -D FORWARD -s 10.200.0.1 -p tcp --sport 8080 -j ACCEPT 2>/dev/null || true
                iptables -t nat -D POSTROUTING -d 10.200.0.1 -p tcp --dport 8080 -j MASQUERADE 2>/dev/null || true
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
            mkIf (qbCfg.webUiCredentialsSecret != null && config ? sops) (
              let
                secretName = qbCfg.webUiCredentialsSecret;
              in {
                "${secretName}" = mkMerge [
                  {
                    restartUnits = mkBefore ["qbittorrent.service"];
                  }
                  {
                    owner = mkForce cfg.user;
                    group = mkForce cfg.group;
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
