# Syncthing Service Module - Dendritic Pattern
# Peer-to-peer file synchronization
# Usage:
#   - NixOS hosts: import flake.modules.nixos.syncthing
#   - User-scope (Darwin / Linux without a system service): import
#     flake.modules.homeManager.syncthing in the host's home-manager block
# Folder/device wiring is contributed by feature modules (e.g. obsidian.nix).
{ config, ... }:
let
  inherit (config) constants;
  inherit (config) username;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.syncthing =
    { lib, ... }:
    let
      inherit (lib) mkDefault;
    in
    {
      services.syncthing = {
        enable = true;
        user = username;
        dataDir = "/home/${username}/.syncthing";
        configDir = "/home/${username}/.config/syncthing";

        settings = {
          options = {
            urAccepted = -1; # Disable usage reporting
            globalAnnounceEnabled = false; # LAN/tailnet-only discovery
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

  # ==========================================================================
  # Home-Manager User Service (Darwin via launchd, Linux via systemd --user)
  # ==========================================================================
  flake.modules.homeManager.syncthing =
    { lib, ... }:
    {
      services.syncthing = {
        enable = true;
        overrideDevices = lib.mkDefault true;
        overrideFolders = lib.mkDefault true;
        settings = {
          options = {
            urAccepted = -1;
            globalAnnounceEnabled = lib.mkDefault false;
            localAnnounceEnabled = lib.mkDefault true;
            relaysEnabled = lib.mkDefault false;
          };
          gui.address = lib.mkDefault "127.0.0.1:8384";
        };
      };
    };
}
