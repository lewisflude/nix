# ComfyUI Service (Native Nix Package)
#
# This module configures ComfyUI using the utensils/nix-comfyui flake instead
# of a Docker container. The flake provides:
# - Automatic GPU detection (CUDA, MPS, CPU fallback)
# - Python 3.12 support
# - ComfyUI-Manager for plugin management
# - Persistent data in configurable directory
#
# Replaces: modules/nixos/services/containers-supplemental/services/comfyui.nix
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
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.services.comfyui;
in
{
  options.services.comfyui = {
    enable = mkEnableOption "ComfyUI AI Image Generation (native package)";

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/comfyui";
      description = "Directory for ComfyUI data (models, outputs, user files).";
    };

    port = mkOption {
      type = types.int;
      default = constants.ports.services.comfyui;
      description = "Port for ComfyUI web interface.";
    };

    user = mkOption {
      type = types.str;
      default = "comfyui";
      description = "User account under which ComfyUI runs.";
    };

    group = mkOption {
      type = types.str;
      default = "comfyui";
      description = "Group under which ComfyUI runs.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments to pass to ComfyUI.";
      example = [
        "--listen"
        "0.0.0.0"
      ];
    };

    enableGpu = mkOption {
      type = types.bool;
      default = true;
      description = "Enable GPU acceleration (automatically detected by flake).";
    };

    openFirewall = mkEnableOption "Open firewall ports for ComfyUI" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # Add ComfyUI package from flake
    environment.systemPackages = [ pkgs.comfyui ];

    # Create systemd service
    systemd.services.comfyui = {
      description = "ComfyUI AI Image Generation";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = lib.concatStringsSep " " (
          [
            "${pkgs.comfyui}/bin/comfyui"
            "--listen"
            "0.0.0.0"
            "--port"
            (toString cfg.port)
          ]
          ++ cfg.extraArgs
        );
        Restart = "on-failure";
        RestartSec = "10s";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];

        # Resource limits
        MemoryMax = "16G";
        CPUQuota = "800%";
      };

      environment = {
        COMFYUI_DATA_DIR = cfg.dataDir;
        # GPU support is automatic via the flake's detection
      };

      preStart = ''
        # Ensure data directories exist with correct permissions
        mkdir -p ${cfg.dataDir}/{models,output,input,user}
        chown -R ${cfg.user}:${cfg.group} ${cfg.dataDir}
      '';
    };

    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.dataDir;
      createHome = true;
      description = "ComfyUI service user";
    };

    users.groups.${cfg.group} = { };

    # GPU support is handled automatically by the comfyui flake (CUDA/MPS detection)
    # Configure NVIDIA drivers at the host level if needed

    # Firewall configuration
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
