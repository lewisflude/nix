# Bridge module: Maps host.features.aiTools to host.services.aiTools
# This allows host configurations to use the features interface
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.aiTools;
in
{
  config = mkIf cfg.enable {
    # Map features to services
    host.services.aiTools = {
      enable = true;
      ollama = cfg.ollama or { };
      openWebui = cfg.openWebui or { };
    };
  };
}
