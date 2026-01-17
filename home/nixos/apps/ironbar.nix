# Ironbar Desktop Status Bar
# Platform: NixOS (Linux)
# Status bar for Niri compositor
{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ironbar = {
    enable = true;
    # Basic configuration - you can customize this further
    # See: https://github.com/JakeStanger/ironbar/wiki
  };
}
