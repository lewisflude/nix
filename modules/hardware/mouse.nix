# Mouse hardware support (Logitech, gaming mice)
_:
{
  flake.modules.nixos.mouse =
    { pkgs, ... }:
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
