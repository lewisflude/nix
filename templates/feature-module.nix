# Feature module template
# Replace FEATURE_NAME with your feature name (e.g., "docker", "kubernetes", "monitoring")
# Replace DESCRIPTION with a brief description of what this feature provides
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.FEATURE_NAME;
in {
  # Note: Options are defined centrally in modules/shared/host-options.nix
  # You need to add your feature options there first

  config = mkIf cfg.enable {
    # Assertions to validate configuration
    assertions = [
      {
        assertion = cfg.enable -> (config.host.features.REQUIRED_FEATURE.enable or true);
        message = "FEATURE_NAME requires REQUIRED_FEATURE to be enabled";
      }
    ];

    # Platform-specific package installation
    environment.systemPackages = with pkgs;
      optionals pkgs.stdenv.isLinux [
        # Linux-specific packages
        # example-linux-package
      ]
      ++ optionals pkgs.stdenv.isDarwin [
        # macOS-specific packages
        # example-darwin-package
      ]
      ++ optionals cfg.OPTIONAL_FLAG [
        # Conditionally installed packages
        # example-optional-package
      ];

    # System services (NixOS/Linux only)
    systemd.services = mkIf pkgs.stdenv.isLinux {
      example-service = {
        description = "Example service for FEATURE_NAME";
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.example}/bin/example-daemon";
          Restart = "on-failure";
        };
      };
    };

    # User groups
    users.users.${config.host.username}.extraGroups =
      optional cfg.enable "example-group";

    # Home Manager integration
    home-manager.users.${config.host.username} = {
      # User-level configuration
      programs.example = {
        enable = true;
        # Additional config...
      };

      # User packages (installed in user profile)
      home.packages = with pkgs; [
        # User-specific tools
      ];
    };

    # Additional system configuration
    # networking.firewall.allowedTCPPorts = [ 8080 ];
    # environment.sessionVariables.EXAMPLE_VAR = "value";
  };
}
