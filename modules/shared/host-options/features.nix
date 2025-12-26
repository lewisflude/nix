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
      enable = mkEnableOption "development tools and environments" // {
        default = true;
      };

      rust = mkEnableOption "Rust development environment" // {
        default = true;
      };
      python = mkEnableOption "Python development environment" // {
        default = true;
      };
      go = mkEnableOption "Go development environment" // {
        default = false;
      };
      node = mkEnableOption "Node.js/TypeScript development" // {
        default = true;
      };
      lua = mkEnableOption "Lua development environment" // {
        default = false;
      };
      java = mkEnableOption "Java development environment" // {
        default = false;
      };
      nix = mkEnableOption "Nix development tools";

      docker = mkEnableOption "Docker and containerization";
      git = mkEnableOption "Git and version control tools";
      neovim = mkEnableOption "Neovim text editor" // {
        default = false;
      };
    };

    gaming = {
      enable = mkEnableOption "gaming platforms and optimizations";
      steam = mkEnableOption "Steam gaming platform";
      performance = mkEnableOption "gaming performance optimizations";
      lutris = mkEnableOption "Lutris game manager";
      emulators = mkEnableOption "gaming emulators";
    };

    vr = {
      enable = mkEnableOption "virtual reality support and optimizations";
      alvr = mkEnableOption "ALVR wireless VR streaming" // {
        default = true;
      };
      monado = mkEnableOption "Monado OpenXR runtime" // {
        default = true;
      };
      wivrn = {
        enable = mkEnableOption "WiVRn wireless VR streaming";
        autoStart = mkEnableOption "Start WiVRn service automatically on boot";
        defaultRuntime = mkEnableOption "Set WiVRn as default OpenXR runtime";
        openFirewall = mkEnableOption "Open firewall ports for WiVRn" // {
          default = true;
        };
      };
      opencomposite = mkEnableOption "OpenComposite (OpenVR to OpenXR translation)";
      steamvr = mkEnableOption "SteamVR support";
      sidequest = mkEnableOption "SideQuest for Quest sideloading" // {
        default = true;
      };
      performance = mkEnableOption "VR-specific performance optimizations" // {
        default = true;
      };
    };

    virtualisation = {
      enable = mkEnableOption "virtual machines and containers";
      docker = mkEnableOption "Docker containers";
      podman = mkEnableOption "Podman containers";
    };

    homeServer = {
      enable = mkEnableOption "home server and self-hosting";
      homeAssistant = mkEnableOption "Home Assistant home automation";
      fileSharing = mkEnableOption "Samba/NFS file sharing";
      backups = mkEnableOption "Restic backup services";
    };

    desktop = {
      enable = mkEnableOption "desktop environment and customization" // {
        default = true;
      };
      niri = mkEnableOption "Niri Wayland compositor" // {
        default = false;
      };
      hyprland = mkEnableOption "Hyprland Wayland compositor" // {
        default = false;
      };
      theming = mkEnableOption "system-wide theming" // {
        default = true;
      };
      utilities = mkEnableOption "desktop utilities" // {
        default = false;
      };

      # Signal theme options
      signalTheme = {
        enable = mkEnableOption "Signal OKLCH color palette theme" // {
          default = true;
        };
        mode = mkOption {
          type = types.enum [
            "light"
            "dark"
            "auto"
          ];
          default = "dark";
          description = ''
            Color theme mode:
            - light: Use light mode colors
            - dark: Use dark mode colors
            - auto: Follow system preference (defaults to dark)
          '';
        };
      };
    };

    restic = {
      enable = mkEnableOption "Restic backup integration" // {
        default = false;
      };

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
        enable = mkEnableOption "Restic REST server" // {
          default = false;
        };
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
      office = mkEnableOption "office suite (LibreOffice)";
      notes = mkEnableOption "note-taking (Obsidian)";
      email = mkEnableOption "email clients";
      calendar = mkEnableOption "calendar applications";
      resume = mkEnableOption "resume generation and management";
    };

    media = {
      enable = mkEnableOption "media production tools and environments" // {
        default = false;
      };

      audio = {
        enable = mkEnableOption "audio production and music";
        production = mkEnableOption "DAW and audio tools";
        realtime = mkEnableOption "real-time audio optimizations (musnix)";

        # Low-latency settings for professional audio work
        ultraLowLatency = mkOption {
          type = types.bool;
          default = false;
          description = "Enable ultra-low latency settings (64 frames @ 48kHz = ~1.3ms) for professional recording";
        };

        # USB audio interface optimization
        usbAudioInterface = {
          enable = mkEnableOption "USB audio interface optimizations (disable autosuspend, set IRQ priorities)";

          # PCI ID of the USB controller (not the audio device itself)
          # Find with: lspci | grep -i usb
          # Example: "00:14.0" for Intel xHCI controller
          pciId = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "PCI ID of the USB controller for latency timer optimization";
            example = "00:14.0";
          };
        };

        # musnix advanced options
        rtirq = mkOption {
          type = types.bool;
          default = true;
          description = "Enable rtirq for IRQ priority management (requires realtime kernel)";
        };

        dasWatchdog = mkOption {
          type = types.bool;
          default = true;
          description = "Enable das_watchdog to prevent RT processes from hanging the system";
        };

        rtcqs = mkOption {
          type = types.bool;
          default = true;
          description = "Install rtcqs (realtime configuration quick scan) analysis tool";
        };

        noiseCancellation = mkOption {
          type = types.bool;
          default = false;
          description = "Enable RNNoise-based noise cancellation filter (for voice chat/calls)";
        };

        echoCancellation = mkOption {
          type = types.bool;
          default = false;
          description = "Enable WebRTC-based echo cancellation (for voice chat/calls)";
        };

        audioNix = {
          enable = mkOption {
            type = types.bool;
            default = false;
            description = "Enable audio packages from polygon/audio.nix flake";
          };

          bitwig = mkOption {
            type = types.bool;
            default = false;
            description = "Install Bitwig Studio (latest beta version)";
          };

          plugins = mkOption {
            type = types.bool;
            default = false;
            description = "Install audio plugins from audio.nix (neuralnote, paulxstretch, etc.)";
          };
        };
      };

      video = {
        enable = mkEnableOption "video production and editing tools";

        editing = mkEnableOption "video editing tools (kdenlive, ffmpeg, handbrake, imagemagick, gimp)";

        streaming = mkEnableOption "video streaming tools (v4l2loopback for virtual camera)";
      };

      streaming = {
        enable = mkEnableOption "media streaming and recording (OBS Studio)";
      };
    };

    security = {
      enable = mkEnableOption "security and privacy tools";
      yubikey = mkEnableOption "YubiKey hardware support";
      gpg = mkEnableOption "GPG/PGP encryption";
      firewall = mkEnableOption "advanced firewall configuration (NixOS only)";
      fail2ban = mkEnableOption "fail2ban intrusion detection (NixOS only)";
    };

    aiTools = {
      enable = mkEnableOption "AI tools stack (Ollama, Open WebUI) - NixOS only" // {
        default = false;
      };

      ollama = {
        enable = mkEnableOption "Ollama LLM backend" // {
          default = true;
        };
        acceleration = mkOption {
          type = types.nullOr (
            types.enum [
              "rocm"
              "cuda"
            ]
          );
          default = null;
          description = "GPU acceleration type (null for CPU-only)";
        };
        models = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "List of models to pre-download";
        };
      };

      openWebui = {
        enable = mkEnableOption "Open WebUI interface for LLMs" // {
          default = true;
        };
        port = mkOption {
          type = types.port;
          default = 7000;
          description = "Port for Open WebUI";
        };
      };
    };
  };
}
