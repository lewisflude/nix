{
  imports = [
    ./host-options/core.nix
    ./host-options/features
    ./host-options/hardware.nix
    ./host-options/system.nix
    ./host-options/services/media-management.nix
    ./host-options/services/containers-supplemental.nix
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
    ./features/media
  ];
}
