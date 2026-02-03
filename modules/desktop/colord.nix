# Colord Module - Dendritic Pattern
# Color management daemon
{ ... }:
{
  flake.modules.nixos.colord = { ... }: {
    services.colord.enable = true;
  };
}
