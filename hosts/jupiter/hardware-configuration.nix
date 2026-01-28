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
  environment.systemPackages = [
    pkgs.mergerfs
    pkgs.xfsprogs
  ];
  boot = {
      kernelModules = [
      "kvm-intel"
      "zfs"
      "hid_sony"
    ];
    extraModulePackages = [ ];
  };
  hardware = {
    cpu.intel.updateMicrocode = true;
    enableAllFirmware = true;
    i2c.enable = true;
  };
  # USB device permissions for hardware (ColorHug device)
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="085c", ATTR{idProduct}=="0a00", MODE="0666"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="085c", ATTRS{idProduct}=="0a00", MODE="0666"
    KERNEL=="hiddev*", ATTRS{idVendor}=="085c", ATTRS{idProduct}=="0a00", MODE="0666"
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
        "fsname=mergerfs" # Good practice for identifying the mount
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
  networking.hostId = "8425e349";
}
