# Bridge module: Maps host.features.aiTools to host.services.aiTools
# This allows host configurations to use the features interface
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.host.features.aiTools or {};
in {
  config = mkIf (cfg.enable or false) {
    # Map features to services
    host.services.aiTools = {
      enable = true;
      ollama = cfg.ollama or {};
      openWebui = cfg.openWebui or {};
    };
  };
}
