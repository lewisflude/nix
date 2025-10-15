# Productivity feature module (cross-platform)
# Controlled by host.features.productivity.*
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.features.productivity;
in {
  config = mkIf cfg.enable {};
}
