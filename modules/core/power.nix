# Power management module
# Disables power-profiles-daemon (conflicts with manual cpufreq governor)
{ config, ... }:
{
  flake.modules.nixos.power = { lib, ... }: {
    # For performance users, kernel governor (schedutil) handles P/E core scheduling better
    services.power-profiles-daemon.enable = false;
  };
}
