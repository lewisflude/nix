{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  inherit (config.host) username;
  cfg = config.host.services.syncthing;
in
{
  options.host.services.syncthing = {
    enable = mkEnableOption "Syncthing peer-to-peer file synchronization";

    devices = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            id = mkOption {
              type = types.str;
              description = "Syncthing device ID (get via: syncthing --device-id)";
            };
            addresses = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Addresses to connect to this device (optional for LAN discovery)";
            };
          };
        }
      );
      default = { };
      description = "Syncthing devices to sync with";
      example = {
        jupiter = {
          id = "XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX-XXXXXXX";
          addresses = [ "tcp://192.168.10.210:22000" ];
        };
      };
    };

    folders = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            path = mkOption {
              type = types.str;
              description = "Path to the folder to sync";
            };
            devices = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "List of device names to sync this folder with";
            };
            versioning = mkOption {
              type = types.nullOr types.attrs;
              default = null;
              description = "Versioning configuration (optional)";
              example = {
                type = "simple";
                params.keep = "5";
              };
            };
          };
        }
      );
      default = { };
      description = "Folders to synchronize";
      example = {
        "Documents" = {
          path = "/home/lewis/Documents";
          devices = [
            "jupiter"
            "mercury"
          ];
        };
      };
    };

    guiAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:8384";
      description = "Address for the Syncthing web GUI";
    };
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = username;
      dataDir = "/home/${username}/.syncthing";
      configDir = "/home/${username}/.config/syncthing";

      # Map our simplified device structure to Syncthing's format
      devices = lib.mapAttrs (_name: device: {
        inherit (device) id addresses;
      }) cfg.devices;

      # Map our simplified folder structure to Syncthing's format
      folders = lib.mapAttrs (_name: folder: {
        inherit (folder) path devices versioning;
      }) cfg.folders;

      settings = {
        options = {
          urAccepted = -1; # Disable usage reporting
          globalAnnounceEnabled = false; # LAN-only discovery (no internet relay)
          localAnnounceEnabled = true; # Enable local network discovery
          relaysEnabled = false; # Disable relay servers (direct connections only)
        };
        gui = {
          address = cfg.guiAddress;
        };
      };
    };

    # Note: Firewall configuration should be handled at the host level for NixOS systems
    # Example for NixOS hosts:
    # networking.firewall.allowedTCPPorts = [ 22000 ];
    # networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
