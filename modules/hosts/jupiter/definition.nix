# Jupiter - NixOS desktop workstation
# Primary host with NVIDIA RTX 4090, VR (WiVRn), home server services
# Follows dendritic pattern: ALL modules imported here, not in infrastructure
{ config, inputs, ... }:
let
  inherit (config) constants;
  inherit (config) username useremail;
  inherit (config.flake.modules) nixos homeManager;
in
{
  configurations.nixos.jupiter.module =
    { ... }:
    {
      imports = [
        # ═══════════════════════════════════════════════════════════════════════
        # External Input Modules (NixOS)
        # ═══════════════════════════════════════════════════════════════════════
        inputs.nixpkgs.nixosModules.notDetected
        inputs.nixos-hardware.nixosModules.common-cpu-intel
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        inputs.niri.nixosModules.niri
        inputs.musnix.nixosModules.musnix
        inputs.determinate.nixosModules.default
        inputs.vpn-confinement.nixosModules.default
        inputs.dms.nixosModules.default
        inputs.dms.nixosModules.greeter
        inputs.solaar.nixosModules.default

        # ═══════════════════════════════════════════════════════════════════════
        # Core Modules (dendritic: each concern has its own module)
        # ═══════════════════════════════════════════════════════════════════════
        nixos.hostOptions
        nixos.nix
        nixos.nixpkgs
        nixos.sops
        nixos.users
        nixos.homeManagerBase

        # ═══════════════════════════════════════════════════════════════════════
        # Core NixOS Modules
        # ═══════════════════════════════════════════════════════════════════════
        nixos.boot
        nixos.networking
        nixos.wakeOnLan
        nixos.security

        # ═══════════════════════════════════════════════════════════════════════
        # Hardware Modules
        # ═══════════════════════════════════════════════════════════════════════
        nixos.bluetooth
        nixos.keyboard
        nixos.mouse
        nixos.gpg # GPG + YubiKey hardware support (merged module)

        # ═══════════════════════════════════════════════════════════════════════
        # Virtualization
        # ═══════════════════════════════════════════════════════════════════════
        nixos.gpuPassthrough

        # ═══════════════════════════════════════════════════════════════════════
        # Desktop Environment (dendritic: explicit imports, not aggregation)
        # ═══════════════════════════════════════════════════════════════════════
        nixos.niri
        nixos.graphics
        nixos.fonts
        nixos.greeter
        nixos.console
        nixos.hardwareSupport
        nixos.desktopEnvironment
        nixos.desktopUserGroups

        # ═══════════════════════════════════════════════════════════════════════
        # Gaming & VR
        # ═══════════════════════════════════════════════════════════════════════
        nixos.gaming
        nixos.vr
        nixos.vrchatCreation

        # ═══════════════════════════════════════════════════════════════════════
        # Audio & Music Production
        # ═══════════════════════════════════════════════════════════════════════
        nixos.audio
        nixos.musicProduction

        # ═══════════════════════════════════════════════════════════════════════
        # Services
        # ═══════════════════════════════════════════════════════════════════════
        nixos.ssh
        nixos.samba
        nixos.nfs
        nixos.caddy
        nixos.filebrowser
        nixos.syncthing
        nixos.sunshine
        nixos.homeAssistant
        nixos.musicAssistant
        nixos.wyoming

        # ═══════════════════════════════════════════════════════════════════════
        # Media Management Services
        # ═══════════════════════════════════════════════════════════════════════
        nixos.mediaUser
        nixos.prowlarr
        nixos.radarr
        nixos.sonarr
        nixos.lidarr
        nixos.bazarr
        nixos.readarr
        nixos.jellyfin
        nixos.sabnzbd
        nixos.flaresolverr
        nixos.seerr
        nixos.recyclarr
        nixos.simpleContainers

        # ═══════════════════════════════════════════════════════════════════════
        # VPN & Downloads
        # ═══════════════════════════════════════════════════════════════════════
        nixos.qbittorrent
        nixos.protonvpnPortforward

        # ═══════════════════════════════════════════════════════════════════════
        # Security & Networking
        # ═══════════════════════════════════════════════════════════════════════
        nixos.fail2ban
        nixos.mosh
        nixos.eternalTerminal
        nixos.tailscale

        # ═══════════════════════════════════════════════════════════════════════
        # System Tools
        # ═══════════════════════════════════════════════════════════════════════
        nixos.keyd
        nixos.zfs
        nixos.nixLd
        nixos.flatpak
        nixos.restic

        # ═══════════════════════════════════════════════════════════════════════
        # AI Tools
        # ═══════════════════════════════════════════════════════════════════════
        nixos.claudeCode

        # ═══════════════════════════════════════════════════════════════════════
        # Container Services
        # ═══════════════════════════════════════════════════════════════════════
        nixos.podmanContainers

        # ═══════════════════════════════════════════════════════════════════════
        # Desktop Extras
        # ═══════════════════════════════════════════════════════════════════════
        nixos.printing
        nixos.xdgPortal
      ];

      # Required for NixOS
      nixpkgs.hostPlatform = "x86_64-linux";

      # =========================================================================
      # Home-Manager Module Imports (Dendritic: at host level)
      # =========================================================================
      home-manager.users.${username}.imports = [
        # External home-manager modules
        inputs.nix-index-database.homeModules.nix-index
        inputs.sops-nix.homeManagerModules.sops
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.dms.homeModules.default
        inputs.dms.homeModules.niri
        inputs.dms-plugin-registry.homeModules.default
        inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
        inputs.signal-nix.homeManagerModules.default

        # Core home-manager modules
        homeManager.shell
        homeManager.git
        homeManager.ssh
        homeManager.gpg
        homeManager.terminal
        homeManager.xdg
        homeManager.nh
        homeManager.sops
        homeManager.nixUser

        # CLI apps and editors
        homeManager.cliApps
        homeManager.zellij
        homeManager.gh
        homeManager.git-cliff
        homeManager.helix
        homeManager.powerlevel10k
        homeManager.claudeCode
        homeManager.geminiCli
        homeManager.yazi
        homeManager.iaGet
        homeManager.mpv
        homeManager.obsidian
        homeManager.zed

        # Desktop home-manager modules
        homeManager.browser
        homeManager.desktopApps
        homeManager.gimp
        homeManager.niri
        homeManager.niriOutputsJupiter
        homeManager.dms
        homeManager.flatpak
        homeManager.theming
        homeManager.developmentTools
        homeManager.javascript

        # Virtualization home-manager modules
        homeManager.gpuPassthrough

        # Gaming & VR home-manager modules
        homeManager.gaming
        homeManager.vr
        homeManager.vrchatCreation

        # Audio & Music Production home-manager modules
        homeManager.audio
        homeManager.musicProduction
        homeManager.liveCoding
      ];

      # =========================================================================
      # Host Identity
      # =========================================================================
      host = {
        inherit username;
        hostname = "jupiter";
        hardware.renderDevice = "/dev/dri/renderD128";

        features = {
          desktop.autoLogin = {
            enable = true;
            user = username;
          };
        };

        services.caddy = {
          enable = true;
          email = useremail;
        };
      };

      # =========================================================================
      # Core System Configuration
      # =========================================================================
      networking.hostName = "jupiter";
      networking.hostId = "8425e349";
      time.timeZone = constants.defaults.timezone;
      system.stateVersion = constants.defaults.stateVersion;

      # Hardware config, boot, filesystems, and user credentials are in hardware.nix
    };
}
