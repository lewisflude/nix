# Security feature module (cross-platform)
# Controlled by host.features.security.*
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
with lib; let
  cfg = config.host.features.security;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
in {
  config = mkIf cfg.enable {};
}
