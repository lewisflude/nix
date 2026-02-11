# Home-Manager Only Module Template - Dendritic Pattern
# For user-level features that don't need system configuration
{ config, ... }:
{
  flake.modules.homeManager.FEATURE_NAME =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home.packages = [
        pkgs.example-tool
        pkgs.example-app
      ];

      programs.example = {
        enable = true;
        settings = {
          theme = "dark";
          editor = "hx";
        };
      };

      # XDG-compliant configuration
      xdg.configFile."example/config.toml" = {
        text = ''
          [settings]
          home = "${config.home.homeDirectory}"
          config_dir = "${config.xdg.configHome}"
          data_dir = "${config.xdg.dataHome}"
          cache_dir = "${config.xdg.cacheHome}"
        '';
      };

      # User services (systemd --user on Linux)
      services.example = lib.mkIf pkgs.stdenv.isLinux {
        enable = true;
      };
    };
}
