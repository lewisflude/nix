{
  lib,
  host,
  pkgs,
  ...
}:
let
  cfg = host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      lib.optionals cfg.utilities [
        xdg-utils
      ];
  };
}
