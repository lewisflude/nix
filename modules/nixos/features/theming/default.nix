# NixOS Theming Module
# Note: This module is deprecated. Theming is now handled by the Signal flake
# in home-manager configuration (home/common/theming/signal.nix)
#
# Only ironbar-nixos remains as it's system-specific
{ lib, ... }:
{
  # Import system-level application theming modules
  imports = [
    ../../../shared/features/theming/applications/desktop/ironbar-nixos.nix
    # mako and swaync are configured directly without theming integration
  ];

  # No configuration needed - modules are imported for backwards compatibility only
  config = { };
}
