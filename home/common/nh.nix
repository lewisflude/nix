{
  config,
  lib,
  system,
  ...
}: let
  platformLib = (import ../../lib/functions.nix {inherit lib;}).withSystem system;
in {
  programs.nh = {
    enable = true;
    # Disable automatic cleanup to speed up nh os switch
    # Run 'nh clean' manually when needed instead
    # This is the biggest performance improvement for nh os switch
    clean.enable = false;
    # Keep configuration in case you want to enable it later
    # clean.enable = true;
    # clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${platformLib.configDir config.home.username}/nix";
  };

  # Environment variables for nh performance and behavior tuning
  home.sessionVariables = {
    # Set flake path (redundant with programs.nh.flake but ensures consistency)
    NH_FLAKE = "${platformLib.configDir config.home.username}/nix";

    # Performance: Skip startup checks when generating completions or in constrained environments
    # Set to "1" to skip checks (small performance gain, assumes you know what you're doing)
    # NH_NO_CHECKS = "1";  # Uncomment if you want to skip checks

    # Control nix-output-monitor (nom) integration
    # Set to "1" to disable nom (useful if nom causes cursor issues or slows builds)
    # NH_NOM = "0";  # Keep nom enabled by default, uncomment and set to "1" to disable

    # Preserve environment variables when nh elevates with sudo
    # Set to "0" to disable preservation, "1" to force preservation
    # Defaults to enabled if unset
    # NH_PRESERVE_ENV = "1";  # Uncomment to explicitly enable

    # Clean arguments for manual nh clean runs
    # Used by nh-clean alias
    NH_CLEAN_ARGS = "--keep-since 4d --keep 3";
  };
}
