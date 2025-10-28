{
  imports = [
    # Core system configuration
    ./nix.nix
    ./system.nix

    # System preferences and UI
    ./system-preferences.nix
    ./dock-preferences.nix
    ./finder-preferences.nix
    ./documentation.nix
    ./security-preferences.nix

    # Applications and tools
    ./apps.nix
    ./gaming.nix

    # Hardware and peripherals
    ./keyboard.nix
    ./karabiner.nix
    ./yubikey.nix

    # Services and utilities
    ./backup.nix
    ./sops.nix
  ];
}
