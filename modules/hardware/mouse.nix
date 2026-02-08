# Mouse hardware support (Logitech, gaming mice)
{ config, ... }:
{
  flake.modules.nixos.mouse =
    { pkgs, lib, ... }:
    {
      services.solaar = {
        enable = true;
        package = pkgs.solaar;
        window = "hide";
        batteryIcons = "regular";
        extraArgs = "";
      };
      services.ratbagd.enable = true;
    };
}
