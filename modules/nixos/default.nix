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
    ./yubikey.nix

    # Configuration
    ./nixpkgs.nix
    ./theme.nix

    # Scripts
    ./sh.nix
  ];
}
