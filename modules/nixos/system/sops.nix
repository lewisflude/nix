{
  config,
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
  users.users.${username}.extraGroups = [config.sops.group];

  sops.secrets = lib.genAttrs sharedSecrets (_: {
    neededForUsers = true;
  });
}
