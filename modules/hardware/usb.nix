# USB device support (gvfs, udisks2, tumbler)
_:
{
  flake.modules.nixos.usb =
    _:
    {
      services = {
        gvfs.enable = true;
        udisks2.enable = true;
        tumbler.enable = true;
      };
    };
}
