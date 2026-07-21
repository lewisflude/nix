# Signal NixOS Module Example - Boot Theming
#
# This example shows how to use Signal's NixOS modules to theme
# system-level components like the virtual console and GRUB bootloader.

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Example NixOS configuration with Signal theming
  # This demonstrates theming boot components while keeping
  # user-level theming separate in Home Manager.

  imports = [
    # Your hardware configuration
    # ./hardware-configuration.nix
  ];

  # ============================================================================
  # System-Level Signal Theming
  # ============================================================================

  theming.signal.nixos = {
    enable = true;
    mode = "dark"; # or "light" or "auto"

    # Boot components
    boot = {
      # Virtual console (TTY) colors
      # Applies to Ctrl+Alt+F1-F6 terminals
      console.enable = true;

      # GRUB bootloader theme
      # Styles the boot menu with Signal colors
      grub = {
        enable = true;
        # Optional: custom background image
        # customBackground = ./wallpaper.png;
      };
    };
  };

  # ============================================================================
  # Standard NixOS Configuration
  # ============================================================================

  # Bootloader configuration (Signal will theme this)
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # or "nodev" for UEFI
    # Signal theme will be applied automatically
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  # User accounts
  users.users.alice = {
    isNormalUser = true;
    home = "/home/alice";
    extraGroups = [ "wheel" ]; # Enable sudo
  };

  # Networking
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  # Time zone
  time.timeZone = "America/New_York";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "24.11";
}
