# Optional profile
# Import all modules unconditionally and let them control their behavior with mkIf
# This avoids infinite recursion from referencing config in imports
{...}: {
  imports = [
    # Development tools
    ../apps/cursor
    ../apps/lazydocker.nix
    ../features/development

    # Docker tools
    ../apps/docker.nix

    # Desktop applications
    ./desktop.nix

    # Productivity tools
    ../apps/aws.nix
  ];

  # Note: Each imported module should use mkIf to control whether it's enabled
  # based on config.host.features.* settings
}
