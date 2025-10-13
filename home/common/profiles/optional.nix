# Optional profile
# Conditionally imports modules based on host.features configuration
# This reduces build time by only including what's needed
{
  config,
  lib,
  ...
}:
with lib; {
  imports =
    []
    # Development tools - only if development feature is enabled
    ++ optionals config.host.features.development.enable [
      ../apps/cursor
      ../apps/lazydocker.nix
      ../development
    ]
    # Docker tools - only if virtualisation is enabled
    ++ optionals (config.host.features.virtualisation.enable or false) [
      ../apps/docker.nix
      ../apps/lazydocker.nix
    ]
    # Desktop applications - only if desktop is enabled
    ++ optionals (config.host.features.desktop.enable or false) [
      ./desktop.nix
    ]
    # Productivity tools
    ++ optionals (config.host.features.productivity.enable or false) [
      ../apps/aws.nix
    ];
}
