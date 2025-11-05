# Native NixOS AI Tools Stack
# Uses official NixOS modules for AI tools (Ollama, Open WebUI)
{
  config,
  lib,
  ...
}: let
  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.host.services.aiTools;
in {
  imports = [
    ./ollama.nix
    ./open-webui.nix
  ];

  options.host.services.aiTools = {
    enable = mkEnableOption "native AI tools stack (Ollama, Open WebUI)";

    user = mkOption {
      type = types.str;
      default = "aitools";
      description = "User to run AI tools services as";
    };

    group = mkOption {
      type = types.str;
      default = "aitools";
      description = "Group to run AI tools services as";
    };

    # Service-specific enables
    ollama = {
      enable =
        mkEnableOption "Ollama LLM backend"
        // {
          default = true;
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
        default = [];
        description = "List of models to pre-download";
        example = [
          "llama2"
          "mistral"
        ];
      };
    };

    openWebui = {
      enable =
        mkEnableOption "Open WebUI interface for LLMs"
        // {
          default = true;
        };

      port = mkOption {
        type = types.port;
        default = 7000;
        description = "Port for Open WebUI";
      };

      ollamaUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:11434";
        description = "URL to Ollama backend";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create common AI tools user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      description = "AI tools services user";
    };

    users.groups.${cfg.group} = {};
  };
}
