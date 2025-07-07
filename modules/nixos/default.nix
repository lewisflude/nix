{
  imports = [
    # System core
    ./nix.nix
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
    ./terminal.nix

    # Development
    ./java.nix

    # Storage & Files
    ./file-management.nix
    ./samba.nix
    ./zfs.nix

    # Authentication
    ./yubikey.nix

    # Desktop
    ./desktop-environment.nix
    ./niri.nix
    ./xdg.nix
    ./xwayland.nix

    # Configuration
    ./nixpkgs.nix
    ./theme.nix

    # Scripts
    ./sh.nix

    # Nix optimization
    ./nix-optimization.nix

    # Home Assistant
    ./home-assistant.nix

    # Music Assistant
    ./music-assistant.nix
  ];
}
