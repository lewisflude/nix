# Desktop feature module (cross-platform basics)
# Platform-specific features in modules/nixos/features/desktop.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.desktop;
in {
  config = mkIf cfg.enable {
    # Catppuccin theming
    catppuccin = mkIf cfg.theming {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
    };
    
    # Basic desktop utilities
    home-manager.users.${config.host.username} = {
      catppuccin = mkIf cfg.theming {
        enable = true;
        flavor = "mocha";
        accent = "mauve";
      };
      
      home.packages = with pkgs; mkIf cfg.utilities [
        xdg-utils
      ];
    };
  };
}
