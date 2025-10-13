{
  imports = [
    # NixOS-specific feature modules
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
