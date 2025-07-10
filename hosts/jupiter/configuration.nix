{
  lib,
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

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

  # X11 configuration handled by modules/nixos/graphics.nix

  # SSH configuration handled by modules/nixos/ssh.nix

  # Configure sudo for passwordless access for wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false; # Allow wheel group sudo without password
  };
}
