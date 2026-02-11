# Memory management module
# Enables earlyoom for OOM prevention
_:
{
  flake.modules.nixos.memory =
    _:
    {
      services.earlyoom.enable = true;
    };
}
