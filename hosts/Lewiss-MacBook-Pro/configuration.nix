{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: {
  # Host configuration using the new options system
  host = import ./default.nix;
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
  users = {
    users.${config.host.username} = {
      home = "/Users/${config.host.username}";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeK0wgNYUtZScvg64MoZObPaqjaDd7Gdj4GBsDcqAt7 lewis@lewisflude.com"
      ];
      shell = pkgs.bash;
    };
  };
  time.timeZone = lib.mkForce "Europe/London";
}
