{
  pkgs,
  lib,
  config,
  system,
  hostSystem,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
in {
  home.packages = with pkgs; [
    sops
  ];
  sops = {
    defaultSopsFile = ../../secrets/user.yaml;
    age.keyFile = "${platformLib.configDir config.home.username}/sops/age/keys.txt";
    secrets = {
      KAGI_API_KEY = {};
      CIRCLECI_TOKEN = {};
      OBSIDIAN_API_KEY = {};
      OPENAI_API_KEY = {};
      GITHUB_TOKEN = {
        sopsFile = ../../secrets/secrets.yaml;
      };
    };
  };
  systemd.user.services.sops-nix = lib.mkIf isLinux {
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
