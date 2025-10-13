{...}: {
  # Import the full profile by default
  # For a lighter setup, import a different profile in your host configuration
  imports = [
    ./profiles/full.nix
  ];
}
