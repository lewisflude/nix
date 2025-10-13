# NixOS-specific desktop feature configuration
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.features.desktop;
in {
  config = mkIf cfg.enable {
    # Catppuccin theming at system level (NixOS only)
    catppuccin = mkIf cfg.theming {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
    };
  };
}
