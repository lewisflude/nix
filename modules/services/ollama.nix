# Ollama AI Service Module - Dendritic Pattern
# Local LLM inference server
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

      # Enable NVIDIA container toolkit for other CUDA needs
      hardware.nvidia-container-toolkit.enable = true;
    };
}
