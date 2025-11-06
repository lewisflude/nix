{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.strings) concatMapStringsSep;
  cfg = config.host.services.aiTools;
in
{
  config = mkIf (cfg.enable && cfg.ollama.enable) {
    services.ollama = {
      enable = true;
      inherit (cfg.ollama) acceleration;
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "24h";
      };

      host = "127.0.0.1";
      port = 11434;
    };

    hardware.nvidia-container-toolkit.enable = mkIf (cfg.ollama.acceleration == "cuda") true;

    systemd.services.ollama-models = mkIf (cfg.ollama.models != [ ]) {
      description = "Pre-download Ollama models";
      after = [ "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = cfg.user;
        Group = cfg.group;
      };

      script =
        let
          modelPulls = concatMapStringsSep "\n" (model: "ollama pull ${model} || true") cfg.ollama.models;
        in
        ''

          for i in {1..30}; do
            if curl -s http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done


          ${modelPulls}
        '';
    };
  };
}
