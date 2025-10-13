{
  imports = [
    # Core configuration
    ./host-options.nix
    ./core.nix
    ./shell.nix
    ./dev.nix
    ./environment.nix
    ./overlays.nix
    ./cachix.nix
    ./sops.nix
    ./telemetry.nix

    # Cross-platform feature modules
    ./features/development.nix
    ./features/security.nix
    ./features/productivity.nix
    ./features/desktop.nix
  ];
}
