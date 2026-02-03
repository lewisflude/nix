# Backward compatibility shim - redirects to new modular structure
# This file is kept for compatibility with existing imports
# New code should import home/common/features/core/shell/default.nix directly
# Dendritic pattern: Uses osConfig, let modules access platform via pkgs.stdenv
{
  pkgs,
  config,
  osConfig ? {},
  lib,
  ...
}:
import ./shell/default.nix {
  inherit
    pkgs
    config
    osConfig
    lib
    ;
}
