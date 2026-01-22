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
    enable = mkEnableOption "gaming platforms and optimizations" // {
      example = true;
    };
    steam = mkEnableOption "Steam gaming platform" // {
      example = true;
    };
    performance = mkEnableOption "gaming performance optimizations" // {
      example = true;
    };
    lutris = mkEnableOption "Lutris game manager" // {
      example = true;
    };
    emulators = mkEnableOption "gaming emulators" // {
      example = true;
    };
  };
}
