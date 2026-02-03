# Power management module
# Enables power-profiles-daemon for DMS and system power management
{ config, ... }:
{
  flake.modules.nixos.power =
    { lib, ... }:
    {
      # Power Profiles Daemon - system power/behavior state management
      # Used by DMS and various desktop tools via DBus
      # https://danklinux.com/docs/dankmaterialshell/cli-doctor#optional-features
      services.power-profiles-daemon.enable = true;
    };
}
