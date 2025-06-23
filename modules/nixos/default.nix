{
  imports = [
    # System core
    ./boot.nix
    ./networking.nix
    ./security.nix

    # Hardware
    ./audio.nix
    ./bluetooth.nix
    ./graphics.nix
    ./keyboard.nix
    ./mouse.nix
    ./usb.nix

    # Desktop
    ./desktop-environment.nix

    # Services
    ./ssh.nix

    # Applications
    ./gaming.nix
    ./virtualisation.nix
    ./wine.nix

    # Development
    ./java.nix

    # Storage & Files
    ./file-management.nix
    ./samba.nix
    ./zfs.nix

    # Authentication
    ./password-management.nix
    ./yubikey.nix

    # Configuration
    ./nixpkgs.nix
    ./overlays.nix
    ./secrets.nix
    ./theme.nix

    # Scripts
    ./sh.nix
  ];
}
