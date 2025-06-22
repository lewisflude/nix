{
  config,
  lib,
  pkgs,
  username,
  hostname,
  configVars ? { username = username; hostname = hostname; },
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable flakes and nix command
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
    };
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