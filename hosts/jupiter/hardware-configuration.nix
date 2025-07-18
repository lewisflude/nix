{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  environment.systemPackages = with pkgs; [
    mergerfs
    xfsprogs
  ];
  boot = {
    initrd.supportedFilesystems = [ "zfs" ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "thunderbolt"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "zfs"
      "veth"
      "bridge"
      "br_netfilter"
      "xt_nat"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [
      "kvm-intel"
      "zfs"
      "hid_sony"
    ];
    extraModulePackages = [ ];
  };
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableAllFirmware = true;
  hardware.i2c.enable = true;
  powerManagement.cpuFreqGovernor = "performance";

  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  services.udev.extraRules = ''
    # Use BFQ scheduler for HDDs
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    # Use none/mq-deadline for SSDs
    ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
  '';

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
        "noatime"
        "logbufs=8"
        "allocsize=64m"
        "x-systemd.after=mnt-storage.mount"
      ];
    };

    "/mnt/disk2" = {
      device = "/dev/disk/by-id/ata-WDC_WD140EDFZ-11A0VA0_Y5JTWKLC-part1";
      fsType = "xfs";
      options = [
        "defaults"
        "nofail"
        "noatime"
        "logbufs=8"
        "allocsize=64m"
        "x-systemd.after=mnt-storage.mount"
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
        "x-systemd.before=local-fs.target"
      ];
    };
  };
  swapDevices = [
    {
      device = "/dev/disk/by-uuid/65835c4c-3b5f-4ced-bf61-c73a6e76e562";
    }
  ];

  networking.useDHCP = lib.mkDefault true;
  networking.hostId = "259378f7";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
