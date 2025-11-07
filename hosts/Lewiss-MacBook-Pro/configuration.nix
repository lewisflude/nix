{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
{

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };
  users = {
    users.${config.host.username} = {
      home = "/Users/${config.host.username}";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeK0wgNYUtZScvg64MoZObPaqjaDd7Gdj4GBsDcqAt7 lewis@lewisflude.com"
      ];
      shell = pkgs.zsh;
    };
  };

  # Create wheel group and add user to it for sops-nix secrets access
  users.knownGroups = [ "wheel" ];
  users.groups.wheel.gid = 0; # wheel is traditionally GID 0

  # Add user to wheel group via system activation script
  system.activationScripts.addUserToWheel.text = ''
    if ! dscl . -read /Groups/wheel GroupMembership 2>/dev/null | grep -q "${config.host.username}"; then
      echo "Adding ${config.host.username} to wheel group..."
      dseditgroup -o edit -a ${config.host.username} -t user wheel
    fi
  '';
  time.timeZone = lib.mkForce "Europe/London";

  host.features.restic = {
    enable = true;
    backups.macbook-home = {
      enable = true;
      path = "/Users/${config.host.username}/.config/nix";
      repository = "rest:http://jupiter.local:8000/macos-${config.host.hostname}";
      passwordFile = "/Users/${config.host.username}/.config/restic/password";
      timer = "daily";
      user = config.host.username;
      initialize = false;
      createWrapper = false;
    };
  };
}
