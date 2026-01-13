# AI Tools Feature Options
{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  aiTools = {
    enable = mkEnableOption "AI tools stack (Ollama, Open WebUI) - NixOS only" // {
      default = false;
      example = true;
    };

    ollama = {
      enable = mkEnableOption "Ollama LLM backend" // {
        default = true;
        example = true;
      };
      acceleration = mkOption {
        type = types.nullOr (
          types.enum [
            "rocm"
            "cuda"
          ]
        );
        default = null;
        description = "GPU acceleration type (null for CPU-only)";
        example = "cuda";
      };
      models = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of models to pre-download";
        example = [
          "llama3"
          "mistral"
        ];
      };
    };

    openWebui = {
      enable = mkEnableOption "Open WebUI interface for LLMs" // {
        default = true;
        example = true;
      };
      port = mkOption {
        type = types.port;
        default = 7000;
        description = "Port for Open WebUI";
        example = 7000;
      };
    };
  };
}
