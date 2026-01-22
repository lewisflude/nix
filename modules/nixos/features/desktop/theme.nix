{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # Note: System-level theming has been migrated to Signal flake
      # Theming is now configured in home-manager (home/common/theming/signal.nix)
      # NixOS-specific theming (mako, swaync) remains in modules/nixos/features/theming/
      { }
    ]
  );
}
