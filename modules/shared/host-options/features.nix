{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.host.features = {
    development = {
      enable = mkEnableOption "development tools and environments";

      rust = mkEnableOption "Rust development environment";
      python = mkEnableOption "Python development environment";
      go = mkEnableOption "Go development environment";
      node = mkEnableOption "Node.js/TypeScript development";
      lua = mkEnableOption "Lua development environment";
      java = mkEnableOption "Java development environment";
      nix = mkEnableOption "Nix development tools";

      docker = mkEnableOption "Docker and containerization";
      kubernetes = mkEnableOption "Kubernetes and container orchestration";
      git = mkEnableOption "Git and version control tools";
      buildTools = mkEnableOption "Build tools (make, cmake, pkg-config, etc.)";
      debugTools = mkEnableOption "Debug tools (lldb, gdb)";

      vscode = mkEnableOption "VS Code editor";
      helix = mkEnableOption "Helix editor";
      neovim = mkEnableOption "Neovim editor";
    };

    gaming = {
      enable = mkEnableOption "gaming platforms and optimizations";
      steam = mkEnableOption "Steam gaming platform";
      lutris = mkEnableOption "Lutris game manager";
      emulators = mkEnableOption "game console emulators";
      performance = mkEnableOption "gaming performance optimizations";
    };

    virtualisation = {
      enable = mkEnableOption "virtual machines and containers";
      docker = mkEnableOption "Docker containers";
      podman = mkEnableOption "Podman containers";
      qemu = mkEnableOption "QEMU virtual machines";
      virtualbox = mkEnableOption "VirtualBox VMs";
    };

    homeServer = {
      enable = mkEnableOption "home server and self-hosting";
      homeAssistant = mkEnableOption "Home Assistant smart home";
      mediaServer = mkEnableOption "Plex/Jellyfin media server";
      fileSharing = mkEnableOption "Samba/NFS file sharing";
      backups = mkEnableOption "automated backup systems";
    };

    desktop = {
      enable = mkEnableOption "desktop environment and customization";
      niri = mkEnableOption "Niri Wayland compositor";
      hyprland = mkEnableOption "Hyprland Wayland compositor";
      theming = mkEnableOption "system-wide theming";
      utilities = mkEnableOption "desktop utilities";
    };

    restic = {
      enable = mkEnableOption "Restic backup integration";

      backups = mkOption {
        type = types.attrsOf (
          types.submodule (_: {
            options = {
              enable = mkEnableOption "Enable this Restic backup job";
              path = mkOption {
                type = types.str;
                description = "Path to back up.";
              };
              repository = mkOption {
                type = types.str;
                description = "Restic repository URL.";
              };
              passwordFile = mkOption {
                type = types.str;
                description = "Path to the file containing the repository password.";
              };
              timer = mkOption {
                type = types.str;
                default = "daily";
                description = "Timer specification for the backup job (e.g., 'daily').";
              };
              user = mkOption {
                type = types.str;
                default = "root";
                description = "User account that owns the backup job.";
              };
              extraOptions = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "Additional CLI options passed to restic.";
              };
              initialize = mkOption {
                type = types.bool;
                default = false;
                description = "Initialise the repository if it does not yet exist.";
              };
              createWrapper = mkOption {
                type = types.bool;
                default = false;
                description = "Create a security wrapper for restic to access protected paths.";
              };
            };
          })
        );
        default = { };
        description = "Per-backup job configuration for Restic.";
      };

      restServer = {
        enable = mkEnableOption "Restic REST server";
        port = mkOption {
          type = types.int;
          default = 8000;
          description = "Port the Restic REST server listens on.";
        };
        extraFlags = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional flags for restic-rest-server.";
        };
        htpasswdFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Path to an htpasswd file for server authentication.";
        };
      };
    };

    productivity = {
      enable = mkEnableOption "productivity and office tools";
      office = mkEnableOption "LibreOffice suite";
      notes = mkEnableOption "note-taking (Obsidian)";
      email = mkEnableOption "email clients";
      calendar = mkEnableOption "calendar applications";
      resume = mkEnableOption "resume generation and management";
    };

    media = {
      enable = mkEnableOption "media production tools and environments";

      audio = {
        enable = mkEnableOption "audio production and music";
        production = mkEnableOption "DAW and audio tools";
        realtime = mkEnableOption "real-time audio optimizations (musnix)";
        streaming = mkEnableOption "audio streaming";

        audioNix = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable audio packages from polygon/audio.nix flake";
          };

          bitwig = mkOption {
            type = types.bool;
            default = true;
            description = "Install Bitwig Studio (latest beta version)";
          };

          plugins = mkOption {
            type = types.bool;
            default = true;
            description = "Install audio plugins from audio.nix (neuralnote, paulxstretch, etc.)";
          };
        };
      };

      video = {
        enable = mkEnableOption "video production and editing";
        editing = mkEnableOption "Video editing tools (Kdenlive, etc.)";
        streaming = mkEnableOption "Video streaming tools (OBS, etc.)";
      };

      streaming = {
        enable = mkEnableOption "Streaming and recording tools";
        obs = mkEnableOption "OBS Studio for streaming/recording";
      };
    };

    security = {
      enable = mkEnableOption "security and privacy tools";
      yubikey = mkEnableOption "YubiKey hardware support";
      gpg = mkEnableOption "GPG/PGP encryption";
      firewall = mkEnableOption "advanced firewall";
    };
  };
}
