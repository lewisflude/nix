# Desktop feature module (cross-platform basics)
# Platform-specific features in modules/nixos/features/desktop.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.features.desktop;
in {
  config = mkIf cfg.enable {};
}
