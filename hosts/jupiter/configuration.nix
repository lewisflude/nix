{
  config,
  lib,
  pkgs,
  username,
  hostname,
  configVars ? { username = username; hostname = hostname; },
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

  # User configuration
  users.users.${username} = {
    home = "/home/${username}";
    isNormalUser = true;
    initialPassword = "correcthorsebatterystaple";
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

  # Set timezone
  time.timeZone = lib.mkForce "America/New_York";

  # Enable X11 (desktop environment handled by modules)
  services.xserver.enable = true;

  # Enable OpenSSH
  services.openssh.enable = true;

  # System state version
  system.stateVersion = "24.05";
}