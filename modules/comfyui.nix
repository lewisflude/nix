# ComfyUI Service Module - Dendritic Pattern
# AI image generation with GPU acceleration
# Usage: Import flake.modules.nixos.comfyui in host definition
{ config, ... }:
let
  constants = config.constants;
in
{
  # ==========================================================================
  # NixOS System Configuration
  # ==========================================================================
  flake.modules.nixos.comfyui =
    { lib, pkgs, ... }:
    let
      inherit (lib) mkDefault mkIf concatStringsSep;

      # Default configuration (can be overridden by hosts)
      dataDir = "/var/lib/comfyui";
      port = constants.ports.services.comfyui;
      user = "comfyui";
      group = "comfyui";
    in
    {
      # Create user and group
      users.users.${user} = mkDefault {
        isSystemUser = true;
        inherit group;
        home = dataDir;
        createHome = true;
        description = "ComfyUI service user";
      };

      users.groups.${group} = mkDefault { };

      # Add ComfyUI package from flake
      environment.systemPackages = [ pkgs.comfyui ];

      # Create systemd service
      systemd.services.comfyui = {
        description = "ComfyUI AI Image Generation";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = concatStringsSep " " [
            "${pkgs.comfyui}/bin/comfyui"
            "--listen"
            "0.0.0.0"
            "--port"
            (toString port)
          ];
          Restart = "on-failure";
          RestartSec = "10s";
          User = user;
          Group = group;
          WorkingDirectory = dataDir;

          # Security hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ dataDir ];

          # Resource limits
          MemoryMax = mkDefault "16G";
          CPUQuota = mkDefault "800%";
        };

        environment = {
          COMFYUI_DATA_DIR = dataDir;
          # GPU support is automatic via the flake's detection
        };

        preStart = ''
          # Ensure data directories exist with correct permissions
          mkdir -p ${dataDir}/{models,output,input,user}
          chown -R ${user}:${group} ${dataDir}
        '';
      };

      # GPU support is handled automatically by the comfyui flake (CUDA/MPS detection)
      # Configure NVIDIA drivers at the host level if needed

      # Firewall configuration
      networking.firewall.allowedTCPPorts = mkDefault [ port ];
    };
}
