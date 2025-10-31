# Integration with nixos-hardware repository
# Provides hardware-specific modules for common components
{inputs, ...}: {
  imports = [
    # Intel CPU - microcode updates (may be redundant with existing config)
    inputs.nixos-hardware.nixosModules.common-cpu-intel

    # SSD maintenance - enables fstrim service for NVMe/SSD drives
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    # HiDPI console font configuration
    inputs.nixos-hardware.nixosModules.common-hidpi
  ];

  # Note: common-gpu-nvidia is intentionally skipped as we already set
  # services.xserver.videoDrivers = ["nvidia"] in graphics.nix
}
