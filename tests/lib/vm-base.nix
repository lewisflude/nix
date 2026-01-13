{ lib, ... }:
{
  # Common VM test configuration
  # This module contains overrides needed for all VM-based tests
  # to ensure they work correctly in the NixOS test framework

  # Disable bootloaders - VMs don't need them
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # Simple root filesystem for VM
  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };

  # Disable graphics for faster testing
  virtualisation.graphics = false;

  # Disable X server - most tests don't need GUI
  services.xserver.enable = lib.mkForce false;

  # Allow unfree packages (needed for Steam, etc.)
  nixpkgs.config.allowUnfree = true;
}
