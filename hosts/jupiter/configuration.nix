{
  config,
  lib,
  pkgs,
  username,
  hostname,
  configVars ? {
    username = username;
    hostname = hostname;
  },
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable flakes and nix command
  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        flake-registry = "";
        nix-path = config.nix.nixPath;
      };
      channel.enable = false;
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

  # Basic system configuration (nixpkgs config handled in flake)

  # User configuration - secure setup without passwords
  users = {
    mutableUsers = false; # Prevent password changes outside of configuration
    users.${username} = {
      home = "/home/${username}";
      isNormalUser = true;
      # No password set - rely on SSH keys and sudo authentication
      hashedPassword = null;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeK0wgNYUtZScvg64MoZObPaqjaDd7Gdj4GBsDcqAt7 lewis@lewisflude.com"
      ];
      extraGroups = [
        "wheel"
        "audio"
        "video"
        "nvidia"
        "docker"
        "git"
        "networkmanager"
      ];
      shell = pkgs.zsh;
    };
  };

  # Set timezone
  time.timeZone = lib.mkForce "Europe/London";

  # Enable X11 (desktop environment handled by modules)
  services.xserver.enable = true;

  # SSH configuration handled by modules/nixos/ssh.nix

  # Configure sudo for passwordless access for wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false; # Allow wheel group sudo without password
  };

  # System state version
  system.stateVersion = "24.05";
}
