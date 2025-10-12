{
  lib,
  username,
  ...
}: let
  userSecretsFile = ../../secrets/user.yaml;
  userSecrets =
    lib.genAttrs [
      "KAGI_API_KEY"
      "CIRCLECI_TOKEN"
      "OBSIDIAN_API_KEY"
      "OPENAI_API_KEY"
      "GITHUB_TOKEN"
      "FIGMA_ACCESS_TOKEN"
    ]
    (_: {
      owner = username;
      group = "staff";
      mode = "0400";
      sopsFile = userSecretsFile;
    });
in {
  sops.secrets = userSecrets;
  system.activationScripts.setupSOPSAge = {
    text = ''
      install -d -m 700 -o root -g wheel /var/lib/sops-nix
    '';
  };
}
