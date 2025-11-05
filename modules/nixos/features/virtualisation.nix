# Virtualisation feature module for NixOS
# Controlled by host.features.virtualisation.*
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.host.features.virtualisation;
in
{
  config = mkIf cfg.enable {
    # Virtualisation tooling
    virtualisation = mkMerge [
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
              packages = [ pkgs.OVMFFull.fd ];
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
    ];

    # Add user to virtualisation groups
    users.users.${config.host.username}.extraGroups =
      optional cfg.docker "docker" ++ optional cfg.qemu "libvirtd" ++ optional cfg.virtualbox "vboxusers";

    # Install related tools
    # Note: docker-compose and lazydocker moved to home-manager
    # See home/common/apps/docker.nix and home/common/apps/lazydocker.nix
    environment.systemPackages =
      with pkgs;
      optionals cfg.qemu [
        virt-manager
        qemu
      ];
  };
}
