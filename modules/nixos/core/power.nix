{ pkgs, ... }:
{
  # Disabled: Conflicts with manual cpufreq governor settings
  # For performance users, kernel governor (schedutil) handles P/E core scheduling better
  services.power-profiles-daemon.enable = false;
  # Note: gamemode is configured in modules/nixos/features/gaming.nix
}
