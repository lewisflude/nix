{
  lib,
  username,
  ...
}: let
  sharedSecrets = [
    "CIRCLECI_TOKEN"
    "GITHUB_TOKEN"
    "KAGI_API_KEY"
    "OBSIDIAN_API_KEY"
    "OPENAI_API_KEY"
  ];
in {
  # Add user to the sops-secrets group for secret access
  users.users.${username}.extraGroups = ["sops-secrets"];

  sops.secrets = lib.genAttrs sharedSecrets (_: {
    neededForUsers = true;
  });
}
