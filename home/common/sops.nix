{
  pkgs,
  username,
  ...
}:
{

  home.packages = with pkgs; [
    sops
  ];

  sops = {

    defaultSopsFile = ../../secrets/secrets.yaml;

    gnupg = {
      home = if pkgs.stdenv.isDarwin then "/Users/${username}/.gnupg" else "/home/${username}/.gnupg";
      sshKeyPaths = [ ];
    };

    secrets = {
      KAGI_API_KEY = { };
      CIRCLECI_TOKEN = { };
      GITHUB_PERSONAL_ACCESS_TOKEN = { };
      OBSIDIAN_API_KEY = { };
    };
  };
}
