{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkAfter;
  inherit (lib.lists) optional;
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

    networking.firewall.allowedTCPPorts = [ cfg.openWebui.port ];

    systemd.services.open-webui.serviceConfig = {
      User = cfg.user;
      Group = cfg.group;
    };

    systemd.services.open-webui = {
      after = mkAfter (optional cfg.ollama.enable "ollama.service");
    };
  };
}
