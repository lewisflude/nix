{
  lib,
  config,
  pkgs,
  ...
}: let
  username = "lewis";
in {
  # NixOS-specific SOPS configuration
  sops = {
    # Use user age key instead of system SSH key to avoid boot prompts
    age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

    # Fallback to SSH key if age key doesn't exist
    age.sshKeyPaths = lib.mkIf (!builtins.pathExists "/home/${username}/.config/sops/age/keys.txt") [
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    # Platform-specific secret permissions for NixOS
    secrets = {
      LATITUDE.group = "users";
      LONGITUDE.group = "users";
      HOME_ASSISTANT_BASE_URL.group = "users";
      GITHUB_PERSONAL_ACCESS_TOKEN = {
        group = "users";
        mode = "0440"; # Allow group read for user access
      };
    };
  };

  # Ensure SOPS age directory exists
  systemd.tmpfiles.rules = [
    "d /home/${username}/.config/sops/age 0755 ${username} users -"
  ];
}