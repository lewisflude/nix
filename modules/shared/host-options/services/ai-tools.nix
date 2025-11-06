{
  lib,
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.host.features.aiTools = {
    enable = mkEnableOption "AI tools and LLM services";

    ollama = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Ollama LLM backend";
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
      };

      models = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of models to pre-download";
        example = [
          "llama2"
          "mistral"
        ];
      };
    };

    openWebui = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Open WebUI interface for LLMs";
      };

      port = mkOption {
        type = types.port;
        default = 7000;
        description = "Port for Open WebUI";
      };
    };
  };
}
