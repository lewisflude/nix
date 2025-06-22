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
  
  # Network configuration is handled by modules/nixos/networking.nix
  
  # Set timezone
  time.timeZone = "America/New_York";
  
  # Sound configuration is handled by modules/nixos/audio.nix
  
  # Enable X11 (desktop environment handled later)
  services.xserver.enable = true;
  
  # Enable OpenSSH
  services.openssh.enable = true;
  
  # System state version
  system.stateVersion = "24.05";
}