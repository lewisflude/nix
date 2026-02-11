# Feature Module Template - Dendritic Pattern
# One feature = one file spanning all configuration classes
{ config, ... }:
let
  # Access top-level config values
  inherit (config) username;
in
{
  # NixOS system-level configuration
  flake.modules.nixos.FEATURE_NAME =
    { pkgs, ... }:
    {
      # System packages
      environment.systemPackages = [
        pkgs.example-package
      ];

      # System services
      systemd.services.example = {
        description = "Example service";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.example}/bin/example";
          Restart = "on-failure";
        };
      };

      # User configuration
      users.users.${username}.extraGroups = [ "example-group" ];
    };

  # Home-manager user configuration
  flake.modules.homeManager.FEATURE_NAME =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.example-tool
      ];

      programs.example = {
        enable = true;
        settings = {
          theme = "dark";
        };
      };
    };
}
