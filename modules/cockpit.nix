# Cockpit Service Module - Dendritic Pattern
# Web-based system management interface
# Usage: Import flake.modules.nixos.cockpit in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.cockpit = { lib, ... }:
  let
    inherit (lib) mkDefault;
  in
  {
    services.cockpit = {
      enable = true;
      port = constants.ports.services.cockpit;
      openFirewall = mkDefault true;

      # Allow access from various origins (localhost, hostname, and reverse proxy)
      allowed-origins = mkDefault [
        "https://localhost:${toString constants.ports.services.cockpit}"
        "http://localhost:${toString constants.ports.services.cockpit}"
        "https://jupiter:${toString constants.ports.services.cockpit}"
        "http://jupiter:${toString constants.ports.services.cockpit}"
        "https://cockpit.blmt.io"
        "http://cockpit.blmt.io"
      ];

      settings = {
        WebService = {
          # Allow unencrypted connections (behind reverse proxy with TLS termination)
          AllowUnencrypted = true;

          # Forward proxy headers for proper logging and authentication
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
        };
      };
    };
  };
}
