{
  imports = [
    # NixOS-specific feature modules
    ./features/desktop
    ./features/security.nix
    ./features/gaming.nix
    ./features/virtualisation.nix
    ./features/audio.nix
    ./features/home-server.nix
    ./features/restic.nix
    ./features/containers.nix
    ./features/media-management.nix
    ./features/ai-tools.nix
    ./features/containers-supplemental.nix

    # System modules
    ./core
    ./hardware
    ./services
    ./development
    ./system
  ];
}
