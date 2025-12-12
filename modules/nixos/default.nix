{
  imports = [

    ./features/desktop
    ./features/theming
    ./features/security.nix
    ./features/gaming.nix
    ./features/home-server.nix
    ./features/restic.nix
    ./features/media-management.nix
    ./features/ai-tools.nix
    ./features/containers-supplemental.nix

    ./core
    ./hardware
    ./services
    ./development
    ./system
  ];
}
