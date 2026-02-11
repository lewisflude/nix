# Home-Manager Module Template - Dendritic Pattern
# For user-level configuration
_: {
  # Home-manager configuration for all platforms
  flake.modules.homeManager.FEATURE_NAME =
    {
      pkgs,
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
          integration = "systemd";
        };
      };

      # User services
      services.example = {
        enable = true;
      };

      # Dotfiles
      home.file.".config/example/config.toml" = {
        text = ''
          home_directory = "${config.home.homeDirectory}"
          setting = "value"
        '';
      };
    };

  # Platform-specific home-manager (NixOS)
  flake.modules.homeManager.FEATURE_NAME-linux =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.linux-specific-tool
      ];
    };

  # Platform-specific home-manager (Darwin)
  flake.modules.homeManager.FEATURE_NAME-darwin =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.darwin-specific-tool
      ];
    };
}
