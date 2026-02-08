# USB device support (gvfs, udisks2, tumbler)
{ config, ... }:
{
  flake.modules.nixos.usb =
    { lib, ... }:
    {
      services = {
        gvfs.enable = true;
        udisks2.enable = true;
        tumbler.enable = true;
      };
    };
}
