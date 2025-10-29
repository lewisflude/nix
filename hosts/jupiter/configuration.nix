{
  lib,
  pkgs,
  config,
  ...
}: {
  # Host configuration using the new options system

  imports = [
    ./hardware-configuration.nix
  ];
  users = {
    mutableUsers = false;
    users.${config.host.username} = {
      home = "/home/${config.host.username}";
      isNormalUser = true;
      hashedPassword = null;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeK0wgNYUtZScvg64MoZObPaqjaDd7Gdj4GBsDcqAt7 lewis@lewisflude.com"
      ];
      extraGroups = [
        "dialout"
        "admin"
        "wheel"
        "staff"
        "_developer"
        "git"
      ];
      shell = pkgs.zsh;
    };
  };
  time.timeZone = lib.mkForce "Europe/London";
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
}
