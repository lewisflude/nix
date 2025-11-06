{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.virtualisation;
in
{
  config = mkIf cfg.enable {

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
          dockerCompat = !cfg.docker;
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

    users.users.${config.host.username}.extraGroups =
      optional cfg.docker "docker" ++ optional cfg.qemu "libvirtd" ++ optional cfg.virtualbox "vboxusers";

    environment.systemPackages =
      with pkgs;
      optionals cfg.qemu [
        virt-manager
        qemu
      ];
  };
}
