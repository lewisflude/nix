{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: let
  inherit (lib) mkIf mkMerge optionalAttrs;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.virtualisation;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  inherit (platformLib) isLinux;
  inherit (platformLib) isDarwin;
in {
  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs isLinux {
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
      ];

      users.users.${config.host.username}.extraGroups =
        optional cfg.docker "docker" ++ optional cfg.qemu "libvirtd" ++ optional cfg.virtualbox "vboxusers";

      environment.systemPackages = with pkgs;
        optionals cfg.qemu [
          virt-manager
          qemu
          qemu_kvm
        ]
        ++ optionals cfg.podman [
          podman-compose
          buildah
          skopeo
        ]
        ++ optionals cfg.docker [
          docker-client
        ];
    })

    (optionalAttrs isDarwin {
      homebrew = {
        casks = optionals cfg.docker [
          "docker"
        ];
      };
    })

    {
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
    }
  ]);
}
