{
  config,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  programs.nh = {
    enable = true;

    # Enable automatic cleanup with weekly schedule
    # Integrated cleanup is more reliable than manual session variables
    clean = {
      enable = true;
      dates = "weekly"; # Runs weekly via systemd timer (NixOS) or launchd (Darwin)
      extraArgs = "--keep-since 4d --keep 3"; # Keep 4 days OR 3 most recent generations
    };

    flake = "${platformLib.configDir config.home.username}/nix";
  };

  home.sessionVariables = {
    NH_FLAKE = "${platformLib.configDir config.home.username}/nix";

    # NH_NOM can be set to 1 to enable nix-output-monitor for better build visualization
    # NH_NOM = "1";
  };
}
