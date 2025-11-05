# Virtualisation feature module (cross-platform)
# Controlled by host.features.virtualisation.*
# Provides unified virtualization configuration for NixOS and Darwin
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
with lib; let
  cfg = config.host.features.virtualisation;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  isLinux = platformLib.isLinux;
  isDarwin = platformLib.isDarwin;
in {
  config = mkIf cfg.enable {
    # NixOS-specific virtualization configuration
    virtualisation = mkIf isLinux (mkMerge [
      (mkIf cfg.docker {
        docker = {
          enable = true;
          enableOnBoot = true;
          storageDriver = "zfs";
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
        };
      })
      (mkIf cfg.podman {
        podman = {
          enable = true;
          dockerCompat = !cfg.docker; # Only if docker is not enabled
          defaultNetwork.settings.dns_enabled = true;
        };
      })
      (mkIf cfg.qemu {
        libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            runAsRoot = false;
            swtpm.enable = true;
            ovmf = {
              enable = true;
              packages = [pkgs.OVMFFull.fd];
            };
          };
        };
      })
      (mkIf cfg.virtualbox {
        virtualbox = {
          host = {
            enable = true;
            enableExtensionPack = true;
          };
        };
      })
    ]);

    # Add user to virtualisation groups (NixOS only)
    users.users.${config.host.username}.extraGroups = mkIf isLinux (
      optional cfg.docker "docker" ++ optional cfg.qemu "libvirtd" ++ optional cfg.virtualbox "vboxusers"
    );

    # System-level packages (NixOS only)
    environment.systemPackages = mkIf isLinux (
      with pkgs;
        [
          # QEMU tools
        ]
        ++ optionals cfg.qemu [
          virt-manager # Virtual machine manager GUI
          qemu # QEMU emulator
          qemu_kvm # QEMU with KVM support
        ]
        # Podman tools
        ++ optionals cfg.podman [
          podman-compose # Podman Compose
          buildah # Build container images
          skopeo # Container image management
        ]
        # Docker tools (system-level, client tools in home-manager)
        ++ optionals cfg.docker [
          docker-client # Docker CLI
        ]
    );

    # Darwin-specific virtualization handling
    # Note: Docker Desktop on macOS is typically installed via Homebrew or Docker Desktop installer
    # This module provides configuration hooks for potential future integration
    # For now, Darwin users should use Docker Desktop or colima
    homebrew = mkIf isDarwin {
      casks = optionals cfg.docker [
        "docker" # Docker Desktop for macOS
      ];
    };

    # Assertions
    assertions = [
      {
        assertion = !(cfg.docker && cfg.podman) || isLinux;
        message = "Docker and Podman cannot both be enabled on Darwin (use Docker Desktop)";
      }
      {
        assertion = cfg.qemu -> isLinux;
        message = "QEMU/KVM virtualization is only available on Linux";
      }
      {
        assertion = cfg.virtualbox -> isLinux;
        message = "VirtualBox is only available on Linux";
      }
    ];
  };
}
