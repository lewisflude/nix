{
  config,
  lib,
  pkgs,
  constants,
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
  transmissionCfg = cfg.transmission;
in
{
  options.host.services.mediaManagement.transmission = {
    enable = mkEnableOption "Transmission BitTorrent client";

    webUIPort = mkOption {
      type = types.port;
      default = constants.ports.services.transmission;
      description = "WebUI port (default: 9091)";
    };

    authentication = mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable RPC authentication for WebUI";
            };
            username = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "RPC username (plain text or SOPS secret path)";
            };
            password = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "RPC password (plain text or SOPS secret path). Transmission will automatically hash it.";
            };
            useSops = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to use SOPS secrets for RPC credentials";
            };
          };
        }
      );
      default = null;
      description = "RPC authentication configuration for WebUI access";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/mnt/storage/torrents";
      description = "Directory for completed downloads";
    };

    incompleteDir = mkOption {
      type = types.str;
      default = "/var/lib/transmission/incomplete";
      description = "Directory for incomplete downloads";
    };

    peerPort = mkOption {
      type = types.port;
      default = 62000;
      description = "Initial peer port (will be updated by NAT-PMP)";
    };

    vpn = {
      enable = mkEnableOption "VPN namespace for Transmission";

      namespace = mkOption {
        type = types.str;
        default = "qbt";
        description = "VPN namespace name (shared with qBittorrent)";
      };
    };
  };

  config = mkIf (cfg.enable && transmissionCfg.enable) {
    # Firewall: WebUI port only (peer port handled in VPN namespace)
    networking.firewall.allowedTCPPorts = [ transmissionCfg.webUIPort ];

    # SOPS secrets for RPC credentials
    sops.secrets =
      mkIf (transmissionCfg.authentication != null && transmissionCfg.authentication.useSops)
        {
          "transmission/rpc/username" = {
            owner = cfg.user;
            inherit (cfg) group;
            mode = "0440";
          };
          "transmission/rpc/password" = {
            owner = cfg.user;
            inherit (cfg) group;
            mode = "0440";
          };
        };

    # Generate credentials file from SOPS secrets using templates
    sops.templates."transmission-credentials.json" =
      mkIf (transmissionCfg.authentication != null && transmissionCfg.authentication.useSops)
        {
          owner = cfg.user;
          inherit (cfg) group;
          mode = "0440";
          content = builtins.toJSON {
            rpc-authentication-required = true;
            rpc-username = config.sops.placeholder."transmission/rpc/username";
            rpc-password = config.sops.placeholder."transmission/rpc/password";
          };
        };

    # Ensure required directories exist
    systemd.tmpfiles.rules = [
      "d '${transmissionCfg.incompleteDir}' 0750 ${cfg.user} ${cfg.group} - -"
      "d '${transmissionCfg.downloadDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    # Transmission service configuration
    services.transmission = {
      enable = true;

      # Use Transmission 4 (required in NixOS 24.11+)
      package = pkgs.transmission_4;

      # Use media user/group for file access compatibility
      inherit (cfg) user group;

      # WebUI accessible from host network
      home = "/var/lib/transmission";

      # Use credentialsFile for SOPS secrets, or configure inline for plaintext
      credentialsFile =
        if transmissionCfg.authentication != null && transmissionCfg.authentication.useSops then
          config.sops.templates."transmission-credentials.json".path
        else
          null;

      settings =
        let
          # Authentication configuration (only for non-SOPS mode)
          authConfig =
            if
              transmissionCfg.authentication != null
              && transmissionCfg.authentication.enable
              && !transmissionCfg.authentication.useSops
            then
              {
                rpc-authentication-required = true;
                rpc-username = transmissionCfg.authentication.username;
                rpc-password = transmissionCfg.authentication.password;
              }
            else if transmissionCfg.authentication != null && transmissionCfg.authentication.useSops then
              {
                # credentialsFile will handle these
                rpc-authentication-required = true;
              }
            else
              {
                rpc-authentication-required = false;
              };
        in
        {
          # Download paths
          download-dir = transmissionCfg.downloadDir;
          incomplete-dir = transmissionCfg.incompleteDir;
          incomplete-dir-enabled = true;

          # Peer port (will be dynamically updated by NAT-PMP)
          peer-port = transmissionCfg.peerPort;
          peer-port-random-on-start = false;

          # WebUI configuration
          rpc-enabled = true;
          rpc-port = transmissionCfg.webUIPort;
          rpc-bind-address = "0.0.0.0";
          rpc-whitelist-enabled = false; # Allow from any IP (auth protects access)
          rpc-host-whitelist-enabled = false;

          # Basic limits (minimal configuration)
          speed-limit-up-enabled = false;
          speed-limit-down-enabled = false;

          # Ratio limits (disabled by default)
          ratio-limit-enabled = false;
        }
        // authConfig;
    };

    # VPN confinement when enabled
    systemd.services.transmission = mkIf transmissionCfg.vpn.enable {
      vpnConfinement = {
        enable = true;
        vpnNamespace = transmissionCfg.vpn.namespace;
      };
      wants = [ "network-online.target" ];
    };
  };
}
