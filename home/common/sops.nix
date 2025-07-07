{
  pkgs,
  config,
  ...
}:
{

  home.packages = with pkgs; [
    sops
  ];

  sops = {

    defaultSopsFile = ../../secrets/user.yaml;

    gnupg = {
      home = "${config.home.homeDirectory}/.gnupg";
      sshKeyPaths = [ ];
    };

    secrets = {
      KAGI_API_KEY = { };
      CIRCLECI_TOKEN = { };
      GITHUB_PERSONAL_ACCESS_TOKEN = { };
      OBSIDIAN_API_KEY = { };
    };
  };

  systemd.user.services.sops-nix = {
    Unit = {
      After = [ "gpg-agent.service" ];
      Wants = [ "gpg-agent.service" ];
    };
    Service = {
      Restart = "on-failure";
      RestartSec = "10s";
      StartLimitBurst = 3;
    };
  };
}
