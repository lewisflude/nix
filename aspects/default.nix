# Aspects - Feature-first module architecture
#
# Each aspect defines a complete feature across platforms:
# - Options (shared across NixOS, Darwin, home-manager)
# - NixOS configuration
# - Darwin configuration
# - Home-manager configuration (via osConfig access pattern)
#
# Aspects are imported by modules/nixos/default.nix and modules/darwin/default.nix
# Home-manager accesses aspect config via osConfig.host.features.*
#
# Usage in host config:
#   host.features.gaming.enable = true;
#   host.features.gaming.steam = true;
{ ... }:
{
  imports = [
    # Batch 1 - Simple NixOS-only features
    ./security.nix
    ./ai-tools.nix
    ./home-server.nix
    ./flatpak.nix
    ./media-management.nix

    # Batch 2 - Cross-platform features
    ./gaming.nix
    ./vr.nix
    ./restic.nix
    ./audio.nix

    # Batch 3 - Complex features
    ./desktop
  ];
}
