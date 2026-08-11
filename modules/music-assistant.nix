# Music Assistant Service Module - Dendritic Pattern
# Music server and player with multi-provider support
# Usage: Import flake.modules.nixos.musicAssistant in host definition
{ config, ... }:
let
  inherit (config) constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.musicAssistant = _: {
    services.music-assistant = {
      enable = true;
      # Additional configuration can be added by hosts:
      # - providers (filesystem, streaming services)
      # - dataDir
      # - music library paths
      # - port (default from constants)
    };

    # Open firewall port for Music Assistant web interface.
    # Not mkDefault: see the note in jellyfin.nix — mkDefault port lists lose to
    # networking.nix's normal-priority definition instead of merging with it.
    networking.firewall.allowedTCPPorts = [
      constants.ports.services.musicAssistant
    ];
  };
}
