# Jupiter hardware configuration
# Filesystems (ZFS + mergerfs), kernel modules, boot loader, user credentials
{ config, ... }:
let
  inherit (config) username;
in
{
  # Merges into the same jupiter NixOS configuration as definition.nix
  configurations.nixos.jupiter.module =
    { pkgs, lib, ... }:
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
        "zfs"
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

      environment.systemPackages = [
        pkgs.mergerfs
        pkgs.xfsprogs
      ];

      # =========================================================================
      # Boot Loader
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
        hashedPassword = "$6$qowedYl/fO.6KTXt$Dxs8LBnylnLfNsqlfyC76XGziJX/MNI3hhgRHsvRCfXCebUtDFLSF1ObUcyzYZiVYZJ1Y8N50qr4/6EvkKZpa1";
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
          "video"
          "uinput"
          "libvirtd"
        ];
      };
    };
}
