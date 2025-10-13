# Virtualisation feature module for NixOS
# Controlled by host.features.virtualisation.*
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.host.features.virtualisation;
in {
  config = mkIf cfg.enable {
    # Docker configuration
    virtualisation.docker = mkIf cfg.docker {
      enable = true;
      enableOnBoot = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    # Podman configuration
    virtualisation.podman = mkIf cfg.podman {
      enable = true;
      dockerCompat = !cfg.docker; # Only if docker is not enabled
      defaultNetwork.settings.dns_enabled = true;
    };

    # QEMU/KVM configuration
    virtualisation.libvirtd = mkIf cfg.qemu {
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

    # VirtualBox configuration
    virtualisation.virtualbox.host = mkIf cfg.virtualbox {
      enable = true;
      enableExtensionPack = true;
    };

    # Add user to virtualisation groups
    users.users.${config.host.username}.extraGroups =
      []
      ++ optional cfg.docker "docker"
      ++ optional cfg.qemu "libvirtd"
      ++ optional cfg.virtualbox "vboxusers";

    # Install related tools
    environment.systemPackages = with pkgs;
      []
      ++ optionals cfg.docker [
        docker-compose
        lazydocker
      ]
      ++ optionals cfg.qemu [
        virt-manager
        qemu
      ];
  };
}
