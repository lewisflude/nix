# Desktop audio configuration
# This module configures PipeWire and basic audio routing
# For audio production features, see modules/nixos/features/audio.nix
{ ... }:
{
  imports = [
    ./pipewire.nix
    ./hardware-specific.nix
  ];
}
