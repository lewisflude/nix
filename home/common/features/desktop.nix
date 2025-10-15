{
  lib,
  host,
  pkgs,
  ...
}: let
  cfg = host.features.desktop;
in {
  config = lib.mkIf cfg.enable {
    catppuccin = lib.mkIf cfg.theming {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
    };

    home.packages = with pkgs; lib.optionals cfg.utilities [
      xdg-utils
    ];
  };
}
