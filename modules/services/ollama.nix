# Ollama AI Service Module - Dendritic Pattern
# Local LLM inference server
{ config, ... }:
let
  constants = config.constants;
in
{
  flake.modules.nixos.ollama =
    { lib, pkgs, config, ... }:
    let
      inherit (lib) mkMerge mkAfter;
      models = [ "llama3.2" "qwen2.5-coder" ];
    in
    {
      # User and group for AI tools
      users.users.aitools = {
        isSystemUser = true;
        group = "aitools";
        description = "AI tools services user";
      };

      users.groups.aitools = { };

      # Ollama service
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda; # CUDA acceleration
        environmentVariables = {
          OLLAMA_KEEP_ALIVE = "24h";
        };
        host = "127.0.0.1";
        port = constants.ports.services.ollama;
      };

      # Enable NVIDIA container toolkit for CUDA
      hardware.nvidia-container-toolkit.enable = true;

      # Pre-download models
      systemd.services.ollama-models = {
        description = "Pre-download Ollama models";
        after = [ "ollama.service" ];
        wants = [ "ollama.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          User = "aitools";
          Group = "aitools";
        };

        script =
          let
            modelPulls = lib.concatMapStringsSep "\n" (model: "ollama pull ${model} || true") models;
          in
          ''
            # Wait for Ollama to be ready
            for i in {1..30}; do
              if ${pkgs.curl}/bin/curl -s http://127.0.0.1:${toString constants.ports.services.ollama}/api/tags >/dev/null 2>&1; then
                break
              fi
              sleep 2
            done

            # Pull models
            ${modelPulls}
          '';
      };

      # Open WebUI (configured in host definition)
      # services.open-webui is configured there with port
    };
}
