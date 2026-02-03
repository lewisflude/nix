# Feature Module Template - Dendritic Pattern
# One feature = one file spanning all configuration classes
{ config, lib, ... }:
let
  # Access top-level config values
  inherit (config) username;
  constants = config.constants;
in
{
  # NixOS system-level configuration
  flake.modules.nixos.FEATURE_NAME = { pkgs, lib, ... }: {
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
  flake.modules.homeManager.FEATURE_NAME = { pkgs, lib, ... }: {
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
