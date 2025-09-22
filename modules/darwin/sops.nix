{
  lib,
  config,
  pkgs,
  ...
}: let
  username = "lewis";
in {
  # Darwin-specific SOPS configuration
  sops = {
    # Use user age key instead of system SSH key to avoid boot prompts
    age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";

    # Fallback to SSH key if age key doesn't exist
    age.sshKeyPaths = lib.mkIf (!builtins.pathExists "/Users/${username}/.config/sops/age/keys.txt") [
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    # Platform-specific secret permissions for macOS
    secrets = {
      LATITUDE.group = "admin";
      LONGITUDE.group = "admin";
      HOME_ASSISTANT_BASE_URL.group = "admin";
      GITHUB_PERSONAL_ACCESS_TOKEN = {
        group = "admin";
        mode = "0440"; # Allow group read for user access
      };
    };
  };

  # Ensure SOPS age directory exists
  system.activationScripts.setupSOPSAge = {
    text = ''
      mkdir -p /Users/${username}/.config/sops/age
      chown ${username}:staff /Users/${username}/.config/sops/age
      chmod 755 /Users/${username}/.config/sops/age
    '';
  };
}