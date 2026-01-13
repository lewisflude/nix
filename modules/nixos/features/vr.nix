# Backward compatibility shim - redirects to new modular structure
# This file is kept for compatibility with existing imports
# New code should import modules/nixos/features/vr/default.nix directly
{
  config,
  pkgs,
  lib,
  ...
}:
(import ./vr/default.nix) { inherit config pkgs lib; }
