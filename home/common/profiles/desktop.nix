{ ... }:
{
  imports = [
    ./development.nix

    ../features/desktop
    ../theme.nix
    ../apps/audio
    ../apps/obsidian.nix

    ../system
  ];
}
