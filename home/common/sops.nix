{
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = with pkgs; [
    sops
  ];

  sops = lib.mkIf (!pkgs.stdenv.isDarwin) {
    defaultSopsFile = ../../secrets/user.yaml;

    # Use age for user secrets (no prompts)
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = {
      KAGI_API_KEY = {};
      CIRCLECI_TOKEN = {};
      OBSIDIAN_API_KEY = {};
      OPENAI_API_KEY = {};
      GITHUB_TOKEN = {};
    };
  };

  systemd.user.services.sops-nix = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      After = ["gpg-agent.service"];
      Wants = ["gpg-agent.service"];
    };
    Service = {
      Restart = "on-failure";
      RestartSec = "10s";
      StartLimitBurst = 3;
    };
  };
}
