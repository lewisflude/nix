{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkAfter
    mkOption
    mkPackageOption
    types
    ;
  inherit (lib.lists) optional;
  inherit (lib.strings) concatMapStringsSep;

  cfg = config.host.features.aiTools;
  constants = import ../../../lib/constants.nix;
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
      package = mkPackageOption pkgs "open-webui" { };

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
        default = "http://127.0.0.1:${toString constants.ports.services.ollama}";
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
      inherit (cfg.ollama) acceleration;
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

    # Configure Open WebUI
    services.open-webui = mkIf cfg.openWebui.enable {
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
      inherit (cfg.openWebui) environmentFile;
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
