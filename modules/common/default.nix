{
  imports = [
    ./core.nix
    ./shell.nix
    ./dev.nix
    ./docker.nix
    ./environment.nix
    # ./nix-optimization.nix  # Temporarily disabled
    ./overlays.nix
    ./cachix.nix
  ];
}
