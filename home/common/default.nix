{...}: {
  # Import the full profile by default
  # For a lighter setup, import a different profile in your host configuration
  imports = [
    ./profiles/full.nix

    # Feature modules gated via host.features
    ./features/desktop.nix
    ./features/development.nix
    ./features/productivity.nix
    ./features/security.nix
  ];
}
