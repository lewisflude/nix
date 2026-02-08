# Memory management module
# Enables earlyoom for OOM prevention
{ config, ... }:
{
  flake.modules.nixos.memory =
    { lib, ... }:
    {
      services.earlyoom.enable = true;
    };
}
