# NixOS-only Module Template - Dendritic Pattern
# For features that only apply to NixOS systems
{ config, lib, ... }:
let
  inherit (config) username;
  constants = config.constants;
in
{
  flake.modules.nixos.FEATURE_NAME =
    { pkgs, lib, ... }:
    {
      # System packages
      environment.systemPackages = [
        pkgs.example-package
      ];

      # Kernel modules
      boot.kernelModules = [ "example-module" ];

      # Hardware configuration
      hardware.example.enable = true;

      # System services
      systemd.services.example = {
        description = "Example service";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.example}/bin/example";
          Restart = "on-failure";
        };
      };

      # Firewall rules
      networking.firewall.allowedTCPPorts = [ 8080 ];

      # User configuration
      users.users.${username}.extraGroups = [ "example-group" ];
    };
}
