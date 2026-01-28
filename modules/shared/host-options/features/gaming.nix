# Gaming Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption;
in
{
  gaming = {
    enable = mkEnableOption "gaming platforms and optimizations";
    steam = mkEnableOption "Steam gaming platform";
    performance = mkEnableOption "gaming performance optimizations";
    lutris = mkEnableOption "Lutris game manager";
    emulators = mkEnableOption "gaming emulators";
  };
}
