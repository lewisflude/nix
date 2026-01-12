{ username, ... }:
{
  users.groups.sops-secrets = { };

  users.users.${username}.extraGroups = [ "sops-secrets" ];

  # Secrets are defined in modules/shared/sops.nix with proper defaults.
  # The shared module's mkSecret function already sets owner/group/mode correctly for allowUserRead secrets.
  # This module only needs to define NixOS-specific secrets that aren't in the shared configuration.
  sops.secrets = {
    # Nix access token needs special permissions for Nix daemon to read it
    # This file contains the formatted line: "access-tokens = github.com=TOKEN"
    nix-access-token = {
      neededForUsers = true;
      group = "users";
      mode = "0440"; # Read-only for owner (root) and group (users)
    };
  };
}
