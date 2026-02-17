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
    { pkgs, lib, ... }:
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
        inputs.nixpkgs-xr.nixosModules.nixpkgs-xr

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
        nixos.power
        nixos.memory

        # ═══════════════════════════════════════════════════════════════════════
        # Hardware Modules
        # ═══════════════════════════════════════════════════════════════════════
        nixos.bluetooth
        nixos.keyboard
        nixos.mouse
        nixos.usb
        nixos.gpg # GPG + YubiKey hardware support (merged module)

        # ═══════════════════════════════════════════════════════════════════════
        # Desktop Environment (dendritic: explicit imports, not aggregation)
        # ═══════════════════════════════════════════════════════════════════════
        nixos.niri
        nixos.dms
        nixos.graphics
        nixos.fonts
        nixos.greeter
        nixos.console
        nixos.xwayland
        nixos.hardwareSupport
        nixos.desktopEnvironment
        nixos.desktopUserGroups

        # ═══════════════════════════════════════════════════════════════════════
        # Gaming & VR
        # ═══════════════════════════════════════════════════════════════════════
        nixos.gaming
        nixos.vr

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
        nixos.caddy
        nixos.syncthing
        nixos.sunshine
        nixos.homeAssistant
        nixos.musicAssistant
        nixos.wyoming

        # ═══════════════════════════════════════════════════════════════════════
        # Media Management Services
        # ═══════════════════════════════════════════════════════════════════════
        nixos.prowlarr
        nixos.radarr
        nixos.sonarr
        nixos.lidarr
        nixos.bazarr
        nixos.autobrr
        nixos.readarr
        nixos.jellyfin
        nixos.sabnzbd
        nixos.flaresolverr
        nixos.jellyseerr

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
        nixos.ollama
        nixos.claudeCode

        # ═══════════════════════════════════════════════════════════════════════
        # Container Services
        # ═══════════════════════════════════════════════════════════════════════
        nixos.podmanContainers

        # ═══════════════════════════════════════════════════════════════════════
        # Desktop Extras
        # ═══════════════════════════════════════════════════════════════════════
        nixos.colord
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
        inputs.ironbar.homeManagerModules.default
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
        homeManager.atuin
        homeManager.direnv
        homeManager.fzf
        homeManager.zellij
        homeManager.gh
        homeManager.git-cliff
        homeManager.helix
        homeManager.nixYourShell
        homeManager.powerlevel10k
        homeManager.userPackages
        homeManager.claudeCode
        homeManager.geminiCli
        homeManager.yazi
        homeManager.mpv
        homeManager.obsidian
        homeManager.zed

        # Desktop home-manager modules
        homeManager.browser
        homeManager.desktopApps
        homeManager.niri
        homeManager.dms
        homeManager.flatpak
        homeManager.theming
        homeManager.developmentTools

        # Gaming & VR home-manager modules
        homeManager.gaming
        homeManager.lutris
        homeManager.vr

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
        inherit useremail;
        hostname = "jupiter";
        system = "x86_64-linux";
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

      # =========================================================================
      # Hardware Configuration
      # =========================================================================
      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      boot.kernelModules = [
        "kvm-intel"
        "zfs"
        "hid_sony"
      ];

      hardware = {
        cpu.intel.updateMicrocode = true;
        enableAllFirmware = true;
        i2c.enable = true;
      };

      fileSystems = {
        "/" = {
          device = "npool/root";
          fsType = "zfs";
        };
        "/home" = {
          device = "npool/home";
          fsType = "zfs";
        };
        "/boot" = {
          device = "/dev/disk/by-label/BOOT";
          fsType = "vfat";
        };
        "/var/lib/docker" = {
          device = "npool/docker";
          fsType = "zfs";
        };
        "/mnt/disk1" = {
          device = "/dev/disk/by-id/ata-WDC_WD140EDFZ-11A0VA0_9LGED2YG-part1";
          fsType = "xfs";
          options = [
            "defaults"
            "nofail"
          ];
        };
        "/mnt/disk2" = {
          device = "/dev/disk/by-id/ata-WDC_WD140EDFZ-11A0VA0_Y5JTWKLC-part1";
          fsType = "xfs";
          options = [
            "defaults"
            "nofail"
          ];
        };
        "/mnt/storage" = {
          device = "/mnt/disk1:/mnt/disk2";
          fsType = "fuse.mergerfs";
          options = [
            "defaults"
            "nonempty"
            "allow_other"
            "use_ino"
            "cache.files=partial"
            "dropcacheonclose=true"
            "category.create=mfs"
            "minfreespace=1G"
            "fsname=mergerfs"
            "x-systemd.before=local-fs.target"
          ];
        };
      };

      swapDevices = [ { device = "/dev/disk/by-uuid/65835c4c-3b5f-4ced-bf61-c73a6e76e562"; } ];

      # =========================================================================
      # Boot Configuration
      # =========================================================================
      boot.loader = {
        systemd-boot.enable = true;
        systemd-boot.configurationLimit = 5;
        efi.canTouchEfiVariables = true;
      };

      boot.kernelParams = [
        "nvidia-drm.modeset=1"
        "nvidia-drm.fbdev=1"
        "nvidia-modeset.conceal_vrr_caps=1"
        "cfg80211.ieee80211_regdom=GB"
      ];

      boot.tmp = {
        useTmpfs = true;
        tmpfsSize = "50%";
      };

      # Networking
      networking.networkmanager.enable = true;
      # Power
      powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

      # Prevent suspend when KVM-switched away (no display = idle)
      services.logind.settings.Login = {
        IdleAction = "ignore";
        HandleLidSwitch = "ignore";
      };

      # Security: Passwordless sudo is appropriate for passwordless account with YubiKey at login
      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };

      # Users
      users.mutableUsers = false;
      users.users.${username} = {
        hashedPassword = "$6$//f/zVkBeZS97o3y$MQtzsxbe9oFflYcVt026cEGslOZEgA/ZVg1YY4TMbjGIbLwgfxbnp0tXjFGTuha7VJGGAJ5Xskir972JuFwsn/";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEyBDIzK/OoFY7M1i96wP9wE+OeKk56iTvPwStEiFc+k lewis@lewisflude.com"
          "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBGB2FdscjELsv6fQ4dwLN7ky3Blye+pxJHBfACdYmxhgPodPaRLqbekyrt+XDdXvQYmuiZ0XIa/fL4/452g5MWcAAAAEc3NoOg== lewis@lewisflude.com"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuc2y4LO/GMf02/as8OqUB+zKl+sU44umYXNVC7KzF9 termix@phone"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBL9zRrDvYpeH9zmtzNEMbMaML1mZOilWZbWfHtwDP0cn36PO0lyuRqsKYlrgmCrTdGkh34gk2hQvI4HMeGf2Bxs="
        ];
        extraGroups = [
          "dialout"
          "admin"
          "wheel"
          "staff"
          "_developer"
          "git"
          "i2c"
          "media"
          "audio"
          "uinput"
          "video"
        ];
      };

      # Packages
      environment.systemPackages = [
        pkgs.mergerfs
        pkgs.xfsprogs
      ];

    };
}
