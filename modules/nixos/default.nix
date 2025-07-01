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
    ./mouse.nix
    ./usb.nix

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

    # Desktop
    ./hyprland.nix
    ./desktop-environment.nix

    # Configuration
    ./nixpkgs.nix
    ./theme.nix
    ./environment.nix

    # Scripts
    ./sh.nix
  ];
}
