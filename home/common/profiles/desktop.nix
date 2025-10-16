# Desktop profile
# For systems with GUI and productivity tools
{...}: {
  imports = [
    ./development.nix

    # Desktop specific
    ../features/desktop
    ../theme.nix
    ../apps/obsidian.nix

    # System tools
    ../system
  ];
}
