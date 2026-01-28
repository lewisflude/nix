{
  imports = [
    ./nix.nix
    ./system.nix

    ./system-preferences.nix
    ./dock-preferences.nix
    ./finder-preferences.nix
    ./security-preferences.nix
    ./performance.nix

    ./apps.nix
    ./audio.nix
    ./audio-reconnect.nix
    ./gaming.nix
    ./vr.nix

    ./keyboard.nix
    ./karabiner.nix
    ./yubikey.nix

    ./backup.nix
    ./restic.nix
    ./sops.nix
    ./atuin.nix
    ./mac-app-util.nix
    ./ssh.nix
  ];
}
