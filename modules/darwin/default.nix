{
  imports = [
    ./nix.nix
    ./system.nix

    ./system-preferences.nix
    ./dock-preferences.nix
    ./finder-preferences.nix
    ./documentation.nix
    ./security-preferences.nix

    ./apps.nix
    ./audio.nix
    ./gaming.nix

    ./keyboard.nix
    ./karabiner.nix
    ./yubikey.nix

    ./backup.nix
    ./restic.nix
    ./sops.nix
    ./atuin.nix
    ./mac-app-util.nix
  ];
}
