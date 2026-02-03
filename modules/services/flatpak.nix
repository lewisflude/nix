# Flatpak Service Module - Dendritic Pattern
# Declarative Flatpak management
{ ... }:
{
  flake.modules.nixos.flatpak = { ... }: {
    services.flatpak.enable = true;
  };
}
