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
