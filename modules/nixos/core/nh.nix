{ config, lib, ... }:
{
  # System-level NH configuration for NixOS
  # Note: programs.nh is NixOS-only, not available on nix-darwin
  # This runs 'nh clean all' to clean system generations and store
  # Home-Manager runs 'nh clean user' separately for user profile cleanup
  programs.nh = {
    enable = true;

    # Automatic cleanup runs weekly via systemd timer
    # Runs 'nh clean all' to clean system generations and store
    # This is separate from home-manager's 'nh clean user'
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 4d --keep 3";
    };

    # Set the flake path for the system
    flake = "/home/${config.host.username}/.config/nix";
  };
}
