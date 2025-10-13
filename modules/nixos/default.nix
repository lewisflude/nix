{
  imports = [
    # NixOS-specific modules
    ./telemetry.nix

    # NixOS-specific feature modules
    ./features/desktop.nix
    ./features/security.nix
    ./features/gaming.nix
    ./features/virtualisation.nix
    ./features/audio.nix
    ./features/home-server.nix

    # System modules
    ./core
    ./desktop
    ./hardware
    ./services
    ./development
    ./system
  ];
}
