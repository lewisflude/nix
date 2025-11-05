{
  lib,
  host,
  ...
}:
let
  cfg = host.features.desktop;
in
{
  # Catppuccin is configured globally in home/common/theme.nix
  # This module is kept for feature gating compatibility but doesn't need to do anything
  # since Catppuccin is already enabled with Mocha flavor
  config = lib.mkIf cfg.enable {
    # Catppuccin configuration is handled in home/common/theme.nix
    # No additional configuration needed here
  };
}
