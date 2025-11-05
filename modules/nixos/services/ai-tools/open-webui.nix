# Open WebUI - Web interface for LLMs
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.host.services.aiTools;
in
{
  config = mkIf (cfg.enable && cfg.openWebui.enable) {
    services.open-webui = {
      enable = true;
      inherit (cfg.openWebui) port;
      host = "0.0.0.0";
      environment = {
        OLLAMA_BASE_URL = cfg.openWebui.ollamaUrl;
        WEBUI_AUTH = "True";
      };
    };

    # Open firewall
    networking.firewall.allowedTCPPorts = [ cfg.openWebui.port ];

    # Run as common productivity user
    systemd.services.open-webui.serviceConfig = {
      User = cfg.user;
      Group = cfg.group;
    };

    # Soft dependency on ollama
    systemd.services.open-webui = {
      after = mkAfter (optional cfg.ollama.enable "ollama.service");
    };
  };
}
