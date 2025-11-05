# FEATURE_NAME feature module for NixOS
# Controlled by host.features.FEATURE_NAME.*
#
# PURPOSE:
# Brief description of what this feature provides and its use cases.
#
# USAGE:
# Enable this feature in hosts/<hostname>/default.nix:
#   host.features.FEATURE_NAME = {
#     enable = true;
#     OPTIONAL_FLAG = true;
#   };
#
# DEPENDENCIES:
# - REQUIRED_FEATURE: Description of why this dependency is needed
# - Other dependencies as needed
#
# PLATFORM SUPPORT:
# - Linux: Fully supported
# - macOS: [Supported/Not supported/Partial support]
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.FEATURE_NAME;
in
{
  # Note: Options are defined centrally in modules/shared/host-options.nix
  # You need to add your feature options there first:
  #
  # host.features.FEATURE_NAME = {
  #   enable = mkEnableOption "FEATURE_NAME description";
  #   OPTIONAL_FLAG = mkOption {
  #     type = types.bool;
  #     default = false;
  #     description = "Description of optional flag";
  #   };
  # };

  config = mkIf cfg.enable {
    # Assertions to validate configuration
    # These provide clear error messages when dependencies are missing
    assertions = [
      {
        assertion = cfg.enable -> (config.host.features.REQUIRED_FEATURE.enable or false);
        message = "FEATURE_NAME requires REQUIRED_FEATURE to be enabled. Set host.features.REQUIRED_FEATURE.enable = true;";
      }
      # Add more assertions as needed for validation
      # {
      #   assertion = cfg.OPTIONAL_FLAG -> (someCondition);
      #   message = "OPTIONAL_FLAG requires someCondition to be true";
      # }
    ];

    # Platform-specific package installation
    # Use optionals to conditionally include packages based on platform or feature flags
    environment.systemPackages =
      with pkgs;
      optionals pkgs.stdenv.isLinux [
        # Linux-specific packages
        # example-linux-package
      ]
      ++ optionals pkgs.stdenv.isDarwin [
        # macOS-specific packages
        # example-darwin-package
      ]
      ++ optionals cfg.OPTIONAL_FLAG [
        # Conditionally installed packages based on feature option
        # example-optional-package
      ];

    # System services (NixOS/Linux only)
    # Wrap in mkIf pkgs.stdenv.isLinux to ensure Linux-only services aren't applied on Darwin
    systemd.services = mkIf pkgs.stdenv.isLinux {
      example-service = {
        description = "Example service for FEATURE_NAME";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.example}/bin/example-daemon";
          Restart = "on-failure";
          # Add other service configuration as needed
        };
      };
    };

    # User groups
    # Add users to necessary groups for feature functionality
    users.users.${config.host.username}.extraGroups = optional cfg.enable "example-group";

    # Home Manager integration
    # Configure user-level programs and packages
    home-manager.users.${config.host.username} = {
      # User-level program configuration
      programs.example = {
        enable = true;
        # Additional config...
      };

      # User packages (installed in user profile, not system-wide)
      home.packages = with pkgs; [
        # User-specific tools
      ];
    };

    # Additional system configuration
    # Add any other NixOS configuration options as needed
    # networking.firewall.allowedTCPPorts = [ 8080 ];
    # environment.sessionVariables.EXAMPLE_VAR = "value";
    # boot.kernel.sysctl."vm.example" = "value";
  };
}
