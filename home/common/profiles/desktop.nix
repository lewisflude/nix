{ ... }:
{
  imports = [
    ./development.nix

    ../features/desktop
    ../theme.nix
    ../apps/audio

    ../system
  ];
}
