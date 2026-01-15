# Ironbar Signal Theme Configuration Module
# Configures ironbar with Signal theme design system
# Implements formal design specification v1.0 (Relaxed profile for 1440p+)
# Uses upstream ironbar home-manager module (imported globally in system-builders.nix)
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  # Import design tokens
  tokens = import ./tokens.nix { };

  # Import configuration generator
  configModule = import ./config.nix { inherit pkgs lib; };

  # Style file path
  styleFile = ./style.css;

  cfg = config.theming.ironbar;
in
{
  # Note: ironbar home-manager module is imported globally in lib/system-builders.nix
  # We only configure the options here, not import the module

  options.theming.ironbar = {
    enable = mkEnableOption "Ironbar with Signal theme design system";

    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional configuration to merge with the Signal theme defaults.";
    };
  };

  config = mkIf cfg.enable {
    # Configure ironbar using upstream module
    programs.ironbar = {
      enable = true;

      # Use ironbar package from flake input
      # Note: We pass the package directly without feature customization
      # The ironbar module's feature override causes build issues
      package = inputs.ironbar.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # Enable systemd service
      systemd = true;

      # Apply Signal theme stylesheet
      # The ironbar module accepts either a path or string content
      style = styleFile;

      # Merge default Signal theme config with user overrides
      config = lib.recursiveUpdate configModule.config cfg.extraConfig;

      # IMPORTANT: Leave features unset (defaults to [])
      # The upstream module will try to override with empty features if we set it
      # Since the default is [], the module does: pkg.override {features = [];}
      # This breaks the build, so we need to work around the module's behavior
    };

    # Note: The ironbar package is already set via programs.ironbar.package above.
    # Do NOT use lib.mkForce on home.packages as it overrides ALL other packages!
  };
}
