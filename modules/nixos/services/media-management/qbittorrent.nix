# Backward compatibility shim - redirects to new modular structure
# This file is kept for compatibility with existing imports
# New code should import modules/nixos/services/media-management/qbittorrent/default.nix directly
{
  imports = [
    ./qbittorrent/default.nix
  ];
}
