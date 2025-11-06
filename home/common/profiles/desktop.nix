{ ... }:
{
  imports = [
    ./development.nix

    ../features/desktop
    ../theme.nix
    ../apps/obsidian.nix

    ../system
  ];
}
