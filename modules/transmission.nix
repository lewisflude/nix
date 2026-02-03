# Transmission Service Module - Dendritic Pattern
# BitTorrent client with web UI
# Usage: Import flake.modules.nixos.transmission in host definition
{ config, ... }:
let
  constants = config.constants;
  inherit (config) username;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.transmission = { pkgs, lib, ... }:
  let
    inherit (lib) mkDefault;

    # Default configuration (can be overridden by hosts)
    user = "media";
    group = "media";
    webUIPort = constants.ports.services.transmission;
    downloadDir = "/mnt/storage/torrents";
    incompleteDir = "/var/lib/transmission/incomplete";
    peerPort = 62000;
  in
  {
    # Ensure media user/group exist
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      description = "Media management user";
    };
    users.groups.${group} = { };

    # Ensure required directories exist
    systemd.tmpfiles.rules = [
      "d '${incompleteDir}' 0750 ${user} ${group} - -"
      "d '${downloadDir}' 0750 ${user} ${group} - -"
    ];

    # Transmission service configuration
    services.transmission = {
      enable = true;

      # Use Transmission 4 (required in NixOS 24.11+)
      package = pkgs.transmission_4;

      # Use media user/group for file access compatibility
      inherit user group;

      # WebUI accessible from host network
      home = "/var/lib/transmission";

      settings = {
        # Download paths
        download-dir = downloadDir;
        incomplete-dir = incompleteDir;
        incomplete-dir-enabled = true;

        # Peer port (will be dynamically updated by NAT-PMP if VPN with port forwarding)
        peer-port = peerPort;
        peer-port-random-on-start = false;

        # Network configuration
        # IMPORTANT: Disable IPv6 because ProtonVPN's NAT-PMP port forwarding is IPv4-only
        bind-address-ipv4 = "0.0.0.0";
        bind-address-ipv6 = ""; # Empty string disables IPv6

        # WebUI configuration
        rpc-enabled = true;
        rpc-port = webUIPort;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false; # Allow from any IP (configure auth to protect access)
        rpc-host-whitelist-enabled = false;

        # Authentication (disabled by default - hosts should enable and configure)
        rpc-authentication-required = mkDefault false;

        # Basic limits (minimal configuration)
        speed-limit-up-enabled = false;
        speed-limit-down-enabled = false;

        # Ratio limits (disabled by default - hosts can enable)
        ratio-limit-enabled = false;
      };
    };

    # Firewall configuration
    networking.firewall = {
      allowedTCPPorts = mkDefault [
        webUIPort
        peerPort
      ];
      allowedUDPPorts = mkDefault [ peerPort ];
    };

    # Security hardening
    systemd.services.transmission = {
      serviceConfig = {
        # Restrict filesystem access
        ProtectHome = mkDefault "read-only";
        ReadWritePaths = [
          downloadDir
          incompleteDir
          "/var/lib/transmission"
        ];
      };
      wants = [ "network-online.target" ];
    };
  };
}
