# Home Manager SOPS Configuration
#
# This module prevents the home-manager SOPS module from auto-detecting SSH keys,
# which would fail on Darwin where system SSH host keys don't exist.
#
# Note: All secrets are managed at the system level in modules/shared/sops.nix.
# This configuration only prevents errors from SSH key auto-detection.
{
  config,
  lib,
  system,
  ...
}:
let
  isDarwin = lib.strings.hasSuffix "darwin" system;
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;

  # Use the same age key file location as the system-level config
  # This prevents the home-manager SOPS module from generating its own key
  keyFilePath =
    if isDarwin then
      "${platformLib.dataDir config.home.username}/sops-nix/key.txt"
    else
      "/var/lib/sops-nix/key.txt";
in
{
  sops.age = {
    # Point to the system-managed key file to prevent duplicate key generation
    keyFile = keyFilePath;
    # Disable SSH key auto-detection (prevents errors on Darwin)
    sshKeyPaths = [ ];
  };
}
