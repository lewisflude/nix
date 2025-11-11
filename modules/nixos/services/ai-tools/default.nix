{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    mkPackageOption
    types
    ;
  cfg = config.host.services.aiTools;
in
{
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

    ollama = {
      enable = mkEnableOption "Ollama LLM backend" // {
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
        default = [ ];
        description = "List of models to pre-download";
        example = [
          "llama2"
          "mistral"
        ];
      };
    };

    openWebui = {
      enable = mkEnableOption "Open WebUI interface for LLMs" // {
        default = true;
      };

      package = mkPackageOption pkgs "open-webui" { };

      port = mkOption {
        type = types.port;
        default = 7000;
        description = "Port for Open WebUI";
      };

      host = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = "Host address to bind to";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to open the firewall for Open WebUI";
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/lib/open-webui";
        description = "Directory for Open WebUI state";
      };

      ollamaUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:11434";
        description = "URL to Ollama backend";
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to environment file for sensitive configuration";
      };
    };
  };

  config = mkIf cfg.enable {

    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      description = "AI tools services user";
    };

    users.groups.${cfg.group} = { };
  };
}
