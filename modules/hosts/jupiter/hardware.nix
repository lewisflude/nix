# Jupiter hardware configuration
# Filesystems (ZFS + mergerfs), kernel modules, boot loader, user credentials
{ config, ... }:
let
  inherit (config) username constants;
in
{
  # Merges into the same jupiter NixOS configuration as definition.nix
  configurations.nixos.jupiter.module =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      # =========================================================================
      # Kernel & Hardware
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
        "hid_sony"
      ];

      hardware = {
        cpu.intel.updateMicrocode = true;
        enableAllFirmware = true;
        i2c.enable = true;
      };

      # =========================================================================
      # Filesystems
      # =========================================================================
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

      # Compressed RAM swap on top of the 4 GiB partition. Gives systemd-oomd
      # real headroom during heavy parallel source builds instead of instantly
      # exhausting the tiny partition. zstd is fast and compresses build/heap
      # pages well; the device only consumes RAM as pages are actually swapped.
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 40;
      };

      environment.systemPackages = [
        pkgs.mergerfs
        pkgs.xfsprogs
      ];

      # =========================================================================
      # Boot Loader
      # =========================================================================
      boot.loader = {
        systemd-boot.enable = true;
        systemd-boot.configurationLimit = 20;
        efi.canTouchEfiVariables = true;
      };

      boot.kernelParams = [
        "nvidia-drm.modeset=1"
        "nvidia-drm.fbdev=1"
        "nvidia-modeset.conceal_vrr_caps=1"
        "cfg80211.ieee80211_regdom=GB"
        # Cap ZFS ARC at 24 GiB (of 62 GiB). Uncapped, ARC grows to ~all RAM
        # and doesn't evict fast enough against parallel source builds
        # (home-assistant, sunshine, wivrn-cuda) that compile in the tmpfs
        # /tmp, so systemd-oomd kills the build. 24 GiB leaves ~38 GiB free.
        # Takes effect on reboot (kernel-module param).
        "zfs.zfs_arc_max=25769803776"
      ];

      boot.tmp = {
        useTmpfs = true;
        tmpfsSize = "50%";
      };

      # =========================================================================
      # Host-Specific System Tweaks
      # =========================================================================
      networking.networkmanager.enable = true;
      powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

      # Prevent suspend when KVM-switched away (no display = idle)
      services.logind.settings.Login = {
        IdleAction = "ignore";
        HandleLidSwitch = "ignore";
      };

      # Passwordless sudo: appropriate for passwordless account with YubiKey at login
      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };

      # =========================================================================
      # User Credentials & Groups
      # =========================================================================
      users.mutableUsers = false;
      users.users.${username} = {
        hashedPasswordFile = config.sops.secrets.hashedPassword.path;
        openssh.authorizedKeys.keys = constants.authorizedKeys;
        extraGroups = [
          "dialout"
          "wheel"
          "i2c"
          "media"
          "video"
          "uinput"
          "libvirtd"
        ];
      };
    };
}
