{ ... }:
{
  imports = [
    # NOTE: development features already imported via base features in modules/programs/base.nix
    # Removed ./development.nix to prevent duplicate neovim configuration

    ../features/desktop
    ../theme.nix
    ../apps/audio

    ../system
  ];
}
