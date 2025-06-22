{
  config,
  lib,
  pkgs,
  inputs,
  username,
  hostname,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Basic system configuration
  nixpkgs.config.allowUnfree = true;
  
  # Set hostname
  networking.hostName = hostname;
  
  # Enable NetworkManager for networking
  networking.networkmanager.enable = true;
  
  # Set timezone
  time.timeZone = "America/New_York";
  
  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
  
  # Enable X11 and basic desktop
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  
  # Enable OpenSSH
  services.openssh.enable = true;
  
  # System state version
  system.stateVersion = "24.05";
}