{
  config,
  lib,
  ...
}:
{
  # Configure Nix to use GitHub token from sops-managed secret
  # This avoids GitHub API rate limiting when fetching flake dependencies
  #
  # The secret file contains: "access-tokens = github.com=TOKEN"
  # which is included directly into nix.conf
  config = lib.mkIf (config.sops.secrets ? "nix-access-token") {
    nix.extraOptions = ''
      # The '!' prefix makes the include optional, preventing errors
      # if the secret file doesn't exist during initial system build
      !include ${config.sops.secrets."nix-access-token".path}
    '';
  };
}
