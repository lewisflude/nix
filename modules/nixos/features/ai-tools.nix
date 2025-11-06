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

    host.services.aiTools = {
      enable = true;
      ollama = cfg.ollama or { };
      openWebui = cfg.openWebui or { };
    };
  };
}
