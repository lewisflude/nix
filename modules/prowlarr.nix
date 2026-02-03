# Prowlarr Service Module - Dendritic Pattern
# Indexer manager for *arr services
# Usage: Import config.flake.modules.nixos.prowlarr in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.prowlarr = { lib, ... }:
  let
    inherit (lib) mkDefault;

    # Default configuration (can be overridden by hosts)
    user = "media";
    group = "media";
  in
  {
    # Ensure media user/group exist
    users.users.${user} = {
      isSystemUser = true;
      group = group;
      description = "Media management user";
    };
    users.groups.${group} = { };

    # Prowlarr service configuration
    services.prowlarr = {
      enable = true;
      openFirewall = false;
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = mkDefault [
      constants.ports.services.prowlarr
    ];

    # Service overrides
    systemd.services.prowlarr = {
      environment = {
        TZ = mkDefault constants.defaults.timezone;
      };
      serviceConfig = {
        User = user;
        Group = group;
      };
    };
  };
}
