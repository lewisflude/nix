# Music Assistant Service Module - Dendritic Pattern
# Music server and player with multi-provider support
# Usage: Import flake.modules.nixos.musicAssistant in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.musicAssistant = { lib, ... }:
  let
    inherit (lib) mkDefault;
  in
  {
    services.music-assistant = {
      enable = true;
      # Additional configuration can be added by hosts:
      # - providers (filesystem, streaming services)
      # - dataDir
      # - music library paths
      # - port (default from constants)
    };

    # Open firewall port for Music Assistant web interface
    networking.firewall.allowedTCPPorts = mkDefault [
      constants.ports.services.musicAssistant
    ];
  };
}
