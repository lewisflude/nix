# Host options for the dendritic pattern
# Defines host.* options that feature modules set when imported
# Home-manager modules can read these via osConfig/systemConfig
{ config, lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
  # Dendritic pattern: Access constants via top-level config
  meta = config.constants or {};
in
{
  # Define host options for both NixOS and Darwin
  flake.modules.nixos.base = {
    options.host = {
      username = mkOption {
        type = types.str;
        description = "Primary user's username";
      };

      useremail = mkOption {
        type = types.str;
        default = "";
        description = "Primary user's email address";
      };

      hostname = mkOption {
        type = types.str;
        description = "System hostname";
      };

      system = mkOption {
        type = types.str;
        description = "System architecture";
      };

      # Hardware options
      hardware = {
        renderDevice = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "DRM render device path for GPU selection";
        };
      };

      # Feature flags - set by importing feature modules
      features = {
        # Gaming
        gaming = {
          enable = mkEnableOption "gaming platforms and optimizations";
          steam = mkEnableOption "Steam gaming platform";
          performance = mkEnableOption "gaming performance optimizations";
          lutris = mkEnableOption "Lutris game manager";
          emulators = mkEnableOption "gaming emulators";
        };

        # VR
        vr = {
          enable = mkEnableOption "VR support";
          wivrn = {
            enable = mkEnableOption "WiVRn wireless VR";
            autoStart = mkEnableOption "auto-start WiVRn" // { default = true; };
            defaultRuntime = mkEnableOption "set WiVRn as default OpenXR runtime" // { default = true; };
            openFirewall = mkEnableOption "open firewall for WiVRn" // { default = true; };
          };
          steamvr = mkEnableOption "SteamVR";
          immersed = {
            enable = mkEnableOption "Immersed VR";
            openFirewall = mkEnableOption "open firewall for Immersed" // { default = true; };
          };
          performance = mkEnableOption "VR performance optimizations" // { default = true; };
        };

        # Desktop
        desktop = {
          enable = mkEnableOption "desktop environment" // { default = true; };
          niri = mkEnableOption "Niri Wayland compositor";
          theming = mkEnableOption "system-wide theming" // { default = true; };
          utilities = mkEnableOption "desktop utilities";
          autoLogin = {
            enable = mkEnableOption "auto-login";
            user = mkOption {
              type = types.str;
              default = "";
              description = "User to auto-login";
            };
          };
          signalTheme = {
            enable = mkEnableOption "Signal theme" // { default = true; };
            mode = mkOption {
              type = types.enum [ "light" "dark" "auto" ];
              default = "dark";
              description = "Color theme mode";
            };
          };
        };

        # Productivity
        productivity = {
          enable = mkEnableOption "productivity tools";
          office = mkEnableOption "office suite";
          notes = mkEnableOption "note-taking";
          email = mkEnableOption "email clients";
          calendar = mkEnableOption "calendar applications";
          resume = mkEnableOption "resume tools";
        };

        # Security
        security = {
          enable = mkEnableOption "security tools";
          yubikey = mkEnableOption "YubiKey support";
          gpg = mkEnableOption "GPG encryption";
          firewall = mkEnableOption "advanced firewall";
          fail2ban = mkEnableOption "fail2ban";
        };

        # Development
        development = {
          enable = mkEnableOption "development tools";
          nix = mkEnableOption "Nix development" // { default = true; };
          git = mkEnableOption "Git version control" // { default = true; };
          neovim = mkEnableOption "Neovim editor";
          containers = mkEnableOption "container tools";
        };

        # AI Tools
        aiTools = {
          enable = mkEnableOption "AI tools";
          ollama = mkEnableOption "Ollama local LLM";
          openWebui = mkEnableOption "Open WebUI";
        };

        # Media
        media = {
          enable = mkEnableOption "media features";
          audio = {
            enable = mkEnableOption "audio support" // { default = true; };
            realtime = mkEnableOption "realtime audio";
          };
        };

        # Virtualisation
        virtualisation = {
          enable = mkEnableOption "virtualisation";
          docker = mkEnableOption "Docker";
          podman = mkEnableOption "Podman";
          libvirt = mkEnableOption "libvirt/QEMU";
        };
      };

      # Services options
      services = {
        caddy = {
          enable = mkEnableOption "Caddy reverse proxy";
          email = mkOption {
            type = types.str;
            default = "";
            description = "Email for ACME certificates";
          };
        };
      };
    };

    # Set defaults from meta
    config.host = lib.mkIf (config.options.host.username.isDefined or false) {
      system = lib.mkDefault "x86_64-linux";
    };
  };

  # Darwin version (subset of options)
  flake.modules.darwin.base = {
    options.host = {
      username = mkOption {
        type = types.str;
        description = "Primary user's username";
      };

      useremail = mkOption {
        type = types.str;
        default = "";
        description = "Primary user's email address";
      };

      hostname = mkOption {
        type = types.str;
        description = "System hostname";
      };

      system = mkOption {
        type = types.str;
        description = "System architecture";
      };

      features = {
        desktop = {
          enable = mkEnableOption "desktop environment" // { default = true; };
          theming = mkEnableOption "system-wide theming" // { default = true; };
          utilities = mkEnableOption "desktop utilities";
          niri = mkEnableOption "Niri Wayland compositor"; # NixOS-only, but defined for option consistency
          autoLogin = {
            enable = mkEnableOption "auto-login";
            user = mkOption {
              type = types.str;
              default = "";
              description = "User to auto-login";
            };
          };
          signalTheme = {
            enable = mkEnableOption "Signal theme" // { default = true; };
            mode = mkOption {
              type = types.enum [ "light" "dark" "auto" ];
              default = "dark";
              description = "Color theme mode";
            };
          };
        };

        productivity = {
          enable = mkEnableOption "productivity tools";
          office = mkEnableOption "office suite";
          notes = mkEnableOption "note-taking";
          email = mkEnableOption "email clients";
          calendar = mkEnableOption "calendar applications";
          resume = mkEnableOption "resume tools";
        };

        security = {
          enable = mkEnableOption "security tools";
          yubikey = mkEnableOption "YubiKey support";
          gpg = mkEnableOption "GPG encryption";
        };

        gaming = {
          enable = mkEnableOption "gaming";
        };

        vr = {
          enable = mkEnableOption "VR";
          immersed = {
            enable = mkEnableOption "Immersed VR";
          };
        };

        # Development (same as NixOS for cross-platform consistency)
        development = {
          enable = mkEnableOption "development tools";
          nix = mkEnableOption "Nix development" // { default = true; };
          git = mkEnableOption "Git version control" // { default = true; };
          neovim = mkEnableOption "Neovim editor";
          containers = mkEnableOption "container tools";
        };

        # AI Tools
        aiTools = {
          enable = mkEnableOption "AI tools";
          ollama = mkEnableOption "Ollama local LLM";
          openWebui = mkEnableOption "Open WebUI";
        };

        # Media
        media = {
          enable = mkEnableOption "media features";
          audio = {
            enable = mkEnableOption "audio support" // { default = true; };
            realtime = mkEnableOption "realtime audio";
          };
        };

        # Virtualisation
        virtualisation = {
          enable = mkEnableOption "virtualisation";
          docker = mkEnableOption "Docker";
          podman = mkEnableOption "Podman";
          libvirt = mkEnableOption "libvirt/QEMU";
        };
      };
    };

    config.host = {
      system = lib.mkDefault "aarch64-darwin";
    };
  };
}
