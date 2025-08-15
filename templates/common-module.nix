# Template for modules/shared/ - Cross-platform system modules only
{
  pkgs,
  lib,
  system,
  username,
  ...
}:
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
in
{
  # Cross-platform configuration only
  # Platform-specific logic should be moved to modules/darwin/ or modules/nixos/

  # Example cross-platform package installation
  environment.systemPackages = with pkgs; [
    # Only packages that work identically on all platforms
    curl
    wget
    git
  ];

  # Example cross-platform service configuration using username parameter
  services.example = {
    enable = true;
    # Only settings that are identical across platforms
    port = 8080;
    user = username;
  };

  # Example using platform helpers for conditional config
  # (Only use when truly necessary - prefer platform-specific modules)
  programs.example = {
    enable = true;
    package = platformLib.platformPackage pkgs.example-linux pkgs.example-darwin;
  };

  # Example user-specific configuration using username parameter
  # users.users.${username} = {
  #   description = "Cross-platform user ${username}";
  #   # Additional cross-platform user configuration
  # };
}
