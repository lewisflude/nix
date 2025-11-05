{
  imports = [
    ./host-options/core.nix
    ./host-options/features.nix
    ./host-options/services.nix
    ./core.nix
    ./shell.nix
    ./dev.nix
    ./environment.nix
    ./overlays.nix
    ./cachix.nix
    ./sops.nix
    ./telemetry.nix

    ./features/development
    ./features/security
    ./features/productivity
    ./features/desktop
  ];
}
