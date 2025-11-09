{
  ...
}:
{
  # Main flake-parts entry point
  # Imports all modular components
  #
  # Import order matters:
  # 1. Systems and module args (foundation)
  # 2. perSystem/pkgs (must be before other perSystem modules that use pkgs)
  # 3. perSystem/pog-overlay (depends on pkgs)
  # 4. Other perSystem modules (formatters, checks, devShells, apps, topology)
  # 5. Flake-level outputs (darwin, nixos, lib, overlays)

  imports = [
    # Foundation
    ./systems.nix
    ./module-args.nix
    # perSystem: package setup
    ./per-system/pkgs.nix
    ./per-system/pog-overlay.nix
    # perSystem: outputs
    ./per-system/formatters.nix
    ./per-system/checks.nix
    ./per-system/devShells.nix
    ./per-system/apps.nix
    ./per-system/topology.nix
    # Flake-level outputs
    ./outputs/darwin.nix
    ./outputs/nixos.nix
    ./outputs/lib.nix
    ./outputs/overlays.nix
  ];
}
