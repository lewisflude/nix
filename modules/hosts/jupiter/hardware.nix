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
      ...
    }@nixosArgs:
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
        # rasdaemon lives in modules/hardware-errors.nix, the module that reads
        # its database.
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
          # cache.files=off (mergerfs' own default) is deliberate. The old
          # cache.files=partial + dropcacheonclose=true recipe existed only
          # because FUSE could not do shared mmap without page caching. Kernel
          # >= 6.6 added direct-io-allow-mmap, which mergerfs enables
          # automatically, so page caching is no longer needed for mmap.
          #
          # Keeping it on was actively harmful here: on 2026-08-08/09 five
          # `BUG: Bad page map` faults hit mmap'd .mkv files on this mount
          # (fuse_file_mmap -> filemap_fault -> fuse_read_folio), each writing a
          # bogus PFN into a PTE, ending in a hard lockup. Turning the page
          # cache off removes that code path entirely. Reads still hit the
          # branch filesystems' own page cache, so this also drops the double
          # caching dropcacheonclose was papering over.
          options = [
            "defaults"
            "nonempty"
            "allow_other"
            "use_ino"
            "cache.files=off"
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

        # This is non-ECC memory on a consumer platform: no EDAC memory
        # controller registers, so correctable DRAM errors are structurally
        # invisible and rasdaemon can only ever report "No Memory errors"
        # regardless of the truth. Given the history of memory-corruption-
        # shaped Oopses on this box, having memtest one keypress away in the
        # boot menu turns "was it RAM?" from a guess into a test. Adds a menu
        # entry only — nothing runs automatically.
        systemd-boot.memtest86.enable = true;
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
      powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

      # eno2 is Jupiter's onboard Intel NIC. The interface name is a host
      # hardware fact, so the .network unit lives here rather than in the shared
      # nixos.networking feature module.
      #
      # NetworkManager is deliberately NOT enabled on this host: nixos.networking
      # runs systemd-networkd, and enabling both put two DHCP clients and two
      # default routes on this NIC. See the assertion in modules/networking.nix.
      systemd.network.networks."10-main" = {
        matchConfig.Name = "eno2";
        DHCP = "yes";
        networkConfig.IPv6AcceptRA = true;
      };

      # SATA link power management: force max_performance on every port.
      #
      # nixpkgs sets CONFIG_SATA_MOBILE_LPM_POLICY=3 (med_power_with_dipm)
      # kernel-wide for power savings, and kernel 6.9's commit 7627a0edef54
      # ("ata: ahci: Drop low power policy board type") removed the gate that
      # used to confine that policy to mobile chipsets. The result is that this
      # desktop PCH applies DIPM to the 14TB helium HDDs, which do not tolerate
      # it: both /mnt/disk1 and /mnt/disk2 threw `SError: { CommWake LinkSeq }`
      # interface fatal errors and failed READ FPDMA QUEUED commands on PHY
      # wake-up. Note the absent bits — no BadCRC/10B8B/Dispar — which is what
      # distinguishes an LPM wake-handshake fault from a marginal cable.
      powerManagement.scsiLinkPolicy = "max_performance";

      # Prevent suspend when KVM-switched away (no display = idle)
      services.logind.settings.Login = {
        IdleAction = "ignore";
        HandleLidSwitch = "ignore";
      };

      # =========================================================================
      # User Credentials & Groups
      # =========================================================================
      # sudo policy now lives in modules/security.nix, which owns PAM for this
      # account; "wheel" and "libvirtd" moved to the modules that create the
      # need (security.nix and gpu-passthrough.nix). What stays here is the
      # host's own credentials plus groups tied to this machine's hardware.
      users.users.${username} = {
        hashedPasswordFile = nixosArgs.config.sops.secrets.hashedPassword.path;
        openssh.authorizedKeys.keys = constants.authorizedKeys;
        extraGroups = [
          "dialout" # serial/MIDI hardware on this box
          "i2c" # paired with hardware.i2c.enable above
          "uinput" # keyd/mouse remapping on this box
          "video"
        ];
      };
    };
}
