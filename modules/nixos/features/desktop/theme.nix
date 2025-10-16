{
  config,
  lib,
  ...
}: let
  cfg = config.host.features.desktop;
in {
  config = lib.mkIf cfg.enable {
    catppuccin = lib.mkIf cfg.theming {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
    };
  };
}
