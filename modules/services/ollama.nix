# Ollama + Open WebUI - Local LLM inference
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.ollama =
    { pkgs, ... }:
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
        loadModels = [
          "llama3.2"
          "qwen2.5-coder"
        ];
        host = "127.0.0.1";
        port = constants.ports.services.ollama;
        environmentVariables = {
          OLLAMA_KEEP_ALIVE = "24h";
        };
      };

      services.open-webui = {
        enable = true;
        port = constants.ports.services.openWebui;
        openFirewall = true;
        environment = {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          OLLAMA_API_BASE_URL = "http://127.0.0.1:${toString constants.ports.services.ollama}";
        };
      };

      hardware.nvidia-container-toolkit.enable = true;
    };
}
