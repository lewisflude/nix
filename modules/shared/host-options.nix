# Host configuration options with type safety
# Defines a proper module options interface for host-specific configuration
{
  lib,
  config,
  ...
}:
with lib; {
  options.host = {
    username = mkOption {
      type = types.str;
      description = "Primary user's username";
      example = "lewis";
    };

    useremail = mkOption {
      type = types.str;
      description = "Primary user's email address";
      example = "lewis@example.com";
    };

    hostname = mkOption {
      type = types.str;
      description = "System hostname";
      example = "jupiter";
    };

    system = mkOption {
      type = types.str;
      description = "System architecture (e.g., x86_64-linux, aarch64-darwin)";
      example = "x86_64-linux";
    };

    features = {
      development = {
        enable = mkEnableOption "development tools and environments";
        rust = mkEnableOption "Rust development environment";
        python = mkEnableOption "Python development environment";
        go = mkEnableOption "Go development environment";
        node = mkEnableOption "Node.js/TypeScript development";
        lua = mkEnableOption "Lua development environment";
        docker = mkEnableOption "Docker and containerization";
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

      productivity = {
        enable = mkEnableOption "productivity and office tools";
        office = mkEnableOption "LibreOffice suite";
        notes = mkEnableOption "note-taking (Obsidian)";
        email = mkEnableOption "email clients";
        calendar = mkEnableOption "calendar applications";
      };

      audio = {
        enable = mkEnableOption "audio production and music";
        production = mkEnableOption "DAW and audio tools";
        realtime = mkEnableOption "real-time audio optimizations";
        streaming = mkEnableOption "audio streaming";
      };

      security = {
        enable = mkEnableOption "security and privacy tools";
        yubikey = mkEnableOption "YubiKey hardware support";
        gpg = mkEnableOption "GPG/PGP encryption";
        vpn = mkEnableOption "VPN clients";
        firewall = mkEnableOption "advanced firewall";
      };
    };

    # Legacy virtualisation config for backward compatibility
    virtualisation = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Legacy virtualisation configuration (deprecated, use host.features.virtualisation)";
    };
  };

  config = {
    # Validation assertions
    assertions = [
      {
        assertion = config.host.username != "";
        message = "host.username must be set";
      }
      {
        assertion = config.host.hostname != "";
        message = "host.hostname must be set";
      }
      {
        assertion = builtins.match ".*@.*" config.host.useremail != null;
        message = "host.useremail must be a valid email address";
      }
    ];
  };
}
