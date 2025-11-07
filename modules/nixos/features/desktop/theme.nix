{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{

  config = lib.mkIf cfg.enable {
    # System-level Catppuccin theme configuration
    # This enables theming for system services like greetd, plymouth, tty, etc.
    # Matches the home-manager theme configuration in home/common/theme.nix
    catppuccin = {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
    };
  };
}
