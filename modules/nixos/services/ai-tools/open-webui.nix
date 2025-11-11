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
      inherit (cfg.openWebui)
        package
        port
        host
        stateDir
        openFirewall
        ;
      environment = {
        OLLAMA_BASE_URL = cfg.openWebui.ollamaUrl;
        WEBUI_AUTH = "True";
      };
      # Use environmentFile if provided (for secrets like API keys)
      inherit (cfg.openWebui) environmentFile;
    };

    # Override user/group to match aiTools configuration
    systemd.services.open-webui.serviceConfig = {
      inherit (cfg) user group;
    };

    # Ensure Open WebUI starts after Ollama if both are enabled
    systemd.services.open-webui = {
      after = mkAfter (optional cfg.ollama.enable "ollama.service");
    };
  };
}
