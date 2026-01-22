{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem system;
  flakePath = "${platformLib.configDir config.home.username}/nix";
in
{
  # Home Manager NH configuration (works on both NixOS and nix-darwin)
  # This runs 'nh clean user' to clean user profile generations
  # On NixOS: System-level config runs 'nh clean all' for system generations
  # On Darwin: This is the only cleanup (no system-level module available)
  programs.nh = {
    enable = true;

    # Automatic cleanup runs weekly via systemd user timer (Linux) or launchd (Darwin)
    # Runs 'nh clean user' to clean user profile generations
    # This is separate from system-level 'nh clean all' on NixOS
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 4d --keep 3";
    };

    flake = flakePath;
  };

  home.sessionVariables = {
    # Generic flake path (backward compatibility with older NH versions)
    NH_FLAKE = flakePath;

    # Platform-specific flake paths (NH 4.0+ recommended)
    # All point to the same location since we use a unified flake
    NH_OS_FLAKE = flakePath;
    NH_HOME_FLAKE = flakePath;
    NH_DARWIN_FLAKE = flakePath;

    # Enable nix-output-monitor for beautiful build tree visualization
    # Shows progress bars and dependency trees during rebuilds
    NH_NOM = "1";
  };
}
