# Syncthing Service Module - Dendritic Pattern
# Peer-to-peer file synchronization
# Usage: Import flake.modules.nixos.syncthing in host definition
{ config, ... }:
let
  constants = config.constants;
  inherit (config) username;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.syncthing = { lib, ... }:
  let
    inherit (lib) mkDefault;
  in
  {
    services.syncthing = {
      enable = true;
      user = username;
      dataDir = "/home/${username}/.syncthing";
      configDir = "/home/${username}/.config/syncthing";

      # Devices and folders should be configured by hosts
      # Example:
      # devices = {
      #   jupiter = {
      #     id = "XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX";
      #     addresses = [ "tcp://192.168.10.210:22000" ];
      #   };
      # };
      # folders = {
      #   "Documents" = {
      #     path = "/home/${username}/Documents";
      #     devices = [ "jupiter" "mercury" ];
      #   };
      # };

      settings = {
        options = {
          urAccepted = -1; # Disable usage reporting
          globalAnnounceEnabled = false; # LAN-only discovery (no internet relay)
          localAnnounceEnabled = true; # Enable local network discovery
          relaysEnabled = false; # Disable relay servers (direct connections only)
        };
        gui = {
          address = mkDefault "127.0.0.1:8384";
        };
      };
    };

    # Firewall configuration
    networking.firewall = {
      allowedTCPPorts = mkDefault [ constants.ports.services.syncthing.sync ];
      allowedUDPPorts = mkDefault [
        constants.ports.services.syncthing.sync
        constants.ports.services.syncthing.discovery
      ];
    };
  };
}
