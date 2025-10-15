# Security feature module (cross-platform)
# Controlled by host.features.security.*
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.features.security;
in {
  config = mkIf cfg.enable {};
}
