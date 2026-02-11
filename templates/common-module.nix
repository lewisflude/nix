# Cross-Platform Module Template - Dendritic Pattern
# For features that work on both NixOS and Darwin
{ config, ... }:
{
  # NixOS system configuration
  flake.modules.nixos.FEATURE_NAME =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.example-package
      ];

      systemd.services.example = {
        description = "Example service";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.example}/bin/example";
          Restart = "on-failure";
        };
      };
    };

  # Darwin system configuration
  flake.modules.darwin.FEATURE_NAME =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.example-package
      ];

      launchd.daemons.example = {
        serviceConfig = {
          ProgramArguments = [ "${pkgs.example}/bin/example" ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };

  # Home-manager configuration (shared across platforms)
  flake.modules.homeManager.FEATURE_NAME =
    {
      pkgs,
      config,
      ...
    }:
    {
      home.packages = [
        pkgs.example-tool
      ];

      programs.example = {
        enable = true;
        settings = {
          configDir = config.xdg.configHome;
        };
      };
    };
}
