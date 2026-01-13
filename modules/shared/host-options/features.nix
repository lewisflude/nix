# Backward compatibility shim - redirects to new modular structure
# This file is kept for compatibility with existing imports
# New code should import modules/shared/host-options/features/default.nix directly
{
  imports = [
    ./features/default.nix
  ];
}
