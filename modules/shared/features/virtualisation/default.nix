{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  inherit (lib) mkIf mkMerge optionalAttrs;
  inherit (lib.lists) optional optionals;
  cfg = config.host.features.virtualisation;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  inherit (platformLib) isLinux;
  inherit (platformLib) isDarwin;
in
{
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

            # Podman 5.0+ uses pasta as default network backend (more secure than slirp4netns)
            # Pasta provides better IPv6 support, improved security isolation, and modern Linux mechanisms
            defaultNetwork.settings = {
              dns_enabled = true;
            };

            # Auto-prune containers, images, and volumes to save disk space
            autoPrune = {
              enable = true;
              dates = "weekly";
              flags = [ "--all" ];
            };
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

      # SELinux support for Podman containers (enhanced security isolation)
      # Only enable if SELinux is available and activated on the system
      virtualisation.podman.extraPackages = mkIf (cfg.podman && config.security.selinux.enable or false) [
        pkgs.podman-selinux
      ];

      environment.systemPackages =
        optionals cfg.qemu [
          pkgs.virt-manager
          pkgs.qemu
          pkgs.qemu_kvm
        ]
        ++ optionals cfg.podman [
          pkgs.podman-compose
          pkgs.buildah
          pkgs.skopeo
        ]
        ++ optionals cfg.docker [
          pkgs.docker-client
          pkgs.docker-compose
          pkgs.docker-credential-helpers
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
