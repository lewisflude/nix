{
  lib,
  username,
  ...
}:
let
  # Import shared secret names from the shared module
  # These match the secrets defined in modules/shared/sops.nix with allowUserRead = true
  sharedSecrets = [
    "CIRCLECI_TOKEN"
    "GITHUB_TOKEN"
    "KAGI_API_KEY"
    "OBSIDIAN_API_KEY"
    "OPENAI_API_KEY"
  ];
in
{

  users.groups.sops-secrets = { };

  users.users.${username}.extraGroups = [ "sops-secrets" ];

  # Fix SOPS secret permissions on NixOS
  # sops-nix with neededForUsers creates secrets as root:root, but we need sops-secrets group
  system.activationScripts.fixSOPSSecretPermissions = lib.stringAfter [ "users" "groups" ] ''
    # Fix permissions for user-readable secrets
    if [ -d /run/secrets-for-users ]; then
      ${lib.concatMapStringsSep "\n" (secret: ''
        if [ -f /run/secrets-for-users/${secret} ]; then
          chown ${username}:sops-secrets /run/secrets-for-users/${secret} || true
          chmod 640 /run/secrets-for-users/${secret} || true
        fi
      '') sharedSecrets}
    fi
  '';

  # Configure NixOS-specific SOPS settings for secrets already defined in modules/shared/sops.nix
  # The shared module defines the secrets themselves; this module adds NixOS-specific permissions
  sops.secrets =
    lib.genAttrs sharedSecrets (_: {
      neededForUsers = true;
    })
    // {
      # Nix access token needs special permissions for Nix daemon to read it
      # This file contains the formatted line: "access-tokens = github.com=TOKEN"
      nix-access-token = {
        neededForUsers = true;
        group = "users";
        mode = "0440"; # Read-only for owner (root) and group (users)
      };
    };
}
