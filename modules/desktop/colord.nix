# Colord Module - Dendritic Pattern
# Color management daemon
_: {
  flake.modules.nixos.colord = _: {
    services.colord.enable = true;
  };
}
