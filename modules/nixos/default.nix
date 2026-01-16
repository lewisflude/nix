{
  imports = [

    ./features/desktop
    ./features/theming
    ./features/security.nix
    ./features/gaming.nix
    ./features/vr
    ./features/home-server.nix
    ./features/restic.nix
    ./features/media-management.nix
    ./features/ai-tools.nix
    ./features/containers-supplemental.nix
    ./features/boot-optimization.nix
    ./features/flatpak.nix

    ./core
    ./hardware
    ./services
    ./development
    ./system
  ];
}
