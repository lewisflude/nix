# Backward compatibility shim - redirects to new modular structure
# This file is kept for compatibility with existing imports
# New code should import home/common/features/core/shell/default.nix directly
{
  pkgs,
  config,
  systemConfig,
  system,
  hostSystem,
  lib,
  inputs,
  ...
}:
import ./shell/default.nix {
  inherit
    pkgs
    config
    systemConfig
    system
    hostSystem
    lib
    inputs
    ;
}
