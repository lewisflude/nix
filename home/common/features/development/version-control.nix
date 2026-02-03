# Version control development tools
# Dendritic pattern: Uses osConfig instead of systemConfig
{
  lib,
  osConfig ? {},
  ...
}:
let
  cfg = osConfig.host.features.development or {};
in
{
  imports = [
    ../../apps/gh.nix
  ];

  config = lib.mkIf (cfg.enable or false) {

  };
}
