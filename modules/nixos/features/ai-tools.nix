{
  config,
  lib,
  pkgs,
  constants,
  ...
}:
let
  inherit (lib)
    mkIf
    mkAfter
    mkOption
    types
    ;
  inherit (lib.lists) optional;
  inherit (lib.strings) concatMapStringsSep;

  cfg = config.host.features.aiTools;
in
{
  # Additional options not in shared/host-options/features.nix
  options.host.features.aiTools = {
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

    openWebui = {
      ollamaUrl = mkOption {
        type = types.str;
        default = "http://127.0.0.1:${toString constants.ports.services.ollama}";
        description = ''
          URL to Ollama backend.
          Configure other options directly via `services.open-webui.*`
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      description = "AI tools services user";
    };

    users.groups.${cfg.group} = { };

    # Configure Ollama
    services.ollama = mkIf cfg.ollama.enable {
      enable = true;
      package =
        if cfg.ollama.acceleration == "cuda" then
          pkgs.ollama-cuda
        else if cfg.ollama.acceleration == "rocm" then
          pkgs.ollama-rocm
        else
          pkgs.ollama; # CPU-only by default
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "24h";
      };
      host = "127.0.0.1";
      port = constants.ports.services.ollama;
    };

    # Enable NVIDIA container toolkit if using CUDA
    hardware.nvidia-container-toolkit.enable = mkIf (
      cfg.ollama.enable && cfg.ollama.acceleration == "cuda"
    ) true;

    # Pre-download Ollama models
    systemd.services.ollama-models = mkIf (cfg.ollama.enable && cfg.ollama.models != [ ]) {
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
          # Wait for Ollama to be ready
          for i in {1..30}; do
            if curl -s http://127.0.0.1:${toString constants.ports.services.ollama}/api/tags >/dev/null 2>&1; then
              break
            fi
            sleep 2
          done

          # Pull models
          ${modelPulls}
        '';
    };

    # Configure Open WebUI with sensible defaults
    # Users can override via services.open-webui.* for advanced configuration
    services.open-webui = mkIf cfg.openWebui.enable {
      enable = true;
      environment = {
        OLLAMA_BASE_URL = cfg.openWebui.ollamaUrl;
        WEBUI_AUTH = "True";
      };
    };

    # Override Open WebUI user/group to match aiTools configuration
    systemd.services.open-webui = mkIf cfg.openWebui.enable {
      serviceConfig = {
        inherit (cfg) user group;
      };
      # Ensure Open WebUI starts after Ollama if both are enabled
      after = mkAfter (optional cfg.ollama.enable "ollama.service");
    };
  };
}
