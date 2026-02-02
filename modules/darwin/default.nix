{
  imports = [
    # Aspects (dendritic feature modules)
    # All feature implementations are now in aspects/
    ../../aspects

    # Core Darwin system modules (not features)
    ./nix.nix
    ./system.nix

    ./system-preferences.nix
    ./dock-preferences.nix
    ./finder-preferences.nix
    ./security-preferences.nix
    ./performance.nix

    ./apps.nix

    ./keyboard.nix
    ./karabiner.nix
    ./yubikey.nix

    ./backup.nix
    ./restic.nix # Darwin-specific launchd config (aspects/restic.nix handles common config)
    ./sops.nix
    ./atuin.nix
    ./mac-app-util.nix
    ./ssh.nix
  ];
}
